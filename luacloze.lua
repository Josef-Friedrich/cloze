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
process_clozeend = function(head)
  return head
end

---
--
---
process_clozepar = function(head)

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
process_clozefixed = function(head)

  B, E = false
  for current in node.traverse_id(node.id('whatsit'), head) do
    if not B then B = get_begin(current, 'clozefixed') end
    if not E then E = get_end(current, 'clozefixed') end

    if B and E then
      make_clozefixed(head, B, E)
      B, E = false
    end
  end

  return head
end

-- B whatsit begin marker
-- E whatsit end marker
function make_clozefixed(head, B, E)
  width = node.dimensions(B,E)
  head, new = create.rule_colored(head, B, width)
  head, new = node.insert_after(head, new, create.kern(-width))
end

---
--
---
process_cloze = function(head)

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