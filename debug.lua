---@type PreLinebreakFilterCallback
local function visit_nodes(n, group)

  while n do
    -- if n.id == node.id('kern') then
    --   ---@cast n KernNode
    --   print(n.kern)
    --   n.kern = tex.sp('2cm')
    -- end

    if n.id == node.id('glyph') then
      ---@type KernNode
      local kern = node.new('kern') --[[@as KernNode]]
      kern.kern = tex.sp('2pt')
      local next = n.next
      n.next = kern
      kern.next = next
    end

    if n.id == node.id('glue') and n.subtype == 13 then
      ---@cast n GlueNode
      n.width = tex.sp('1cm')

    end

    n = n.next
  end
  for i, v in ipairs(node.fields(node.id('glue'))) do
    print(v)
  end

  return true

end

luatexbase.add_to_callback('pre_linebreak_filter', visit_nodes,
  'visit nodes')
