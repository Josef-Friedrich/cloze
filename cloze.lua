-- cloze.lua
-- Copyright 2015-2025 Josef Friedrich
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
---__Initialisation of the function tables__
---It is good form to provide some background informations about this Lua
---module.
if not modules then
  modules = {}
end
modules['cloze'] = {
  version = '2.0.0',
  comment = 'cloze',
  author = 'Josef Friedrich, R.-M. Huber',
  copyright = 'Josef Friedrich, R.-M. Huber',
  license = 'The LaTeX Project Public License Version 1.3c 2008-05-04',
}

local farbe = require('farbe')
local luakeys = require('luakeys')()
local lparse = require('lparse')

local ansi_color = luakeys.utils.ansi_color
local log = luakeys.utils.log
local tex_printf = luakeys.utils.tex_printf

---
---The different types of cloze texts required different processing of
---the node lists.
---@alias ClozeType
---|'basic' # `\cloze`, `\clozenol`
---|'fix' # `\clozefix`
---|'par' # `\begin{clozepar}` and `\end{clozepar}`
---|'strike' # `\clozestrike`

---
---@alias MarkerPosition 'start'|'stop' # The argument `position` is either set to `start` or to `stop`.

---
---@class MarkerData
---@field cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
---@field position MarkerPosition # Whether the marker node indicates the beginning or the end of a cloze.
---@field finished? boolean # true if the node manipulation for the cloze is finished
---@field local_opts Options

