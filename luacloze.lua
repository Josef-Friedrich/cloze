create = require("create")

local GLUE = node.id("glue")

WHATSIT_USERID = 3121978

show_cloze_text = true

is_registered = {}

function cloze_register_callback(name, func, description)
  if not is_registered[description] then
    luatexbase.add_to_callback(name, func, description)
    is_registered[description] = true
  end
end

---
--
---
function process_clozeend(head)
  return head
end

---
--
---
function process_clozepar(head)

  for line in node.traverse_id(node.id("hlist"), head) do

    if line.subtype == 1 then
      local rule = create.rule(line.width)
      print(rule)
    end

    current = line.head

    node.insert_after(current, current, create.rule("20cm"))


    while current do
      -- print(current)
      if check_marker(current, 'clozepar-begin') then
        -- print('begin')
      end

      if check_marker(current, 'clozepar-end') then
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
function process_clozefixed(head)

  b, e = false
  for current in node.traverse_id(node.id('whatsit'), head) do
    if not b then b = get_begin(current, 'clozefixed') end
    if not e then e = get_end(current, 'clozefixed') end

    if b and e then
      make_clozefixed(head, b, e)
      b, e = false
    end
  end

  return head
end

-- b whatsit begin marker
-- e whatsit end marker
-- t tmp
function make_clozefixed(head,b,e)
  local t = {}
  t.text_width = node.dimensions(b,e)

  t.align = 'l'
  t.length = tex.sp("8cm")

  if t.align == 'r' then
    t.begin_kern = - t.text_width
    t.end_kern = 0
  elseif t.align == 'c' then
    t.half = (t.length - t.text_width) / 2
    t.begin_kern = - t.half - t.text_width
    t.end_kern = t.half
  else
    t.begin_kern = -t.length
    t.end_kern = t.length - t.text_width
  end

  -- W[b] W[linecolor] R[length] W[colorreset] K[begin_kern]
  --   cloze test K[end_kern] W[e]
  head, new = create.rule_colored(head,b,t.length)
  head, new = node.insert_after(head,new,create.kern(t.begin_kern))
  head, new = node.insert_before(head,e,create.kern(t.end_kern))
end

---
--
---
function process_cloze(head)

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

      if check_marker(item, "cloze-begin") or INIT_CLOZE then
        node.insert_after(line.head, item, create.color('text'))

        INIT_CLOZE = false

        local end_node = item
        while end_node.next do

          LINE_END = true

          if check_marker(end_node.next, "cloze-end") then
            LINE_END = false
            break
          end

          end_node = end_node.next
        end

        local rule_width = node.dimensions(line.glue_set, line.glue_sign, line.glue_order, item, end_node.next)

        head, current = create.rule_colored(head, item, rule_width)

        if show_cloze_text then
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

function get_begin(current, value)
    if check_marker(current, value .. '-begin') then
      return current
    else
      return false
    end
end

function get_end(current, value)
    if check_marker(current, value .. '-end') then
      return current
    else
      return false
    end
end