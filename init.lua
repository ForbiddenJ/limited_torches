local mod = {}
local modname = minetest.get_current_modname()
mod.modpath = minetest.get_modpath(modname)
_G[modname] = mod

dofile(mod.modpath .. "/api.lua")
dofile(mod.modpath .. "/torch.lua")