---
---The table `config` bundles functions that deal with the option
---handling. All values and functions, which are related to the option
---management, are stored in this table.
---
---<h2>Marker processing (marker)</h2>
---
---A marker is a whatsit node of the subtype `user_defined`. A marker
---has two purposes:
---
---* Mark the begin and the end of a gap.
---* Store a index number, that points to a Lua table, which holds some
---  additional data like the local options.
local config = (function()
  ---
  ---I didn’t know what value I should take as `user_id`. Therefore I
  ---took my birthday (3.12.1978) and transformed it into a large number.
  local user_id = 3121978

  ---
  ---Store all local options of the markers.
  ---@type {[integer]: MarkerData }
  local storage = {}

  ---@class Options
  ---@field align? 'left'|'center'|'right' # The alignment of a fixed-size cloze text (`\clozefix`).
  ---@field box_height? string # The height of a cloze box (`clozebox`).
  ---@field box_rule? string # The thickness of the line around a cloze box (`clozebox`).
  ---@field box_width? string # The width of a cloze box (`clozebox`).
  ---@field debug? number # The debug or log level.
  ---@field distance? string # The distance between the cloze text and the cloze line.
  ---@field extend_count? integer # The number of extension units (`\clozeextend`).
  ---@field extend_height? string # The height of one extension unit (`\clozeextend`).
  ---@field extend_width? string # The width of one extension unit (`\clozeextend`).
  ---@field font? string # The font of the cloze text.
  ---@field line_color? string # The color name to colorize the cloze line.
  ---@field margin? string # The additional margin between the normal and the cloze text.
  ---@field min_lines? integer # The minimum number of lines a `clozepar` environment must have.
  ---@field spacing? number # The spacing of the lines in the environment `clozespace`.
  ---@field spread? number # The magnification or spreading factor of a gap.
  ---@field text_color? string # The color name to colorize the cloze text.
  ---@field thickness? string # The thickness of a line.
  ---@field visibility? boolean # The visibility of the cloze text.
  ---@field width? string # The width of a fixed size cloze (`\clozefix`).

  ---The default options.
  ---@type Options
  local defaults = {
    align = 'left',
    box_height = nil,
    box_rule = '0.4pt',
    box_width = '\\linewidth',
    debug = 0,
    distance = '1.5pt',
    extend_count = 5,
    extend_height = '2ex',
    extend_width = '1em',
    font = nil,
    line_color = 'black',
    margin = '3pt',
    min_lines = 0,
    spacing = 1.6,
    spread = 0,
    text_color = 'blue',
    thickness = '0.4pt',
    visibility = true,
    width = '2cm',
  }

  ---
  ---The global options set by the user.
  ---@type Options
  local global_options = {}

  ---
  ---The local options.
  ---@type Options
  local local_options = {}

  ---@type MarkerData|nil
  local current_marker_data = nil

  ---@type integer
  local index

  ---
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

  ---
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
  ---Write a marker node to TeX's current node list.
  ---
  ---@param cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
  ---@param position MarkerPosition # Whether the marker node indicates the beginning or the end of a cloze.
  ---@param local_opts? Options
  local function write_marker(cloze_type, position, local_opts)
    local index = get_index()
    local data = { cloze_type = cloze_type, position = position }
    if local_opts ~= nil then
      data.local_opts = local_opts
    end
    storage[index] = data
    local marker = node.new('whatsit', 'user_defined') --[[@as UserDefinedWhatsitNode]]
    marker.type = 100 -- number
    marker.user_id = user_id
    marker.value = index
    node.write(marker)
  end

  ---
  ---Test whether the node `n` is a marker and retrieve the
  ---the corresponding marker data. If the specified node is a start
  ---marker, the local options of that marker node are loaded.
  ---
  ---@param n UserDefinedWhatsitNode # The argument `n` is a node of unspecified type.
  ---
  ---@return MarkerData|nil # The marker data or nothing if given node is not a marker.
  local function get_marker_data(n)
    if n.id == node.id('whatsit') and n.subtype ==
      node.subtype('user_defined') and n.user_id == user_id then
      local data = get_storage(n.value --[[@as integer]] )
      if data.position == 'start' then
        if data.local_opts == nil then
          local_options = {}
        else
          local_options = data.local_opts
        end
        current_marker_data = data
      end
      return data
    end
  end

  ---
  ---Check if the given node is a marker.
  ---
  ---If the specified node is a start marker, the local options of that
  ---marker node are loaded.
  ---
  ---@param head_node Node # The current node.
  ---@param cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
  ---@param position MarkerPosition # Whether the marker node indicates the beginning or the end of a cloze.
  ---
  ---@return boolean
  local function check_marker(head_node, cloze_type, position)
    local data =
      get_marker_data(head_node --[[@as UserDefinedWhatsitNode]] )
    if data and data.cloze_type == cloze_type and data.position ==
      position and not data.finished then
      return true
    end
    return false
  end

  ---
  ---Return the input node only if it is a marker of the specified
  ---cloze type and position.
  ---
  ---If the specified node is a start marker, the local options of that
  ---marker node are loaded.
  ---
  ---@param head_node Node # The current node.
  ---@param cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
  ---@param position MarkerPosition # Whether the marker node indicates the beginning or the end of a cloze.
  ---
  ---@return UserDefinedWhatsitNode|nil # The node if `head_node` is a marker node.
  local function get_marker(head_node, cloze_type, position)
    ---@type UserDefinedWhatsitNode|nil
    local marker = nil
    if check_marker(head_node, cloze_type, position) then
      marker = head_node --[[@as UserDefinedWhatsitNode]]
    end
    return marker
  end

  ---
  ---Set the current start marker as completed by setting the `finalized` field to true.
  local function finalize_cloze()
    if current_marker_data ~= nil then
      current_marker_data.finished = true
    end
  end

  ---
  ---Clear the global options storage.
  local function reset_global_options()
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

  ---
  ---Retrieve a value from a given key. First search for the value in the
  ---local options, then in the global options. If both option storages are
  ---empty, the default value will be returned.
  ---
  ---@param key string # The name of the options key.
  ---
  ---@return any # The value of the corresponding option key.
  local function get(key)
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

  ---
  ---Return the default value of the given option.
  ---
  ---@param key any # The name of the options key.
  ---
  ---@return any # The corresponding value of the options key.
  local function get_defaults(key)
    return defaults[key]
  end

  ---@type DefinitionCollection
  local defs = {
    align = {
      description = 'The alignment of a fixed-size cloze text (\\clozefix).',
      alias = 'alignment',
      choices = { 'left', 'center', 'right' },
    },
    box_height = {
      description = 'The height of a cloze box (clozebox).',
      alias = { 'boxheight' },
      data_type = 'string'
    },
    box_rule = {
      description = 'The thickness of the line around a cloze box (clozebox).',
      alias = { 'boxrule' },
      data_type = 'string'
    },
    box_width = {
      description = 'The width of a cloze box (clozebox).',
      alias = { 'boxwidth' },
      data_type = 'string'
    },
    debug = {
      description = 'The debug or log level.',
      alias = { 'log' },
      data_type = 'integer',
      process = function(value)
        log.set(value)
      end,
    },
    distance = {
      description = 'The distance between the cloze text and the cloze line.',
      data_type = 'string'
    },
    extend_count = {
      description = 'The number of extension units (\\clozeextend).',
      alias = { 'extension_count', 'extensioncount' },
      data_type = 'integer',
    },
    extend_height = {
      -- default = '2ex',
      description = 'The height of one extension unit (\\clozeextend).',
      alias = { 'extension_height', 'extensionheight' },
      data_type = 'string',
    },
    extend_width = {
      -- default = '1em',
      description = 'The width of one extension unit (\\clozeextend).',
      alias = { 'extension_width', 'extensionwidth' },
      data_type = 'string',
    },
    font = {
      description = 'The font of the cloze text.',
      data_type = 'string',
    },
    line_color = {
      description = 'The color name to colorize the cloze line.',
      alias = 'linecolor',
      process = function(value, input)
        tex_printf('\\FarbeImport{%s}', value)
      end,
      data_type = 'string'
    },
    margin = {
      description = 'The additional margin between the normal and the cloze text.',
      data_type = 'string',
    },
    min_lines = {
      description = 'The minimum number of lines a `clozepar` environment must have.',
      alias = { 'minimum_lines', 'minlines' },
      data_type = 'integer',
    },
    spacing = {
      data_type = 'number',
      description = 'The spacing of the lines in the environment clozespace',
    },
    spread = {
      alias = { 'openup', 'scale' },
      description = 'The magnification or spreading factor of a gap.',
      data_type = 'number',
    },
    text_color = {
      description = 'The color name to colorize the cloze text.',
      alias = 'textcolor',
      data_type = 'string',
      process = function(value)
        tex_printf('\\FarbeImport{%s}', value)
      end,
    },
    thickness = {
      description = 'The thickness of a line.',
      data_type = 'string',
    },
    visibility = {
      description = 'The visibility of the cloze text',
      opposite_keys = { [true] = 'show', [false] = 'hide' },
    },
    width = {
      description = 'The width of a fixed size cloze (\\clozefix)',
      data_type = 'string',
    },
  }

  ---
  ---@param local_opts Options
  local function set_local_options(local_opts)
    local_options = local_opts
  end

  ---
  ---Parse local options and set this options to the global variabl local_options
  ---
  ---@param kv_string string # A string of key-value pairs that can be parsed by luakeys.
  ---
  ---@return Options
  local function parse_local_options(kv_string)
    local_options = luakeys.parse(kv_string, {
      defs = defs,
      debug = log.get() > 3,
    })
    return local_options
  end

  ---
  ---@param kv_string string # A string of key-value pairs that can be parsed by luakeys.
  local function parse_global_options(kv_string)
    luakeys.parse(kv_string, {
      defs = defs,
      accumulated_result = global_options,
      debug = log.get() > 3,
    })
  end

  local defs_manager = luakeys.DefinitionManager(defs)

  ---
  ---Key-value pair definitions for the environment `clozespace`
  local defs_space = (function()
    local manager = defs_manager:clone({ include = { 'spacing' } })
    manager.defs.spacing.pick = 'number'
    return manager
  end)()

  ---
  ---Parse the oarg (optional argument) of the environment `clozespace`
  ---
  ---@param kv_string string for example `2` or `spacing=2`
  local function parse_local_space_options(kv_string)
    local local_opts = defs_space:parse(kv_string)
    set_local_options(local_opts)
  end

  ---
  ---Key-value pair definitions for the environment `clozebox`
  local defs_box = (function()
    local manager = defs_manager:clone({ exclude = { 'width' } })
    manager.defs.box_height.alias = { 'boxheight', 'height' }
    manager.defs.box_rule.alias = { 'boxrule', 'rule' }
    manager.defs.box_width.alias = { 'boxwidth', 'width' }
    return manager
  end)()

  ---
  ---Parse the oarg (optional argument) of the environment `clozebox`
  ---
  ---@param kv_string string
  local function parse_local_box_options(kv_string)
    local local_opts = defs_box:parse(kv_string)
    set_local_options(local_opts)
  end

  ---
  ---Key-value pair definitions for the command `clozeextend`
  local defs_extend = (function()
    local manager = defs_manager:clone({
      include = { 'extend_count', 'extend_height', 'extend_width' },
    })
    manager.defs.extend_count.pick = 'number'
    manager.defs.extend_count.alias = {
      'extension_count',
      'extensioncount',
      'count',
    }
    manager.defs.extend_height.alias = {
      'extension_height',
      'extensionheight',
      'height',
    }
    manager.defs.extend_width.alias = {
      'extension_width',
      'extensionwidth',
      'width',
    }
    return manager
  end)()

  ---
  ---Parse the oarg (optional argument) of the command `clozeextend`
  ---
  ---@param kv_string string
  local function parse_local_extend_options(kv_string)
    local local_opts = defs_extend:parse(kv_string)
    set_local_options(local_opts)
  end

  return {
    get = get,
    get_defaults = get_defaults,
    reset_global_options = reset_global_options,
    finalize_cloze = finalize_cloze,
    check_marker = check_marker,
    write_marker = write_marker,
    get_marker = get_marker,
    get_marker_data = get_marker_data,
    set_local_options = set_local_options,
    parse_local_options = parse_local_options,
    parse_global_options = parse_global_options,
    parse_local_space_options = parse_local_space_options,
    parse_local_box_options = parse_local_box_options,
    parse_local_extend_options = parse_local_extend_options,
    defs_manager = defs_manager,

    ---
    ---Get the alignment of a fixed-size cloze text (`\clozefix`).
    ---
    ---@return 'left'|'center'|'right' align # The alignment of a fixed-size cloze text (`\clozefix`).
    get_align = function()
      return get('align')
    end,

    ---
    ---Get the height of a cloze box (`clozebox`).
    ---
    ---@return string|nil box_width # The height of a cloze box (`clozebox`).
    get_box_height = function()
      return get('box_height')
    end,

    ---
    ---Get the thickness of the line around a cloze box (`clozebox`).
    ---
    ---@return string box_width # The thickness of the line around a cloze box (`clozebox`).
    get_box_rule = function()
      return get('box_rule')
    end,

    ---
    ---Get the width of a cloze box (`clozebox`).
    ---
    ---@return string box_width # The width of a cloze box (`clozebox`).
    get_box_width = function()
      return get('box_width')
    end,

    ---
    ---Get the distance between the cloze text and the cloze line in scaled points.
    ---
    ---@return integer distance # The distance between the cloze text and the cloze line in scaled points.
    get_distance = function()
      return tex.sp(get('distance'))
    end,

    ---
    ---Get the number of extension units (`\clozeextend`).
    ---
    ---@return integer extend_count # The number of extension units (`\clozeextend`).
    get_extend_count = function()
      return get('extend_count')
    end,

    ---
    ---Get the height of one extension unit (`\clozeextend`) in scaled points.
    ---
    ---@return integer extend_height # The height of one extension unit (`\clozeextend`) in scaled points.
    get_extend_height = function()
      return tex.sp(get('extend_height'))
    end,

    ---
    ---Get the width of one extension unit (`\clozeextend`) in scaled points.
    ---
    ---@return integer extend_width # The width of one extension unit (`\clozeextend`) in scaled points.
    get_extend_width = function()
      return tex.sp(get('extend_width'))
    end,

    ---
    ---Get the font of the cloze text.
    ---
    ---@return string|nil font # The font of the cloze text.
    get_font = function()
      return get('font')
    end,

    ---
    ---Get the color to colorize the cloze line.
    ---
    ---@return Color text_color # The color to colorize the cloze line.
    get_line_color = function()
      return farbe.Color(get('line_color'))
    end,

    ---
    ---Get the additional margin in scaled points between the normal and the cloze text.
    ---
    ---@return integer min_lines # The additional margin in scaled points between the normal and the cloze text.
    get_margin = function()
      return tex.sp(get('margin'))
    end,

    ---
    ---Get the minimum number of lines a `clozepar` environment must have.
    ---
    ---@return number min_lines # The minimum number of lines a `clozepar` environment must have.
    get_min_lines = function()
      return get('min_lines')
    end,

    ---
    ---Get the spacing of the lines in the environment `clozespace`.
    ---
    ---@return number spacing # The spacing of the lines in the environment `clozespace`.
    get_spacing = function()
      return get('spacing')
    end,

    ---
    ---Get the magnification or spreading factor of a gap.
    ---
    ---@return number spread # The magnification or spreading factor of a gap.
    get_spread = function()
      return get('spread')
    end,

    ---
    ---Get the color to colorize the cloze text.
    ---
    ---@return Color text_color # The color to colorize the cloze text.
    get_text_color = function()
      return farbe.Color(get('text_color'))
    end,

    ---
    ---Get the thickness of a line in scaled points.
    ---
    ---@return integer thickness # The thickness of a line in scaled points.
    get_thickness = function()
      return tex.sp(get('thickness'))
    end,

    ---
    ---Get the visibility of the cloze text.
    ---
    ---@return boolean visibility # The visibility of the cloze text.
    get_visibility = function()
      return get('visibility')
    end,

    ---
    ---Get the width of a fixed size cloze (`\clozefix`) in scaled points.
    ---
    ---@return integer width # The width of a fixed size cloze (`\clozefix`) in scaled points.
    get_width = function()
      return tex.sp(get('width'))
    end,
  }

end)()

