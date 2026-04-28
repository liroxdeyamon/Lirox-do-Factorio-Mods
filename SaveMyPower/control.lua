storage.player_power_preserve_enabled = storage.player_power_preserve_enabled or {}

-- By RedRafe, from mod Solar Productivity, thanks for allowing me to use it!
local function transfer_properties(old, new)
  if old.energy then
    new.energy = old.energy
  end

  local damage = old.prototype.get_max_health(old.quality) - old.health
  if damage > 0 then
    new.damage(damage, game.forces.neutral)
  end

  for wire_id, connector in pairs(old.get_wire_connectors(false)) do
    local link = new.get_wire_connector(wire_id, true)
    for _, v in pairs(connector.connections) do
      link.connect_to(v.target, false, v.origin)
    end
  end

  local old_cb = old.get_control_behavior()
  if old_cb and old_cb.valid then
    local new_cb = new.get_or_create_control_behavior()
    new_cb.read_charge = old_cb.read_charge
    new_cb.output_signal = old_cb.output_signal
  end
end

-- gives actual item name cuz solar prod use default item but have custom itemname
-- if itemname has sp-*- then return anything past it, else return itemname
local function get_actual_itemname(itemname)
  return itemname:match("^sp%-%d+%-(.+)$") or itemname
end

local function is_blacklisted(name, blacklist_key, whitelist_key)
  local blacklist = settings.global[blacklist_key].value or ""
  local whitelist = whitelist_key and settings.global[whitelist_key].value or false
  for entry in blacklist:gmatch("%S+") do
    if entry == name then return not whitelist end
  end
  return whitelist
end

local function get_color(setting_name)
  local c = settings.global[setting_name].value
  return "[color="..c.r..","..c.g..","..c.b..","..(c.a or 1).."]"
end

local function is_entity_blacklisted(name)
  return is_blacklisted(name, "entity-blacklist", "entity-blacklist-as-whitelist") or is_blacklisted(name, "default-blacklist")
end

local function is_equipment_blacklisted(name)
  return is_blacklisted(name, "equipment-blacklist", "equipment-blacklist-as-whitelist") or is_blacklisted(name, "default-blacklist")
end

local function is_entity(name)
  return prototypes.entity[name] ~= nil
end

local function is_equipment(name)
  return prototypes.equipment[name] ~= nil
end

local function get_max_energy(instance)
  return instance.electric_buffer_size or instance.max_energy or instance.max_shield or (instance.is_item_with_tags and instance.get_tag("__energy__") and instance.get_tag("__energy__").capacity) or nil
end

local function get_energy(instance)
  return instance.energy or instance.shield or (instance.is_item_with_tags and instance.get_tag("__energy__") and instance.get_tag("__energy__").saved) or nil
end

local function set_energy(instance, energy)
  if is_entity(instance.name) then
    instance.energy = energy
  elseif is_equipment(instance.name) then
    if instance.max_shield > 0 then instance.shield = energy
    else instance.energy = energy end
  end
end

local function get_prototype(name)
  return prototypes.entity[name] or prototypes.equipment[name] or nil
end

local function validate_prototype(name)
  return prototypes.entity[name] ~= nil or prototypes.equipment[name] ~= nil or false
end

local function set_energy_tag(itemstack, saved, capacity, prototype)
  itemstack.set_tag("__energy__", { saved = saved, capacity = capacity, prototype = prototype })
end

local function get_energy_tag(itemstack)
  return itemstack.is_item_with_tags and itemstack.get_tag("__energy__")
end

local function apply_energy_tag(instance, tags)
  if not instance or not tags then return end
  if is_entity(instance.name) then
    if instance.name ~= tags.prototype and prototypes.entity[tags.prototype] then
      -- By RedRafe, from mod Solar Productivity, thanks for allowing me to use it!
      local old = instance

      local new = old.surface.create_entity({
        name = tags.prototype,
        position = old.position,
        force = old.force,
        player = old.last_user,
        quality = old.quality,
        create_build_effect_smoke = false,
        raise_built = true,
      })

      if not (new and new.valid) then return end

      transfer_properties(old, new)
      old.destroy()
      instance = new
    end
    instance.energy = tags.saved
  elseif is_equipment(instance.name) then
    if instance.max_shield > 0 then instance.shield = tags.saved
    else instance.energy = tags.saved end
  end
end

