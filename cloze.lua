--- Cloze uses [LDoc](https://github.com/stevedonovan/ldoc) for the
--  source code documentation. The supported tags are described on in
--  the [wiki](https://github.com/stevedonovan/LDoc/wiki).
--
-- @module cloze



-- \subsection{The file \tt{cloze.lua}}

-- \paragraph{Initialisation of the function tables}

-- It is good form to provide some background informations about this Lua
-- module.
if not modules then modules = { } end modules ['cloze'] = {
  version   = '1.4',
  comment   = 'cloze',
  author    = 'Josef Friedrich, R.-M. Huber',
  copyright = 'Josef Friedrich, R.-M. Huber',
  license   = 'The LaTeX Project Public License Version 1.3c 2008-05-04'
}

--- `nodex` is a abbreviation for \emph{node eXtended}.
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
-- `nodex` is a abbreviation for \emph{node eXtended}. The `nodex` table
-- bundles all functions, which extend the built-in `node` library.

-- \paragraph{Color handling (color)}

-- \clozeluafunction{create_colorstack}
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

-- \paragraph{Line handling (line)}

--- Create a rule node, which is used as a line for the cloze texts. The
-- `depth` and the `height` of the rule are calculated form the options
-- `thickness` and `distance`. The argument `width` must have the length
-- unit \emph{scaled points}.
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
function nodex.insert_list(position, current, list, head)
  if not head then
    head = current
  end
  for i, insert in ipairs(list) do
    if position == 'after' then
      head, current = node.insert_after(head, current, insert)
    elseif position == 'before' then
      head, current = node.insert_before(head, current, insert)
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
-- \begin{nodelist} `n.color_line` & `whatsit` & `pdf_colorstack` & Line
-- color \\
-- `n.line` & `rule` &  & `width` \\
-- `n.color_reset` & `whatsit` & `pdf_colorstack` & Reset color \\
-- \end{nodelist}
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

-- \paragraph{Handling of extendable lines (linefil)}

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

-- \paragraph{Kern handling (kern)}

--- This function creates a kern node with a given width. The argument
-- `width` had to be specified in scaled points.
function nodex.create_kern(width)
  local kern = node.new(node.id('kern'))
  kern.kern = width
  return kern
end

--- To make life easier: We add at the beginning of each hlist a strut.
-- Now we can add line, color etc. nodes after the first node of a hlist
-- not before - after is much more easier.
function nodex.strut_to_hlist(hlist)
  local n = {} -- node
  n.head = hlist.head
  n.kern = nodex.create_kern(0)
  n.strut = node.insert_before(n.head, n.head, n.kern)
  hlist.head = n.head.prev
  return hlist, n.strut, n.head
end

--- Write kern nodes to the current node list. This kern nodes can be used
-- to build a margin.
function nodex.write_margin()
  local kern = nodex.create_kern(tex.sp(registry.get_value('margin')))
  node.write(kern)
end

--- Search for a `hlist` (subtype `line`). Return false, if no `hlist` can
-- be found.
function nodex.search_hlist(head)
  while head do
    if head.id == node.id('hlist') and head.subtype == 1 then
      return nodex.strut_to_hlist(head)
    end
    head = head.next
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

-- \paragraph{Storage functions (storage)}

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

-- \paragraph{Option processing (option)}

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
function cloze.basic_make(node_first, node_last)
  local node_head = node_first
  if not node_first or not node_last then
    return
  end
  local line_width = node.dimensions(
    cloze.status.hlist.glue_set,
    cloze.status.hlist.glue_sign,
    cloze.status.hlist.glue_order,
    node_first,
    node_last
  )
  local node_line = nodex.insert_line(node_first, line_width)
  local node_color_text = nodex.insert_list('after', node_line, {nodex.create_color('text')})
  if registry.get_value_show() then
    nodex.insert_list('after', node_color_text, {nodex.create_kern(-line_width)})
    nodex.insert_list('before', node_last, {nodex.create_color('reset')}, node_head)
  else
    node_line.next = node_last.next
    node_last.prev = node_line -- not node_line.prev -> line color leaks out
  end
  -- In some edge cases the lua callbacks get fired up twice. After the
  -- cloze has been created, the start and stop whatsit markers can be
  -- deleted.
  registry.remove_marker(node_first)
  registry.remove_marker(node_last)
end

--- Search for a stop marker.
function cloze.basic_search_stop(head)
  local stop
  while head do
    cloze.status.continue = true
    stop = head
    if registry.check_marker(stop, 'basic', 'stop') then
      cloze.status.continue = false
      break
    end
    head = head.next
  end
  return stop
end

--- Search for a start marker. Also begin a new cloze, if the boolean
-- value `cloze.status.continue` is true. The knowledge of the last
-- hlist node is a requirement to begin a cloze.
function cloze.basic_search_start(head)
  local start
  local stop
  local n = {}
  if cloze.status.continue then
    n.hlist = nodex.search_hlist(head)
    if n.hlist then
      cloze.status.hlist = n.hlist
      start = cloze.status.hlist.head
    end
  elseif registry.check_marker(head, 'basic', 'start') then
    start = head
  end
  if start then
    stop = cloze.basic_search_stop(start)
    cloze.basic_make(start, stop)
  end
end

--- Parse recursivley the node tree. Start and stop markers can be nested
-- deeply into the node tree.
function cloze.basic_recursion(head)
  while head do
    if head.head then
      cloze.status.hlist = head
      cloze.basic_recursion(head.head)
    else
      cloze.basic_search_start(head)
    end
      head = head.next
  end
end

--- The corresponding LaTeX command to this lua function is `\cloze`.
--
-- The argument `head` is the head node of a
-- node list.
function cloze.basic(head)
  cloze.status.continue = false
  cloze.basic_recursion(head)
  return head
end

--- Calculate the length of the whitespace before (`l.kern_start`) and
-- after (`l.kern_stopt`) the text.
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

--- \clozeluafunction{fix_make}
-- The function `cloze.fix_make` generates a gap of fixed width.
--
-- \subparagraph*{Node lists}
--
-- \subparagraph*{Show text:}
--
-- \begin{nodelist}
-- `n.start` & `whatsit` & `user_definded` & `index` \\
-- `n.line` & `rule` &  & `l.width` \\
-- `n.kern_start` & `kern` & & Depends on `align` \\
-- `n.color_text` & `whatsit` & `pdf_colorstack` & Text color \\
--  & `glyphs` & & Text to show \\
-- `n.color_reset` & `whatsit` & `pdf_colorstack` & Reset color \\
-- `n.kern_stop` & `kern` & & Depends on `align` \\
-- `n.stop` & `whatsit` & `user_definded` & `index` \\
-- \end{nodelist}
--
-- \subparagraph*{Hide text:}
--
-- \begin{nodelist}
-- `n.start` & `whatsit` & `user_definded` & `index` \\
-- `n.line` & `rule` &  & `l.width` \\
-- `n.stop` & `whatsit` & `user_definded` & `index` \\
-- \end{nodelist}
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
        nodex.create_kern(l.kern_start),
        nodex.create_color('text')
      }
    )
    nodex.insert_list(
      'before',
      stop,
      {
        nodex.create_color('reset'),
        nodex.create_kern(l.kern_stop)
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
-- `head` is the head node of a node list.
function cloze.fix_recursion(head)
  local n = {} -- node
  n.start, n.stop = false
  while head do
    if head.head then
      cloze.fix_recursion(head.head)
    else
      if not n.start then
        n.start = registry.get_marker(head, 'fix', 'start')
      end
      if not n.stop then
        n.stop = registry.get_marker(head, 'fix', 'stop')
      end
      if n.start and n.stop then
        cloze.fix_make(n.start, n.stop)
        n.start, n.stop = false
      end
    end
    head = head.next
  end
end

--- The corresponding LaTeX command to this Lua function is `\clozefix`.
--
-- The argument `head` is the head node of a node list.
function cloze.fix(head)
  cloze.fix_recursion(head)
  return head
end

--- The corresponding LaTeX environment to this lua function is
-- `clozepar`.
--
-- \subparagraph*{Node lists}
--
-- \subparagraph*{Show text:}
--
-- \begin{nodelist}
-- `n.strut` & `kern` &  & width = 0  \\
-- `n.line` & `rule` &  & `l.width` (Width from hlist) \\
-- `n.kern` & `kern` & & `-l.width` \\
-- `n.color_text` & `whatsit` & `pdf_colorstack` & Text color \\
--  & `glyphs` & & Text to show \\
-- `n.tail` & `glyph` &  & Last glyph in hlist \\
-- `n.color_reset` & `whatsit` & `pdf_colorstack` & Reset color \\
-- \end{nodelist}
--
-- \subparagraph*{Hide text:}
--
-- \begin{nodelist}
-- `n.strut` & `kern` &  & width = 0 \\
-- `n.line` & `rule` &  & `l.width` (Width from hlist) \\
-- \end{nodelist}
--
-- The argument `head` is the head node of a node list.
function cloze.par(head)
  local l = {} -- length
  local n = {} -- node
  for hlist in node.traverse_id(node.id('hlist'), head) do
    for whatsit in node.traverse_id(node.id('whatsit'), hlist.head) do
      registry.get_marker(whatsit, 'par', 'start')
    end
    l.width = hlist.width
    hlist, n.strut, n.head = nodex.strut_to_hlist(hlist)
    n.line = nodex.insert_line(n.strut, l.width)
    if registry.get_value_show() then
      nodex.insert_list(
        'after',
        n.line,
        {
          nodex.create_kern(-l.width),
          nodex.create_color('text')
        }
      )
      nodex.insert_list(
        'after',
        node.tail(head),
        {nodex.create_color('reset')}
      )
    else
      n.line.next = nil
    end
  end
  return head
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
-- The argument `mode` accepts the string values
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