local utils = (function()
  ---
  ---Create a new PDF colorstack whatsit node.
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
    local color
    if kind == 'line' then
      color = config.get_line_color()
    else
      color = config.get_text_color()
    end
    return color:create_pdf_colorstack_node(command)
  end

  ---
  ---Create a rule node that is used as a line for the cloze texts.
  ---
  ---The `depth` and the `height` of the rule are calculated form the options
  ---`thickness` and `distance`.
  ---
  ---@param width number # The argument `width` must have the length unit __scaled points__.
  ---
  ---@return RuleNode
  local function create_line(width)
    local rule = node.new('rule') --[[@as RuleNode]]
    local thickness = config.get_thickness()
    local distance = config.get_distance()
    rule.depth = distance + thickness
    rule.height = -distance
    rule.width = width
    return rule
  end

  ---
  ---Insert a `list` of nodes after or before the `current` node.
  ---
  ---The `head_node` argument is optional.  Unfortunately, it is necessary in some edge cases.
  ---If `head_node` is omitted, the `current` node is used.
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

  ---
  ---Enclose a rule node (cloze line) with two PDF colorstack whatsits.
  ---
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

  ---
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
    node.write(create_line(config.get_width()))
    node.write(create_color('line', 'pop'))
  end

  ---
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
    node.write(create_kern_node(config.get_margin()))
  end

  ---
  ---Search for a `hlist` (subtype `line`) and insert a strut node into
  ---the list if a hlist is found.
  ---
  ---@param head_node Node # The head of a node list.
  ---@param insert_strut boolean
  ---
  ---@return HlistNode|nil hlist_node
  ---@return Node|nil strut_node
  ---@return Node|nil prev_head_node
  local function search_hlist(head_node, insert_strut)
    while head_node do
      if head_node.id == node.id('hlist') and head_node.subtype == 1 then
        ---@cast head_node HlistNode
        if insert_strut then
          return insert_strut_into_hlist(head_node)
        else
          return head_node
        end
      end
      head_node = head_node.next
    end
  end

  ---
  ---See nodetree
  ---@param n Node
  local function debug_node_list(n)
    if log.get() < 5 then
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
    create_line = create_line,
    create_kern_node = create_kern_node,
    insert_strut_into_hlist = insert_strut_into_hlist,
    write_margin_node = write_margin_node,
    search_hlist = search_hlist,
  }
