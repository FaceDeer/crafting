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

simplecrafting_lib.register_crafting_guide_item("crafting:table_guide", "table", {
	guide_color = "#0088ff",
	copy_item_to_book = "crafting:table",
})
	
----------------------------------------------------------------
-- Hopper compatibility

if minetest.get_modpath("hopper") and hopper ~= nil and hopper.add_container ~= nil then
	hopper:add_container({
		{"top", "crafting:table", "input"},
		{"bottom", "crafting:table", "input"},
		{"side", "crafting:table", "input"},
	})
end

minetest.register_lbm({
	name = "crafting:move_inventory",
	nodenames = {"crafting:table"},
	action = function(pos, node)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local size = inv:get_size("store")
		local list = inv:get_list("store")
		inv:set_size("input", size)
		inv:set_list("input", list)
		inv:set_size("store", 0)
	end,
})