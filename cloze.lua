--- Cloze uses [LDoc](https://github.com/stevedonovan/ldoc) for the
--  source code documentation. The supported tags are described on in
--  the [wiki](https://github.com/stevedonovan/LDoc/wiki).
--
-- <h3>Naming conventions</h3>
--
-- * _Variable_ names for _nodes_ are suffixed with `_node`, for example
--   `head_node`.
-- * _Variable_ names for _lengths_ (dimensions) are suffixed with
--   `_length`, for example `width`.
--
-- @module cloze

-- luacheck: globals node tex modules luatexbase callback

-- __cloze.lua__

-- __Initialisation of the function tables__

-- It is good form to provide some background informations about this Lua
-- module.

if not modules then modules = { } end modules ['cloze'] = {
  version   = '1.6',
  comment   = 'cloze',
  author    = 'Josef Friedrich, R.-M. Huber',
  copyright = 'Josef Friedrich, R.-M. Huber',
  license   = 'The LaTeX Project Public License Version 1.3c 2008-05-04'
}

local lpeg = require('lpeg')

--- See [lpeg.P](http://www.inf.puc-rio.br/~roberto/lpeg#op-p)
--
-- Like `"literal"` in peg.js.
local Pattern = lpeg.P

--- See [lpeg.R](http://www.inf.puc-rio.br/~roberto/lpeg#op-r)
--
-- Like `[a-z]` in peg.js.
local Range = lpeg.R

--- See [lpeg.S](http://www.inf.puc-rio.br/~roberto/lpeg#op-s)
--
-- Like `[characters]` in peg.js.
local Set = lpeg.S

--- See [lpeg.C](http://www.inf.puc-rio.br/~roberto/lpeg#cap-c)
local capture = lpeg.C

--- See [lpeg.Ct](http://www.inf.puc-rio.br/~roberto/lpeg#cap-t)
local capture_table = lpeg.Ct

--- See [lpeg.Cf](http://www.inf.puc-rio.br/~roberto/lpeg#cap-f)
local capture_fold = lpeg.Cf

--- See [lpeg.Cg](http://www.inf.puc-rio.br/~roberto/lpeg#cap-g)
local capture_group = lpeg.Cg

--- See [lpeg.Cg](http://www.inf.puc-rio.br/~roberto/lpeg#cap-cc)
local capture_constant = lpeg.Cc

--- A naive key value parser written with Lpeg to get rid of kvoptions.
--
-- * `patt^0` = `expression *` (peg.js)
-- * `patt^1` = `expression +` (peg.js)
-- * `patt^-1` = `expression ?` (peg.js)
-- * `patt1 * patt2` = `expression1 expression2` (peg.js) -> Sequence
-- * `patt1 + patt2` = `expression1 / expression2` (peg.js) -> Ordered choice
--
-- * [TUGboat article: Parsing complex data formats in LuaTEX with LPEG](https://tug.org/TUGboat/tb40-2/tb125menke-lpeg.pdf)
-- * [Dimension handling in lualibs](https://github.com/lualatex/lualibs/blob/master/lualibs-util-dim.lua)
--
-- @tparam string input The key value options in a unparsed fashion as a
--   string.
--
-- @treturn table The key value options as a table.
local function key_value_parser(input)
  local white_space = Set(' \t\r\n')^0

  --- Define data type boolean.
  --
  -- @return Lpeg patterns
  local function data_type_boolean ()
    local boolean_true = (
      Pattern('true') +
      Pattern('TRUE') +
      Pattern('yes') +
      Pattern('YES')
    ) * capture_constant(true)

    local boolean_false = (
      Pattern('false') +
      Pattern('FALSE') +
      Pattern('no') +
      Pattern('NO')
    ) * capture_constant(false)

    return boolean_true + boolean_false
  end

  --- Define data type integer.
  --
  -- @return Lpeg patterns
  local function data_type_integer()
    -- patt / function
    -- Creates a function capture. It calls the given function passing
    -- all captures made b nby patt as arguments, or the whole match if
    -- patt made no capture. The values returned by the function are the
    -- final values of the capture. In particular, if function returns
    -- no value, there is no captured value
    return Range('09')^1 / tonumber
  end

  --- Define data type dimension.
  --
  -- @return Lpeg patterns
  local function data_type_dimension()
    local sign = Set('-+')
    local integer = Range('09')^1
    local number = integer^1 * Pattern('.')^0 * integer^0
    local unit =
      Pattern('pt') +
      Pattern('cm') +
      Pattern('mm') +
      Pattern('sp') +
      Pattern('bp') +
      Pattern('in') +
      Pattern('pc') +
      Pattern('dd') +
      Pattern('cc')

    -- patt / function -> function capture
    return (sign^0 * number * unit) / tex.sp
  end

  --- Define data type string.
  --
  -- @return Lpeg patterns
  local data_type_string = function()
    return capture(Range('az', 'AZ', '09')^1)
  end

  local data_type = {
    boolean = data_type_boolean(),
    integer = data_type_integer(),
    dimension = data_type_dimension(),
    string = data_type_string(),
  }

  local minimun_lines =
    (Pattern('minimumlines') + Pattern('minlines')) *
    capture_constant('minimum lines')

  local generic_key = capture(Range('az')^1)

  local key =
    white_space *
    (minimun_lines + generic_key) *
    white_space

  local value =
    white_space *
    (data_type.dimension + data_type.integer + data_type.boolean + data_type.string) *
    white_space

  -- For example: hide -> hide = true
  local key_only =
    key *
    capture_constant(true)

  local key_value =
    key *
    Pattern('=') *
    value

  local keyval_groups = capture_group(
    (key_value + key_only) *
    Pattern(',')^-1
  )

  -- rawset (table, index, value)
  -- Sets the real value of table[index] to value, without invoking the
  -- __newindex metamethod. table must be a table, index any value
  -- different from nil and NaN, and value any Lua value.
  local kvlist = capture_fold(capture_table('') * keyval_groups^0, rawset)
  return kvlist:match(input)
end

--- `nodex` is a abbreviation for __node eXtended__.
local nodex = {}

--- All values and functions, which are related to the option
--  management, are stored in a table called `registry`.
local registry = {}

--- I didn’t know what value I should take as `user_id`. Therefore I
-- took my birthday and transformed it into a large number.
registry.user_id = 3121978

--- Store all local options of the markers.
--
-- <code><pre>
-- registry.storage = {
--   {
--     mode = "basic",
--     position = "start",
--     values = {
--       distance = "3mm"
--     }
--   },
--   {
--     mode = "basic",
--     position = "stop"
--   }
-- }</pre></code>
registry.storage = {}

--- The default options.
registry.defaults = {
  ['align'] = 'l',
  ['boxheight'] = false,
  ['boxrule'] = '0.4pt',
  ['boxwidth'] = '\\linewidth',
  ['distance'] = '1.5pt',
  ['hide'] = false,
  ['linecolor_name'] = 'black',
  ['linecolor'] = '0 0 0 rg 0 0 0 RG', -- black
  ['margin'] = '3pt',
  ['minlines'] = 0,
  ['resetcolor_name'] = 'black',
  ['resetcolor'] = '0 0 0 rg 0 0 0 RG', -- black
  ['show_text'] = true,
  ['show'] = true,
  ['spacing'] = '1.6',
  ['textcolor_name'] = 'blue', -- blue
  ['textcolor'] = '0 0 1 rg 0 0 1 RG', -- blue
  ['thickness'] = '0.4pt',
  ['width'] = '2cm',
}

--- The global options set by the user.
registry.global_options = {}

--- The local options.
registry.local_options = {}

--- Node precessing (nodex)
-- @section nodex

-- All functions in this section are stored in a table called `nodex`.
-- `nodex` is a abbreviation for __node eXtended__. The `nodex` table
-- bundles all functions, which extend the built-in `node` library.

-- __Color handling (color)__

-- __create_colorstack__
-- Create a whatsit node of the subtype `pdf_colorstack`. `data` is a PDF
-- colorstack string like `0 0 0 rg 0 0 0 RG`.
function nodex.create_colorstack(data)
  if not data then
    data = '0 0 0 rg 0 0 0 RG' -- black
  end
  local whatsit = node.new('whatsit', 'pdf_colorstack')
  whatsit.stack = 0
  whatsit.data = data
  return whatsit
end

---
-- `nodex.create_color()` is a wrapper for the function
-- `nodex.create_colorstack()`. It queries the current values of the
-- options `linecolor` and `textcolor`. The argument `option` accepts the
-- strings `line`, `text` and `reset`.
function nodex.create_color(option)
  local data
  if option == 'line' then
    data = registry.get_value('linecolor')
  elseif option == 'text' then
    data = registry.get_value('textcolor')
  elseif option == 'reset' then
    data = nil
  else
    data = nil
  end
  return nodex.create_colorstack(data)
end

-- __Line handling (line)__

--- Create a rule node, which is used as a line for the cloze texts. The
-- `depth` and the `height` of the rule are calculated form the options
-- `thickness` and `distance`. The argument `width` must have the length
-- unit __scaled points__.
function nodex.create_line(width)
  local rule = node.new(node.id('rule'))
  local thickness = tex.sp(registry.get_value('thickness'))
  local distance = tex.sp(registry.get_value('distance'))
  rule.depth = distance + thickness
  rule.height = - distance
  rule.width = width
  return rule
end

--- Insert a `list` of nodes after or before the `current`. The `head`
-- argument is optional. In some edge cases it is unfortately necessary.
-- if `head` is omitted the `current` node is used. The argument
-- `position` can take the values `'after'` or `'before'`.
function nodex.insert_list(position, current, list, head_node)
  if not head_node then
    head_node = current
  end
  for _, insert in ipairs(list) do
    if position == 'after' then
      head_node, current = node.insert_after(head_node, current, insert)
    elseif position == 'before' then
      head_node, current = node.insert_before(head_node, current, insert)
    end
  end
  return current
end

--- Enclose a rule node (cloze line) with two PDF colorstack whatsits.
--  The first colorstack node dyes the line, the seccond resets the
--  color.
--
-- __Node list__
--
-- <table>
-- <thead>
--   <tr>
--     <th>`color_line_node`</th>
--     <th>`whatsit`</th>
--     <th>`pdf_colorstack`</th>
--     <th>Line color</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`line_node`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`width`</td>
--   </tr>
--   <tr>
--     <td>`color_reset_node`</td>
--     <td>`whatsit`</td>
--     <td>`pdf_colorstack`</td>
--     <td>Reset color</td>
--   </tr>
-- </tbody>
-- </table>
function nodex.insert_line(current, width)
  return nodex.insert_list(
    'after',
    current,
    {
      nodex.create_color('line'),
      nodex.create_line(width),
      nodex.create_color('reset')
    }
  )
end

--- This function enclozes a rule node with color nodes as it the
--  function `nodex.insert_line` does. In contrast to
--  `nodex.insert_line` the three nodes are appended to TeX’s ‘current
--  list’. They are not inserted in a node list, which is accessed by a
--  Lua callback.
--
-- __Node list__
--
-- <table>
-- <thead>
--   <tr>
--     <th>-</th>
--     <th>`whatsit`</th>
--     <th>`pdf_colorstack`</th>
--     <th>Line color</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>-</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`width`</td>
--   </tr>
--   <tr>
--     <td>-</td>
--     <td>`whatsit`</td>
--     <td>`pdf_colorstack`</td>
--     <td>Reset color</td>
--   </tr>
-- </tbody>
-- </table>
local function write_line_nodes()
  node.write(nodex.create_color('line'))
  node.write(nodex.create_line(tex.sp(registry.get_value('width'))))
  node.write(nodex.create_color('reset'))
end

-- __Handling of extendable lines (linefil)__

--- This function creates a line which stretchs indefinitely in the
-- horizontal direction.
function nodex.create_linefil()
  local glue = node.new('glue')
  glue.subtype = 100
  glue.stretch = 65536
  glue.stretch_order = 3
  local rule = nodex.create_line(0)
  rule.dir = 'TLT'
  glue.leader = rule
  return glue
end

--- Surround a indefinitely strechable line with color whatsits and puts
--  it to TeX’s ‘current (node) list’ (write).
local function write_linefil_nodes()
  node.write(nodex.create_color('line'))
  node.write(nodex.create_linefil())
  node.write(nodex.create_color('reset'))
end

-- __Kern handling (kern)__

--- This function creates a kern node with a given width. The argument
-- `width` had to be specified in scaled points.
local function create_kern_node(width)
  local kern_node = node.new(node.id('kern'))
  kern_node.kern = width
  return kern_node
end

--- Add at the beginning of each `hlist` node list a strut (a invisible
--  character).
--
-- Now we can add line, color etc. nodes after the first node of a hlist
-- not before - after is much more easier.
--
-- @tparam node hlist_node
--
-- @treturn node hlist_node
-- @treturn node strut_node
-- @treturn node prev_head_node
local function insert_strut_into_hlist(hlist_node)
  local prev_head_node = hlist_node.head
  local kern_node = create_kern_node(0)
  local strut_node = node.insert_before(hlist_node.head, prev_head_node, kern_node)
  hlist_node.head = prev_head_node.prev
  return hlist_node, strut_node, prev_head_node
end

--- Write a kern node to the current node list. This kern node can be
--  used to build a margin.
function write_margin_node()
  node.write(create_kern_node(tex.sp(registry.get_value('margin'))))
end

--- Search for a `hlist` (subtype `line`) and nsert a strut node into
-- the list if a hlist is found.
--
-- @tparam node head_node The head of a node list.
--
-- @treturn node hlist_node
-- @treturn node strut_node
-- @treturn node prev_head_node
local function search_hlist(head_node)
  while head_node do
    if head_node.id == node.id('hlist') and head_node.subtype == 1 then
      return insert_strut_into_hlist(head_node)
    end
    head_node = head_node.next
  end
end

--- Option handling.
--
-- The table `registry` bundles functions that deal with the option
-- handling.
--
-- <h2>Marker processing (marker)</h2>
--
-- A marker is a whatsit node of the subtype `user_defined`. A marker
-- has two purposes:
--
-- * Mark the begin and the end of a gap.
-- * Store a index number, that points to a Lua table, which holds some
--   additional data like the local options.
--
-- @section registry

--- We create a user defined whatsit node that can store a number (type
--  = 100).
--
-- In order to distinguish this node from other user defined whatsit
-- nodes we set the `user_id` to a large number. We call this whatsit
-- node a marker. The argument `index` is a number, which is associated
-- to values in the `registry.storage` table.
function registry.create_marker(index)
  local marker = node.new('whatsit', 'user_defined')
  marker.type = 100 -- number
  marker.user_id = registry.user_id
  marker.value = index
  return marker
end

--- Write a marker node to TeX's current node list.
--
-- The argument `mode` accepts the string values `basic`, `fix` and
-- `par`. The argument `position`. The argument `position` is either set
-- to `start` or to `stop`.
function registry.write_marker(mode, position)
  local index = registry.set_storage(mode, position)
  local marker = registry.create_marker(index)
  node.write(marker)
end

--- This functions checks if the given node `item` is a marker.
function registry.is_marker(item)
  if item.id == node.id('whatsit')
    and item.subtype == node.subtype('user_defined')
    and item.user_id == registry.user_id then
    return true
  end
  return false
end

--- This functions tests, whether the given node `item` is a marker.
--
-- @tparam node head_node The current node.
-- @tparam string mode The argument `mode` accepts the string values
--   `basic`, `fix` and `par`.
-- @tparam string position The argument `position` is either set
--   to `start` or to `stop`.
function registry.check_marker(head_node, mode, position)
  local data = registry.get_marker_data(head_node)
  if data and data.mode == mode and data.position == position then
    return true
  end
  return false
end

--- `registry.get_marker` returns the given marker.
--
-- @tparam node head_node The current node.
-- @tparam string mode The argument `mode` accepts the string values
--   `basic`, `fix` and `par`.
-- @tparam string position The argument `position` is either set
--   to `start` or to `stop`.
--
-- @treturn mixed The node if `head_node` is a marker node.
function registry.get_marker(head_node, mode, position)
  local out
  if registry.check_marker(head_node, mode, position) then
    out = head_node
  else
    out = false
  end
  if out and position == 'start' then
    registry.get_marker_values(head_node)
  end
  return out
end

--- Test whether the node `item` is a marker and retrieve the
-- the corresponding registry data.
--
-- @tparam node item The argument `item` is a node of unspecified type.
--
-- @treturn table The marker data.
function registry.get_marker_data(item)
  if item.id == node.id('whatsit') and
     item.subtype == node.subtype('user_defined') and
     item.user_id == registry.user_id then
    return registry.get_storage(item.value)
  else
    return false
  end
end

--- First this function saves the associatied values of a marker to the
-- local options table. Second it returns this values. The argument
-- `marker` is a whatsit node.
function registry.get_marker_values(marker)
  local data = registry.get_marker_data(marker)
  registry.local_options = data.values
  return data.values
end

--- This function removes a given whatsit marker.
--
-- It only deletes a node, if a marker is given.
--
-- @treturn node head
-- @treturn node current
function registry.remove_marker(marker)
  if registry.is_marker(marker) then
    return node.remove(marker, marker)
  end
end

-- __Storage functions (storage)__

--- `registry.index` is a counter. The functions `registry.get_index()`
-- increases the counter by one and then returns it.
--
-- @treturn int The index number of the corresponding table in
--   `registry.storage`.
function registry.get_index()
  if not registry.index then
    registry.index = 0
  end
  registry.index = registry.index + 1
  return registry.index
end

--- `registry.set_storage()` stores the local options in the Lua table
--  `registry.storage`.
--
-- It returns a numeric index number. This index number is the key,
-- where the local options in the Lua table are stored.
--
-- @tparam string mode The argument `mode` accepts the string values
--   `basic`, `fix` and `par`.
-- @tparam string position The argument `position` is either set
--   to `start` or to `stop`.
--
-- @treturn int The index number of the corresponding table in
--   `registry.storage`.
function registry.set_storage(mode, position)
  local index = registry.get_index()
  local data = {
    ['mode'] = mode,
    ['position'] = position
  }
  if position == 'start' then
    data.values = {}
    for key, value in pairs(registry.local_options) do
      data.values[key] = value
    end
  end
  registry.storage[index] = data
  return index
end

--- The function `registry.get_storage()` retrieves values which belong
--  to a whatsit marker.
--
-- The argument `index` is a numeric value.
function registry.get_storage(index)
  return registry.storage[index]
end

-- __Option processing (option)__

--- This function stores a value `value` and his associated key `key`
--  either to the global (`registry.global_options`) or to the local
--  (`registry.local_options`) option table.
--
-- The global boolean variable `registry.local_options` controls in
-- which table the values are stored.
--
-- @tparam string key The option key.
-- @tparam mixed value The value that is stored under the options key.
function registry.set_option(key, value)
  if value == '' or value == '\\color@ ' then
    return false
  end
  if registry.is_global == true then
    registry.global_options[key] = value
  else
    registry.local_options[key] = value
  end
end

--- Set the variable `registry.is_global`.
--
-- @tparam boolean is_global
function registry.set_is_global(is_global)
  registry.is_global = is_global
end

--- This function unsets the local options.
function registry.unset_local_options()
  registry.local_options = {}
end

--- `registry.unset_global_options` empties the global options storage.
function registry.unset_global_options()
  registry.global_options = {}
end

--- Retrieve a value from a given key. First search for the value in the
-- local options, then in the global options. If both option storages are
-- empty, the default value will be returned.
--
-- @tparam string key The name of the options key.
--
-- @treturn mixed The value of the corresponding option key.
function registry.get_value(key)
  if registry.has_value(registry.local_options[key]) then
    return registry.local_options[key]
  end
  if registry.has_value(registry.global_options[key]) then
    return registry.global_options[key]
  end
  return registry.defaults[key]
end

--- The function `registry.get_value_show()` returns the boolean value
-- `true` if the option `show` is true. In contrast to the function
-- `registry.get_value()` it converts the string value `true' to a
-- boolean value.
function registry.get_value_show()
  if
    registry.get_value('show') == true
  or
    registry.get_value('show') == 'true'
  then
    return true
  else
    return false
  end
end

--- This function tests whether the value `value` is not empty and has a
-- value.
--
-- @tparam mixed value A value of different types.
--
-- @treturn boolean True is the value is set otherwise false.
function registry.has_value(value)
  if value == nil or value == '' or value == '\\color@ ' then
    return false
  else
    return true
  end
end

--- Return the default value of the given option.
--
-- @tparam string key The name of the options key.
--
-- @treturn mixed The corresponding value of the options key.
function registry.get_defaults(key)
  return registry.defaults[key]
end

--- Assembly to cloze texts.
-- @section cloze_functions

--- Assemble a possibly multiline cloze.
--
-- The corresponding LaTeX command to this Lua function is `\cloze`.
--  This function is used by other cloze TeX macros too: `\clozenol`,
-- `\clozefil`
--
-- @tparam node head_node_input The head of a node list.
--
-- @treturn node The head of the node list.
local function make_basic(head_node_input)
  -- This local variables are overloaded by function who
  -- call each other.
  local continue_cloze, search_stop

  --- The function `make_single()` makes one gap. The argument
  --  `start_node` is the node where the gap begins. The argument
  --  `stop_node` is the node where the gap ends.
  --
  -- @tparam node start_node The node to start / begin a new cloze.
  -- @tparam node stop_node The node to stop / end a new cloze.
  -- @tparam node parent_node The parent node (hlist) of the start and
  --   the stop node.
  --
  -- @treturn node stop_node The stop node.
  -- @treturn parent_node The parent node (hlist) of the stop node.
  local function make_single(start_node, stop_node, parent_node)
    local node_head = start_node
    local line_width = node.dimensions(
      parent_node.glue_set,
      parent_node.glue_sign,
      parent_node.glue_order,
      start_node,
      stop_node
    )
    local line_node = nodex.insert_line(start_node, line_width)
    local color_text_node = nodex.insert_list('after', line_node, {nodex.create_color('text')})
    if registry.get_value_show() then
      nodex.insert_list('after', color_text_node, {create_kern_node(-line_width)})
      nodex.insert_list('before', stop_node, {nodex.create_color('reset')}, node_head)
    else
      line_node.next = stop_node.next
      stop_node.prev = line_node -- not line_node.prev -> line color leaks out
    end
    -- In some edge cases the lua callbacks get fired up twice. After the
    -- cloze has been created, the start and stop whatsit markers can be
    -- deleted.
    registry.remove_marker(start_node)
    return registry.remove_marker(stop_node), parent_node
  end

  --- Search for a stop marker or make a cloze up to the end of the node
  -- list.
  --
  -- @tparam node start_node The node to start a new cloze.
  -- @tparam node parent_node The parent node (hlist) of the start node.
  --
  -- @treturn head_node The fast forwarded new head of the node list.
  -- @treturn parent_node The parent node (hlist) of the head node.
  function search_stop(start_node, parent_node)
    local head_node = start_node
    local last_node
    while head_node do
      if registry.check_marker(head_node, 'basic', 'stop') then
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

  --- Continue a multiline cloze.
  --
  -- @tparam node parent_node A parent node to search for a hlist node.
  --
  -- @treturn head_node The fast forwarded new head of the node list.
  -- @treturn parent_node The parent node (hlist) of the head node.
  function continue_cloze(parent_node)
    local hlist_node = search_hlist(parent_node)
    if hlist_node then
      local start_node = hlist_node.head
      return search_stop(start_node, hlist_node)
    end
  end

  --- Search for a start marker.
  --
  -- @tparam node head_node The head of a node list.
  -- @tparam node parent_node The parent node (hlist) of the head node.
  local function search_start(head_node, parent_node)
    while head_node do
      if head_node.head then
        search_start(head_node.head, head_node)
      elseif registry.check_marker(head_node, 'basic', 'start') and
             parent_node and
             parent_node.id == node.id('hlist') then
        -- Adds also a strut at the first position. It prepars the
        -- hlist and makes it ready to build a cloze.
        search_hlist(parent_node)
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

--- The corresponding LaTeX command to this Lua function is `\clozefix`.
--
-- @tparam node head_node_input The head of a node list.
local function make_fix(head_node_input)

  --- Calculate the length of the whitespace before (`kern_start_length`) and
  -- after (`kern_stop_length`) the text.
  local function calculate_length(start, stop)
    local width, kern_start_length, kern_stop_length, text_width, half_length, align
    width = tex.sp(registry.get_value('width'))
    text_width = node.dimensions(start, stop)
    align = registry.get_value('align')
    if align == 'right' then
      kern_start_length = - text_width
      kern_stop_length = 0
    elseif align == 'center' then
      half_length = (width - text_width) / 2
      kern_start_length = - half_length - text_width
      kern_stop_length = half_length
    else
      kern_start_length = - width
      kern_stop_length = width - text_width
    end
    return width, kern_start_length, kern_stop_length
  end

  --- The function `make_single` generates a gap of fixed width.
  --
  -- __Node lists__
  --
  -- __Show text:__
  --
  -- <table>
  -- <tbody>
  --   <tr>
  --     <td>`start_node`</td>
  --     <td>`whatsit`</td>
  --     <td>`user_definded`</td>
  --     <td>`index`</td>
  --   </tr>
  --   <tr>
  --     <td>`line_node`</td>
  --     <td>`rule`</td>
  --     <td></td>
  --     <td>`width`</td>
  --   </tr>
  --   <tr>
  --     <td>`kern_start_node`</td>
  --     <td>`kern`</td>
  --     <td>&amp; Depends on `align`</td>
  --     <td></td>
  --   </tr>
  --   <tr>
  --     <td>`color_text_node`</td>
  --     <td>`whatsit`</td>
  --     <td>`pdf_colorstack`</td>
  --     <td>Text color</td>
  --   </tr>
  --   <tr>
  --     <td></td>
  --     <td>`glyphs`</td>
  --     <td>&amp; Text to show</td>
  --     <td></td>
  --   </tr>
  --   <tr>
  --     <td>`color_reset_node`</td>
  --     <td>`whatsit`</td>
  --     <td>`pdf_colorstack`</td>
  --     <td>Reset color</td>
  --   </tr>
  --   <tr>
  --     <td>`kern_stop_node`</td>
  --     <td>`kern`</td>
  --     <td>&amp; Depends on `align`</td>
  --     <td></td>
  --   </tr>
  --   <tr>
  --     <td>`stop_node`</td>
  --     <td>`whatsit`</td>
  --     <td>`user_definded`</td>
  --     <td>`index`</td>
  --   </tr>
  -- </tbody>
  -- </table>
  --
  -- __Hide text:__
  --
  -- <table>
  -- <thead>
  --   <tr>
  --     <th>`start_node`</th>
  --     <th>`whatsit`</th>
  --     <th>`user_definded`</th>
  --     <th>`index`</th>
  --   </tr>
  -- </thead>
  -- <tbody>
  --   <tr>
  --     <td>`line_node`</td>
  --     <td>`rule`</td>
  --     <td></td>
  --     <td>`width`</td>
  --   </tr>
  --   <tr>
  --     <td>`stop_node`</td>
  --     <td>`whatsit`</td>
  --     <td>`user_definded`</td>
  --     <td>`index`</td>
  --   </tr>
  -- </tbody>
  -- </table>
  --
  -- Make fixed size cloze.
  --
  -- @param start The node, where the gap begins
  -- @param stop The node, where the gap ends
  local function make_single(start, stop)
    local width, kern_start_length, kern_stop_length, line_node
    width, kern_start_length, kern_stop_length = calculate_length(start, stop)
    line_node = nodex.insert_line(start, width)
    if registry.get_value_show() then
      nodex.insert_list(
        'after',
        line_node,
        {
          create_kern_node(kern_start_length),
          nodex.create_color('text')
        }
      )
      nodex.insert_list(
        'before',
        stop,
        {
          nodex.create_color('reset'),
          create_kern_node(kern_stop_length)
        },
        start
      )
    else
      line_node.next = stop.next
    end
    registry.remove_marker(start)
    registry.remove_marker(stop)
  end

  --- Function to recurse the node list and search after marker.
  --
  -- @tparam node head_node The head of a node list.
  local function make_fix_recursion(head_node)
    local start_node, stop_node = false, false
    while head_node do
      if head_node.head then
        make_fix_recursion(head_node.head)
      else
        if not start_node then
          start_node = registry.get_marker(head_node, 'fix', 'start')
        end
        if not stop_node then
          stop_node = registry.get_marker(head_node, 'fix', 'stop')
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

--- The corresponding LaTeX environment to this lua function is
-- `clozepar`.
--
-- __Node lists__
--
-- __Show text:__
--
-- <table>
-- <thead>
--   <tr>
--     <th>`strut_node`</th>
--     <th>`kern`</th>
--     <th></th>
--     <th>width = 0</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`line_node`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`width` (Width from hlist)</td>
--   </tr>
--   <tr>
--     <td>`kern_node`</td>
--     <td>`kern`</td>
--     <td></td>
--     <td>`-width`</td>
--   </tr>
--   <tr>
--     <td>`color_text_node`</td>
--     <td>`whatsit`</td>
--     <td>`pdf_colorstack`</td>
--     <td>Text color</td>
--   </tr>
--   <tr>
--     <td></td>
--     <td>`glyphs`</td>
--     <td></td>
--     <td>Text to show</td>
--   </tr>
--   <tr>
--     <td>`tail_node`</td>
--     <td>`glyph`</td>
--     <td></td>
--     <td>Last glyph in hlist</td>
--   </tr>
--   <tr>
--     <td>`color_reset_node`</td>
--     <td>`whatsit`</td>
--     <td>`pdf_colorstack`</td>
--     <td>Reset color</td>
--   </tr>
-- </tbody>
-- </table>
--
-- __Hide text:__
--
-- <table>
-- <thead>
--   <tr>
--     <th>`strut_node`</th>
--     <th>`kern`</th>
--     <th></th>
--     <th>width = 0</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`line_node`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`width` (Width from hlist)</td>
--   </tr>
-- </tbody>
-- </table>
--
-- @tparam node head_node The head of a node list.
local function make_par(head_node)

  --- Add one additional empty line at the end of a paragraph.
  --
  -- All fields from the last hlist node are copied to the created
  -- hlist.
  --
  -- @tparam node last_hlist_node The last hlist node of a paragraph.
  --
  -- @treturn node The created new hlist node containing the line.
  local function add_additional_line(last_hlist_node)
    local hlist_node = node.new(node.id('hlist'))
    hlist_node.subtype = 1

    local fields = {
      'width',
      'depth',
      'height',
      'shift',
      'glue_order',
      'glue_set',
      'glue_sign',
      'dir'
    }
    for _, field in ipairs(fields) do
      if last_hlist_node[field] then
        hlist_node[field] = last_hlist_node[field]
      end
    end

    local kern_node = create_kern_node(0)
    hlist_node.head = kern_node
    nodex.insert_line(kern_node, last_hlist_node.width)
    last_hlist_node.next = hlist_node
    hlist_node.prev = last_hlist_node
    hlist_node.next = nil
    return hlist_node
  end

  --- Add multiple empty lines at the end of a paragraph.
  --
  -- @tparam node last_hlist_node The last hlist node of a paragraph.
  -- @tparam number count Count of the lines to add at the end.
  local function add_additional_lines(last_hlist_node, count)
    local i = 0
    while i < count do
      last_hlist_node = add_additional_line(last_hlist_node)
      i = i + 1
    end
  end

  local strut_node, line_node, width, last_hlist_node, hlist_node
  local line_count = 0
  while head_node do
    if head_node.id == node.id('hlist') then
      hlist_node = head_node

      line_count = line_count + 1
      last_hlist_node = hlist_node
      width = hlist_node.width
      hlist_node, strut_node, _ = insert_strut_into_hlist(hlist_node)
      line_node = nodex.insert_line(strut_node, width)
      if registry.get_value_show() then
        nodex.insert_list(
          'after',
          line_node,
          {
            create_kern_node(-width),
            nodex.create_color('text')
          }
        )
        nodex.insert_list(
          'after',
          node.tail(head_node),
          {nodex.create_color('reset')}
        )
      else
        line_node.next = nil
      end
    end
    head_node = head_node.next
  end

  local minlines = registry.get_value('minlines')
  local additional_lines = minlines - line_count

  if additional_lines > 0 then
    add_additional_lines(last_hlist_node, additional_lines)
  end

  return true
end

---
-- @tparam string callback_name The name of a callback
-- @tparam function func A function to register for the callback
-- @tparam string description Only used in LuaLatex
local function register_callback(callback_name, func, description)
  if luatexbase then
    luatexbase.add_to_callback(
      callback_name,
      func,
      description
    )
  else
    callback.register(callback_name, func)
  end
end

---
-- @tparam string callback_name The name of a callback
-- @tparam string description Only used in LuaLatex
local function unregister_callback(callback_name, description)
  if luatexbase then
    luatexbase.remove_from_callback(
      callback_name,
      description
    )
  else
    callback.register(callback_name, nil)
  end
end

--- Exported functions.
--
-- The `export` table contains functions which are published to the
-- `cloze.lua` and `cloze.sty` file.
--
-- @section export

--- The `export` table contains some basic functions. `export` is the
-- only table of this Lua module that will be exported.
local export = {}

--- Store informations if the callbacks are already registered for
-- a certain mode (`basic`, `fix`, `par`).
--
-- <code><pre>
-- is_registered = {
--   fix = true,
--   basic = false,
--   par = false,
-- }</pre></code>
--
export.is_registered = {}

--- This function registers the functions `make_par`, `make_basic` and
--  `make_fix` the Lua callbacks.
--
-- `make_par` and `make_basic` are registered to the callback
-- `post_linebreak_filter` and `make_fix` to the callback
-- `pre_linebreak_filter`. The argument `mode` accepts the string values
-- `basic`, `fix` and `par`. A special treatment is needed for clozes in
-- display math mode. The `post_linebreak_filter` is not called on
-- display math formulas. I’m not sure if the `pre_output_filter` is the
-- right choice to capture the display math formulas.
function export.register_callback(mode)
  if mode == 'par' then
    register_callback(
      'post_linebreak_filter',
      make_par,
      mode
    )
    return true
  end
  if not export.is_registered[mode] then
    if mode == 'basic' then
      register_callback(
        'post_linebreak_filter',
        make_basic,
        mode
      )
      register_callback(
        'pre_output_filter',
        make_basic,
        mode
      )
    elseif mode == 'fix' then
      register_callback(
        'pre_linebreak_filter',
        make_fix,
        mode
      )
    else
      return false
    end
    export.is_registered[mode] = true
  end
end

--- Delete the registered functions from the Lua callbacks.
--
-- @tparam string mode The argument `mode` accepts the string values
-- `basic`, `fix` and `par`.
function export.unregister_callback(mode)
  if mode == 'basic' then
    unregister_callback('post_linebreak_filter', mode)
    unregister_callback('pre_output_filter', mode)
  elseif mode == 'fix' then
    unregister_callback('pre_linebreak_filter', mode)
  else
    unregister_callback('post_linebreak_filter', mode)
  end
end

-- Export some functions and values.

--- Variable that can be used to store the previous fbox rule thickness
--  to be able to restore the previous thickness.
export.fboxrule_restore = nil
export.write_linefil_nodes = write_linefil_nodes
export.write_line_nodes = write_line_nodes
export.write_margin_node = write_margin_node
export.set_option = registry.set_option
export.set_is_global = registry.set_is_global
export.unset_local_options = registry.unset_local_options
export.reset = registry.unset_global_options
export.get_defaults = registry.get_defaults
export.get_value = registry.get_value
export.marker = registry.write_marker
export.key_value_parser = key_value_parser

return export
