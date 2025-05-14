local bigpack = require("__big-data-string2__.pack")

local found_accumulators = ""
-- local found_batteries = ""


for _, thing in pairs(data.raw["accumulator"]) do
  if thing then
    local item = data.raw['item'][thing.name]
    if item then
      local new_item = table.deepcopy(item)
      new_item.type = 'item-with-tags'
      data:extend{new_item}
      found_accumulators = found_accumulators .. item.name .. " "
      data.raw['item'][item.name] = nil
    else
      log("item for accumulator '" .. thing.name .. "' not found (nil)")
    end
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

if settings.startup["research-required"].value then
  data:extend({
    {
      type = "technology",
      name = "advanced_power_conservation",
      icon = "__SaveMyPower__/thumbnail.png",
      icon_size = 256,
      prerequisites = {"electric-energy-accumulators"},
      localised_name = {
        "technology-name.advanced_power_conservation"
      },
      unit = {
        count = 250,
        ingredients = {
          {"automation-science-pack", 1},
          {"logistic-science-pack", 1}
        },
        time = 30
      },
    }
  })
end

data:extend({
  {
    type = "shortcut",
    name = "SaveMyPower_enable",
    toggleable = true,
    action = "lua",
    icons = {
      {
        icon = "__SaveMyPower__/thumbnail_small.png",
        icon_size = 128
      }
    },
    small_icons = {
      {
        icon = "__SaveMyPower__/thumbnail_smaller.png",
        icon_size = 64
      }
    }
  }
})

data:extend({
  {
    type = "custom-input",
    name = "SaveMyPower_toggle",
    key_sequence = "CTRL + I",
    action = "lua"
  }
})
