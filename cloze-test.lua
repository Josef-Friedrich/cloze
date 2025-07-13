local lparse = require('lparse')
local luakeys = require('luakeys')()
local cloze = require('cloze')
-- local assert = require('luassert')

---@class VerbatimCapture
---@field title? string
---@field description? string
---@field lines string[]

-- https://tug.org/TUGboat/tb32-1/tb100isambert.pdf
---@type VerbatimCapture[]
local all_captures = {}

---@type VerbatimCapture
local last_capture

local is_latex = luatexbase ~= nil

---
---Register a callback independently of the engine
---(plain `LuaTeX` or `LuaLaTeX`).
---
---@param callback_name CallbackName # The name of the callback to register.
---@param fn function # A function to register for the callback
---@param description string # A description to identify the function (only used in LuaLaTeX).
local function register_callback(callback_name,
  fn,
  description)
  if luatexbase then
    luatexbase.add_to_callback(callback_name, fn, description)
  else
    callback.register(callback_name, fn)
  end
end

---
---Unregister a callback independently of the engine
---(plain `LuaTeX` or `LuaLaTeX`).
---
---@param callback_name CallbackName # The name of the callback to unregister.
---@param description string # A description to identify the function (only used in LuaLaTeX).
local function unregister_callback(callback_name,
  description)
  if luatexbase then
    luatexbase.remove_from_callback(callback_name, description)
  else
    callback.register(callback_name, nil)
  end
end

local function store_lines(str)
  if string.find(str, '\\tEndVerbatim') then
    unregister_callback('process_input_buffer', 'store_lines')
    table.insert(all_captures, last_capture)
  else
    table.insert(last_capture.lines, str)
  end
  return ''
end

---
---@param title? string
---@param description? string
local function capture(title, description)
  last_capture = { lines = {} }
  if title ~= nil then
    last_capture.title = title
  end
  if description ~= nil then
    last_capture.description = description
  end
  register_callback('process_input_buffer', store_lines, 'store_lines')
end

local defs = luakeys.DefinitionManager({
  title = { data_type = 'string' },
  desciption = { data_type = 'string' },
})

---
---@param capture? VerbatimCapture
---
---@return VerbatimCapture capture
local function get_capture(capture)
  if capture == nil then
    return last_capture
  end
  return capture
end

---
---@param capture? VerbatimCapture
local function print_last_verbatim(capture)
  capture = get_capture(capture)
  if is_latex then
    tex.print('\\begin{minted}{latex}')
    tex.print(capture.lines)
    tex.print('\\end{minted}')
  else
    tex.print('\\bigskip')
    tex.print('\\FarbeColor{gray}')
    tex.print('\\bgroup\\parindent=0pt \\tt')
    tex.print(1, capture.lines)
    tex.print('\\egroup\\FarbeColorEnd')
    tex.print('\\FarbeColorEnd')
    tex.print('\\bigskip')
  end
end

---
---@param capture? VerbatimCapture
local function use_last(capture)
  capture = get_capture(capture)
  tex.print(capture.lines)
end

local function print_all()
  for _, capture in ipairs(all_captures) do
    if capture.title then
      tex.sprint('\\tSection{')
      tex.sprint(-2, capture.title)
      tex.sprint('}')
    end
    if capture.description then
      tex.sprint('\\tComment{')
      tex.sprint(-2, capture.description)
      tex.print('}')
    end
    print_last_verbatim(capture)
    use_last(capture)
  end
end

--- deeply compare two objects
--- https://gist.github.com/sapphyrus/fd9aeb871e3ce966cc4b0b969f62f539?permalink_comment_id=4563041#gistcomment-4563041
---
local function deep_equals(o1, o2, ignore_mt)
  -- same object
  if o1 == o2 then
    return true
  end

  local o1Type = type(o1)
  local o2Type = type(o2)
  --- different type
  if o1Type ~= o2Type then
    return false
  end
  --- same type but not table, already compared above
  if o1Type ~= 'table' then
    return false
  end

  -- use metatable method
  if not ignore_mt then
    local mt1 = getmetatable(o1)
    if mt1 and mt1.__eq then
      -- compare using built in method
      return o1 == o2
    end
  end

  -- iterate over o1
  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or deep_equals(value1, value2, ignore_mt) == false then
      return false
    end
  end

  --- check keys in o2 but missing from o1
  for key2, _ in pairs(o2) do
    if o1[key2] == nil then
      return false
    end
  end
  return true
end

---
---@param expected_kv_string string
---@param actual unknown
local function assert_same(expected_kv_string, actual)
  local _, _, expected = luakeys.parse(expected_kv_string)
  if not deep_equals(actual, expected) then
    print('\nActual:')
    luakeys.debug(actual)
    print('\nExpected:')
    luakeys.debug(expected)
    print('\nRendered:')
    print(luakeys.render(actual))
    tex.error('The provided tables are not the same!')
  end
end

return {
  set_if_plain_luatex = function()
    if is_latex then
      tex.print('\\PLAINLUATEXfalse')
    else
      tex.print('\\PLAINLUATEXtrue')
    end
  end,

  print_last_verbatim = print_last_verbatim,

  use_last = use_last,

  print_all = print_all,

  register_functions = function()
    lparse.register_csname('tBeginVerbatim', function()
      local kv_string = lparse.scan('m')
      local result = defs:parse(kv_string)
      capture(result.title, result.desciption)
    end)

    lparse.register_csname('tAssertAllLocalOpts', function()
      local kv_string = lparse.scan('m')
      assert_same(kv_string, cloze.export_all_local_opts())
    end)

    lparse.register_csname('tAssertAllStartMarker', function()
      local kv_string = lparse.scan('m')
      assert_same(kv_string, cloze.export_all_start_marker())
    end)

    lparse.register_csname('tAssertGroupOpts', function()
      local group, kv_string = lparse.scan('m m')
      assert_same(kv_string, cloze.export_group_opts(group))
    end)

    lparse.register_csname('tAssertAllGroupOpts', function()
      local kv_string = lparse.scan('m')
      assert_same(kv_string, cloze.export_all_group_opts())
    end)

    lparse.register_csname('tAssertGlobalOpts', function()
      local kv_string = lparse.scan('m')
      assert_same(kv_string, cloze.export_global_opts())
    end)
  end,

  print_title = function()
    tex.setcatcode('global', utf8.codepoint('_'), 12)

    local title, description = lparse.scan('m O{}')

    -- title
    tex.sprint('\\noindent{\\tTypewriterFontBigger')
    if is_latex then
      tex.sprint('LuaLa\\TeX{}: ')
    else
      tex.sprint('Lua\\TeX{}: ')
    end
    tex.sprint(-2, title)
    tex.print('}\\par')

    -- description
    if description ~= nil then
      tex.print('\\noindent{\\tTypewriterFontNormal{}' .. description ..
                  '}\\par')
    end
    tex.sprint('{\\noindent\\tTypewriterFontNormal{}Test file: ')
    tex.sprint(-2, tex.jobname)
    tex.sprint({ '.tex}', '\\par', '\\hrule depth 1pt', '\\bigskip' })
  end,

}
