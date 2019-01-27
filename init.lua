local modpath = minetest.get_modpath(minetest.get_current_modname()) 

crafting = {}
crafting.append_to_formspec = nil -- nil leaves this with default background, "bgcolor[#080808BB;true]background[5,5;1,1;gui_formbg.png;true]listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]".

dofile(modpath .. "/config.lua")
dofile(modpath .. "/table.lua")
dofile(modpath .. "/furnace.lua")

if crafting.config.enable_autotable then
	dofile(modpath .. "/autotable.lua")
end

simplecrafting_lib.set_crafting_guide_def("table", {
	append_to_formspec = crafting.append_to_formspec,
})

if crafting.config.import_default_recipes then
	simplecrafting_lib.register_recipe_import_filter(function(legacy_recipe)
		if legacy_recipe.input["simplecrafting_lib:heat"] then
			return "furnace", crafting.config.clear_default_crafting
		elseif legacy_recipe.output and legacy_recipe.output:get_name() == "simplecrafting_lib:heat" then
			return "fuel", crafting.config.clear_default_crafting
		else
			return "table", crafting.config.clear_default_crafting
		end
	end)
end

if crafting.config.clear_default_crafting then
	-- If we've cleared all native crafting recipes, add the table back
	-- in to the native crafting system so that the player can
	-- build that and access everything else through it
	simplecrafting_lib.minetest_register_craft({
		output = "crafting:table",
		recipe = {
			{"group:tree","group:tree",""},
			{"group:tree","group:tree",""},
			{"","",""},
		},
	})
end
