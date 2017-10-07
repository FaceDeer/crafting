local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local table_functions = simplecrafting_lib.generate_autocraft_functions("table", {
	show_guides = crafting.config.show_guides,
	alphabetize_items = crafting.config.sort_alphabetically,
	hopper_node_name = "crafting:table",
	enable_pipeworks = true,
	description = S("Autocrafting Table"),
	crafting_time_multiplier = function(pos, recipe)
		if recipe.cooktime then
			return recipe.cooktime
		end
		local totalcount = 0
		for _, count in pairs(recipe.input) do
			totalcount = totalcount + count
		end
		return totalcount
	end,
})

local table_def = {
	description = S("Autocrafting Table"),
	drawtype = "normal",
	tiles = {"crafting.table_top.png^crafting.gears.png", "default_chest_top.png",
		"crafting.table_front.png", "crafting.table_front.png",
		"crafting.table_side.png^crafting.gears.png", "crafting.table_side.png^crafting.gears.png"},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {oddly_breakable_by_hand = 1, choppy=3, tubedevice = 1, tubedevice_receiver = 1},
}

for k, v in pairs(table_functions) do
	table_def[k] = v
end

minetest.register_node("crafting:autotable", table_def)

----------------------------------------------------------
-- Crafting

local table_recipe = {
	output = "crafting:autotable",
	recipe = {
		{"default:mese_crystal_fragment","default:mese_crystal_fragment",""},
		{"group:tree","group:tree","default:steel_ingot"},
		{"group:tree","group:tree","default:steel_ingot"},
	},
}

minetest.register_craft(table_recipe)
