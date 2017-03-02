local ModName = minetest.get_current_modname()
local mod = _G[ModName]
mod.defs = {} -- This is a list of definitions registered by name.
mod.def_glossary = {} -- This is used to lookup definitions by using node names.

-- Basic implementations
function mod.Table_Copy(table)
	local r = {}
	for k, v in pairs(table) do
		r[k] = v
	end
	return r
end
function mod.Table_Invert(table)
	local r = {}
	for k, v in pairs(table) do
		r[v] = k
	end
	return r
end

-- Functions
function mod.register_torch(def)
	assert(def, "def must be a table.")
	assert(def.id, "def.id must be a string.")
	assert(def.nodes, "def.nodes must be a table.")
	assert(def.fuel_capacity, "def.fuel_capacity must be a number.")
	assert(def.fuel_persecond, "def.fuel_persecond must be a number.")
	assert(def.fuel_lowthreshold, "def.fuel_lowthreshold must be a number.")
	
	def.nodes_backward = mod.Table_Invert(def.nodes)
	
	-- Deplete fuel supply gradually.
	minetest.register_abm({
		nodenames = {def.nodes[1], def.nodes[2]},
		interval = 1,
		chance = 1,
		action = mod.abm_action,
	})
	-- In the case a mapblock has been unloaded for a while, play catch-up.
	-- This code block isn't required, but then unloaded torches will stay
	-- as they were when they are loaded.
	minetest.register_lbm({
		name = ModName..":"..def.id.."_lbm",
		nodenames = {def.nodes[1], def.nodes[2]},
		run_at_every_load = true,
		action = mod.lbm_action,
	})
	
	for k, v in pairs(def.nodes) do
		mod.def_glossary[v] = def
	end
	mod.defs[def.id] = def
end
function mod.GetFuel(node, meta)
	local def = mod.def_glossary[node.name]
	local IsModdedValue = meta:get_int("justin_burning_out_torches_modded")
	local IsModTorch = (IsModdedValue == 1) or (def.nodes_backward[node.name] ~= 1)
	if IsModTorch then
		local OldCapacity = meta:get_float("justin_burning_out_torches_fuel_capacity")
		local fuel = (meta:get_float("justin_burning_out_torches_fuel") or 0)
		return ((OldCapacity == def.fuel_capacity and fuel > 0) and fuel or ((fuel / OldCapacity) * def.fuel_capacity))
	else
		return (def.fuel_lowthreshold * 1.1)
	end
end
function mod.UpdateFuel(pos, node_param, func, alter_node_param)
	local node = node_param or minetest.get_node(pos)
	local alter_node
	if alter_node_param == nil then
		alter_node = true
	else
		alter_node = alter_node_param
	end
	
	local def = mod.def_glossary[node.name]
	local meta = minetest.get_meta(pos)
	local fuel_old = mod.GetFuel(node, meta)
	local fuel = math.min(math.max(0, func(pos, node, fuel_old, meta)), def.fuel_capacity)
	
	if alter_node and fuel > 0 then -- Turn on torch node.
		mod.SetTorchNode(pos, node, (fuel > def.fuel_lowthreshold and 1 or 2), true, meta)
		
		meta = minetest.get_meta(pos) -- Deliberately replace meta to keep it alive.
	end
	meta:set_float("justin_burning_out_torches_fuel", fuel)
	meta:set_float("justin_burning_out_torches_fuel_capacity", def.fuel_capacity)
	meta:set_int("justin_burning_out_torches_modded", 1)
	meta:set_float("justin_burning_out_torches_lastticktime", minetest.get_day_count() + minetest.get_timeofday())
	mod.UpdateLabel(node, meta)
	if alter_node and fuel <= 0 then -- Turn off torch node.
		mod.SetTorchNode(pos, node, 0, false, meta)
	end
end
function mod.SetFuel(pos, node, new_fuel, alter_node)
	return mod.UpdateFuel(pos, node, function(...)
		return new_fuel
	end, alter_node)
end
function mod.SetTorchNode(pos, node, new_state, keep_meta, meta_param)
	-- Node Numbers:
	--  1 = Regular torch
	--  0 = Dead Torch
	--  2 = Low-Fuel Torch
	
	local def = mod.def_glossary[node.name] -- Type: Table
	--local old_state = (def.nodes_backward[node.name]) -- Type: Integer
	local NewNodeName = def.nodes[new_state] -- Type: String
	
	if (NewNodeName ~= node.name) then
		local meta, meta_copy
		if keep_meta then
			meta = meta_param or minetest.get_meta(pos)
			meta_copy = meta:to_table()
		end
		minetest.set_node(pos, {name = NewNodeName, param1 = node.param1, param2 = node.param2})
		if keep_meta then
			minetest.get_meta(pos):from_table(meta_copy)
		end
	end
end
function mod.UpdateLabel(node, meta)
	local def = mod.def_glossary[node.name]
	local fuel = mod.GetFuel(node, meta)
	local fuel_time = fuel / def.fuel_persecond
	local capacity_time = def.fuel_capacity / def.fuel_persecond
	meta:set_string(
		"infotext", 
		(
			def.name.." active ("..
			--"Fuel: "..string.sub(tostring((fuel / def.fuel_capacity) * 100), 1, 4).."% ("..fuel.."/"..def.fuel_capacity..")"..
			"Fuel: "..tostring(math.floor((fuel / def.fuel_capacity) * 1000) / 10).."% ("..mod.AsClockText(fuel_time).."/"..mod.AsClockText(capacity_time)..")"..
			(fuel < def.fuel_lowthreshold and "; Running low!" or "")..
			")"
		)
	)
end
function mod.AsClockText(seconds)
	local function IntDivide(a, b)
		local x = math.floor(a / b)
		local y = x * b -- dividend
		local z = a - y -- remainder
		return x, z
	end
	local function FormatNumber(text)
		return (#tostring(text) == 1 and "0" or "")..text
	end

	local part_seconds = math.floor(seconds)
	local part_minutes = 0
	local part_hours = 0
	
	part_minutes, part_seconds = IntDivide(part_seconds, 60)
	part_hours, part_minutes = IntDivide(part_minutes, 60)
	
	return FormatNumber(part_hours)..":"..FormatNumber(part_minutes)..":"..FormatNumber(part_seconds)
end

-- Events
function mod.abm_action(pos, node, active_object_count, active_object_count_wider)
	local def = mod.def_glossary[node.name]
	mod.UpdateFuel(pos, node, function(pos, node, fuel, meta)
		return fuel - def.fuel_persecond
	end, true)
end
function mod.lbm_action(pos, node, active_object_count, active_object_count_wider)
	local def = mod.def_glossary[node.name]
	mod.UpdateFuel(pos, node, function(pos, node, fuel, meta)
		local MetaLastTick = meta:get_float("justin_burning_out_torches_lastticktime")
		if MetaLastTick ~= 0 and MetaLastTick ~= nil then
			local TimePassed = math.max(0, minetest.get_day_count() + minetest.get_timeofday() - MetaLastTick) * 24000
			return fuel - (def.fuel_persecond * TimePassed)
		else
			return fuel
		end
	end, true)
end
