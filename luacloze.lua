local check = {}
local get = {}
check.user_id = 3121978
local create = {}
local insert = {}
local registry = {}
registry.storage = {}
local cloze = {}
local base = {}
base.options = {}
local is_registered = {}

local options

------------------------------------------------------------------------
-- check
------------------------------------------------------------------------

function check.whatsit_marker(item)
  if item.id == node.id('whatsit')
      and item.subtype == 44
      and item.user_id == check.user_id then
    return true
  else
    return false
  end
end

function check.marker(item, mode, position)
  local data = get.marker_data(item)

  if data and data.mode == mode and data.position == position then
    return true
  else
    return false
  end
end

------------------------------------------------------------------------
-- check
------------------------------------------------------------------------

function get.marker_data(item)
  if not check.whatsit_marker(item) then
    return false
  else
    return registry.get(item.value)
  end
end

function get.marker_values(item)
  local data = get.marker_data(item)
  return data.values
end

function get.marker(item, mode, position)
  if check.marker(item, mode, position) then
    return item
  else
    return false
  end
end

------------------------------------------------------------------------
-- create
------------------------------------------------------------------------

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

function create.color(option, loptions)
  local data

  if loptions == nil then
    loptions = registry.process_local_options(loptions)
  end

  if option == 'line' then
    data = loptions.linecolor
  elseif option == 'text' then
    data = loptions.textcolor
  elseif option == 'reset' then
    data = nil
  else
    data = nil
  end

  return create.whatsit_colorstack(data)
end

function create.rule(width, loptions)

  if not loptions then
    loptions = {}
  end

  local node = node.new(node.id('rule'))

  if loptions.descender == nil then
    loptions.descender = "3.4pt"
  end

  if loptions.thickness == nil then
    loptions.thickness = "0.4pt"
  end

  local height = tex.sp(loptions.thickness) - tex.sp(loptions.descender)

  node.depth = tex.sp(loptions.descender)
  node.height = tex.sp(height)
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

  -- Append rule and kern to the node list.
  local rule = create.rule(width, loptions)

  head, new = node.insert_after(head, current, create.color('line', loptions))
  head, new = node.insert_after(head, new, rule)
  head, new = node.insert_after(head, new, create.color('reset', loptions))

  return head, new
end

------------------------------------------------------------------------
-- registry
------------------------------------------------------------------------

function registry.get_index()
  if not registry.index then
    registry.index = 0
  end

  registry.index = registry.index + 1
  return registry.index
end

function registry.set(mode, position, values)
  local index = registry.get_index()

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

  registry.storage[index] = data
  return index
end

function registry.get(index)
  return registry.storage[index]
end

function registry.process_local_options(loptions)
  if loptions == nil then
    loptions = {}
  end

  if loptions.show == 'unset' then
    loptions.show = nil
  end

  if loptions.hide == 'unset' then
    loptions.hide = nil
  end

  if loptions.hide then
    loptions.show_text = false
    loptions.hide = nil
  end

  if loptions.show then
    loptions.show_text = true
    loptions.show = nil
  end

  for key, value in pairs(options) do
    if loptions[key] == nil then
      loptions[key] = value
    end
  end

  return loptions
end

------------------------------------------------------------------------
-- cloze
------------------------------------------------------------------------

