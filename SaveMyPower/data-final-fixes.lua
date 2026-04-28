local function convert_category_to_items_with_tags(category, options)
  options = options or {}
  log("Modifying " .. category .. " to item-with-tags")
  for _, thing in pairs(data.raw[category] or {}) do
    if thing then
      local name = thing.name
      local item = data.raw["item"] and data.raw["item"][name]
      if item then
        local new_item = table.deepcopy(item)
        new_item.type = "item-with-tags"
        data:extend{new_item}
        data.raw["item"][name] = nil
        log("Modified " .. name)
      elseif options.skip_pattern and name:match(options.skip_pattern) then
        log(options.skip_message:format(name))
      else
        log("Missing item for " .. name .. ", please contact mod author")
      end
    end
  end
end

convert_category_to_items_with_tags("accumulator", {
  skip_pattern = "^sp%-%d+%-(.+)$",
  skip_message = "Skipping %s as its from Solar Productivity and has no custom item"
})
convert_category_to_items_with_tags("roboport")
convert_category_to_items_with_tags("battery-equipment")
convert_category_to_items_with_tags("energy-shield-equipment")
convert_category_to_items_with_tags("personal-roboport-equipment")


log("Registering research")
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

log("Registering shortcut")
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

log("Registering custom input")
data:extend({
  {
    type = "custom-input",
    name = "SaveMyPower_toggle",
    key_sequence = "CONTROL + I",
    action = "lua"
  }
})
