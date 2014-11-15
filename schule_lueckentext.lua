local GLUE = node.id("glue")

WHATSIT_USERID = 3121978

show_cloze_text = true

---
--
function get_lines(head)

  for line in node.traverse_id(node.id("hlist"), head) do

    -- To make life easier: We add at the beginning of each line a blank
    -- user defined whatsit. Now we can add rule, color etc. nodes AFTER
    -- the first node of a line not BEFORE. AFTER is much more easier.
    current = line.head
    node.insert_before(current, current, whatsit_userdefined(99))
    line.head = current.prev

    if ZEILEN_ENDE then
      INIT_LUECKE = true
    end

    local item = line.head

    while item do

      if check_luecke_marker(item, 1) or INIT_LUECKE then

        colorstack_blue = color_text()
        node.insert_after(line.head, item, colorstack_blue)

        INIT_LUECKE = false

        local end_node = item
        while end_node.next do

          ZEILEN_ENDE = true

          if check_luecke_marker(end_node.next, 2) then
            ZEILEN_ENDE = false
            break
          end

          end_node = end_node.next
        end

        local rule_width = node.dimensions(line.glue_set, line.glue_sign, line.glue_order, item, end_node.next)
        local rule = node_rule(rule_width)
        -- Kern.
        local kern = node.new(node.id("kern"), 1)
        kern.kern = -rule_width

        -- Append rule and kern to the node list.
        colorstack_rule = color_rule()
        node.insert_after(head, item, colorstack_rule)
        node.insert_after(head, colorstack_rule, rule)
        colorstack_reset = node_colorstack()
        newitem, current = node.insert_after(head, rule, colorstack_reset)

        if show_cloze_text then
          node.insert_after(head, colorstack_reset, kern)
          colorstack_reset = node_colorstack()
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
function check_luecke_marker(item, value)
  if item.id == node.id('whatsit')
      and item.subtype == 44
      and item.user_id == WHATSIT_USERID
      and item.value == value then
    return true
  else
    return false
  end
end

---
--
function color_rule()

  local data

  if not farbelinie then
    -- black
    data = '0 0 0 rg 0 0 0 RG'

  else
    data = farbelinie
  end

  local node = node_colorstack(data)

  return node
end

---
--
function color_text()
  local data

  if not farbeluecke then
    -- black
    data = '0 0 1 rg 0 0 1 RG'

  else
    data = farbeluecke
  end

  local node = node_colorstack(data)

  return node
end

---
--
function node_rule(width)
  -- Rule.
  local node = node.new(node.id('rule'))

  -- tickness = depth - height

  if not unterlaenge then
    unterlaenge = "3.4pt"
  end

  if not dicke then
    dicke = "0.4pt"
  end

  hoehe = tex.sp(dicke) - tex.sp(unterlaenge)

  node.depth = tex.sp(unterlaenge) -- 3.4pt
  node.height = tex.sp(hoehe) -- -3pt
  node.width = width

  return node
end

-- Whatsit: colorstack
function node_colorstack(data)
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
function whatsit_userdefined(value)
  local node = node.new('whatsit','user_defined')
  node.type = 100
  node.user_id = WHATSIT_USERID
  node.value = value

  return node
end
