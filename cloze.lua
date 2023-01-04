-- cloze.lua
-- Copyright 2015-2023 Josef Friedrich
--
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3c
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3c or later is part of all distributions of LaTeX
-- version 2008/05/04 or later.
--
-- This work has the LPPL maintenance status `maintained'.
--
-- The Current Maintainer of this work is Josef Friedrich.
--
-- This work consists of the files cloze.lua, cloze.tex,
-- and cloze.sty.
---
---<h3>Naming conventions</h3>
---
---* _Variable_ names for _nodes_ are suffixed with `_node`, for example
---  `head_node`.
---* _Variable_ names for _lengths_ (dimensions) are suffixed with
---  `_length`, for example `width`.
---
---@module cloze
---luacheck: globals node tex modules luatexbase callback
---__cloze.lua__
---__Initialisation of the function tables__
---It is good form to provide some background informations about this Lua
---module.
if not modules then
  modules = {}
end
modules['cloze'] = {
  version = '1.6',
  comment = 'cloze',
  author = 'Josef Friedrich, R.-M. Huber',
  copyright = 'Josef Friedrich, R.-M. Huber',
  license = 'The LaTeX Project Public License Version 1.3c 2008-05-04',
}

local farbe = require('farbe')

---Small library to surround strings with ANSI color codes.
---
---The upstream source is located at: [boilerplate.lua](https://github.com/Josef-Friedrich/tex-project-boilerplate/blob/main/boilerplate.lua)
--
---[SGR (Select Graphic Rendition) Parameters](https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters)
---
---__attributes__
---
---| color      |code|
---|------------|----|
---| reset      |  0 |
---| clear      |  0 |
---| bright     |  1 |
---| dim        |  2 |
---| underscore |  4 |
---| blink      |  5 |
---| reverse    |  7 |
---| hidden     |  8 |
---
---__foreground__
---
---| color      |code|
---|------------|----|
---| black      | 30 |
---| red        | 31 |
---| green      | 32 |
---| yellow     | 33 |
---| blue       | 34 |
---| magenta    | 35 |
---| cyan       | 36 |
---| white      | 37 |
---
---__background__
---
---| color      |code|
---|------------|----|
---| onblack    | 40 |
---| onred      | 41 |
---| ongreen    | 42 |
---| onyellow   | 43 |
---| onblue     | 44 |
---| onmagenta  | 45 |
---| oncyan     | 46 |
---| onwhite    | 47 |
---
---@alias ColorName `black'|'red'|'green'|'yellow'|'blue'|'magenta'|'cyan'|'white`
---@alias ColorMode `bright'|'dim`
local ansi_color = (function()

  ---
  ---@param code integer
  ---
  ---@return string
  local function format_color_code(code)
    return string.char(27) .. '[' .. tostring(code) .. 'm'
  end

  ---
  ---@param color ColorName # A color name.
  ---@param mode? ColorMode
  ---@param background? boolean # Colorize the background not the text.
  ---
  ---@return string
  local function get_color_code(color, mode, background)

    local output = ''
    local code

    if mode == 'bright' then
      output = format_color_code(1)
    elseif mode == 'dim' then
      output = format_color_code(2)
    end

    if not background then
      if color == 'reset' then
        code = 0
      elseif color == 'red' then
        code = 31
      elseif color == 'green' then
        code = 32
      elseif color == 'yellow' then
        code = 33
      elseif color == 'blue' then
        code = 34
      elseif color == 'magenta' then
        code = 35
      elseif color == 'cyan' then
        code = 36
      else
        code = 37
      end
    else
      if color == 'black' then
        code = 40
      elseif color == 'red' then
        code = 41
      elseif color == 'green' then
        code = 42
      elseif color == 'yellow' then
        code = 43
      elseif color == 'blue' then
        code = 44
      elseif color == 'magenta' then
        code = 45
      elseif color == 'cyan' then
        code = 46
      elseif color == 'white' then
        code = 47
      else
        code = 40
      end
    end
    return output .. format_color_code(code)
  end

  ---@param text any
  ---@param color ColorName # A color name.
  ---@param mode? ColorMode
  ---@param background? boolean # Colorize the background not the text.
  ---
  ---@return string
  local function surround_text(text, color, mode, background)
    return string.format('%s%s%s',
      get_color_code(color, mode, background), text,
      get_color_code('reset'))
  end

  return {
    ---
    ---@param text any
    ---
    ---@return string
    red = function(text)
      return surround_text(text, 'red')
    end,

    ---
    ---@param text any
    ---
    ---@return string
    green = function(text)
      return surround_text(text, 'green')
    end,

    ---@return string
    yellow = function(text)
      return surround_text(text, 'yellow')
    end,

    ---
    ---@param text any
    ---
    ---@return string
    blue = function(text)
      return surround_text(text, 'blue')
    end,

    ---
    ---@param text any
    ---
    ---@return string
    magenta = function(text)
      return surround_text(text, 'magenta')
    end,

    ---
    ---@param text any
    ---
    ---@return string
    cyan = function(text)
      return surround_text(text, 'cyan')
    end,
  }
end)()

---
---Small logging library.
---
---The upstream source is located at: [boilerplate.lua](https://github.com/Josef-Friedrich/tex-project-boilerplate/blob/main/boilerplate.lua)
---
---Log levels:
---
---* 0: silent
---* 1: error (red)
---* 2: warn (yellow)
---* 3: info (green)
---* 4: verbose (blue)
---* 5: debug (magenta)
---
local log = (function()
  local opts = { level = 0 }

  local function print_message(message, ...)
    print(string.format(message, ...))
  end

  local function error(message, ...)
    if opts.level >= 1 then
      print_message(message, ...)
    end
  end

  local function warn(message, ...)
    if opts.level >= 2 then
      print_message(message, ...)
    end
  end

  local function info(message, ...)
    if opts.level >= 3 then
      print_message(message, ...)
    end
  end

  local function verbose(message, ...)
    if opts.level >= 4 then
      print_message(message, ...)
    end
  end

  local function debug(message, ...)
    if opts.level >= 5 then
      print_message(message, ...)
    end
  end

  return {
    opts = opts,
    error = error,
    warn = warn,
    info = info,
    verbose = verbose,
    debug = debug,
  }
end)()

---
---@param s string
---@param ... any
local function tex_printf(s, ...)
  tex.print(string.format(s, ...))
end

---Option handling.
---
---The table `config` bundles functions that deal with the option
---handling.
---
---<h2>Marker processing (marker)</h2>
---
---A marker is a whatsit node of the subtype `user_defined`. A marker
---has two purposes:
---
---* Mark the begin and the end of a gap.
---* Store a index number, that points to a Lua table, which holds some
---  additional data like the local options.
---
---@section config

---All values and functions, which are related to the option
---management, are stored in a table called `config`.
local config = (function()
  local luakeys = require('luakeys')()

  ---I didn’t know what value I should take as `user_id`. Therefore I
  ---took my birthday and transformed it into a large number.
  local user_id = 3121978

  ---Store all local options of the markers.
  ---
  ---<code><pre>
  ---storage = {
  ---  {
  ---    mode = "basic",
  ---    position = "start",
  ---    values = {
  ---      distance = "3mm"
  ---    }
  ---  },
  ---  {
  ---    mode = "basic",
  ---    position = "stop"
  ---  }
  ---}</pre></code>
  local storage = {}

  ---@class Options
  ---@field align? 'l'|'r'
  ---@field boxheigh? string
  ---@field boxrule? string
  ---@field boxwidth? string
  ---@field distance? string
  ---@field visibility? boolean
  ---@field line_color? string
  ---@field margin? string
  ---@field minlines? integer
  ---@field resetcolor? string
  ---@field show_text? boolean
  ---@field spacing? number
  ---@field text_color? string
  ---@field thickness? string
  ---@field width? string

  ---The default options.
  local defaults = {
    ['align'] = 'l',
    ['boxheight'] = false,
    ['boxrule'] = '0.4pt',
    ['boxwidth'] = '\\linewidth',
    ['distance'] = '1.5pt',
    ['line_color'] = farbe.Color('black'),
    ['margin'] = '3pt',
    ['minlines'] = 0,
    ['show_text'] = true,
    ['spacing'] = '1.6',
    ['text_color'] = farbe.Color('blue'),
    ['thickness'] = '0.4pt',
    ['visibility'] = true,
    ['width'] = '2cm',
  }

  ---The global options set by the user.
  local global_options = {}

  ---The local options.
  local local_options = {}

  local index

  ---__Storage functions (storage)__

  ---`index` is a counter. The functions `get_index()`
  ---increases the counter by one and then returns it.
  ---
  ---@return integer # The index number of the corresponding table in `storage`.
  local function get_index()
    if not index then
      index = 0
    end
    index = index + 1
    return index
  end

  ---The function `get_storage()` retrieves values which belong
  --- to a whatsit marker.
  ---
  ---@param index integer # The argument `index` is a numeric value.
  ---
  ---@return MarkerData value
  local function get_storage(index)
    return storage[index]
  end

  ---
  ---`set_storage()` stores the local options in the Lua table
  --- `storage`.
  ---
  ---It returns a numeric index number. This index number is the key,
  ---where the local options in the Lua table are stored.
  ---
  ---@param mode MarkerMode
  ---@param position MarkerPosition
  ---
  ---@return number # The index number of the corresponding table in
  ---  `storage`.
  local function set_storage(mode, position)
    local index = get_index()
    local data = { mode = mode, position = position }
    if position == 'start' then
      data.local_opts = {}
      for key, value in pairs(local_options) do
        data.local_opts[key] = value
      end
    end
    storage[index] = data
    return index
  end

  ---We create a user defined whatsit node that can store a number (type
  --- = 100).
  ---
  ---In order to distinguish this node from other user defined whatsit
  ---nodes we set the `user_id` to a large number. We call this whatsit
  ---node a marker.
  ---
  ---@param index number The argument `index` is a number, which is associated to values in the `storage` table.
  ---
  ---@return UserDefinedWhatsitNode
  local function create_marker(index)
    local marker = node.new('whatsit', 'user_defined') --[[@as UserDefinedWhatsitNode]]
    marker.type = 100 -- number
    marker.user_id = user_id
    marker.value = index
    node.setproperty(marker, { cloze = get_storage(index) })
    return marker
  end

  ---Write a marker node to TeX's current node list.
  ---
  ---@param mode MarkerMode
  ---@param position MarkerPosition
  local function write_marker(mode, position)
    local index = set_storage(mode, position)
    local marker = create_marker(index)
    node.write(marker)
  end

  ---
  ---Check if the given node is a marker.
  ---
  ---@param item Node
  ---
  ---@return boolean
  local function is_marker(item)
    local n = item --[[@as UserDefinedWhatsitNode]]
    if n.id == node.id('whatsit') and n.subtype ==
      node.subtype('user_defined') and n.user_id == user_id then
      return true
    end
    return false
  end

  ---
  ---Test whether the node `n` is a marker and retrieve the
  ---the corresponding marker data.
  ---
  ---@param n UserDefinedWhatsitNode # The argument `n` is a node of unspecified type.
  ---
  ---@return MarkerData|nil # The marker data or nothing if given node is not a marker.
  local function get_marker_data(n)
    if n.id == node.id('whatsit') and n.subtype ==
      node.subtype('user_defined') and n.user_id == user_id then
      return get_storage(n.value --[[@as integer]] )
    end
  end

  ---
  ---This functions tests, whether the given node `item` is a marker.
  ---
  ---@param head_node Node # The current node.
  ---@param mode MarkerMode
  ---@param position MarkerPosition
  ---
  ---@return boolean
  local function check_marker(head_node, mode, position)
    local data =
      get_marker_data(head_node --[[@as UserDefinedWhatsitNode]] )
    if data and data.mode == mode and data.position == position then
      return true
    end
    return false
  end

  ---
  ---First this function saves the associatied values of a marker to the
  ---local options table. Second it returns this values. The argument
  ---`marker` is a whatsit node.
  ---
  ---@param marker UserDefinedWhatsitNode
  ---
  ---@return unknown
  local function get_marker_values(marker)
    local data = get_marker_data(marker)
    if data then
      local_options = data.local_opts
      return data.local_opts
    end
  end

  ---
  ---`get_marker` returns the given marker.
  ---
  ---@param head_node Node # The current node.
  ---@param mode MarkerMode
  ---@param position MarkerPosition
  ---
  ---@return false|Node # The node if `head_node` is a marker node.
  local function get_marker(head_node, mode, position)
    local out
    if check_marker(head_node, mode, position) then
      out = head_node
    else
      out = false
    end
    if out and position == 'start' then
      get_marker_values(head_node --[[@as UserDefinedWhatsitNode]] )
    end
    return out
  end

  ---This function removes a given whatsit marker.
  ---
  ---It only deletes a node, if a marker is given.
  ---
  ---@param marker Node
  ---
  ---@return Node|nil head
  ---@return Node|nil current
  local function remove_marker(marker)
    if is_marker(marker) then
      return node.remove(marker, marker)
    end
  end

  ---@type 'local'|'global'
  local options_dest

  ---__Option processing (option)__

  ---Store a value `value` and his associated key `key`
  ---either to the global (`global_options`) or to the local
  ---(`local_options`) option table.
  ---
  ---The global boolean variable `local_options` controls in
  ---which table the values are stored.
  ---
  ---@param key string # The option key.
  ---@param value any # The value that is stored under the options key.
  local function set_option(key, value)
    if value == '' then
      return false
    end
    if options_dest == 'global' then
      global_options[key] = value
    else
      local_options[key] = value
    end
  end

  ---
  ---Set the variable `options_dest`.
  ---
  ---@param dest 'local'|'global'
  local function set_options_dest(dest)
    options_dest = dest
  end

  ---
  ---Clear the local options storage.
  local function unset_local_options()
    local_options = {}
  end

  ---
  ---Clear the global options storage.
  local function unset_global_options()
    -- unset_local_options()
    global_options = {}
  end

  ---
  ---Test whether the value `value` is not empty and has a
  ---value.
  ---
  ---@param value any # A value of different types.
  ---
  ---@return boolean # True is the value is set otherwise false.
  local function has_value(value)
    if value == nil or value == '' then
      return false
    else
      return true
    end
  end

  ---Retrieve a value from a given key. First search for the value in the
  ---local options, then in the global options. If both option storages are
  ---empty, the default value will be returned.
  ---
  ---@param key string # The name of the options key.
  ---
  ---@return any # The value of the corresponding option key.
  local function get_value(key)
    local value_local = local_options[key]
    local value_global = global_options[key]

    local value, source
    if has_value(value_local) then
      source = 'local'
      value = local_options[key]
    elseif has_value(value_global) then
      source = 'global'
      value = value_global
    else
      source = 'default'
      value = defaults[key]
    end

    local g = ansi_color.green

    log.debug(
      'Get value “%s” from the key “%s” the %s options storage',
      g(value), g(key), g(source))

    return value
  end

  ---Return the default value of the given option.
  ---
  ---@param key any # The name of the options key.
  ---
  ---@return any # The corresponding value of the options key.
  local function get_defaults(key)
    return defaults[key]
  end

  ---
  ---@param kv_string string
  ---@param options_dest 'local'|'global'
  local function parse_options(kv_string, options_dest)
    unset_local_options()
    set_options_dest(options_dest)
    local defs = {
      align = {
        description = 'Align the text of a fixed size cloze.',
        process = function(value)
          set_option('align', value)
        end,
      },
      boxheight = {
        description = 'The height of a cloze box.',
        process = function(value)
          set_option('boxheight', value)
        end,
      },
      boxrule = {
        description = 'The thickness of the rule around a cloze box.',
        process = function(value)
          set_option('boxrule', value)
        end,
      },
      boxwidth = {
        description = 'The width of a cloze box.',
        process = function(value)
          set_option('boxwidth', value)
        end,
      },
      distance = {
        description = 'The distance between the cloze text and the cloze line.',
        process = function(value)
          set_option('distance', value)
        end,
      },
      visibility = {
        description = 'Show or hide the cloze text.',
        opposite_keys = { [true] = 'show', [false] = 'hide' },
        process = function(value)
          set_option('visibility', value)
        end,
      },
      line_color = {
        description = 'A color name to colorize the cloze line.',
        alias = 'linecolor',
        process = function(value, input)
          tex_printf('\\FarbeImport{%s}', value)
          set_option('line_color', value)
        end,
      },
      margin = {
        description = 'Indicates how far the cloze line sticks up horizontally from the text.',
        process = function(value)
          set_option('margin', value)
        end,
      },
      minlines = {
        description = 'How many lines a clozepar at least must have.',
        process = function(value)
          set_option('minlines', value)
        end,
      },
      spacing = {
        description = 'The spacing between lines (environment clozespace).',
        process = function(value)
          set_option('spacing', value)
        end,
      },
      text_color = {
        description = 'The color (name) of the cloze text.',
        alias = 'textcolor',
        data_type = 'string',
        process = function(value)
          tex_printf('\\FarbeImport{%s}', value)
          set_option('text_color', value)
        end,
      },
      thickness = {
        description = 'The thickness of the cloze line.',
        process = function(value)
          set_option('thickness', value)
        end,
      },
      width = {
        description = 'The width of the cloze line of the command \\clozefix.',
        process = function(value)
          set_option('width', value)
        end,
      },
      debug = {
        data_type = 'integer',
        process = function(value)
          log.opts.level = value
        end,
      },
    }

    luakeys.parse(kv_string, { defs = defs })
  end

  return {
    get_value = get_value,
    get_defaults = get_defaults,
    unset_global_options = unset_global_options,
    unset_local_options = unset_local_options,
    set_is_global = set_options_dest,
    remove_marker = remove_marker,
    check_marker = check_marker,
    set_option = set_option,
    write_marker = write_marker,
    get_marker = get_marker,
    get_marker_data = get_marker_data,
    parse_options = parse_options,
  }

end)()

local utils = (function()

  ---All functions in this section are stored in a table called `nodex`.
  ---`nodex` is a abbreviation for __node eXtended__. The `nodex` table
  ---bundles all functions, which extend the built-in `node` library.

  ---__Color handling (color)__

  ---
  ---`utils.create_color()` is a wrapper for the function
  ---`utils.create_colorstack()`. It queries the current values of the
  ---options `line_color` and `text_color`.
  ---
  ---@param kind 'line'|'text'
  ---@param command 'push'|'pop'
  ---
  ---@return PdfColorstackWhatsitNode
  local function create_color(kind, command)
    local color_spec
    if kind == 'line' then
      color_spec = config.get_value('line_color')
    else
      color_spec = config.get_value('text_color')
    end
    local color = farbe.Color(color_spec)
    return color:create_pdf_colorstack_node(command)
  end

  ---__Line handling (line)__

  ---Create a rule node, which is used as a line for the cloze texts. The
  ---`depth` and the `height` of the rule are calculated form the options
  ---`thickness` and `distance`.
  ---
  ---@param width number # The argument `width` must have the length unit __scaled points__.
  ---
  ---@return RuleNode
  local function create_line(width)
    local rule = node.new('rule') --[[@as RuleNode]]
    local thickness = tex.sp(config.get_value('thickness'))
    local distance = tex.sp(config.get_value('distance'))
    rule.depth = distance + thickness
    rule.height = -distance
    rule.width = width
    return rule
  end

  ---Insert a `list` of nodes after or before the `current`. The `head`
  ---argument is optional. In some edge cases it is unfortately necessary.
  ---if `head` is omitted the `current` node is used.
  ---
  ---@param position 'before'|'after' # The argument `position` can take the values `'after'` or `'before'`.
  ---@param current Node
  ---@param list table
  ---@param head_node? Node
  ---
  ---@return Node
  local function insert_list(position, current, list, head_node)
    if not head_node then
      head_node = current
    end
    for _, insert in ipairs(list) do
      if position == 'after' then
        head_node, current = node.insert_after(head_node, current,
          insert)
      elseif position == 'before' then
        head_node, current = node.insert_before(head_node, current,
          insert)
      end
    end
    return current
  end

  ---Enclose a rule node (cloze line) with two PDF colorstack whatsits.
  ---The first colorstack node colors the line, the second resets the
  ---color.
  ---
  ---__Node list__: `whatsit:pdf_colorstack` (line_color) - `rule` (width) - `whatsit:pdf_colorstack` (reset_color)
  ---
  ---@param current Node
  ---@param width number
  ---
  ---@return Node
  local function insert_line(current, width)
    return insert_list('after', current, {
      create_color('line', 'push'),
      create_line(width),
      create_color('line', 'pop'),
    })
  end

  ---Encloze a rule node with color nodes as the function
  -- `utils.insert_line` does.
  ---
  ---In contrast to -`utils.insert_line` the three nodes are appended to
  ---TeX’s ‘current-list’. They are not inserted in a node list, which
  ---is accessed by a Lua callback.
  ---
  ---__Node list__: `whatsit:pdf_colorstack` (line_color) - `rule` (width) - `whatsit:pdf_colorstack` (reset_color)
  ---
  local function write_line_nodes()
    node.write(create_color('line', 'push'))
    node.write(create_line(tex.sp(config.get_value('width'))))
    node.write(create_color('line', 'pop'))
  end

  ---__Handling of extendable lines (linefil)__

  ---Create a line which stretches indefinitely in the
  ---horizontal direction.
  ---
  ---@return GlueNode
  local function create_linefil()
    local glue = node.new('glue') --[[@as GlueNode]]
    glue.subtype = 100
    glue.stretch = 65536
    glue.stretch_order = 3
    local rule = create_line(0)
    rule.dir = 'TLT'
    glue.leader = rule
    return glue
  end

  ---
  ---Surround a indefinitely strechable line with color whatsits and puts
  ---it to TeX’s ‘current (node) list’ (write).
  local function write_linefil_nodes()
    node.write(create_color('line', 'push'))
    node.write(create_linefil())
    node.write(create_color('line', 'pop'))
  end

  ---
  ---Create a kern node with a given width.
  ---
  ---@param width number # The argument `width` had to be specified in scaled points.
  ---
  ---@return KernNode
  local function create_kern_node(width)
    local kern_node = node.new('kern') --[[@as KernNode]]
    kern_node.kern = width
    return kern_node
  end

  ---
  ---Add at the beginning of each `hlist` node list a strut (a invisible
  ---character).
  ---
  ---Now we can add line, color etc. nodes after the first node of a hlist
  ---not before - after is much more easier.
  ---
  ---@param hlist_node HlistNode
  ---
  ---@return HlistNode hlist_node
  ---@return Node strut_node
  ---@return Node prev_head_node
  local function insert_strut_into_hlist(hlist_node)
    local prev_head_node = hlist_node.head
    local kern_node = create_kern_node(0)
    local strut_node = node.insert_before(hlist_node.head,
      prev_head_node, kern_node)
    hlist_node.head = prev_head_node.prev
    return hlist_node, strut_node, prev_head_node
  end

  ---
  ---Write a kern node to the current node list. This kern node can be
  ---used to build a margin.
  local function write_margin_node()
    node.write(create_kern_node(tex.sp(config.get_value('margin'))))
  end

  ---
  ---Search for a `hlist` (subtype `line`) and insert a strut node into
  ---the list if a hlist is found.
  ---
  ---@param head_node Node # The head of a node list.
  ---
  ---@return HlistNode|nil hlist_node
  ---@return Node|nil strut_node
  ---@return Node|nil prev_head_node
  local function search_hlist(head_node)
    while head_node do
      if head_node.id == node.id('hlist') and head_node.subtype == 1 then
        ---@cast head_node HlistNode
        return insert_strut_into_hlist(head_node)
      end
      head_node = head_node.next
    end
  end

  --- See nodetree
  ---@param n Node
  local function debug_node_list(n)
    if log.opts.level < 5 then
      return
    end

    local is_cloze = false

    ---@param head_node Node
    local function get_textual_from_glyph(head_node)
      local properties = node.direct.get_properties_table()
      local node_id = node.direct.todirect(head_node) -- Convert to node id
      local props = properties[node_id]
      local info = props and props.glyph_info
      local textual
      local character_index = node.direct.getchar(node_id)
      if info then
        textual = info
      elseif character_index == 0 then
        textual = '^^@'
      elseif character_index <= 31 or
        (character_index >= 127 and character_index <= 159) then
        textual = '???'
      elseif character_index < 0x110000 then
        textual = utf8.char(character_index)
      else
        textual = string.format('^^^^^^%06X', character_index)
      end
      return textual
    end

    local output = {}

    ---
    ---@param value string
    local add = function(value)
      table.insert(output, value)
    end

    local red = ansi_color.red
    local green = ansi_color.green
    local yellow = ansi_color.yellow
    local blue = ansi_color.blue
    local magenta = ansi_color.magenta
    local cyan = ansi_color.cyan

    while n do
      local marker_data =
        config.get_marker_data(n --[[@as UserDefinedWhatsitNode]] )

      if marker_data then
        if marker_data.position == 'start' then
          is_cloze = true
        else
          is_cloze = false
        end
      end
      if n.id == node.id('glyph') then
        if is_cloze then
          add(yellow(get_textual_from_glyph(n)))
        else
          add(get_textual_from_glyph(n))
        end

      elseif n.id == node.id('glue') then
        add(' ')

      elseif n.id == node.id('disc') then
        add(cyan('|'))

      elseif n.id == node.id('kern') then
        add(blue('<'))

      elseif marker_data then
        local char
        if marker_data.position == 'start' then
          char = 'START'
        else
          char = 'STOP'
        end
        add(magenta('[' .. char .. ']'))

      elseif n.id == node.id('whatsit') and n.subtype ==
        node.subtype('pdf_colorstack') then
        local c = n --[[@as PdfColorstackWhatsitNode]]
        local command
        if c.command == 1 then
          command = 'push'
        elseif c.command == 2 then
          command = 'pop'
        end
        add(green('[' .. command .. ']'))

      elseif n.id == node.id('rule') then
        add(red('_'))

      elseif n.id == node.id('hlist') then

        debug_node_list(n.head)
        add(red('└'))
      end

      n = n.next
    end

    print(table.concat(output, ''))
  end

  return {
    debug_node_list = debug_node_list,
    insert_list = insert_list,
    create_color = create_color,
    insert_line = insert_line,
    write_line_nodes = write_line_nodes,
    write_linefil_nodes = write_linefil_nodes,
    create_kern_node = create_kern_node,
    insert_strut_into_hlist = insert_strut_into_hlist,
    write_margin_node = write_margin_node,
    search_hlist = search_hlist,
  }
end)()

---@alias MarkerMode 'basic'|'fix'|'par' # The argument `mode` accepts the string values `basic`, `fix` and `par`.
---@alias MarkerPosition 'start'|'stop' # The argument `position` is either set to `start` or to `stop`.

---
---@class MarkerData
---@field mode MarkerMode
---@field position MarkerPosition
---@field local_opts Options

---Assembly to cloze texts.
---@section cloze_functions

---Assemble a possibly multiline cloze.
---
---The corresponding LaTeX command to this Lua function is `\cloze`.
---This function is used by other cloze TeX macros too: `\clozenol`,
---`\clozefil`
---
---@param head_node_input Node # The head of a node list.
---
---@return Node # The head of the node list.
local function make_basic(head_node_input)

  utils.debug_node_list(head_node_input)

  -- This local variables are overloaded by functions
  -- calling each other.
  local continue_cloze, search_stop

  ---
  ---Make a single gap.
  ---
  ---@param start_node Node # The node to start / begin a new cloze.
  ---@param stop_node Node # The node to stop / end a new cloze.
  ---@param parent_node HlistNode # The parent node (hlist) of the start and the stop node.
  ---
  ---@return Node|nil stop_node # The stop node.
  ---@return HlistNode parent_node # The parent node (hlist) of the stop node.
  local function make_single(start_node, stop_node, parent_node)
    local node_head = start_node
    local line_width = node.dimensions(parent_node.glue_set,
      parent_node.glue_sign, parent_node.glue_order, start_node,
      stop_node)

    log.info('Make a line of the width of: %dsp', line_width)

    local line_node = utils.insert_line(start_node, line_width)
    local color_text_node = utils.insert_list('after', line_node, {
      utils.create_color('text', 'push'),
    })
    if config.get_value('visibility') then
      utils.insert_list('after', color_text_node,
        { utils.create_kern_node(-line_width) })
      utils.insert_list('before', stop_node,
        { utils.create_color('text', 'pop') }, node_head)
    else
      line_node.next = stop_node.next
      stop_node.prev = line_node -- not line_node.prev -> line color leaks out
    end
    -- In some edge cases the lua callbacks get fired up twice. After the
    -- cloze has been created, the start and stop whatsit markers can be
    -- deleted.
    config.remove_marker(start_node)
    return config.remove_marker(stop_node), parent_node
  end

  ---Search for a stop marker or make a cloze up to the end of the node
  ---list.
  ---
  ---@param start_node Node # The node to start a new cloze.
  ---@param parent_node HlistNode # The parent node (hlist) of the start node.
  ---
  ---@return Node|nil head_node # The fast forwarded new head of the node list.
  ---@return Node|nil parent_node # The parent node (hlist) of the head node.
  function search_stop(start_node, parent_node)
    local head_node = start_node
    local last_node
    while head_node do
      if config.check_marker(head_node, 'basic', 'stop') then
        return make_single(start_node, head_node, parent_node)
      end
      last_node = head_node
      head_node = head_node.next
    end
    -- Make a cloze until the end of the node list.
    head_node = make_single(start_node, last_node, parent_node)
    if parent_node.next then
      return continue_cloze(parent_node.next)
    else
      return head_node, parent_node
    end
  end

  ---Continue a multiline cloze.
  ---
  ---@param parent_node Node # A parent node to search for a hlist node.
  ---
  ---@return Node|nil head_node # The fast forwarded new head of the node list.
  ---@return Node|nil parent_node # The parent node (hlist) of the head node.
  function continue_cloze(parent_node)
    local hlist_node = utils.search_hlist(parent_node)
    if hlist_node then
      local start_node = hlist_node.head
      return search_stop(start_node, hlist_node)
    end
  end

  ---Search for a start marker.
  ---
  ---@param head_node Node # The head of a node list.
  ---@param parent_node HlistNode # The parent node (hlist) of the head node.
  ---
  ---@return Node
  local function search_start(head_node, parent_node)
    while head_node do
      if head_node.head then
        ---@cast head_node HlistNode
        search_start(head_node.head, head_node)
      elseif config.check_marker(head_node, 'basic', 'start') and
        parent_node and parent_node.id == node.id('hlist') then
        -- Adds also a strut at the first position. It prepars the
        -- hlist and makes it ready to build a cloze.
        utils.search_hlist(parent_node)
        head_node, parent_node = search_stop(head_node, parent_node)
      end
      if head_node then
        head_node = head_node.next
      else
        break
      end
    end
  end

  search_start(head_node_input)
  return head_node_input
end

---The corresponding LaTeX command to this Lua function is `\clozefix`.
---
---@param head_node_input Node # The head of a node list.
local function make_fix(head_node_input)

  ---
  ---Calculate the widths of the whitespace before (`start_width`) and
  ---after (`stop_width`) the cloze text.
  ---
  ---@param start Node
  ---@param stop Node
  ---
  ---@return integer width
  ---@return integer start_width # The width of the whitespace before the cloze text.
  ---@return integer stop_width # The width of the whitespace after the cloze text.
  local function calculate_widths(start, stop)
    local start_width, stop_width
    local width = tex.sp(config.get_value('width'))
    local text_width = node.dimensions(start, stop)
    local align = config.get_value('align')
    if align == 'right' then
      start_width = -text_width
      stop_width = 0
    elseif align == 'center' then
      local half = (width - text_width) / 2
      start_width = -half - text_width
      stop_width = half
    else
      start_width = -width
      stop_width = width - text_width
    end
    return width, start_width, stop_width
  end

  ---The function `make_single` generates a gap of fixed width.
  ---
  ---__Node lists__
  ---
  ---__Show text:__
  ---
  ---<table>
  ---<tbody>
  ---  <tr>
  ---    <td>`start_node`</td>
  ---    <td>`whatsit`</td>
  ---    <td>`user_definded`</td>
  ---    <td>`index`</td>
  ---  </tr>
  ---  <tr>
  ---    <td>`line_node`</td>
  ---    <td>`rule`</td>
  ---    <td></td>
  ---    <td>`width`</td>
  ---  </tr>
  ---  <tr>
  ---    <td>`kern_start_node`</td>
  ---    <td>`kern`</td>
  ---    <td>&amp; Depends on `align`</td>
  ---    <td></td>
  ---  </tr>
  ---  <tr>
  ---    <td>`color_text_node`</td>
  ---    <td>`whatsit`</td>
  ---    <td>`pdf_colorstack`</td>
  ---    <td>Text color</td>
  ---  </tr>
  ---  <tr>
  ---    <td></td>
  ---    <td>`glyphs`</td>
  ---    <td>&amp; Text to show</td>
  ---    <td></td>
  ---  </tr>
  ---  <tr>
  ---    <td>`color_reset_node`</td>
  ---    <td>`whatsit`</td>
  ---    <td>`pdf_colorstack`</td>
  ---    <td>Reset color</td>
  ---  </tr>
  ---  <tr>
  ---    <td>`kern_stop_node`</td>
  ---    <td>`kern`</td>
  ---    <td>&amp; Depends on `align`</td>
  ---    <td></td>
  ---  </tr>
  ---  <tr>
  ---    <td>`stop_node`</td>
  ---    <td>`whatsit`</td>
  ---    <td>`user_definded`</td>
  ---    <td>`index`</td>
  ---  </tr>
  ---</tbody>
  ---</table>
  ---
  ---__Hide text:__
  ---
  ---<table>
  ---<thead>
  ---  <tr>
  ---    <th>`start_node`</th>
  ---    <th>`whatsit`</th>
  ---    <th>`user_definded`</th>
  ---    <th>`index`</th>
  ---  </tr>
  ---</thead>
  ---<tbody>
  ---  <tr>
  ---    <td>`line_node`</td>
  ---    <td>`rule`</td>
  ---    <td></td>
  ---    <td>`width`</td>
  ---  </tr>
  ---  <tr>
  ---    <td>`stop_node`</td>
  ---    <td>`whatsit`</td>
  ---    <td>`user_definded`</td>
  ---    <td>`index`</td>
  ---  </tr>
  ---</tbody>
  ---</table>
  ---
  ---Make a fixed sized cloze.
  ---
  ---@param start Node # The node, where the gap begins
  ---@param stop Node # The node, where the gap ends
  local function make_single(start, stop)
    local width, kern_start_length, kern_stop_length = calculate_widths(
      start, stop)
    local line_node = utils.insert_line(start, width)
    if config.get_value('visibility') then
      utils.insert_list('after', line_node, {
        utils.create_kern_node(kern_start_length),
        utils.create_color('text', 'push'),
      })
      utils.insert_list('before', stop, {
        utils.create_color('text', 'pop'),
        utils.create_kern_node(kern_stop_length),
      }, start)
    else
      line_node.next = stop.next
    end
    config.remove_marker(start)
    config.remove_marker(stop)
  end

  ---Function to recurse the node list and search after marker.
  ---
  ---@param head_node Node # The head of a node list.
  local function make_fix_recursion(head_node)
    local start_node, stop_node = false, false
    while head_node do
      if head_node.head then
        make_fix_recursion(head_node.head)
      else
        if not start_node then
          start_node = config.get_marker(head_node, 'fix', 'start')
        end
        if not stop_node then
          stop_node = config.get_marker(head_node, 'fix', 'stop')
        end
        if start_node and stop_node then
          make_single(start_node, stop_node)
          start_node, stop_node = false, false
        end
      end
      head_node = head_node.next
    end
  end

  make_fix_recursion(head_node_input)
  return head_node_input
end

---The corresponding LaTeX environment to this lua function is
---`clozepar`.
---
---__Node lists__
---
---__Show text:__
---
---<table>
---<thead>
---  <tr>
---    <th>`strut_node`</th>
---    <th>`kern`</th>
---    <th></th>
---    <th>width = 0</th>
---  </tr>
---</thead>
---<tbody>
---  <tr>
---    <td>`line_node`</td>
---    <td>`rule`</td>
---    <td></td>
---    <td>`width` (Width from hlist)</td>
---  </tr>
---  <tr>
---    <td>`kern_node`</td>
---    <td>`kern`</td>
---    <td></td>
---    <td>`-width`</td>
---  </tr>
---  <tr>
---    <td>`color_text_node`</td>
---    <td>`whatsit`</td>
---    <td>`pdf_colorstack`</td>
---    <td>Text color</td>
---  </tr>
---  <tr>
---    <td></td>
---    <td>`glyphs`</td>
---    <td></td>
---    <td>Text to show</td>
---  </tr>
---  <tr>
---    <td>`tail_node`</td>
---    <td>`glyph`</td>
---    <td></td>
---    <td>Last glyph in hlist</td>
---  </tr>
---  <tr>
---    <td>`color_reset_node`</td>
---    <td>`whatsit`</td>
---    <td>`pdf_colorstack`</td>
---    <td>Reset color</td>
---  </tr>
---</tbody>
---</table>
---
---__Hide text:__
---
---<table>
---<thead>
---  <tr>
---    <th>`strut_node`</th>
---    <th>`kern`</th>
---    <th></th>
---    <th>width = 0</th>
---  </tr>
---</thead>
---<tbody>
---  <tr>
---    <td>`line_node`</td>
---    <td>`rule`</td>
---    <td></td>
---    <td>`width` (Width from hlist)</td>
---  </tr>
---</tbody>
---</table>
---
---@param head_node Node # The head of a node list.
local function make_par(head_node)
  utils.debug_node_list(head_node)

  ---Add one additional empty line at the end of a paragraph.
  ---
  ---All fields from the last hlist node are copied to the created
  ---hlist.
  ---
  ---@param last_hlist_node HlistNode # The last hlist node of a paragraph.
  ---
  ---@return HlistNode # The created new hlist node containing the line.
  local function add_additional_line(last_hlist_node)
    local hlist_node = node.new('hlist') --[[@as HlistNode]]
    hlist_node.subtype = 1

    local fields = {
      'width',
      'depth',
      'height',
      'shift',
      'glue_order',
      'glue_set',
      'glue_sign',
      'dir',
    }
    for _, field in ipairs(fields) do
      if last_hlist_node[field] then
        hlist_node[field] = last_hlist_node[field]
      end
    end

    local kern_node = utils.create_kern_node(0)
    hlist_node.head = kern_node
    utils.insert_line(kern_node, last_hlist_node.width)
    last_hlist_node.next = hlist_node
    hlist_node.prev = last_hlist_node
    hlist_node.next = nil
    return hlist_node
  end

  ---Add multiple empty lines at the end of a paragraph.
  ---
  ---@param last_hlist_node HlistNode # The last hlist node of a paragraph.
  ---@param count number # Count of the lines to add at the end.
  local function add_additional_lines(last_hlist_node,
    count)
    local i = 0
    while i < count do
      last_hlist_node = add_additional_line(last_hlist_node)
      i = i + 1
    end
  end

  ---@type Node
  local strut_node
  ---@type Node
  local line_node
  ---@type number
  local width
  ---@type HlistNode
  local last_hlist_node
  ---@type HlistNode
  local hlist_node

  local line_count = 0
  while head_node do
    if head_node.id == node.id('hlist') then
      ---@cast head_node HlistNode
      hlist_node = head_node

      line_count = line_count + 1
      last_hlist_node = hlist_node
      width = hlist_node.width
      hlist_node, strut_node, _ = utils.insert_strut_into_hlist(
        hlist_node)
      line_node = utils.insert_line(strut_node, width)
      if config.get_value('visibility') then
        utils.insert_list('after', line_node, {
          utils.create_kern_node(-width),
          utils.create_color('text', 'push'),
        })
        utils.insert_list('after', node.tail(line_node),
          { utils.create_color('text', 'pop') })
      else
        line_node.next = nil
      end
    end
    head_node = head_node.next
  end

  local minlines = config.get_value('minlines')
  local additional_lines = minlines - line_count

  if additional_lines > 0 then
    add_additional_lines(last_hlist_node, additional_lines)
  end

  return true
end

local cb = (function()
  ---
  ---@param callback_name CallbackName # The name of a callback
  ---@param func function # A function to register for the callback
  ---@param description string # Only used in LuaLatex
  local function register(callback_name, func, description)
    if luatexbase then
      luatexbase.add_to_callback(callback_name, func, description)
    else
      callback.register(callback_name, func)
    end
  end

  ---
  ---@param callback_name CallbackName # The name of a callback
  ---@param description string # Only used in LuaLatex
  local function unregister(callback_name, description)
    if luatexbase then
      luatexbase.remove_from_callback(callback_name, description)
    else
      callback.register(callback_name, nil)
    end
  end

  ---
  ---Store informations if the callbacks are already registered for
  ---a certain mode (`basic`, `fix`, `par`).
  ---
  ---<code><pre>
  ---is_registered = {
  ---  fix = true,
  ---  basic = false,
  ---  par = false,
  ---}</pre></code>
  ---
  local is_registered = {}

  return { ---
    ---Register the functions `make_par`, `make_basic` and
    ---`make_fix` as callbacks.
    ---
    ---`make_par` and `make_basic` are registered to the callback
    ---`post_linebreak_filter` and `make_fix` to the callback
    ---`pre_linebreak_filter`. The argument `mode` accepts the string values
    ---`basic`, `fix` and `par`. A special treatment is needed for clozes in
    ---display math mode. The `post_linebreak_filter` is not called on
    ---display math formulas. I’m not sure if the `pre_output_filter` is the
    ---right choice to capture the display math formulas.
    ---
    ---@param mode MarkerMode
    ---
    ---@return boolean|nil
    register_callbacks = function(mode)
      if mode == 'par' then
        register('post_linebreak_filter', make_par, mode)
        return true
      end
      if not is_registered[mode] then
        if mode == 'basic' then
          register('post_linebreak_filter', make_basic, mode)
          register('pre_output_filter', make_basic, mode)
        elseif mode == 'fix' then
          register('pre_linebreak_filter', make_fix, mode)
        else
          return false
        end
        is_registered[mode] = true
      end
    end,

    ---
    ---Delete the registered functions from the Lua callbacks.
    ---
    ---@param mode MarkerMode
    unregister_callbacks = function(mode)
      if mode == 'basic' then
        unregister('post_linebreak_filter', mode)
        unregister('pre_output_filter', mode)
      elseif mode == 'fix' then
        unregister('pre_linebreak_filter', mode)
      else
        unregister('post_linebreak_filter', mode)
      end
    end,
  }
end)()

---
---This table contains some basic functions which are published to the
---`cloze.tex` and `cloze.sty` file.
return {

  ---Variable that can be used to store the previous fbox rule thickness
  --- to be able to restore the previous thickness.
  fboxrule_restore = nil,
  write_linefil_nodes = utils.write_linefil_nodes,
  write_line_nodes = utils.write_line_nodes,
  write_margin_node = utils.write_margin_node,
  set_option = config.set_option,
  set_is_global = config.set_is_global,
  unset_local_options = config.unset_local_options,
  reset = config.unset_global_options,
  get_defaults = config.get_defaults,
  get_value = config.get_value,
  marker = config.write_marker,
  parse_options = config.parse_options,
  register_callback = cb.register_callbacks,
  unregister_callback = cb.unregister_callbacks,
}
