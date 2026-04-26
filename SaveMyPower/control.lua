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

local function is_name_blacklisted(name)
  local blacklist = settings.global["accumulator-blacklist"].value or ""
  log("Checking if " .. name .. " is blacklisted in " .. blacklist .. " with blacklist as whitelist: " .. tostring(settings.global["accumulator-blacklist-as-whitelist"].value))
  for entry in blacklist:gmatch("%S+") do
    log("Comparing against " .. entry .. ": " .. tostring(name == entry))
    if entry == name then return not settings.global["accumulator-blacklist-as-whitelist"].value end
  end
  log("No match found for " .. name .. " in blacklist, returning " .. tostring(settings.global["accumulator-blacklist-as-whitelist"].value))
  return settings.global["accumulator-blacklist-as-whitelist"].value
end

local function get_accumulator_max_energy(entity)
  return entity.electric_buffer_size
end

local function calculate_charge(energy, max_energy)
  return math.max(0, math.min(100, math.floor((energy / max_energy) * 100)))
end

local function fetch_in_inventory(inventory, name)
  for i = 1, #inventory do
    local stack = inventory[i]
    if stack.valid_for_read and stack.name == name then
      return stack
    end
  end
  log("No itemstack found for " .. name .. " in inventory, contact mod author")
end


-- ItemStack modifications
local function set_itemstack_energy_tag(itemstack, energy, prototype, capacity)
  itemstack.set_tag("__accumulator-energy__", { energy_amount = energy, prototype = prototype, capacity = capacity })
end

local function update_itemstack_description(itemstack, charge, energy, prototype, capacity)
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
  local filled_len = math.floor(charge / 100 * length)

  if settings.global["description-show-bar"].value then
    table.insert(description, {"",
    "[color=", settings.global["description-bar-decorator-color"].value, "]", first,
    "[/color][color=", settings.global["description-bar-filled-color"].value, "]",
    bar:sub(1, filled_len),
    "[/color][color=", settings.global["description-bar-empty-color"].value, "]",
    bar:sub(filled_len + 1),
    "[/color][color=", settings.global["description-bar-decorator-color"].value, "]", last, "[/color]"})
  end
  if settings.global["description-show-percentage"].value then
    table.insert(description, {"",
    "[color=", settings.global["description-percentage-color"].value, "] (", charge, "%)[/color]"})
  end
  if settings.global["debug"].value then
    table.insert(description, {"",
    "\nNAME: ", itemstack.name, ", ENERGY: ", energy , "/", capacity, ", CHARGE: ", charge, ", PROTOTYPE: ", prototype,
    "\n(To remove that description - uncheck Debug in mod settings then place it and collect back OR run /smp_update_descriptions)"})
  end
  itemstack.custom_description = description
end


-- Mining events
local function on_mined_accumulator_entity(event, itemstack)
  if settings.global["debug"] then log("Mined " .. event.entity.name) end

  if settings.startup["research-required"].value and not storage.advanced_power_conservation then return end
  if is_name_blacklisted(get_actual_itemname(itemstack.name)) then return end

  local minimum = settings.global["minimum-energy-retain-accumulator"].value

  if minimum == 0 then return end
  if not (itemstack and itemstack.is_item_with_tags) then return end

  local capacity = get_accumulator_max_energy(event.entity)
  local jumps = settings.global["energy-stack-jumps"].value
  local saved_energy = event.entity.energy
  if jumps > 0 then saved_energy = math.min(capacity, math.floor(event.entity.energy / capacity * jumps) / jumps * capacity) end
  local charge = calculate_charge(saved_energy, capacity)
  if charge < minimum then return end

  set_itemstack_energy_tag(itemstack, saved_energy, event.entity.prototype.name, capacity)
  update_itemstack_description(itemstack, charge, saved_energy, event.entity.prototype.name, capacity)
end

local function on_player_mined_entity(event)
  if not storage.player_power_preserve_enabled[event.player_index] then return end
  if not settings.global["retain-on-player-mined"].value then return end
  on_mined_accumulator_entity(event, fetch_in_inventory(event.buffer, get_actual_itemname(event.entity.name)))
end

local function on_robot_mined_entity(event)
  if not settings.global["retain-on-robot-mined"].value then return end
  on_mined_accumulator_entity(event, fetch_in_inventory(event.buffer, event.entity.name))
end

local function on_space_platform_mined_entity(event)
  if not settings.global["retain-on-space-platform-mined"].value then return end
  on_mined_accumulator_entity(event, fetch_in_inventory(event.buffer, event.entity.name))
end

-- Building events
local function on_built_entity(event, itemstack)
  if settings.global["debug"] then log("Built " .. event.entity.name) end
  if not (itemstack and itemstack.is_item_with_tags) then return end
  if is_name_blacklisted(get_actual_itemname(itemstack.name)) then return end

  local tags = itemstack.get_tag("__accumulator-energy__")
  if tags then
    local prot = prototypes.entity[tags.prototype] or nil
    if prot then
        -- By RedRafe, from mod Solar Productivity, thanks for allowing me to use it!
        local old = event.entity

        local new = old.surface.create_entity({
          name = tags.prototype,
          position = old.position,
          force = old.force,
          player = old.last_user,
          quality = old.quality,
          create_build_effect_smoke = false,
          raise_built = true,
        })

        if not (new and new.valid) then
          return
        end

        transfer_properties(old, new)
        old.destroy()
        event.entity = new
      end
      event.entity.energy = tags.energy_amount
    return
  end

  local tags = itemstack.get_tag("__charge__") -- migraton
  if tags then
    event.entity.energy = tags.charge / 10 * get_accumulator_max_energy(event.entity)
    return
  end
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

-- Commands
commands.add_command(
  "smp_update_descriptions",
  "Updates descriptions of all charged accumulators in your inventory.",
  function(event)
    local player = game.players[event.player_index]
    if not player then return end

    local count = 0
    local inventory = player.get_main_inventory()
    for i = 1, #inventory do
      local stack = inventory[i]
      if stack.valid_for_read and stack.is_item_with_tags then
        local tags = stack.get_tag("__accumulator-energy__")
        if tags and tags.capacity then
          update_itemstack_description(stack, calculate_charge(tags.energy_amount, tags.capacity), tags.energy_amount, tags.prototype)
          count = count + 1
        end
      end
    end

    player.print(count .. " accumulator item(s) updated.")
  end
)


-- Registering events 
log("Registering events")
script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity, {{ filter = 'type', type = 'accumulator' }})
script.on_event(defines.events.on_robot_mined_entity, on_robot_mined_entity, {{ filter = 'type', type = 'accumulator' }})
script.on_event(defines.events.on_space_platform_mined_entity, on_space_platform_mined_entity, {{ filter = 'type', type = 'accumulator' }})
script.on_event(defines.events.on_built_entity, on_player_built_entity, {{ filter = 'type', type = 'accumulator' }})
script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity, {{ filter = 'type', type = 'accumulator' }})
script.on_event(defines.events.on_space_platform_built_entity, on_space_platform_built_entity, {{ filter = 'type', type = 'accumulator' }})

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