end)()

---
---The `traversor` table provides functions to simplify traversing node
---lists. The cloze algorithms can then be implemented in callback
---functions. One callback call is made for each cloze line to be drawn.
local traversor = (function()

  ---@alias ClozeContinuation 'start-stop' | 'continue-stop' | 'start-continue' | 'continue-continue'

  ---The enviroment in the node list where the cloze can be inserted.
  ---The table is passed as an input parameter to the callback function
  ---`Visitor`.
  ---@class ClozeNodeEnvironment
  ---@field parent_hlist HlistNode
  ---@field start_marker? UserDefinedWhatsitNode
  ---@field start_node? Node # The start node, which marks the beginning of a cloze.
  ---@field start Node # The start node, which marks the beginning of a cloze. This field is derived from the fields `start_marker` or `start_node`.
  ---@field start_continuation boolean # `true` if the cloze must be continued by a line break.
  ---@field stop_node? Node # The stop node, which marks the end of a cloze. This field is derived from the fields `stop_marker` or `stop_node`.
  ---@field stop_marker? UserDefinedWhatsitNode
  ---@field stop Node # The stop node, which marks the end of a cloze. This field is derived from the fields `stop_marker` or `stop_node`.
  ---@field stop_continuation boolean True if the stop node is not a start marker. The cloze ends because the end of the line is reached.
  ---@field width integer The width in scaled points from the start to the stop node.
  ---@field continuation ClozeContinuation

  ---
  ---This callback function is called every time a cloze line needs to
  ---be inserted into the node list.
  ---@alias Visitor fun(env: ClozeNodeEnvironment): Node|nil

  ---
  ---Call the Visitor callback and assemble `ClozeNodeEnvironment` table
  ---and pass it in.
  ---
  ---@param visitor Visitor A callback function that is called each time a cloze line needs to be inserted into the node list.
  ---@param parent_hlist? HlistNode
  ---@param start_marker? UserDefinedWhatsitNode
  ---@param start_node? Node
  ---@param stop_node? Node
  ---@param stop_marker? UserDefinedWhatsitNode
  ---
  ---@return Node new_head To avoid endless loops if a new node is inserted at the end of a node list we can use this new head to continue
  local function call_visitor(visitor,
    parent_hlist,
    start_marker,
    start_node,
    stop_node,
    stop_marker)

    local start --[[@as Node]]
    if start_marker ~= nil then
      start = start_marker
    else
      start = start_node
    end

    if start == nil then
      error()
    end

    local stop --[[@as Node]]
    if stop_marker ~= nil then
      stop = stop_marker
    else
      stop = stop_node
    end
    if stop == nil then
      error()
    end

    local width
    if parent_hlist then
      width = node.dimensions(parent_hlist.glue_set,
        parent_hlist.glue_sign, parent_hlist.glue_order, start, stop)
    else
      width = node.dimensions(start, stop)
    end

    ---@type ClozeContinuation
    local continuation
    if start_marker and stop_marker then
      continuation = 'start-stop'
    elseif start_node and stop_marker then
      continuation = 'continue-stop'
    elseif start_marker and stop_node then
      continuation = 'start-continue'
    elseif start_node and stop_node then
      continuation = 'continue-continue'
    end

    ---@type ClozeNodeEnvironment
    local env = {
      parent_hlist = parent_hlist,
      start_marker = start_marker,
      start_node = start_node,
      start = start,
      start_continuation = start_marker == nil,
      stop_node = stop_node,
      stop_marker = stop_marker,
      stop = stop,
      stop_continuation = stop_marker == nil,
      width = width,
      continuation = continuation,
    }

    local new_head = visitor(env)
    if new_head then
      return new_head
    end
    return stop
  end

  ---
  ---Continue a basic cloze gap across line breaks.
  ---
  ---@param visitor Visitor # A callback function that is called each time a cloze line needs to be inserted into the node list.
  ---@param head_node Node # The head of a node list.
  local function continue_cloze(visitor, head_node)
    while head_node.next do
      head_node = head_node.next
      if head_node.head then
        local start = head_node.head
        local n = head_node.head
        while n do
          local stop_marker = config.get_marker(n, 'basic', 'stop')
          if stop_marker then
            call_visitor(visitor, head_node, nil, start, nil,
              stop_marker)
            return
          elseif n.next == nil then
            n = call_visitor(visitor, head_node, nil, start, n, nil)
          end
          n = n.next
        end
      end
    end
  end

  ---
  ---Recurse the node list and search for the marker.
  ---
  ---@param visitor Visitor # A callback function that is called each time a cloze line needs to be inserted into the node list.
  ---@param cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
  ---@param head_node Node # The head of a node list.
  ---@param parent_node? HlistNode # The parent node (hlist) of the head node.
  local function traverse(visitor,
    cloze_type,
    head_node,
    parent_node)
    ---@type UserDefinedWhatsitNode|nil
    local start_marker = nil

    ---@type UserDefinedWhatsitNode|nil
    local stop_marker = nil
    while head_node do
      if head_node.head then
        traverse(visitor, cloze_type, head_node.head, head_node --[[@as HlistNode]] )
      else
        if not start_marker then
          start_marker = config.get_marker(head_node, cloze_type,
            'start')
        end
        if not stop_marker then
          stop_marker = config.get_marker(head_node, cloze_type, 'stop')
        end
        if start_marker and stop_marker then
          call_visitor(visitor, parent_node, start_marker, nil, nil,
            stop_marker)
          start_marker, stop_marker = nil, nil
        elseif start_marker and not stop_marker and head_node.next ==
          nil and parent_node then
          --- continue cloze in the next line
          call_visitor(visitor, parent_node, start_marker, nil,
            head_node, nil)
          continue_cloze(visitor, parent_node)
          start_marker = nil
        end
        stop_marker = nil
      end
      head_node = head_node.next
    end
  end

  return { traverse = traverse }
end)()

