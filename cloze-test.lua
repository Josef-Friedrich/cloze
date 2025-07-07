local lparse = require('lparse')

-- https://tug.org/TUGboat/tb32-1/tb100isambert.pdf
local all_captures = {}

local last_capture = {}

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

local function print_last(catcode)
  if catcode then
    tex.print(catcode, last_capture)
  else
    tex.print(last_capture)
  end
end

local function use_last()
  print_last()
end

local function store_lines(str)
  if string.find(str, '\\EndClozeTest') then
    unregister_callback('process_input_buffer', 'store_lines')
    table.insert(all_captures, last_capture)
  else
    table.insert(last_capture, str)
  end
  return ''
end

local function capture()
  last_capture = {}
  register_callback('process_input_buffer', store_lines, 'store_lines')
end

return {
  use_last = use_last,
  tex = {
    print_last_verbatim = function()
      print_last(1)
    end,

    use_last = function()
      print_last()
    end,

    print_all = function()
      for _, lines in ipairs(all_captures) do
        tex.print('\\par')
        tex.print('\\bgroup\\parindent=0pt \\tt')
        tex.print(1, lines)
        tex.print('\\egroup')
        tex.print('\\bigskip')
        tex.print(lines)
        tex.print('\\bigskip')
        tex.print('\\bigskip')
      end
    end,
  },
  latex = {
    print_last_verbatim = function()
      tex.print('\\begin{minted}{latex}')
      tex.print(last_capture)
      tex.print('\\end{minted}')
    end,
  },
  register_functions = function()
    lparse.register_csname('ClozeTest', function()
      lparse.scan('m')
      capture()
    end)
  end,
}
