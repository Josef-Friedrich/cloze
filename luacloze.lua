local check = {}
local get = {}
check.user_id = 3121978
local create = {}
local insert = {}

local registry = {}
registry.storage = {}
registry.defaults = {
  ['align'] = 'l',
  ['descender'] = '3pt',
  ['linecolor'] = '0 0 0 rg 0 0 0 RG', -- black
  ['resetcolor'] = '0 0 0 rg 0 0 0 RG', -- black
  ['show_text'] = true,
  ['textcolor'] = '0 0 1 rg 0 0 1 RG', -- blue
  ['thickness'] = '0.4pt',
  ['width'] = '2cm',
}
registry.global_options = {}
registry.local_options = {}
registry.options = {}

local cloze = {}
local base = {}
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
  local data = registry.marker_data(item)

  if data and data.mode == mode and data.position == position then
    return true
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

function create.color(option)
  local data

  if option == 'line' then
    data = registry.linecolor
  elseif option == 'text' then
    data = registry.textcolor
  elseif option == 'reset' then
    data = nil
  else
    data = nil
  end

  return create.whatsit_colorstack(data)
end

function create.rule(width)
  local node = node.new(node.id('rule'))
  local height = tex.sp(registry.thickness) - tex.sp(registry.descender)

  node.depth = tex.sp(registry.descender)
  node.height = height
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

function create.hfill()
  local glue = node.new('glue')
  glue.subtype = 100

  local glue_spec = node.new('glue_spec')
  glue_spec.stretch = 65536
  glue_spec.stretch_order = 3

  glue.spec = glue_spec

  local rule = create.rule(0)
  rule.dir = 'TLT'

  glue.leader = rule

  return glue
end

------------------------------------------------------------------------
-- insert
------------------------------------------------------------------------

function insert.hfill(options)
  registry.local_options = options
  registry.process_options()

  node.write(create.color('line'))
  node.write(create.hfill())
  node.write(create.color('reset'))
end


function insert.rule_colored(head, current, width)

  local color = {}

  -- Append rule and kern to the node list.
  local rule = create.rule(width)

  head, new = node.insert_after(head, current, create.color('line'))
  head, new = node.insert_after(head, new, rule)
  head, new = node.insert_after(head, new, create.color('reset'))

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

-- Unset options which have the values 'unset' or '\color@ '
function registry.merge_local_options()
  local tmp = {}

  tmp = registry.unset_options(registry.local_options)

  if registry.local_options.hide then
    tmp.show_text = false
  end

  if registry.local_options.show then
    tmp.show_text = true
  end

  registry.options = tmp
end

function registry.unset_options(options)
  local out = {}

  for key, value in pairs(options) do
    if value == 'unset' or value == '\\color@ ' then
      out[key] = nil
    else
      out[key] = value
    end
  end

  return out
end

function registry.merge_global_options()
  registry.global_options = registry.unset_options(registry.global_options)
  for key, value in pairs(registry.global_options) do
    if registry.options[key] == nil or registry.options[key] == '' then
      registry.options[key] = value
    end
  end
end

function registry.merge_defaults()
  for key, value in pairs(registry.defaults) do
    if registry.options[key] == nil or registry.options[key] == '' then
      registry.options[key] = value
    end
  end
end

function registry.fix_align_options()
  local align = string.lower(registry.options.align)
  local result

  if align == 'r' then
    result = 'right'
  elseif align == 'c' then
    result = 'center'
  elseif align == 'l' then
    result = 'left'
  else
    result = align
  end

  registry.options.align = align
end

function registry.move_to_base()
  for key, value in pairs(registry.options) do
    registry[key] = value
  end
end

function registry.debug(table, identifier)
  for key, value in pairs(table) do
    print(identifier .. ' KEY: ' .. tostring(key) .. ' VALUE: ' .. tostring(value))
  end
end

function registry.process_options()
  registry.merge_local_options()
  registry.merge_global_options()
  registry.merge_defaults()
  registry.fix_align_options()
  registry.move_to_base()
end

function registry.marker_data(item)
  if not check.whatsit_marker(item) then
    return false
  else
    return registry.get(item.value)
  end
end

function registry.marker_values(item)
  local data = registry.marker_data(item)
  registry.local_options = data.values
  return data.values
end

function registry.get_marker(item, mode, position)
  local out

  if check.marker(item, mode, position) then
    registry.marker = item
    out = item
  else
    out = false
  end

  if out and position == 'start' then
    registry.marker_values(item)
    registry.process_options()
  end

  return out
end

------------------------------------------------------------------------
-- cloze
------------------------------------------------------------------------

function cloze.basic(head)
  local n = {} -- node
  local b = {} -- boolean
  local l = {} -- length
  local t = {} -- temp

  for hlist in node.traverse_id(node.id('hlist'), head) do

    -- To make life easier: We add at the beginning of each line a strut.
    -- Now we can add rule, color etc. nodes AFTER
    -- the first node of a line not BEFORE. AFTER is much more easier.
    n.head = hlist.head
    n.strut = node.insert_before(n.head, n.head, create.kern(0))
    hlist.head = n.head.prev

    if b.line_end then
      b.init_cloze = true
    end

    n.current = hlist.head

    while n.current do

      if check.marker(n.current, 'basic', 'start') or b.init_cloze then

        n.marker = registry.get_marker(n.current, 'basic', 'start')

        node.insert_after(hlist.head, n.current, create.color('text'))

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

        head, n.line = insert.rule_colored(head, n.current, l.line_width)

        if registry.show_text then
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

function cloze.fix_make(head, start, stop)
  local l = {} -- length

  l.width = tex.sp(registry.width)

  local n = {} -- node
  n.start = start
  n.stop = stop

  l.text_width = node.dimensions(n.start, n.stop)

  if registry.align == 'right' then
    l.kern_start = -l.text_width
    l.kern_stop = 0
  elseif registry.align == 'center' then
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
  head, n.line = insert.rule_colored(head, n.start, l.width)

  -- W[b] W[linecolor] R[length] W[colorreset] K[kern_start] W[textcolor]
  --   cloze test W[colorreset] K[kern_stop] W[e]
  if registry.show_text then

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

function cloze.fix(head)
  local n = {} -- node

  n.start, n.stop = false
  for current in node.traverse_id(node.id('whatsit'), head) do

    if not n.start then n.start = registry.get_marker(current, 'fix', 'start') end
    if not n.stop then n.stop = registry.get_marker(current, 'fix', 'stop') end

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

  for hlist in node.traverse_id(node.id('hlist'), head) do

    for whatsit in node.traverse_id(node.id('whatsit'), hlist.head) do
      registry.get_marker(whatsit, 'par', 'start')
    end

    l.width = hlist.width

    n.head = hlist.head
    n.strut = node.insert_before(n.head, n.head, create.kern(0))
    hlist.head = n.head.prev

    head, n.rule = insert.rule_colored(head, n.strut, l.width)

    if registry.show_text then
      head, n.kern = node.insert_after(head, n.rule, create.kern(-l.width))
      node.insert_after(head, n.kern, create.color('text'))

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

function base.set_global_options(options)
  options.show_text = base.show_text
  registry.global_options = options
end

function base.marker(mode, position, values)
  local index = registry.set(mode, position, values)
  local marker = create.marker(index)
  node.write(marker)
end

base.hfill = insert.hfill

return base