local function make_basic(head_node)
  traversor.traverse(function(env)
    config.finalize_cloze()

    local line_color_push = utils.create_color('line', 'push')
    local line = utils.create_line(env.width)
    line_color_push.next = line

    local line_color_pop = utils.create_color('line', 'pop')
    line.next = line_color_pop

    local first
    if env.start_continuation then
      -- the first node is attached on head of a hlist
      first = env.parent_hlist.head
      env.parent_hlist.head = line_color_push
    else
      first = env.start.next
      env.start.next = line_color_push
    end

    if config.get_visibility() then
      -- show cloze text
      local kern = utils.create_kern_node(-env.width)
      line_color_pop.next = kern
      local text_color_push = utils.create_color('text', 'push')
      kern.next = text_color_push
      local text_color_pop = utils.create_color('text', 'pop')

      --- start
      text_color_push.next = first

      --- stop
      if env.stop.next ~= nil then
        local tmp = env.stop.next
        env.stop.next = text_color_pop
        text_color_pop.next = tmp
      else
        env.stop.next = text_color_pop
        -- to avoid endless loop, we have to return the new end of the node list
        return text_color_pop
      end
    else
      -- hide cloze text
      --- stop
      if env.stop_marker ~= nil then
        line_color_pop.next = env.stop_marker.prev
      else
        return line_color_pop
      end
    end
  end, 'basic', head_node)
  return head_node
end

---
---Enlarge a basic cloze by a spread factor.
---
---We measure the widths of the cloze, calculate the spread width and
---then simply put half of that to the left and right of the cloze if
---the text is typeset.
---
---@param head_node_input Node # The head of a node list.
local function spread_basic(head_node_input)
  local function recurse(head_node)
    local n = head_node
    local m

    while n do
      if n.head then
        recurse(n.head)
      elseif config.check_marker(n, 'basic', 'start') then
        local start = n
        m = n
        while m do
          if config.check_marker(m, 'basic', 'stop') then
            local stop = m

            local width = node.dimensions(start, stop)
            local spread = config.get_spread()
            if spread == 0 then
              break
            end
            local spread_half_width = (width * spread) / 2

            local start_kern = utils.create_kern_node(spread_half_width)
            local start_next = start.next
            start.next = start_kern
            start_kern.next = start_next

            local stop_kern = utils.create_kern_node(spread_half_width)
            local stop_prev = stop.prev
            stop_prev.next = stop_kern
            stop_kern.next = stop
            break
          end
          m = m.next
        end
      end
      if n then
        n = n.next
      else
        break
      end
    end
  end
  recurse(head_node_input)
  return head_node_input
