local lparse = require('lparse')
local luakeys = require('luakeys')()

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
  if string.find(str, '\\EndClozeTest') then
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
    tex.print('\\bgroup\\parindent=0pt \\tt')
    tex.print(1, capture.lines)
    tex.print('\\egroup')
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
    print_last_verbatim(capture)
    use_last(capture)
  end
end

return {
  print_last_verbatim = print_last_verbatim,
  use_last = use_last,
  print_all = print_all,
  register_functions = function()
    lparse.register_csname('ClozeTest', function()
      local kv_string = lparse.scan('m')
      local result = defs:parse(kv_string)
      capture(result.title, result.desciption)
    end)
  end,
}
