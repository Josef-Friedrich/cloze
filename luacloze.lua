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

process = {}

process.clozeend = function(head)
  return head
end

process.clozepar = function(head)
  return head
end

process_clozefixed = function(head)
  return head
end

---
--
process_cloze = function(head)

  for line in node.traverse_id(node.id("hlist"), head) do

    -- To make life easier: We add at the beginning of each line a blank
    -- user defined whatsit. Now we can add rule, color etc. nodes AFTER
    -- the first node of a line not BEFORE. AFTER is much more easier.
    current = line.head
    node.insert_before(current, current, create.whatsit_userdefined(99))
    line.head = current.prev

    if LINE_END then
      INIT_CLOZE = true
    end

    local item = line.head

    while item do

      if check_cloze_marker(item, "begin-cloze") or INIT_CLOZE then

        colorstack_blue = create.color('text')
        node.insert_after(line.head, item, colorstack_blue)

        INIT_CLOZE = false

        local end_node = item
        while end_node.next do

          LINE_END = true

          if check_cloze_marker(end_node.next, "end-cloze") then
            LINE_END = false
            break
          end

          end_node = end_node.next
        end

        local rule_width = node.dimensions(line.glue_set, line.glue_sign, line.glue_order, item, end_node.next)
        local rule = create.rule(rule_width)

        -- Append rule and kern to the node list.
        colorstack_rule = create.color('line')
        node.insert_after(head, item, colorstack_rule)
        node.insert_after(head, colorstack_rule, rule)
        colorstack_reset = create.whatsit_colorstack()
        newitem, current = node.insert_after(head, rule, colorstack_reset)

        if show_cloze_text then
          node.insert_after(head, colorstack_reset, create.kern(-rule_width))
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
function check_cloze_marker(item, value)
  if item.id == node.id('whatsit')
      and item.subtype == 44
      and item.user_id == WHATSIT_USERID
      and item.value == value then
    return true
  else
    return false
  end
end