end

---
---Generate a gap with a fixed width. The corresponding LaTeX command to this Lua function is `\clozefix`.
---
---# Node lists
---
---## Show text:
---
---| Variable name      | Node type | Node subtype       |             |
---|--------------------|-----------|--------------------|-------------|
---| `start_node`       | `whatsit` | `user_definded`    | `index`     |
---| `line_node`        | `rule`    |                    | `width`     |
---| `kern_start_node`  | `kern`    | Depends on `align` |             |
---| `color_text_node`  | `whatsit` | `pdf_colorstack`   | Text color  |
---|                    | `glyphs`  | Text to show       |             |
---| `color_reset_node` | `whatsit` | `pdf_colorstack`   | Reset color |
---| `kern_stop_node`   | `kern`    | Depends on `align` |             |
---| `stop_node`        | `whatsit` | `user_definded`    | `index`     |
---
---## Hide text:
---
---| Variable name | Node type | Node subtype    |         |
---|---------------|-----------|-----------------|---------|
---| `start_node`  | `whatsit` | `user_definded` | `index` |
---| `line_node`   | `rule`    |                 | `width` |
---| `stop_node`   | `whatsit` | `user_definded` | `index` |
---
---@param head_node_input Node # The head of a node list.
local function make_fix(head_node_input)
  traversor.traverse(function(env)
    config.finalize_cloze()
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
      local width = config.get_width()
      local text_width = node.dimensions(start, stop)
      local align = config.get_align()
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

    local width, kern_start_length, kern_stop_length = calculate_widths(
      env.start, env.stop)
    local line_node = utils.insert_line(env.start, width)
    if config.get_visibility() then
      utils.insert_list('after', line_node, {
        utils.create_kern_node(kern_start_length),
        utils.create_color('text', 'push'),
      })
      utils.insert_list('before', env.stop, {
        utils.create_color('text', 'pop'),
        utils.create_kern_node(kern_stop_length),
      }, env.start)
    else
      line_node.next = env.stop.next
    end
  end, 'fix', head_node_input)
  return head_node_input
end

---
---The corresponding LaTeX environment to this lua function is
---`clozepar`.
---
---# Node lists
---
---## Show text:
---
---| Variable name      | Node type | Node subtype     |                            |
---|--------------------|-----------|------------------|----------------------------|
---| `strut_node`       | `kern`    |                  | width = 0                  |
---| `line_node`        | `rule`    |                  | `width` (Width from hlist) |
---| `kern_node`        | `kern`    |                  | `-width`                   |
---| `color_text_node`  | `whatsit` | `pdf_colorstack` | Text color                 |
---|                    | `glyphs`  |                  | Text to show               |
---| `tail_node`        | `glyph`   |                  | Last glyph in hlist        |
---| `color_reset_node` | `whatsit` | `pdf_colorstack` | Reset color
---
---## Hide text:
---
---| Variable name | Node type  | Node subtype |                            |
---|---------------|------------|--------------|----------------------------|
---| `strut_node`  | `kern`     |              | width = 0                  |
---| `line_node`   | `rule`     |              | `width` (Width from hlist) |
---
---@param head_node Node # The head of a node list.
local function make_par(head_node)
  utils.debug_node_list(head_node)

  ---
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

  ---
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
      if config.get_visibility() then
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

  local additional_lines = config.get_min_lines() - line_count

  if additional_lines > 0 then
    add_additional_lines(last_hlist_node, additional_lines)
  end

  return true
end

