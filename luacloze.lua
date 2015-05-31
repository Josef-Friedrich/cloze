create = require("create")

options = {}

local GLUE = node.id("glue")

WHATSIT_USERID = 3121978

options.show_text = true

is_registered = {}

function register(mode)
  if not is_registered[mode] then
    if mode == 'basic' then
      luatexbase.add_to_callback('post_linebreak_filter', process_basic, mode)
    elseif mode == 'fix' then
      luatexbase.add_to_callback('pre_linebreak_filter', process_fix, mode)
    elseif mode == 'end' then
      luatexbase.add_to_callback('post_linebreak_filter', process_end, mode)
    else
      luatexbase.add_to_callback('post_linebreak_filter', process_par, mode)
    end
    is_registered[mode] = true
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

  for line in node.traverse_id(node.id("hlist"), head) do

    if line.subtype == 1 then
      local rule = create.rule(line.width)
      print(rule)
    end

    current = line.head

    node.insert_after(current, current, create.rule("20cm"))


    while current do
      -- print(current)
      if check_marker(current, 'clozepar-start') then
        -- print('begin')
      end

      if check_marker(current, 'clozepar-stop') then
        -- print('end')
      end
      current = current.next
    end

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
    if not n.start then n.start = get_start(current, 'clozefix') end
    if not n.stop then n.stop = get_stop(current, 'clozefix') end

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
  l.length = tex.sp("8cm")

  -- n = node
  local n = {}
  -- loption = local option
  n.start = start
  n.stop = stop

  local loption = {}
  loption.align = 'l'

  l.text_width = node.dimensions(n.start, n.stop)

  if loption.align == 'r' then
    l.kern_start = -l.text_width
    l.kern_stop = 0
  elseif loption.align == 'c' then
    l.half = (l.length - l.text_width) / 2
    l.kern_start = -l.half - l.text_width
    l.kern_stop = l.half
  else
    l.kern_start = -l.length
    l.kern_stop = l.length - l.text_width
  end

  -- W[n.start] R[n.line] K[n.kern_start] W[textcolor]
  --   cloze test W[colorreset] K[n.kern_stop] W[n.end]

  -- Insert colored rule ()
  head, n.line = create.rule_colored(head, n.start, l.length)

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

      if check_marker(item, "cloze-start") or INIT_CLOZE then
        node.insert_after(line.head, item, create.color('text'))

        INIT_CLOZE = false

        local end_node = item
        while end_node.next do

          LINE_END = true

          if check_marker(end_node.next, "cloze-stop") then
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

---
--
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