
local inspect = require('inspect')
local cloze = require('cloze')
local key_value_parser = cloze.key_value_parser

local function test(description, input)
  print()
  print(description)
  print('Input:', input)
  print(inspect(key_value_parser(input)))
  print()
end

test('dimension', 'margin=2pt')

test('', 'hide,margin=2pt,textcolor =red,linecolor=green, show,')
test('', 'one=true,two=TRUE,three = false, four=FALSE,five')
test('', 'one=no,two=NO,three = yes, four=YES,five')
test('Multiline', [[
  hide,
  margin=2pt,
  textcolor =red
]])


test('minlines -> minimum lines', 'minlines=3')