---
---visibilty = true
---
---```
---├─WHATSIT (user_defined) user_id 3121978, type 100, value 3
---├─VLIST (unknown) wd 77.93pt, dp 2.01pt, ht 18.94pt
---│ ╚═head
---│   ├─HLIST (box) wd 21.85pt, dp 0.11pt, ht 6.94pt
---│   │ ╚═head
---│   │   ├─WHATSIT (pdf_colorstack) data '0 0 1 rg 0 0 1 RG'
---│   │   ├─KERN (userkern) 28.04pt
---│   │   ├─GLYPH (glyph) 't', font 19, wd 4.09pt, ht 4.42pt, dp 0.11pt
---│   │   ├─GLYPH (glyph) 'o', font 19, wd 5.11pt, ht 6.94pt, dp 0.11pt
---│   │   ├─GLYPH (glyph) 'p', font 19, wd 5.11pt, ht 4.42pt, dp 0.11pt
---│   │   └─WHATSIT (pdf_colorstack) data ''
---│   ├─GLUE (baselineskip) wd 4.95pt
---│   └─HLIST (box) wd 77.93pt, dp 2.01pt, ht 6.94pt
---│     ╚═head
---│       ├─WHATSIT (pdf_colorstack) data '0 0 1 rg 0 0 1 RG'
---│       ├─RULE (normal) wd 77.93pt, dp -2.31pt, ht 2.71pt
---│       ├─WHATSIT (pdf_colorstack) data ''
---│       ├─KERN (fontkern) -77.93pt
---│       ├─GLYPH (glyph) 'b', font 20, wd 3.19pt, ht 6.94pt
---│       ├─GLYPH (glyph) 'a', font 20, wd 5.75pt, ht 4.53pt, dp 0.06pt
---│       ├─GLYPH (glyph) 's', font 20, wd 6.39pt, ht 4.5pt
---│       ├─GLYPH (glyph) 'e', font 20, wd 5.75pt, ht 4.55pt, dp 2.01pt
---│       └─KERN (italiccorrection)
---├─RULE (normal) dp 3.6pt, ht 8.4pt
---├─WHATSIT (user_defined) user_id 3121978, type 100, value 4
---```
---
---visibilty = false
---
---```
---├─WHATSIT (user_defined) user_id 3121978, type 100, value 3
---├─VLIST (unknown) wd 77.93pt, dp 2.01pt, ht 18.94pt
---│ ╚═head
---│   ├─HLIST (box) wd 21.85pt, dp 0.11pt, ht 6.94pt
---│   ├─GLUE (baselineskip) wd 4.95pt
---│   └─HLIST (box) wd 77.93pt, dp 2.01pt, ht 6.94pt
---│     ╚═head
---│       ├─GLYPH (glyph) 'b', font 20, wd 3.19pt, ht 6.94pt
---│       ├─GLYPH (glyph) 'a', font 20, wd 5.75pt, ht 4.53pt, dp 0.06pt
---│       ├─GLYPH (glyph) 's', font 20, wd 6.39pt, ht 4.5pt
---│       ├─GLYPH (glyph) 'e', font 20, wd 5.75pt, ht 4.55pt, dp 2.01pt
---│       └─KERN (italiccorrection)
---├─RULE (normal) dp 3.6pt, ht 8.4pt
---├─WHATSIT (user_defined) user_id 3121978, type 100, value 4
---```
---
---@param head_node Node # The head of a node list.
---
---@return Node head_node
local function make_strike(head_node)
  traversor.traverse(function(env)
    -- The pre linebreak filter gets fired multiple times (e.g. by package mdframed)
    config.finalize_cloze()
    local text_color = config.get_text_color()

    local vlist = env.start.next --[[@as VlistNode]]
    local top_hlist = vlist.head --[[@as HlistNode]]
    local baselineskip = top_hlist.next --[[@as GlueNode]]
    local base_hlist = baselineskip.next --[[@as HlistNode]]

    local top_kern = top_hlist.head --[[@as KernNode]]

    if top_hlist.width > base_hlist.width then
      -- top  long
      --   short
      vlist.width = base_hlist.width
      top_kern.kern = -(top_hlist.width - base_hlist.width) / 2
    else
      --    top
      -- base long
      top_kern.kern = (base_hlist.width - top_hlist.width) / 2
    end

    -- top
    local top_start = top_hlist.head
    if config.get_visibility() then
      -- top color
      top_hlist.head = utils.create_color('text', 'push')
      top_hlist.head.next = top_start
      local top_stop = node.tail(top_hlist.head)
      top_stop.next = utils.create_color('text', 'pop')
    else
      top_hlist.head = nil
    end

    -- strike line

    if config.get_visibility() then
      local base_start = base_hlist.head
      local line = node.new('rule') --[[@as RuleNode]]
      local thickness = config.get_thickness()
      line.depth = -(base_hlist.height / 3)
      line.height = (base_hlist.height / 3) + thickness
      line.width = base_hlist.width

      base_hlist.head = text_color:create_pdf_colorstack_node('push')

      local color_pop = text_color:create_pdf_colorstack_node('pop')
      line.width = base_hlist.width
      local kern = utils.create_kern_node(-base_hlist.width)

      base_hlist.head.next = line
      line.next = color_pop
      color_pop.next = kern

      kern.next = base_start
    end
  end, 'strike', head_node)
  return head_node
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
  ---a certain cloze type (`basic`, `fix`, `par`).
  ---
  ---@type table<'basic'|'fix'|'par'|'strike', boolean>
  local is_registered = {}

  return {

    ---
    ---Register the functions `make_par`, `make_basic` and
    ---`make_fix` as callbacks.
    ---
    ---`make_par` and `make_basic` are registered to the callback
    ---`post_linebreak_filter` and `make_fix` to the callback
    ---`pre_linebreak_filter`. A special treatment is needed for clozes in
    ---display math mode. The `post_linebreak_filter` is not called on
    ---display math formulas. I’m not sure if the `pre_output_filter` is the
    ---right choice to capture the display math formulas.
    ---
    ---@param cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
    ---
    ---@return boolean|nil
    register_callbacks = function(cloze_type)
      if cloze_type == 'par' then
        register('post_linebreak_filter', make_par, cloze_type)
        return true
      end
      if not is_registered[cloze_type] then
        if cloze_type == 'basic' then
          register('post_linebreak_filter', make_basic, cloze_type)
          register('pre_linebreak_filter', spread_basic, cloze_type)
          register('pre_output_filter', make_basic, cloze_type)
        elseif cloze_type == 'fix' then
          register('pre_linebreak_filter', make_fix, cloze_type)
        elseif cloze_type == 'strike' then
          register('pre_linebreak_filter', make_strike, cloze_type)
        else
          return false
        end
        is_registered[cloze_type] = true
      end
    end,

    ---
    ---Delete the registered functions from the Lua callbacks.
    ---
    ---@param cloze_type ClozeType # The cloze type, for example `basic` or `fixed`.
    unregister_callbacks = function(cloze_type)
      if cloze_type == 'basic' then
        unregister('post_linebreak_filter', cloze_type)
        unregister('pre_linebreak_filter', cloze_type)
        unregister('pre_output_filter', cloze_type)
      elseif cloze_type == 'fix' then
        unregister('pre_linebreak_filter', cloze_type)
      elseif cloze_type == 'strike' then
        unregister('pre_linebreak_filter', cloze_type)
      else
        unregister('post_linebreak_filter', cloze_type)
      end
    end,
  }
end)()

---
---Variable that can be used to store the previous fbox rule thickness
---to be able to restore the previous thickness.
local fboxrule_restore

