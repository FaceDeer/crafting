local modpath = minetest.get_modpath(minetest.get_current_modname()) 

crafting = {}

dofile(modpath .. "/config.lua")
dofile(modpath .. "/table.lua")
dofile(modpath .. "/furnace.lua")

if crafting.config.import_default_recipes then

	crafting_lib.get_legacy_type = function(legacy_method, legacy_recipe)
		if legacy_method == "normal" then
			return "table"
		elseif legacy_method == "cooking" then
			legacy_recipe.fuel_grade = {}
			legacy_recipe.fuel_grade.min = 0
			legacy_recipe.fuel_grade.max = math.huge
			return "furnace"
		elseif legacy_method == "fuel" then
			legacy_recipe.grade = 1
			return "fuel"
		end
		minetest.log("error", "get_legacy_type encountered unknown legacy method: "..legacy_method)
		return nil
	end

	crafting_lib.import_legacy_recipes(crafting.config.clear_default_crafting)
end

if crafting.config.clear_default_crafting then
	-- If we've cleared all native crafting recipes, add the table back
	-- in to the native crafting system so that the player can
	-- build that and access everything else through it
	crafting_lib.minetest_register_craft({
		output = "crafting:table",
		recipe = {
			{"group:tree","group:tree",""},
			{"group:tree","group:tree",""},
			{"","",""},
		},
	})
end
