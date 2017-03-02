-- This file registers the standard torch to the mod.

local ModName = minetest.get_current_modname()
local mod = _G[ModName]

local my_fuel_capacity = (60*60*24*4)
local my_fuel_persecond = 1
local my_fuel_coallump = my_fuel_capacity
local my_fuel_lowthreshold = my_fuel_coallump / 4

-- Different Versions
local nodes_floor = {
	[0] = ModName..":torch_off",
	[1] = "default:torch",
	[2] = ModName..":torch_lowfuel",
}
local nodes_wall = {
	[0] = ModName..":torch_wall_off",
	[1] = "default:torch_wall",
	[2] = ModName..":torch_wall_lowfuel",
}
local nodes_ceiling = {
	[0] = ModName..":torch_ceiling_off",
	[1] = "default:torch_ceiling",
	[2] = ModName..":torch_ceiling_lowfuel",
}

-- Remember old stuff
local Defs_Old = {
	torch = ItemStack("default:torch"):get_definition(),
	torch_wall = ItemStack("default:torch_wall"):get_definition(),
	torch_ceiling = ItemStack("default:torch_ceiling"):get_definition()
}

-- Events
local on_rightclick, torch_after_place_node
function on_rightclick(pos, node, player, itemstack, pointed_thing)
	-- Attempt taking coal piece
	if itemstack:get_name() == "default:coal_lump" then
		local PeekPiece = itemstack:peek_item(1)
		if PeekPiece:get_count() == 1 then
			local Accepted = false
			mod.UpdateFuel(pos, node, function(pos, node, fuel, meta)
				Accepted = (fuel <= my_fuel_capacity - (my_fuel_coallump / 4))
				return fuel + (Accepted and my_fuel_coallump or 0)
			end, true)
			if Accepted then
				itemstack:take_item(1)
				return itemstack
			end
		end
	end
end
function torch_after_place_node(pos, placer, itemstack, pointed_thing)
	--mod.SetFuel(pos, nil, ((my_fuel_coallump / 4) * 1.1), false)
end

-- Define stuff
local Defs_New = {
	torch_off = mod.Table_Copy(Defs_Old.torch),
	torch_wall_off = mod.Table_Copy(Defs_Old.torch_wall),
	torch_ceiling_off = mod.Table_Copy(Defs_Old.torch_ceiling),
	torch_lowfuel = mod.Table_Copy(Defs_Old.torch),
	torch_wall_lowfuel = mod.Table_Copy(Defs_Old.torch_wall),
	torch_ceiling_lowfuel = mod.Table_Copy(Defs_Old.torch_ceiling)
}

-- Burnt-out types
Defs_New.torch_off.light_source = nil
Defs_New.torch_off.description = "Dead Torch"
Defs_New.torch_off.inventory_image = "justin_burning_out_torches_torch_off_floor.png"
Defs_New.torch_off.wield_image = "justin_burning_out_torches_torch_off_floor.png"
Defs_New.torch_off.tiles = {{name = "justin_burning_out_torches_torch_off_floor.png"}}
Defs_New.torch_off.drop = ModName..":torch_off"
Defs_New.torch_off.on_place = function(itemstack, placer, pointed_thing) -- This function is a near-direct copy of the builtin one.
	local under = pointed_thing.under
	local node = minetest.get_node(under)
	local def = minetest.registered_nodes[node.name]
	if def and def.on_rightclick and
		((not placer) or (placer and not placer:get_player_control().sneak)) then
		return def.on_rightclick(under, node, placer, itemstack,
			pointed_thing) or itemstack
	end

	local above = pointed_thing.above
	local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
	local fakestack = itemstack
	if wdir == 0 then
		fakestack:set_name(ModName..":torch_ceiling_off")
	elseif wdir == 1 then
		fakestack:set_name(ModName..":torch_off")
	else
		fakestack:set_name(ModName..":torch_wall_off")
	end

	itemstack = minetest.item_place(fakestack, placer, pointed_thing, wdir)
	itemstack:set_name(ModName..":torch_off")

	return itemstack
end
Defs_New.torch_off.on_rightclick = on_rightclick
minetest.register_node(ModName..":torch_off", Defs_New.torch_off)

Defs_New.torch_wall_off.light_source = nil
Defs_New.torch_wall_off.drop = ModName..":torch_off"
Defs_New.torch_wall_off.tiles = {{name = "justin_burning_out_torches_torch_off_floor.png"}}
Defs_New.torch_wall_off.on_rightclick = on_rightclick
minetest.register_node(ModName..":torch_wall_off", Defs_New.torch_wall_off)

