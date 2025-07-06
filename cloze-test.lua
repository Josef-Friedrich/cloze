local lparse = require('lparse')

-- https://tug.org/TUGboat/tb32-1/tb100isambert.pdf
local all_runs = {}

local lines = {}

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

local function print_lines(catcode)
  if catcode then
    tex.print(catcode, lines)
  else
    tex.print(lines)
  end
end

local function store_lines(str)
  if string.find(str, '\\EndClozeTest') then
    unregister_callback('process_input_buffer', 'store_lines')
    table.insert(all_runs, lines)
  else
    table.insert(lines, str)
  end
  return ''
end

local function capture_lines_verbatim()
  lines = {}
  register_callback('process_input_buffer', store_lines, 'store_lines')
end

local function test_all()
  for index, lines in ipairs(all_runs) do
    tex.print('\\par')
    tex.print('\\bgroup\\parindent=0pt \\tt')
    tex.print(1, lines)
    tex.print('\\egroup')
    tex.print('\\bigskip')
    tex.print(lines)
    tex.print('\\bigskip')
    tex.print('\\bigskip')
  end
end

return {
  print_lines = print_lines,
  test_all = test_all,
  register_functions = function()
    lparse.register_csname('ClozeTest', function()
      lparse.scan('m')
      capture_lines_verbatim()
    end)
  end,
}