---
---@param cloze_type ClozeType
---@param append_opts? string
local function print_cloze(cloze_type, append_opts)
  local kv_string, text = lparse.scan('O{} v')
  if append_opts ~= nil then
    if kv_string == '' then
      kv_string = append_opts
    else
      kv_string = kv_string .. ',' .. append_opts
    end
  end

  tex.print(string.format('\\Cloze{%s}{%s}{%s}', cloze_type, kv_string,
    text))
end

---
---This table contains some basic functions which are published to the
---`cloze.tex` and `cloze.sty` file.
return {
  register_functions = function()
    lparse.register_csname('cloze', function()
      print_cloze('basic')
    end)

    lparse.register_csname('clozefix', function()
      print_cloze('fix')
    end)

    lparse.register_csname('clozenol', function()
      print_cloze('basic', 'thickness=0pt')
    end)

    lparse.register_csname('clozestrike', function()
      local kv_string, error_text, solution_text =
        lparse.scan('O{} v v')
      tex.print(string.format('\\ClozeStrike{%s}{%s}{%s}', kv_string,
        error_text, solution_text))
    end)

    lparse.register_csname('clozeline', function()
      local kv_string = lparse.scan('O{}')
      tex.print(string.format('\\ClozeLine{%s}', kv_string))
    end)

    lparse.register_csname('clozelinefil', function()
      local kv_string = lparse.scan('O{}')
      tex.print(string.format('\\ClozeLinefil{%s}', kv_string))
    end)

    lparse.register_csname('clozefil', function()
      local kv_string, text = lparse.scan('O{} v')
      tex.print(string.format('\\ClozeFil{%s}{%s}', kv_string, text))
    end)

    lparse.register_csname('clozeextend', function()
      local kv_string = lparse.scan('O{}')
      tex.print(string.format('\\ClozeExtend{%s}', kv_string))
    end)

  end,

  write_linefil_nodes = utils.write_linefil_nodes,
  write_line_nodes = utils.write_line_nodes,
  write_margin_node = utils.write_margin_node,
  reset = config.reset_global_options,
  get_defaults = config.get_defaults,
  get_option = config.get,
  write_marker = config.write_marker,
  parse_global_options = config.parse_global_options,
  parse_local_options = config.parse_local_options,

  register_callback = cb.register_callbacks,
  unregister_callback = cb.unregister_callbacks,

  initialize_cloze = function(cloze_type, kv_string)
    cb.register_callbacks(cloze_type)
    config.write_marker(cloze_type, 'start',
      config.parse_local_options(kv_string))
  end,

  ---
  ---Print the TeX markup for the command `\clozeextend`
  ---
  ---@param kv_string string
  print_extension = function(kv_string)
    config.parse_local_extend_options(kv_string)
    for _ = 1, config.get_extend_count() do
      ---ex: vertical measure of x
      ---px: x height current font (has no effect)
      local userskip = node.new('glue', 'userskip') --[[@as GlueNode]]
      userskip.width = config.get_extend_width()
      node.write(userskip)

      local spaceskip = node.new('glue', 'spaceskip') --[[@as GlueNode]]
      spaceskip.width = 0
      spaceskip.stretch = config.get_extend_width()
      spaceskip.shrink = config.get_extend_width()
      node.write(spaceskip)

      local rule = node.new('rule') --[[@as RuleNode]]
      rule.depth = 0
      rule.height = config.get_extend_height()
      rule.width = 0
      node.write(rule)
    end
  end,

  ---
  ---@param text string
  ---@param kv_string string # A string of key-value pairs that can be parsed by luakeys.
  ---@param starred string # `\BooleanTrue` `\BooleanFalse`
  print_box = function(text, kv_string, starred)
    log.debug('text: %s kv_string: %s starred: %s', text, kv_string,
      starred)
    config.parse_local_box_options(kv_string)
    fboxrule_restore = tex.dimen['fboxrule']
    local rule = config.get_box_rule()
    if rule then
      tex.dimen['fboxrule'] = tex.sp(rule)
    end

    tex.print('\\noindent')
    tex.print('\\begin{lrbox}{\\ClozeBox}')

    local height = config.get_box_height()
    local width = config.get_box_width()

    if height then
      tex_printf('\\begin{minipage}[t][%s][t]{%s}', height, width)
    else
      tex_printf('\\begin{minipage}[t]{%s}', width)
    end
    tex.print('\\setlength{\\parindent}{0pt}')
    tex_printf('\\clozenol[margin=0pt]{%s}', text)
    tex.print('\\end{minipage}')
    tex.print('\\end{lrbox}')
    if starred:match('True') then
      tex.print('\\usebox{\\ClozeBox}')
    else
      tex.print('\\fbox{\\usebox{\\ClozeBox}}')
    end
  end,

  ---
  ---Print the required TeX markup for the environment `clozespace` using `tex.print()`
  ---
  ---@param kv_string string # A string of key-value pairs that can be parsed by luakeys.
  print_space = function(kv_string)
    config.parse_local_space_options(kv_string)
    tex_printf('\\begin{spacing}{%s}', config.get_spacing())
  end,

  print_font = function()
    local font = config.get_font()
    if font ~= nil then
      tex.print(font)
    else
      tex.print('\\clozefont')
    end
  end,

  restore_fboxrule = function()
    tex.dimen['fboxrule'] = fboxrule_restore
  end,

  ---
  ---Print to a minted environment and then as material to be typeset.
  ---
  ---verbatim alternativ? https://www.alanshawn.com/tech/2020/07/07/luatex-mimic-input.html#source-code
  ---
  ---Only used for the visual test files.
  ---
  ---@param markup string unexpanded TeX markup
  print_test = function(markup)
    markup = string.gsub(markup, '\\obeyedline ', '\n')
    tex.print('\\begin{minted}{latex}')
    tex.print(string.format('%s', markup))
    tex.print('\\end{minted}')
    tex.print(markup)
  end,
}