local function calculate_charge(energy, max_energy)
  local ratio = math.min(1.0, energy / max_energy)
  local jumps = settings.global["energy-stacking"].value
  if jumps > 0 then
    energy = math.min(max_energy, math.floor(ratio * jumps + 0.5) / jumps * max_energy)
    ratio = energy / max_energy
  end
  return math.max(0, math.min(100, math.floor(ratio * 100 + 0.5))), energy
end

local function fetch_in_inventory(inventory, name, cursor, min_count, quality, exclude_index)
  min_count = min_count or 1
  if cursor and cursor.valid_for_read and cursor.name == name
    and cursor.count >= min_count
    and (not quality or cursor.quality.name == quality) then
    return cursor, nil
  end
  for i = 1, #inventory do
    if i == exclude_index then goto continue end
    local stack = inventory[i]
    if stack.valid_for_read and stack.name == name
      and stack.count >= min_count
      and (not quality or stack.quality.name == quality) then
      return stack, i
    end
    ::continue::
  end
  log("No itemstack found for " .. name .. " in inventory, contact mod author")
end

local function migrate_itemstack(itemstack)
  if not (itemstack and itemstack.is_item_with_tags) then return end

  local charge_tags = itemstack.get_tag("__charge__")
  local accumulator_energy_tags = itemstack.get_tag("__accumulator-energy__")
  if charge_tags and charge_tags.charge then
    local capacity = nil
    if is_entity(itemstack.name) then 
      capacity = get_prototype(itemstack.name).electric_energy_source_prototype.buffer_capacity
    else
      capacity = get_max_energy(itemstack)
    end
    set_energy_tag(itemstack, charge_tags.charge / 10 * capacity, capacity, itemstack.name)
    itemstack.set_tag("__charge__", nil)
    return true
  elseif accumulator_energy_tags and accumulator_energy_tags.energy_amount then
    local capacity = nil
    if is_entity(itemstack.name) then 
      capacity = get_prototype(itemstack.name).electric_energy_source_prototype.buffer_capacity
    else
      capacity = get_max_energy(itemstack)
    end
    set_energy_tag(itemstack, accumulator_energy_tags.energy_amount, accumulator_energy_tags.capacity or capacity, itemstack.name)
    itemstack.set_tag("__accumulator-energy__", nil)
    return true
  end
end

local function update_itemstack_description(itemstack, tags)
  if not (itemstack and tags) then return false end
  local description = {''}
  local bar_str = settings.global["description-string"].value
  local first, rest, last = bar_str:match("^(.)(.+)(.)$")
  if #bar_str <= 2 then
    first = ""
    rest = bar_str
    last = ""
  end
  local length = settings.global["description-bar-length"].value
  local bar = string.rep(rest, length):sub(1, length)
  local charge = calculate_charge(tags.saved, tags.capacity)
  local filled_len = math.floor(charge / 100 * length)

  if settings.global["description-show-bar"].value then
    table.insert(description, {"",
    get_color("description-bar-decorator-color"), first, "[/color]",
    get_color("description-bar-filled-color"), bar:sub(1, filled_len), "[/color]",
    get_color("description-bar-empty-color"), bar:sub(filled_len + 1), "[/color]",
    get_color("description-bar-decorator-color"), last, "[/color]"})
  end
  if settings.global["description-show-percentage"].value then
    table.insert(description, {"",
    get_color("description-percentage-color"), " (", charge, "%)[/color]"})
  end
  if settings.global["debug"].value then
    table.insert(description, {"",
    "\nNAME: ", itemstack.name, ", ENERGY: ", tags.saved , "/", tags.capacity, ", CHARGE: ", charge, ", PROTOTYPE: ", tags.prototype,
    "\n(To remove that description - uncheck Debug in mod settings then place it and collect back OR run /smp_update_descriptions)"})
  end
  if is_equipment(itemstack.name) then
    table.insert(description, {"",
    "\nPLEASE do not shift+click or ctrl+click this to equip, only use your cursor!",
    "\nBecause of factorio limitations i can't get actual used itemstack, so if you dare to equip it not via cursor - it wont regain energy!",
    "\nAlso, while retaining energy works in any armor, actually SAVING energy works only on currently equipped armor.",
    "\nAnd lastly, clicking on charged equipment with uncharged one will discarge clicked equipment!"})
  end
  itemstack.custom_description = description
  return true
end


