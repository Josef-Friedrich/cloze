local check = {}
check.user_id = 3121978
local create = {}
local insert = {}
local cache = {}
cache.storage = {}
local cloze = {}
local base = {}
base.options = {}
local is_registered = {}

local options
------------------------------------------------------------------------
-- check
------------------------------------------------------------------------

function check.is_marker(item)
  if item.id == node.id('whatsit')
      and item.subtype == 44
      and item.user_id == check.user_id then
    return true
  else
    return false
  end
end

function check.get_marker_data(item)
  if not check.is_marker(item) then
    return false
  else
    return cache.get(item.value)
  end
end

function check.get_marker_values(item)
  local data = check.get_marker_data(item)
  return data.values
end

function check.is_mode(item, mode)
  local data = check.get_marker_data(item)

  if data and data.mode == mode then
    return true
  else
    return false
  end
end

function check.is_position(item, position)
  local data = check.get_marker_data(item)

  if data and data.position == position then
    return true
  else
    return false
  end
end

function check.mode_position(item, mode, position)
  local data = check.get_marker_data(item)

  if data and data.mode == mode and data.position == position then
    return true
  else
    return false
  end
end

function check.get_by_mode_pos(item, mode, position)
  if check.mode_position(item, mode, position) then
    return item
  else
    return false
  end
end

------------------------------------------------------------------------
-- create
------------------------------------------------------------------------

-- Whatsit: colorstack
function create.whatsit_colorstack(data)
  if not data then
    -- black
    data = '0 0 0 rg 0 0 0 RG'
  end

  local node = node.new('whatsit', 'pdf_colorstack')
  node.stack = 0
  node.data = data

  return node
end

---
--
function create.color(option)
  local data

  if option == 'line' then
    data = options.linecolor
  elseif option == 'text' then
    data = options.textcolor
  elseif option == 'reset' then
    data = nil
  else
    data = nil
  end

  return create.whatsit_colorstack(data)
end

---
--
function create.rule(width, loptions)
  -- Rule.
  local node = node.new(node.id('rule'))

  -- thickness = depth - height
  if not loptions.descender then
    loptions.descender = "3.4pt"
  end

  if not loptions.thickness then
    loptions.thickness = "0.4pt"
  end

  local height = tex.sp(loptions.thickness) - tex.sp(loptions.descender)

  node.depth = tex.sp(loptions.descender) -- 3.4pt
  node.height = tex.sp(height) -- -3pt
  node.width = width

  return node
end

function create.kern(kern)
  local node = node.new(node.id('kern'))
  node.kern = kern
  return node
end

function create.glyph()
  local node = node.new(node.id('glyph'))
  node.char = 34
  return node
end

---
--
function create.whatsit_userdefined(value)
  local node = node.new('whatsit','user_defined')
  node.type = 115 -- string
  node.user_id = WHATSIT_USERID
  node.value = value

  return node
end

---
--
function create.marker(index)
  local marker = node.new('whatsit','user_defined')
  marker.type = 100 -- number
  marker.user_id = check.user_id
  marker.value = index

  return marker
end

------------------------------------------------------------------------
-- insert
------------------------------------------------------------------------

function insert.rule_colored(head, current, width, loptions)

  local color = {}

  color.line = create.color('line')
  color.reset = create.whatsit_colorstack()

  -- Append rule and kern to the node list.
  local rule = create.rule(width, loptions)

  head, new = node.insert_after(head, current, color.line)
  head, new = node.insert_after(head, new, rule)
  head, new = node.insert_after(head, new, color.reset)

  return head, new
end

------------------------------------------------------------------------
-- cache
------------------------------------------------------------------------

function cache.get_index()
  if not cache.index then
    cache.index = 0
  end

  cache.index = cache.index + 1
  return cache.index
end

function cache.set(mode, position, values)
  local index = cache.get_index()

  local data = {
    ['mode'] = mode,
    ['position'] = position
  }

  if values then
    local cleaned_values = {}
    for key, value in pairs(values) do
      if value ~= '' then
        cleaned_values[key] = value
      end
    end
    data.values = cleaned_values
  end

  cache.storage[index] = data
  return index
end

function cache.get(index)
  return cache.storage[index]
end

function cache.process_local_options(loptions)
  if not loptions then
    local loptions = {}
  end
  for key, value in pairs(options) do
    if not loptions[key] then
      loptions[key] = value
    end
  end

  return loptions
end

------------------------------------------------------------------------
-- cloze
------------------------------------------------------------------------

---
--
---
function cloze.basic(head)

  for line in node.traverse_id(node.id("hlist"), head) do

    -- To make life easier: We add at the beginning of each line a blank
    -- user defined whatsit. Now we can add rule, color etc. nodes AFTER
    -- the first node of a line not BEFORE. AFTER is much more easier.
    current = line.head
    node.insert_before(current, current, create.whatsit_userdefined('cloze-anchor'))
    line.head = current.prev

    if LINE_END then
      INIT_CLOZE = true
    end

    local item = line.head

    while item do

      if check.mode_position(item, 'basic', 'start') or INIT_CLOZE then
        node.insert_after(line.head, item, create.color('text'))

        INIT_CLOZE = false

        local end_node = item
        while end_node.next do

          LINE_END = true

          if check.mode_position(end_node, 'basic', 'stop') then
            LINE_END = false
            break
          end

          end_node = end_node.next
        end

        local rule_width = node.dimensions(line.glue_set, line.glue_sign, line.glue_order, item, end_node.next)

        head, current = insert.rule_colored(head, item, rule_width)

        if options.show_text then
          node.insert_after(head, current, create.kern(-rule_width))
          colorstack_reset = create.whatsit_colorstack()
          node.insert_after(head, end_node, colorstack_reset)
        else
          current.next = end_node.next
          end_node.prev = current.prev
        end

        item = end_node.next
      else
        item = item.next
      end -- if

    end -- while

  end -- for

  return head