function cloze.basic(head)
  local n = {} -- node
  local b = {} -- boolean
  local l = {} -- length
  local t = {} -- temp

  for hlist in node.traverse_id(node.id("hlist"), head) do

    -- To make life easier: We add at the beginning of each line a strut.
    -- Now we can add rule, color etc. nodes AFTER
    -- the first node of a line not BEFORE. AFTER is much more easier.
    n.head = hlist.head
    n.strut = node.insert_before(n.head, n.head, create.rule(0))
    hlist.head = n.head.prev

    if b.line_end then
      b.init_cloze = true
    end

    n.current = hlist.head

    while n.current do

      if check.marker(n.current, 'basic', 'start') or b.init_cloze then

        n.marker = get.marker(n.current, 'basic', 'start')
        if n.marker then
          t.options = get.marker_values(n.marker)
          t.options = registry.process_local_options(t.options)
        end

        node.insert_after(hlist.head, n.current, create.color('text', t.options))

        b.init_cloze = false

        n.stop = n.current
        while n.stop.next do

          b.line_end = true

          if check.marker(n.stop, 'basic', 'stop') then
            b.line_end = false
            break
          end

          n.stop = n.stop.next
        end

        l.line_width = node.dimensions(hlist.glue_set, hlist.glue_sign, hlist.glue_order, n.current, n.stop.next)

        head, n.line = insert.rule_colored(head, n.current, l.line_width, t.options)

        if t.options.show_text then
          node.insert_after(head, n.line, create.kern(-l.line_width))
          node.insert_after(head, n.stop, create.color('reset'))
        else
          n.line.next = n.stop.next
          n.stop.prev = n.line.prev
        end

        n.current = n.stop.next
      else
        n.current = n.current.next
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

function cloze.fix_make(head, start, stop)
  local l = {} -- length

  local loptions = get.marker_values(start)
  loptions = registry.process_local_options(loptions)

  l.width = tex.sp(loptions.width)

  local n = {} -- node
  n.start = start
  n.stop = stop

  local loption = {} -- local option
  loption.align = cloze.fix_align_options(loptions.align)

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
  if loptions.show_text then

  -- Insert kerning for the gap at the beginning.
  head, n.kern_start = node.insert_after(head, n.line, create.kern(l.kern_start))

  -- Insert text color.
  node.insert_after(head, n.kern_start, create.color('text', loptions))

  -- Reset text color.
  node.insert_before(head, n.stop, create.whatsit_colorstack())

  -- Insert kerning for the gap at the end.
  node.insert_before(head, n.stop, create.kern(l.kern_stop))

  -- W[b] W[linecolor] R[length] W[colorreset] K[kern_start] W[e]
  else
    n.line.next = n.stop.next
  end
end

function cloze.fix(head)
  local n = {} -- node

  n.start, n.stop = false
  for current in node.traverse_id(node.id('whatsit'), head) do

    if not n.start then n.start = get.marker(current, 'fix', 'start') end
    if not n.stop then n.stop = get.marker(current, 'fix', 'stop') end

    if n.start and n.stop then
      cloze.fix_make(head, n.start, n.stop)
      n.start, n.stop = false
    end
  end

  return head
end

-- mode: toend ---------------------------------------------------------

function cloze.toend(head)
  return head
end

-- mode: par -----------------------------------------------------------

function cloze.par(head)
  local l = {} -- length
  local n = {} -- node
  local loptions

  for hlist in node.traverse_id(node.id('hlist'), head) do

    for whatsit in node.traverse_id(node.id('whatsit'), hlist.head) do
      if check.marker(whatsit, 'par', 'start') then
        loptions = get.marker_values(whatsit)
        loptions = registry.process_local_options(loptions)
      end
    end

    l.width = hlist.width

    n.head = hlist.head
    n.strut = node.insert_before(n.head, n.head, create.rule(0))
    hlist.head = n.head.prev

    head, n.rule = insert.rule_colored(head, n.strut, l.width, loptions)

    if loptions.show_text then
      head, n.kern = node.insert_after(head, n.rule, create.kern(-l.width))
      node.insert_after(head, n.kern, create.color('text', loptions))

      n.tail = node.tail(n.head)
      node.insert_after(n.head, n.tail, create.color('reset'))
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
  if mode == 'par' then
    luatexbase.add_to_callback('post_linebreak_filter', cloze.par, mode, 1)
    return true
  end

  if not is_registered[mode] then
    if mode == 'basic' then
      luatexbase.add_to_callback('post_linebreak_filter', cloze.basic, mode, 1)
    elseif mode == 'fix' then
      luatexbase.add_to_callback('pre_linebreak_filter', cloze.fix, mode, 1)
    elseif mode == 'toend' then
      luatexbase.add_to_callback('post_linebreak_filter', cloze.toend, mode, 1)
    else
      return false
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
  local index = registry.set(mode, position, values)
  local marker = create.marker(index)
  node.write(marker)
end

return base