-- Mining events
local function on_mined_entity(event, itemstack)
  if settings.global["debug"] then log("Mined " .. event.entity.name) end

  if settings.startup["research-required"].value and not storage.advanced_power_conservation then return end
  if is_entity_blacklisted(get_actual_itemname(itemstack.name)) then return end
  if not (itemstack and itemstack.is_item_with_tags) then return end

  local minimum = settings.global["minimum-energy-to-retain"].value
  if minimum == 0 then return end

  local capacity = get_max_energy(event.entity)
  local charge, saved_energy = calculate_charge(event.entity.energy, capacity)
  if charge < minimum then return end

  set_energy_tag(itemstack, saved_energy, capacity, event.entity.prototype.name)
  update_itemstack_description(itemstack, get_energy_tag(itemstack))
end

local function on_player_mined_entity(event)
  if not storage.player_power_preserve_enabled[event.player_index] then return end
  if not settings.global["retain-on-player-mined"].value then return end
  on_mined_entity(event, fetch_in_inventory(event.buffer, get_actual_itemname(event.entity.name)))
end

local function on_space_platform_mined_entity(event)
  if not settings.global["retain-on-player-mined"].value then return end
  on_mined_entity(event, fetch_in_inventory(event.buffer, event.entity.name))
end

local function on_robot_mined_entity(event)
  if not settings.global["retain-on-robot-mined"].value then return end
  on_mined_entity(event, fetch_in_inventory(event.buffer, event.entity.name))
end


-- Building events
local function on_built_entity(event, itemstack)
  if settings.global["debug"] then log("Built " .. event.entity.name) end
  if not (itemstack and itemstack.is_item_with_tags) then return end
  if is_entity_blacklisted(get_actual_itemname(itemstack.name)) then return end

  apply_energy_tag(event.entity, get_energy_tag(itemstack))
end

local function on_player_built_entity(event)
  on_built_entity(event, fetch_in_inventory(event.consumed_items, event.entity.name))
end

local function on_space_platform_built_entity(event)
  on_built_entity(event, event.stack)
end

local function on_robot_built_entity(event)
  on_built_entity(event, event.stack)
end


-- Equipment
-- omg this is SO LIMITED ISTG
local function on_player_placed_equipment(event)
  if not storage.player_power_preserve_enabled[event.player_index] then return end
  if is_equipment_blacklisted(event.equipment.name) then return end

  local tick = storage.playerdata and storage.playerdata[event.player_index]
  if not (tick and tick.cursor and tick.cursor.tags and tick.cursor.name == event.equipment.name) then return end
  
  set_energy(event.equipment, tick.cursor.tags.saved)
end

-- yoo im so proud of this
-- on tick save previous grid energy for each player
-- calculate how much energy is removed
-- divide it by count of batteries removed
-- get battery itemstack in the inventory
-- divide it if the count is more than removed count
-- set the tag
local function on_player_removed_equipment(event)
  if settings.global["debug"] then log("Removed " .. event.equipment) end
  if not settings.global["retain-equipment-energy"].value then return end
  if not storage.player_power_preserve_enabled[event.player_index] then return end
  if not is_equipment(event.equipment) then return end
  if is_equipment_blacklisted(event.equipment) then return end

  local per_equipment_energy = (storage.playerdata[event.player_index].energy - event.grid.available_in_batteries) / event.count
  local per_equipment_max_energy = (storage.playerdata[event.player_index].max_energy - event.grid.battery_capacity) / event.count
  local per_equipment_shield = (storage.playerdata[event.player_index].shield - event.grid.shield) / event.count
  local per_equipment_max_shield = (storage.playerdata[event.player_index].max_shield - event.grid.max_shield) / event.count

  local player = game.players[event.player_index]
  if not player then return end

  local inventory = player.get_main_inventory()
  if not inventory then return end

  local quality = event.quality and event.quality.name
  local itemstack, original_index = fetch_in_inventory(inventory, event.equipment, player.cursor_stack, event.count, quality)
  if not itemstack then return end

  if itemstack.count > event.count then
    if not original_index then return end
    itemstack.count = itemstack.count - event.count
    inventory.insert({ name = event.equipment, count = event.count, quality = event.quality })
    itemstack = fetch_in_inventory(inventory, event.equipment, nil, event.count, quality, original_index)
    if not itemstack then return end
  end
  if not itemstack.is_item_with_tags then return end

  local minimum = settings.global["minimum-energy-to-retain"].value
  local charge, saved = calculate_charge(per_equipment_energy, per_equipment_max_energy)
  local energy, max_energy = per_equipment_energy, per_equipment_max_energy
  if get_prototype(itemstack.name).energy_per_shield then
    charge, saved = calculate_charge(per_equipment_shield, per_equipment_max_shield)
    energy, max_energy = per_equipment_shield, per_equipment_max_shield
  end
  
  if charge < minimum then return end
  set_energy_tag(itemstack, saved, max_energy, event.equipment)
  update_itemstack_description(itemstack, get_energy_tag(itemstack))
