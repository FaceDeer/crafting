local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local craft_function = simplecrafting_lib.generate_tool_functions("table", {
	show_guides = true,
	alphabetize_items = true,
	description = "Table",
})

minetest.register_craftitem("crafting:crafting_tool", {
	description = S("Crafting Tool"),

	inventory_image = "default_tool_steelaxe.png",

	stack_max = 1,

	on_secondary_use = function(itemstack, user, pointed_thing)
		craft_function(user)
	end,

	on_use = function(itemstack, user, pointed_thing)
		craft_function(user)
	end,
})