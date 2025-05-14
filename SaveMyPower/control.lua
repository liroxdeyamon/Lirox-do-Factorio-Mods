local bigunpack = require("__big-data-string2__.unpack")

storage.player_power_preserve_enabled = storage.player_power_preserve_enabled or {}

local function split(str)
  local result = {}
  for word in str:gmatch("%S+") do
    table.insert(result, word)
  end
  return result
end

local function update_enabled_accumulators_filter()
  storage.enabled_accumulator_items_filter = {}

  local filter_mode_whitelist = settings.startup["accumulator-blacklist-as-whitelist"].value
  local listed = {}
  for _, name in ipairs(split(settings.startup["accumulator-blacklist"].value)) do
    listed[name] = true
  end

  for _, name in ipairs(split(bigunpack("found-accumulators"))) do
    if (filter_mode_whitelist and listed[name]) or (not filter_mode_whitelist and not listed[name]) then
      table.insert(storage.enabled_accumulator_items_filter, {filter = "name", name = name})
    end
  end
end


-- local function update_enabled_batteries_filter()
--   storage.enabled_battery_items_filter = {}

--   local blacklist = {}
--   for _, name in ipairs(split(settings.startup["battery-blacklist"].value)) do
--     blacklist[name] = true
--   end
--   for _, name in ipairs(split(bigunpack("found-batteries"))) do
--     if not blacklist[name] then
--       table.insert(storage.enabled_battery_items_filter, {filter = 'name', name = name})
--     end
--   end
-- end

local function get_max_accumulator_energy_entity(entity)
  return entity.electric_buffer_size
end

local function calculate_charge(energy, max_energy)
  return math.max(0, math.min(10, math.floor((energy / max_energy) * 10)))
end

local function set_itemstack_charge_tag(itemstack, charge)
  itemstack.set_tag("__charge__", {
    charge = charge
  })
end

local function update_itemstack_description(itemstack, charge)
  local description = {''}

  if settings.global["description-show-bar"].value then
    table.insert(description, {"",
    "[color=green][[/color][color=",
    settings.global["description-bar-filled-color"].value,
    "]",
    string.rep('█', charge),
    "[/color][color=",
    settings.global["description-bar-empty-color"].value,
    "]",
    string.rep('█', 10 - charge),
    "[/color][color=green]][/color]"})
  end
  if settings.global["description-show-percentage"].value then
    table.insert(description, {"",
    "[color=",
    settings.global["description-percentage-color"].value
    ,"] (",
    charge * 10,
    "%)[/color]"})
  end
  if settings.global["debug-show-item-info"].value then
    table.insert(description, {"",
    "\n",
    itemstack.name,
    "\n(To remove that description - uncheck Debug in settings then place it and collect back)"})
  end
  itemstack.custom_description = description
end

local function find_matching_itemstack(inventory, name)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read and stack.name == name then
      return stack
    end
  end
end

local function on_mined_accumulator_entity(event, itemstack)
  local minimum = settings.global["minimum-energy-to-retain-accumulator"].value
  if minimum == 0 then return end

  if not (itemstack and itemstack.is_item_with_tags) then return end

  local charge = calculate_charge(event.entity.energy, get_max_accumulator_energy_entity(event.entity))
  if charge < minimum then return end

  set_itemstack_charge_tag(itemstack, charge)
  update_itemstack_description(itemstack, charge)
end

local function on_built_entity(event, itemstack)
  if not (itemstack and itemstack.is_item_with_tags) then return end

  local tags = itemstack.get_tag("__accumulator-energy__") -- migration
  if tags then
    event.entity.energy = tags.energy_amount
    return
  end

  local tags = itemstack.get_tag("__charge__")
  if tags then
    event.entity.energy = tags.charge / 10 * get_max_accumulator_energy_entity(event.entity)
    return
  end
end

local function on_player_built_entity(event)
  on_built_entity(event, find_matching_itemstack(event.consumed_items, event.entity.name))
end

local function on_space_platform_built_entity(event)
  on_built_entity(event, event.stack)
end

local function on_robot_built_entity(event)
  on_built_entity(event, event.stack)
end


local function on_player_mined_entity(event)
  if settings.startup["research-required"].value and not storage.advanced_power_conservation then return end
  if not storage.player_power_preserve_enabled[event.player_index] then return end
  if not settings.global["retain-on-player-mined"].value then return end
  on_mined_accumulator_entity(event, find_matching_itemstack(event.buffer, event.entity.name))
end

local function on_robot_mined_entity(event)
  if settings.startup["research-required"].value and not storage.advanced_power_conservation then return end
  if not settings.global["retain-on-robot-mined"].value then return end
  on_mined_accumulator_entity(event, find_matching_itemstack(event.buffer, event.entity.name))
end

local function on_space_platform_mined_entity(event)
  if settings.startup["research-required"].value and not storage.advanced_power_conservation then return end
  if not settings.global["retain-on-space-platform-mined"].value then return end
  on_mined_accumulator_entity(event, find_matching_itemstack(event.buffer, event.entity.name))
end
local function register_events()
  script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity, storage.enabled_accumulator_items_filter)
  script.on_event(defines.events.on_robot_mined_entity, on_robot_mined_entity, storage.enabled_accumulator_items_filter)
  script.on_event(defines.events.on_space_platform_mined_entity, on_space_platform_mined_entity, storage.enabled_accumulator_items_filter)
  script.on_event(defines.events.on_built_entity, on_player_built_entity, storage.enabled_accumulator_items_filter)
  script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity, storage.enabled_accumulator_items_filter)
  script.on_event(defines.events.on_space_platform_built_entity, on_space_platform_built_entity, storage.enabled_accumulator_items_filter)
  -- script.on_event(defines.events.on_player_placed_equipment, on_player_placed_equipment)
  -- script.on_event(defines.events.on_player_removed_equipment, on_player_removed_equipment)
end

script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name ~= "advanced_power_conservation" then return end
  storage.advanced_power_conservation = true
  for _, player in pairs(game.players) do
    player.set_shortcut_available("SaveMyPower_enable", true)
    storage.player_power_preserve_enabled[player.index] = true
  end
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "SaveMyPower_enable" then
    local current = storage.player_power_preserve_enabled[event.player_index]
    storage.player_power_preserve_enabled[event.player_index] = not current
    game.get_player(event.player_index).set_shortcut_toggled("SaveMyPower_enable", not current)
  end
end)

script.on_init(function()
  local enabled = not settings.startup["research-required"].value or (storage.advanced_power_conservation or false)
  for _, player in pairs(game.players) do
    player.set_shortcut_available("SaveMyPower_enable", enabled)
    storage.player_power_preserve_enabled[player.index] = enabled
  end
end)


script.on_event(defines.events.on_player_created, function(event)
  local enabled = not settings.startup["research-required"].value or (storage.advanced_power_conservation or false)
  local player = game.get_player(event.player_index)
  player.set_shortcut_available("SaveMyPower_enable", enabled)
  storage.player_power_preserve_enabled[event.player_index] = enabled
end)



update_enabled_accumulators_filter()
-- update_enabled_batteries_filter()
register_events()

script.on_configuration_changed(function()
  update_enabled_accumulators_filter()
  -- update_enabled_batteries_filter()
  register_events()
end)