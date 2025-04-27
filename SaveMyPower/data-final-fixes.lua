local function add_metadata(item)
  item.type = 'item-with-tags'
  data:extend{item}
  data.raw['item'][item.name] = nil
end

add_metadata(data.raw['item']['accumulator'])