---@type PreLinebreakFilterCallback
local function visit_nodes(head, group)
  while head do
    print(head)
    head = head.next
  end
  return true
end

luatexbase.add_to_callback('pre_linebreak_filter', visit_nodes, 'visit nodes')
