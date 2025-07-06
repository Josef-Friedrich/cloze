-- https://tug.org/TUGboat/tb32-1/tb100isambert.pdf
local verb_table = {}

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
    tex.print(catcode, verb_table)
  else
    tex.print(verb_table)
  end
end

local function store_lines(str)
  if string.find(str, '\\EndClozeTest') then
    unregister_callback('process_input_buffer', 'store_lines')
  else
    table.insert(verb_table, str)
  end
  return ''
end

local function register_verbatim()
  verb_table = {}
  register_callback('process_input_buffer', store_lines, 'store_lines')
end

return {
  print_lines = print_lines,
  register_verbatim = register_verbatim,
}
