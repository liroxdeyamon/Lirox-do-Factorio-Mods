local accumulator_filter = {
  {filter = 'name', name = 'accumulator'}
}

local accumulator_max_energy = {
  accumulator = 5000000
}

local function calculate_charge(energy, max_energy)
  return math.max(0, math.min(10, math.floor((energy / max_energy) * 10)))
end

local function update_itemstack_tags(itemstack, charge, max_energy)
  itemstack.set_tag('__accumulator-energy__', {
    id = charge,
    energy_amount = charge / 10 * max_energy
  })
end

local function update_itemstack_description(itemstack, charge)
  itemstack.custom_description = {
    '',
    '[color=green][[/color][color=cyan]',
    string.rep('█', charge),
    '[/color][color=gray]',
    string.rep('█', 10 - charge),
    '[/color][color=green]][/color]'
  }
end

local function on_mined_entity(event)
  local minimum = settings.global["minimum-energy-to-retain"].value
  if minimum == 0 then return end

  local itemstack = event.buffer.find_item_stack(event.entity.name)
  if not (itemstack and itemstack.is_item_with_tags) then return end

  local energy = event.entity.energy
  if not energy then return end

  local max_energy = accumulator_max_energy[event.entity.name]
  if not max_energy then return end

  local charge = calculate_charge(energy, max_energy)
  if charge < minimum then return end

  update_itemstack_tags(itemstack, charge, max_energy)
  update_itemstack_description(itemstack, charge)
end

local function on_built_entity(event, itemstack)
  if not (itemstack and itemstack.is_item_with_tags) then return end

  local tags = itemstack.get_tag('__accumulator-energy__')
  if not tags then return end

  local entity = event.entity
  entity.energy = tags.energy_amount
end

local function on_player_built_entity(event)
  on_built_entity(event, event.consumed_items.find_item_stack(event.entity.name))
end

local function on_robot_built_entity(event)
  on_built_entity(event, event.stack)
end

script.on_event(defines.events.on_player_mined_entity, on_mined_entity, accumulator_filter)
script.on_event(defines.events.on_robot_mined_entity, on_mined_entity, accumulator_filter)
script.on_event(defines.events.on_built_entity, on_player_built_entity, accumulator_filter)
script.on_event(defines.events.on_robot_built_entity, on_robot_built_entity, accumulator_filter)
