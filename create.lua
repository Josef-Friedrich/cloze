local create = {}

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
  else
    data = options.textcolor
  end

  return create.whatsit_colorstack(data)
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

---
--
function create.whatsit_userdefined(value)
  local node = node.new('whatsit','user_defined')
  node.type = 115 -- string
  node.user_id = WHATSIT_USERID
  node.value = value

  return node
end

return create