end


-- Commands
commands.add_command(
  "smp_update_descriptions",
  "Updates descriptions of all charged items in your inventory.",
  function(event)
    local player = game.players[event.player_index]
    if not player then return end

    local count = 0
    local inventory = player.get_main_inventory()
    for i = 1, #inventory do
      if update_itemstack_description(inventory[i], get_energy_tag(inventory[i])) then
        count = count + 1
      end
    end

    player.print(count .. " item(s) updated.")
  end
)

commands.add_command(
  "smp_migrate_items",
  "Migrates all pre v0.3.0 charged items in your inventory to new working format.",
  function(event)
    local player = game.players[event.player_index]
    if not player then return end

    local count = 0
    local inventory = player.get_main_inventory()
    for i = 1, #inventory do
      if migrate_itemstack(inventory[i]) then count = count + 1 end
    end

    player.print(count .. " item(s) migrated.")
  end
)


-- Registering events 
log("Registering events")
script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity, {{ filter = 'type', type = 'accumulator' }, { mode = 'or', filter = 'type', type = 'roboport' }})
script.on_event(defines.events.on_robot_mined_entity, on_robot_mined_entity, {{ filter = 'type', type = 'accumulator' }, { mode = 'or', filter = 'type', type = 'roboport' }})
script.on_event(defines.events.on_space_platform_mined_entity, on_space_platform_mined_entity, {{ filter = 'type', type = 'accumulator' }, { mode = 'or', filter = 'type', type = 'roboport' }})
script.on_event(defines.events.on_built_entity, on_player_built_entity, {{ filter = 'type', type = 'accumulator' }, { mode = 'or', filter = 'type', type = 'roboport' }})
script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity, {{ filter = 'type', type = 'accumulator' }, { mode = 'or', filter = 'type', type = 'roboport' }})
script.on_event(defines.events.on_space_platform_built_entity, on_space_platform_built_entity, {{ filter = 'type', type = 'accumulator' }})
script.on_event(defines.events.on_player_placed_equipment, on_player_placed_equipment)
script.on_event(defines.events.on_player_removed_equipment, on_player_removed_equipment)

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

script.on_event(defines.events.on_player_created, function(event)
  local enabled = not settings.startup["research-required"].value or (storage.advanced_power_conservation or false)
  local player = game.get_player(event.player_index) 
  player.set_shortcut_available("SaveMyPower_enable", enabled)
  storage.player_power_preserve_enabled[event.player_index] = enabled
end)

script.on_init(function()
  local enabled = not settings.startup["research-required"].value or (storage.advanced_power_conservation or false)
  for _, player in pairs(game.players) do
    player.set_shortcut_available("SaveMyPower_enable", enabled)
    storage.player_power_preserve_enabled[player.index] = enabled
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local available = not settings.startup["research-required"].value or (storage.advanced_power_conservation or false)
  local player = game.get_player(event.player_index)
  player.set_shortcut_available("SaveMyPower_enable", available)
  local state = storage.player_power_preserve_enabled[event.player_index]
  if state == nil then
    state = available
    storage.player_power_preserve_enabled[event.player_index] = state
  end
  player.set_shortcut_toggled("SaveMyPower_enable", state)
end)

script.on_event(defines.events.on_tick, function()
  local result = {}

  for _, player in pairs(game.players) do
    local grid = player.character and player.character.grid
    if not (grid and grid.valid) then goto continue end

    local cursor = player.cursor_stack
    local cursor_snapshot = nil
    if cursor and cursor.valid_for_read and cursor.is_item_with_tags then
      cursor_snapshot = {
        name = cursor.name,
        tags = get_energy_tag(cursor)
      }
    end

    result[player.index] = {
      energy = grid.available_in_batteries,
      max_energy = grid.battery_capacity,
      shield = grid.shield,
      max_shield = grid.max_shield,
      cursor = cursor_snapshot
    }

    ::continue::
  end

  storage.playerdata = result
end)