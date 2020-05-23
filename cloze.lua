--- Cloze uses [LDoc](https://github.com/stevedonovan/ldoc) for the
--  source code documentation. The supported tags are described on in
--  the [wiki](https://github.com/stevedonovan/LDoc/wiki).
--
-- <h3>Naming conventions</h3>
--
-- * _Variable_ names for _nodes_ are suffixed with `_node`, for example
--   `head_node`.
-- * _Variable_ names for _lengths_ (dimensions) are suffixed with
--   `_length`, for example `width_length`.
--
-- @module cloze

-- __cloze.lua}__

-- __Initialisation of the function tables__

-- It is good form to provide some background informations about this Lua
-- module.
if not modules then modules = { } end modules ['cloze'] = {
  version   = '1.4',
  comment   = 'cloze',
  author    = 'Josef Friedrich, R.-M. Huber',
  copyright = 'Josef Friedrich, R.-M. Huber',
  license   = 'The LaTeX Project Public License Version 1.3c 2008-05-04'
}

--- `nodex` is a abbreviation for __node eXtended__.
local nodex = {}

--- All values and functions, which are related to the option management,
-- are stored in a table called `registry`.
local registry = {}

--- I didn't know what value I should take as `user_id`. Therefore I
-- took my birthday and transformed it to a large number.
registry.user_id = 3121978
registry.storage = {}
registry.defaults = {
  ['align'] = 'l',
  ['boxheight'] = false,
  ['boxwidth'] = '\\linewidth',
  ['distance'] = '1.5pt',
  ['hide'] = false,
  ['linecolor'] = '0 0 0 rg 0 0 0 RG', -- black
  ['linecolor_name'] = 'black',
  ['margin'] = '3pt',
  ['resetcolor'] = '0 0 0 rg 0 0 0 RG', -- black
  ['resetcolor_name'] = 'black',
  ['show_text'] = true,
  ['show'] = true,
  ['spacing'] = '1.6',
  ['textcolor'] = '0 0 1 rg 0 0 1 RG', -- blue
  ['textcolor_name'] = 'blue', -- blue
  ['thickness'] = '0.4pt',
  ['width'] = '2cm',
}
registry.global_options = {}
registry.local_options = {}

-- All those functions are stored in the table `cloze` that are
-- registered as callbacks to the pre and post linebreak filters.
local cloze = {}
-- In the status table are stored state information, which are necessary
-- for the recursive cloze generation.
cloze.status = {}

-- The `base` table contains some basic functions. `base` is the only
-- table of this Lua module that will be exported.
local base = {}
base.is_registered = {}

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
  for i, insert in ipairs(list) do
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
--     <th>`n.color_line`</th>
--     <th>`whatsit`</th>
--     <th>`pdf_colorstack`</th>
--     <th>Line color</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`n.line`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`width`</td>
--   </tr>
--   <tr>
--     <td>`n.color_reset`</td>
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

--- This function enclozes a rule node with color nodes as it the function
-- `nodex.insert_line` does. In contrast to `nodex.insert_line` the three
-- nodes are appended to \TeX’s ‘current list’. They are not inserted in
-- a node list, which is accessed by a Lua callback.
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
function nodex.write_line()
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

--- The function `nodex.write_linefil` surrounds a indefinitely strechable
-- line with color whatsits and puts it to \TeX’s ‘current (node) list’.
function nodex.write_linefil()
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
-- @treturn node head_node
local function insert_strut_into_hlist(hlist_node)
  local head_node = hlist_node.head
  local kern_node = create_kern_node(0)
  local strut_node = node.insert_before(hlist_node.head, head_node, kern_node)
  hlist_node.head = head_node.prev
  return hlist_node, strut_node, head_node
end

--- Write kern nodes to the current node list. This kern nodes can be used
-- to build a margin.
function nodex.write_margin()
  local kern = create_kern_node(tex.sp(registry.get_value('margin')))
  node.write(kern)
end

--- Search for a `hlist` (subtype `line`).
--
-- Insert a strut node into the list if a hlist is found.
--
-- @tparam node head_node The head of a node list.
--
-- @treturn node|false Return false, if no `hlist` can
-- be found.
local function search_hlist(head_node)
  while head_node do
    if head_node.id == node.id('hlist') and head_node.subtype == 1 then
      return insert_strut_into_hlist(head_node)
    end
    head_node = head_node.next
  end
  return false
end

--- Option handling.
--
-- The table `registry` bundels functions that deal with option handling.
--
-- <h2>Marker processing (marker)</h2>
--
-- A marker is a whatsit node of the subtype `user_defined`. A marker has
-- two purposes:
--
-- * Mark the begin and the end of a gap.
-- * Store a index number, that points to a Lua table, which holds
--   some additional data like the local options.
-- @section registry

--- We create a user defined whatsit node that can store a number (type
--  = 100).
--
-- In order to distinguish this node from other user defined whatsit
-- nodes we set the `user_id` to a large number. We call this whatsit
-- node a marker. The argument `index` is a number, which is associated
-- to values in the `registry.storage` table.
function registry.create_marker(index)
  local marker = node.new('whatsit','user_defined')
  marker.type = 100 -- number
  marker.user_id = registry.user_id
  marker.value = index
  return marker
end

--- Write a marker node to \TeX's current node list.
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
  else
    return false
  end
end

--- This functions tests, whether the given node `item` is a marker.
--
-- The argument `item` is a node. The argument `mode` accepts the string
-- values `basic`, `fix` and `par`. The argument `position` is either
-- set to `start` or to `stop`.
function registry.check_marker(item, mode, position)
  local data = registry.get_marker_data(item)
  if data and data.mode == mode and data.position == position then
    return true
  else
    return false
  end
end

--- `registry.get_marker` returns the given marker.
--
-- The argument `item` is a node. The argument `mode` accepts the string
-- values `basic`, `fix` and `par`. The argument `position` is either
-- set to `start` or to `stop`.
function registry.get_marker(item, mode, position)
  local out
  if registry.check_marker(item, mode, position) then
    out = item
  else
    out = false
  end
  if out and position == 'start' then
    registry.get_marker_values(item)
  end
  return out
end

--- `registry.get_marker_data` tests whether the node `item` is a
--  marker.
--
-- The argument `item` is a node of unspecified type.
function registry.get_marker_data(item)
  if item.id == node.id('whatsit')
    and item.subtype == node.subtype('user_defined')
    and item.user_id == registry.user_id then
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
function registry.remove_marker(marker)
  if registry.is_marker(marker) then node.remove(marker, marker) end
end

-- __Storage functions (storage)__

--- `registry.index` is a counter. The functions `registry.get_index()`
-- increases the counter by one and then returns it.
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
-- where the local options in the Lua table are stored. The argument
-- `mode` accepts the string values `basic`, `fix` and `par`.
function registry.set_storage(mode, position)
  local index = registry.get_index()
  local data = {
    ['mode'] = mode,
    ['position'] = position
  }
  data.values = registry.local_options
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

--- `registry.set_is_global()` sets the variable `registry.is_global` to
-- the value `value`. It is intended, that the variable takes boolean
-- values.
function registry.set_is_global(value)
  registry.is_global = value
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
function registry.has_value(value)
  if value == nil or value == '' or value == '\\color@ ' then
    return false
  else
    return true
  end
end

--- `registry.get_defaults(option)` returns a the default value of the
-- given option.
function registry.get_defaults(option)
  return registry.defaults[option]
end

--- Assembly to cloze texts.
-- @section cloze_functions

--- The function `cloze.basic_make()` makes one gap. The argument `start`
-- is the node, where the gap begins. The argument `stop` is the node,
-- where the gap ends.
function cloze.basic_make(start_node, end_node)
  local node_head = start_node
  if not start_node or not end_node then
    return
  end
  local line_width = node.dimensions(
    cloze.status.hlist.glue_set,
    cloze.status.hlist.glue_sign,
    cloze.status.hlist.glue_order,
    start_node,
    end_node
  )
  local line_node = nodex.insert_line(start_node, line_width)
  local color_text_node = nodex.insert_list('after', line_node, {nodex.create_color('text')})
  if registry.get_value_show() then
    nodex.insert_list('after', color_text_node, {create_kern_node(-line_width)})
    nodex.insert_list('before', end_node, {nodex.create_color('reset')}, node_head)
  else
    line_node.next = end_node.next
    end_node.prev = line_node -- not line_node.prev -> line color leaks out
  end
  -- In some edge cases the lua callbacks get fired up twice. After the
  -- cloze has been created, the start and stop whatsit markers can be
  -- deleted.
  registry.remove_marker(start_node)
  registry.remove_marker(end_node)
end

--- Search for a stop marker.
--
-- @tparam node head_node The head of a node list.
--
-- @treturn node The end node.
function cloze.basic_search_stop(head_node)
  local end_node
  while head_node do
    cloze.status.continue = true
    end_node = head_node
    if registry.check_marker(end_node, 'basic', 'stop') then
      cloze.status.continue = false
      break
    end
    head_node = head_node.next
  end
  return end_node
end

--- Search for a start marker or begin a new cloze if the value
--  `cloze.status.continue` is true.
--
-- We have to find a hlist node and use its on the field `head`
-- attached node list to search for a start marker.
--
-- @tparam node head_node The head of a node list.
function cloze.basic_search_start(head_node)
  local start_node, end_node, hlist_node
  if cloze.status.continue then
    hlist_node = search_hlist(head_node)
    if hlist_node then
      cloze.status.hlist = hlist_node
      start_node = hlist_node.head
    end
  elseif registry.check_marker(head_node, 'basic', 'start') then
    start_node = head_node
  end
  if start_node then
    end_node = cloze.basic_search_stop(start_node)
    cloze.basic_make(start_node, end_node)
  end
end

--- Parse the node tree recursivley.
--
-- Start and end markers could be nested deeply in the node tree.
--
-- @tparam node head_node The head of a node list.
function cloze.basic_recursion(head_node)
  while head_node do
    if head_node.head then
      cloze.status.hlist = head_node
      cloze.basic_recursion(head_node.head)
    else
      cloze.basic_search_start(head_node)
    end
      head_node = head_node.next
  end
end

--- The corresponding LaTeX command to this lua function is `\cloze`.
--
-- @tparam node head_node The head of a node list.
--
-- @treturn node The head of the node list.
function cloze.basic(head_node)
  cloze.status.continue = false
  cloze.basic_recursion(head_node)
  return head_node
end

--- Calculate the length of the whitespace before (`l.kern_start`) and
-- after (`l.kern_stop`) the text.
function cloze.fix_length(start, stop)
  local l = {}
  l.width = tex.sp(registry.get_value('width'))
  l.text_width = node.dimensions(start, stop)
  l.align = registry.get_value('align')
  if l.align == 'right' then
    l.kern_start = - l.text_width
    l.kern_stop = 0
  elseif l.align == 'center' then
    l.half = (l.width - l.text_width) / 2
    l.kern_start = - l.half - l.text_width
    l.kern_stop = l.half
  else
    l.kern_start = - l.width
    l.kern_stop = l.width - l.text_width
  end
  return l.width, l.kern_start, l.kern_stop
end

--- The function `cloze.fix_make` generates a gap of fixed width.
--
-- __Node lists__
--
-- __Show text:__
--
-- <table>
-- <tbody>
--   <tr>
--     <td>`n.start`</td>
--     <td>`whatsit`</td>
--     <td>`user_definded`</td>
--     <td>`index`</td>
--   </tr>
--   <tr>
--     <td>`n.line`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`l.width`</td>
--   </tr>
--   <tr>
--     <td>`n.kern_start`</td>
--     <td>`kern`</td>
--     <td>&amp; Depends on `align`</td>
--     <td></td>
--   </tr>
--   <tr>
--     <td>`n.color_text`</td>
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
--     <td>`n.color_reset`</td>
--     <td>`whatsit`</td>
--     <td>`pdf_colorstack`</td>
--     <td>Reset color</td>
--   </tr>
--   <tr>
--     <td>`n.kern_stop`</td>
--     <td>`kern`</td>
--     <td>&amp; Depends on `align`</td>
--     <td></td>
--   </tr>
--   <tr>
--     <td>`n.stop`</td>
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
--     <th>`n.start`</th>
--     <th>`whatsit`</th>
--     <th>`user_definded`</th>
--     <th>`index`</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`n.line`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`l.width`</td>
--   </tr>
--   <tr>
--     <td>`n.stop`</td>
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
function cloze.fix_make(start, stop)
  local l = {} -- length
  local n = {} -- node
  l.width, l.kern_start, l.kern_stop = cloze.fix_length(start, stop)
  n.line = nodex.insert_line(start, l.width)
  if registry.get_value_show() then
    nodex.insert_list(
      'after',
      n.line,
      {
        create_kern_node(l.kern_start),
        nodex.create_color('text')
      }
    )
    nodex.insert_list(
      'before',
      stop,
      {
        nodex.create_color('reset'),
        create_kern_node(l.kern_stop)
      },
      start
    )
  else
    n.line.next = stop.next
  end
  registry.remove_marker(start)
  registry.remove_marker(stop)
end

--- Function to recurse the node list and search after marker.
--
-- @tparam node head_node The head of a node list.
function cloze.fix_recursion(head_node)
  local n = {} -- node
  n.start, n.stop = false
  while head_node do
    if head_node.head then
      cloze.fix_recursion(head_node.head)
    else
      if not n.start then
        n.start = registry.get_marker(head_node, 'fix', 'start')
      end
      if not n.stop then
        n.stop = registry.get_marker(head_node, 'fix', 'stop')
      end
      if n.start and n.stop then
        cloze.fix_make(n.start, n.stop)
        n.start, n.stop = false
      end
    end
    head_node = head_node.next
  end
end

--- The corresponding LaTeX command to this Lua function is `\clozefix`.
--
-- @tparam node head_node The head of a node list.
function cloze.fix(head_node)
  cloze.fix_recursion(head_node)
  return head_node
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
--     <th>`n.strut`</th>
--     <th>`kern`</th>
--     <th></th>
--     <th>width = 0</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`n.line`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`l.width` (Width from hlist)</td>
--   </tr>
--   <tr>
--     <td>`n.kern`</td>
--     <td>`kern`</td>
--     <td></td>
--     <td>`-l.width`</td>
--   </tr>
--   <tr>
--     <td>`n.color_text`</td>
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
--     <td>`n.tail`</td>
--     <td>`glyph`</td>
--     <td></td>
--     <td>Last glyph in hlist</td>
--   </tr>
--   <tr>
--     <td>`n.color_reset`</td>
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
--     <th>`n.strut`</th>
--     <th>`kern`</th>
--     <th></th>
--     <th>width = 0</th>
--   </tr>
-- </thead>
-- <tbody>
--   <tr>
--     <td>`n.line`</td>
--     <td>`rule`</td>
--     <td></td>
--     <td>`l.width` (Width from hlist)</td>
--   </tr>
-- </tbody>
-- </table>
--
-- @tparam node head_node The head of a node list.
function cloze.par(head_node)
  local l = {} -- length
  local n = {} -- node
  for hlist in node.traverse_id(node.id('hlist'), head_node) do
    for whatsit in node.traverse_id(node.id('whatsit'), hlist.head) do
      registry.get_marker(whatsit, 'par', 'start')
    end
    l.width = hlist.width
    hlist, n.strut, n.head = insert_strut_into_hlist(hlist)
    n.line = nodex.insert_line(n.strut, l.width)
    if registry.get_value_show() then
      nodex.insert_list(
        'after',
        n.line,
        {
          create_kern_node(-l.width),
          nodex.create_color('text')
        }
      )
      nodex.insert_list(
        'after',
        node.tail(head_node),
        {nodex.create_color('reset')}
      )
    else
      n.line.next = nil
    end
  end
  return head_node
end

--- Basic module functions.
-- The `base` table contains functions which are published to the
-- `cloze.sty` file.
-- @section base

--- This function registers the functions `cloze.par`, `cloze.basic` and
--  `cloze.fix` the Lua callbacks.
--
-- `cloze.par` and `cloze.basic` are registered to the callback
-- `post_linebreak_filter` and `cloze.fix` to the callback
-- `pre_linebreak_filter`. The argument `mode` accepts the string values
-- `basic`, `fix` and `par`. A special treatment is needed for clozes in
-- display math mode. The `post_linebreak_filter` is not called on
-- display math formulas. I’m not sure if the `pre_output_filter` is the
-- right choice to capture the display math formulas.
function base.register(mode)
  local basic
  if mode == 'par' then
    luatexbase.add_to_callback(
      'post_linebreak_filter',
      cloze.par,
      mode
    )
    return true
  end
  if not base.is_registered[mode] then
    if mode == 'basic' then
      luatexbase.add_to_callback(
        'post_linebreak_filter',
        cloze.basic,
        mode
      )
      luatexbase.add_to_callback(
        'pre_output_filter',
        cloze.basic,
        mode
      )
    elseif mode == 'fix' then
      luatexbase.add_to_callback(
        'pre_linebreak_filter',
        cloze.fix,
        mode
      )
    else
      return false
    end
    base.is_registered[mode] = true
  end
end

--- `base.unregister(mode)` deletes the registered functions from the
-- Lua callbacks.
--
-- @tparam string mode The argument `mode` accepts the string values
-- `basic`, `fix` and `par`.
function base.unregister(mode)
  if mode == 'basic' then
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
    luatexbase.remove_from_callback('pre_output_filter', mode)
  elseif mode == 'fix' then
    luatexbase.remove_from_callback('pre_linebreak_filter', mode)
  else
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  end
end

-- Publish some functions to the `cloze.sty` file.
base.linefil = nodex.write_linefil
base.line = nodex.write_line
base.margin = nodex.write_margin
base.set_option = registry.set_option
base.set_is_global = registry.set_is_global
base.unset_local_options = registry.unset_local_options
base.reset = registry.unset_global_options
base.get_defaults = registry.get_defaults
base.get_value = registry.get_value
base.marker = registry.write_marker

return base
