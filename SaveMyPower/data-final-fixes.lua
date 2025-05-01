local bigpack = require("__big-data-string2__.pack")

local found_accumulators = ""
-- local found_batteries = ""


for _, thing in pairs(data.raw["accumulator"]) do
  if thing then
    local item = data.raw['item'][thing.name]
    local new_item = table.deepcopy(item)
    new_item.type = 'item-with-tags'
    data:extend{new_item}
    found_accumulators = found_accumulators .. item.name .. " "
    data.raw['item'][item.name] = nil
  end
end

-- for _, thing in pairs(data.raw["battery-equipment"]) do
--   if thing then
--     local item = data.raw['item'][thing.name]
--     local new_item = table.deepcopy(item)
--     new_item.type = 'item-with-tags'
--     data:extend{new_item}
--     found_batteries = found_batteries .. item.name .. " "
--     data.raw['item'][item.name] = nil
--   end
-- end

found_accumulators = found_accumulators:match("^%s*(.-)%s*$")
-- found_batteries = found_batteries:match("^%s*(.-)%s*$")

data:extend{bigpack("found-accumulators", found_accumulators)}
-- data:extend{bigpack("found-batteries", found_batteries)}