Defs_New.torch_ceiling_off.light_source = nil
Defs_New.torch_ceiling_off.drop = ModName..":torch_off"
Defs_New.torch_ceiling_off.tiles = {{name = "justin_burning_out_torches_torch_off_floor.png"}}
Defs_New.torch_ceiling_off.on_rightclick = on_rightclick
minetest.register_node(ModName..":torch_ceiling_off", Defs_New.torch_ceiling_off)

-- Low-fuel types
Defs_New.torch_lowfuel.light_source = Defs_Old.torch.light_source - 4
Defs_New.torch_lowfuel.description = "Dim Torch (How did you get this!?)"
Defs_New.torch_lowfuel.drop = ModName..":torch_off"
Defs_New.torch_lowfuel.on_place = function(itemstack, placer, pointed_thing) -- This function is a near-direct copy of the builtin one.
	local under = pointed_thing.under
	local node = minetest.get_node(under)
	local def = minetest.registered_nodes[node.name]
	if def and def.on_rightclick and
		((not placer) or (placer and not placer:get_player_control().sneak)) then
		return def.on_rightclick(under, node, placer, itemstack,
			pointed_thing) or itemstack
	end

	local above = pointed_thing.above
	local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
	local fakestack = itemstack
	if wdir == 0 then
		fakestack:set_name(ModName..":torch_ceiling_lowfuel")
	elseif wdir == 1 then
		fakestack:set_name(ModName..":torch_lowfuel")
	else
		fakestack:set_name(ModName..":torch_wall_lowfuel")
	end

	itemstack = minetest.item_place(fakestack, placer, pointed_thing, wdir)
	itemstack:set_name(ModName..":torch_lowfuel")

	return itemstack
end
Defs_New.torch_lowfuel.on_rightclick = on_rightclick
local Defs_New_torch_lowfuel_groups = mod.Table_Copy(Defs_Old.torch.groups)
Defs_New_torch_lowfuel_groups["not_in_creative_inventory"] = 1
Defs_New.torch_lowfuel.groups = Defs_New_torch_lowfuel_groups
minetest.register_node(ModName..":torch_lowfuel", Defs_New.torch_lowfuel)

Defs_New.torch_wall_lowfuel.light_source = Defs_Old.torch_wall.light_source - 4
Defs_New.torch_wall_lowfuel.drop = ModName..":torch_off"
Defs_New.torch_wall_lowfuel.on_rightclick = on_rightclick
minetest.register_node(ModName..":torch_wall_lowfuel", Defs_New.torch_wall_lowfuel)

Defs_New.torch_ceiling_lowfuel.light_source = Defs_Old.torch_ceiling.light_source - 4
Defs_New.torch_ceiling_lowfuel.drop = ModName..":torch_off"
Defs_New.torch_ceiling_lowfuel.on_rightclick = on_rightclick
minetest.register_node(ModName..":torch_ceiling_lowfuel", Defs_New.torch_ceiling_lowfuel)

-- Override
minetest.override_item("default:torch", {
	on_rightclick = on_rightclick,
	after_place_node = torch_after_place_node,
})
minetest.override_item("default:torch_wall", {
	on_rightclick = on_rightclick,
	after_place_node = torch_after_place_node,
})
minetest.override_item("default:torch_ceiling", {
	on_rightclick = on_rightclick,
	after_place_node = torch_after_place_node,
})

-- Crafts
minetest.register_craft({
	type = "shapeless",
	output = "default:torch 4",
	recipe = {"default:coal_lump", ModName..":torch_off", ModName..":torch_off", ModName..":torch_off", ModName..":torch_off"},
})
minetest.register_craft({
	type = "fuel",
	recipe = ModName..":torch_off",
	burntime = 1.5,
})

-- API Registration
mod.register_torch({
	id = ModName.."_torch",
	name = "Torch",
	nodes = nodes_floor,
	fuel_capacity = my_fuel_capacity,
	fuel_persecond = my_fuel_persecond,
	fuel_lowthreshold = my_fuel_lowthreshold
})
mod.register_torch({
	id = ModName.."_torch_wall",
	name = "Torch",
	nodes = nodes_wall,
	fuel_capacity = my_fuel_capacity,
	fuel_persecond = my_fuel_persecond,
	fuel_lowthreshold = my_fuel_lowthreshold
})
mod.register_torch({
	id = ModName.."_torch_ceiling",
	name = "Torch",
	nodes = nodes_ceiling,
	fuel_capacity = my_fuel_capacity,
	fuel_persecond = my_fuel_persecond,
	fuel_lowthreshold = my_fuel_lowthreshold
})