end -- function

-- mode: fix -----------------------------------------------------------

function cloze.fix_align_options(option)
  option = string.lower(option)

  if option == 'r' then
    return 'right'
  elseif option == 'c' then
    return 'center'
  elseif option == 'l' then
    return 'left'
  else
    return option
  end

end

-- b whatsit begin marker
-- e whatsit end marker
-- t tmp
function cloze.fix_make(head, start, stop)
  -- l = length
  local l = {}

  local loptions = check.get_marker_values(start)
  loptions = cache.process_local_options(loptions)

  l.width = tex.sp(loptions.width)

  -- n = node
  local n = {}
  -- loption = local option
  n.start = start
  n.stop = stop

  local loption = {}
  loption.align = cloze.fix_align_options(options.align)

  l.text_width = node.dimensions(n.start, n.stop)

  if loption.align == 'right' then
    l.kern_start = -l.text_width
    l.kern_stop = 0
  elseif loption.align == 'center' then
    l.half = (l.width - l.text_width) / 2
    l.kern_start = -l.half - l.text_width
    l.kern_stop = l.half
  else
    l.kern_start = -l.width
    l.kern_stop = l.width - l.text_width
  end

  -- W[n.start] R[n.line] K[n.kern_start] W[textcolor]
  --   cloze test W[colorreset] K[n.kern_stop] W[n.end]

  -- Insert colored rule ()
  head, n.line = insert.rule_colored(head, n.start, l.width, loptions)

  -- W[b] W[linecolor] R[length] W[colorreset] K[kern_start] W[textcolor]
  --   cloze test W[colorreset] K[kern_stop] W[e]
  if options.show_text then

  -- Insert kerning for the gap at the beginning.
  head, n.kern_start = node.insert_after(head, n.line, create.kern(l.kern_start))

  -- Insert text color.
  node.insert_after(head, n.kern_start, create.color('text'))

  -- Reset text color.
  node.insert_before(head, n.stop, create.whatsit_colorstack())

  -- Insert kerning for the gap at the end.
  node.insert_before(head, n.stop, create.kern(l.kern_stop))

  -- W[b] W[linecolor] R[length] W[colorreset] K[kern_start] W[e]
  else
    n.line.next = n.stop.next
  end
end

---
--
---
function cloze.fix(head)
  -- n = node
  local n = {}

  n.start, n.stop = false
  for current in node.traverse_id(node.id('whatsit'), head) do

    if not n.start then n.start = check.get_by_mode_pos(current, 'fix', 'start') end
    if not n.stop then n.stop = check.get_by_mode_pos(current, 'fix', 'stop') end

    if n.start and n.stop then
      cloze.fix_make(head, n.start, n.stop)
      n.start, n.stop = false
    end
  end

  return head
end

-- mode: toend ---------------------------------------------------------

---
--
---
function cloze.toend(head)
  return head
end

-- mode: par -----------------------------------------------------------

---
--
---
function cloze.par(head)
  -- l = lenght
  local l = {}

  -- n = node
  local n = {}

  for hlist in node.traverse_id(node.id("hlist"), head) do

    l.width = hlist.width

    n.current = hlist.head
    n.strut = create.rule(0)
    hlist.head = n.strut
    n.strut.next = n.current

    head, n.rule = insert.rule_colored(head, n.strut, l.width)

    if options.show_text then
      head, n.kern = node.insert_after(head, n.rule, create.kern(-l.width))
      node.insert_after(head, n.kern, create.color('text'))

      n.tail = node.tail(n.current)
      node.insert_after(n.current, n.tail, create.color('reset'))
    else
      n.rule.next = nil
    end
  end

  return head
end

------------------------------------------------------------------------
-- base
------------------------------------------------------------------------

function base.register(mode)
  if not is_registered[mode] then
    if mode == 'basic' then
      luatexbase.add_to_callback('post_linebreak_filter', cloze.basic, mode, 1)
    elseif mode == 'fix' then
      luatexbase.add_to_callback('pre_linebreak_filter', cloze.fix, mode, 1)
    elseif mode == 'toend' then
      luatexbase.add_to_callback('post_linebreak_filter', cloze.toend, mode, 1)
    else
      luatexbase.add_to_callback('post_linebreak_filter', cloze.par, mode, 1)
    end
    is_registered[mode] = true
  end
end

function base.unregister(mode)
  if mode == 'basic' then
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  elseif mode == 'fix' then
    luatexbase.remove_from_callback('pre_linebreak_filter', mode)
  elseif mode == 'toend' then
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  else
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  end
end

function base.get_options(localoptions)
  options = localoptions
  if options.show_text == nil then
    options.show_text = true
  end
end

function base.marker(mode, position, values)
  local index = cache.set(mode, position, values)
  local marker = create.marker(index)
  node.write(marker)
end

base.marker_start = insert.marker_start
base.marker_stop = insert.marker_stop

return base
