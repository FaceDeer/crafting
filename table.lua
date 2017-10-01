local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local table_functions = simplecrafting_lib.generate_table_functions("table", {
	show_guides = crafting.config.show_guides,
	alphabetize_items = crafting.config.sort_alphabetically,
})

local table_def = {
	description = S("Crafting Table"),
	drawtype = "normal",
	tiles = {"crafting.table_top.png", "default_chest_top.png",
		"crafting.table_front.png", "crafting.table_front.png",
		"crafting.table_side.png", "crafting.table_side.png"},
	sounds = default.node_sound_wood_defaults(),
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {oddly_breakable_by_hand = 1, choppy=3},
}

for k, v in pairs(table_functions) do
	table_def[k] = v
end

minetest.register_node("crafting:table", table_def)

----------------------------------------------------------
-- Crafting

local table_recipe = {
	output = "crafting:table",
	recipe = {
		{"group:tree","group:tree",""},
		{"group:tree","group:tree",""},
		{"","",""},
	},
}

minetest.register_craft(table_recipe)

----------------------------------------------------------
-- Guide

if crafting.config.show_guides then
	minetest.register_craftitem("crafting:table_guide", {
		description = S("Crafting Guide (Table)"),
		inventory_image = "crafting_guide_cover.png^[colorize:#0088ff88^crafting_guide_contents.png",
		wield_image = "crafting_guide_cover.png^[colorize:#0088ff88^crafting_guide_contents.png",
		stack_max = 1,
		groups = {book = 1},
		on_use = function(itemstack, user)
			simplecrafting_lib.show_crafting_guide("table", user)
		end,
	})
	
	if minetest.get_modpath("default") then
		minetest.register_craft({
			output = "crafting:table_guide",
			type = "shapeless",
			recipe = {"crafting:table", "default:book"},
			replacements = {{"crafting:table", "crafting:table"}}
		})
	end
end
	
----------------------------------------------------------------
-- Hopper compatibility

if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
	hopper:add_container({
		{"top", "crafting:table", "store"},
		{"bottom", "crafting:table", "store"},
		{"side", "crafting:table", "store"},
	})
end