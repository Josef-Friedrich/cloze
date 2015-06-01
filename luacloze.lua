local create = {}

WHATSIT_USERID = 3121978

options = {}
options.show_text = true

is_registered = {}

------------------------------------------------------------------------
-- check
------------------------------------------------------------------------

function check_marker(item, value)
  if item.id == node.id('whatsit')
      and item.subtype == 44
      and item.user_id == WHATSIT_USERID
      and item.value == value then
    return true
  else
    return false
  end
end

function check_start(item, mode)
  return check_marker(item, mode .. '-start')
end

function check_stop(item, mode)
  return check_marker(item, mode .. '-stop')
end

function get_start(current, value)
    if check_marker(current, value .. '-start') then
      return current
    else
      return false
    end
end

function get_stop(current, value)
    if check_marker(current, value .. '-stop') then
      return current
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
    data = ''
  else
    data = ''
  end

  return create.whatsit_colorstack(data)
end


function create.rule_colored(head, current, width)

  local color = {}

  color.line = create.color('line')
  color.reset = create.whatsit_colorstack()

  -- Append rule and kern to the node list.
  local rule = create.rule(width)

  head, new = node.insert_after(head, current, color.line)
  head, new = node.insert_after(head, new, rule)
  head, new = node.insert_after(head, new, color.reset)

  return head, new
end

---
--
function create.rule(width)
  -- Rule.
  local node = node.new(node.id('rule'))

  -- thickness = depth - height
  if not options.descender then
    options.descender = "3.4pt"
  end

  if not options.thickness then
    options.thickness = "0.4pt"
  end

  local height = tex.sp(options.thickness) - tex.sp(options.descender)

  node.depth = tex.sp(options.descender) -- 3.4pt
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

function create.write_whatsit(value)
  node.write(create.whatsit_userdefined(value))
end

function create.marker_start(value)
  create.write_whatsit(value .. '-start')
end

function create.marker_stop(value)
  create.write_whatsit(value .. '-stop')
end

local GLUE = node.id("glue")

function register(mode)
  if not is_registered[mode] then
    if mode == 'basic' then
      luatexbase.add_to_callback('post_linebreak_filter', process_basic, mode, 1)
    elseif mode == 'fix' then
      luatexbase.add_to_callback('pre_linebreak_filter', process_fix, mode, 1)
    elseif mode == 'end' then
      luatexbase.add_to_callback('post_linebreak_filter', process_end, mode, 1)
    else
      luatexbase.add_to_callback('post_linebreak_filter', process_par, mode, 1)
    end
    is_registered[mode] = true
  end
end

function unregister(mode)
  if mode == 'basic' then
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  elseif mode == 'fix' then
    luatexbase.remove_from_callback('pre_linebreak_filter', mode)
  elseif mode == 'end' then
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  else
    luatexbase.remove_from_callback('post_linebreak_filter', mode)
  end
end

---
--
---
function process_end(head)
  return head
end

---
--
---
function process_par(head)
  -- l = lenght
  local l = {}

  -- n = node
  local n = {}

  for line in node.traverse_id(node.id("hlist"), head) do

    l.width = line.width

    n.current = line.head
    n.rule = create.rule(l.width)
    line.head = n.rule
    n.rule.next = n.current

    node.insert_after(head,  n.rule, create.kern(-l.width))

  end

  return head
end

---
--
---
function process_fix(head)
  -- n = node
  local n = {}

  n.start, n.stop = false
  for current in node.traverse_id(node.id('whatsit'), head) do
    if not n.start then n.start = get_start(current, 'fix') end
    if not n.stop then n.stop = get_stop(current, 'fix') end

    if n.start and n.stop then
      make_clozefix(head, n.start, n.stop)
      n.start, n.stop = false
    end
  end

  return head
end

-- b whatsit begin marker
-- e whatsit end marker
-- t tmp
function make_clozefix(head, start, stop)
  -- l = length
  local l = {}
  l.width = tex.sp(options.width)

  -- n = node
  local n = {}
  -- loption = local option
  n.start = start
  n.stop = stop

  local loption = {}
  loption.align = normalize_align_options(options.align)

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
  head, n.line = create.rule_colored(head, n.start, l.width)

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

function normalize_align_options(option)
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

---
--
---
function process_basic(head)

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

      if check_marker(item, "basic-start") or INIT_CLOZE then
        node.insert_after(line.head, item, create.color('text'))

        INIT_CLOZE = false

        local end_node = item
        while end_node.next do

          LINE_END = true

          if check_marker(end_node.next, "basic-stop") then
            LINE_END = false
            break
          end

          end_node = end_node.next
        end

        local rule_width = node.dimensions(line.glue_set, line.glue_sign, line.glue_order, item, end_node.next)

        head, current = create.rule_colored(head, item, rule_width)

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
