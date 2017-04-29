crafting.register = function(typeof, def)
	def.returns = def.returns or {}
	-- Strip group: from group names to simplify comparison later
	for item, count in pairs(def.input) do
		local group = string.match(item, "^group:(%S+)$")
		if group then
			def.input[group] = count
			def.input[item] = nil
		end
	end

	-- ensure the destination tables exist
	crafting.type[typeof] = crafting.type[typeof] or {}
	crafting.type[typeof].recipes = crafting.type[typeof].recipes or {}
	crafting.type[typeof].recipes_by_out = crafting.type[typeof].recipes_by_out or {}

-- TODO: this was used in the furnace-specific registration but its purpose
-- is unclear.
--	-- Only one input, but pairs is easiest way to find it
--	for item, count in pairs(def.input) do
--		recipes[item] = recipes[item] or {}
--		local inserted = false
--		-- If a recipe is more specific, insert it before other recipe
--		for i, recipe in ipairs(recipes[item]) do
--			if def.fuel_grade.min > recipe.fuel_grade.min
--			or def.fuel_grade.max < recipe.fuel_grade.max then
--				table.insert(recipes[item], i, def)
--				inserted = true
--				break
--			end
--		end
--		if not inserted then
--			recipes[item][#recipes[item] + 1] = def
--		end
--	end
	
	table.insert(crafting.type[typeof].recipes, def)
	
	local recipes_by_out = crafting.type[typeof].recipes_by_out
	for item, _ in pairs(def.output) do
		recipes_by_out[item] = recipes_by_out[item] or {} 
		recipes_by_out[item][#recipes_by_out[item]+1] = def
	end
	return true
end

crafting.register_fuel = function(def)
	-- Strip group: from group names to simplify comparison later
	local group = string.match(def.name, "^group:(%S+)$")
	def.name = group or def.name

	crafting.fuel[def.name] = def
	return true
end

-- returns the fuel definition for the item if it is fuel, nil otherwise
crafting.is_fuel = function(item)
	local fuels = crafting.fuel
	
	-- First check if the item has been explicitly registered as fuel
	if fuels[item] then
		return fuels[item]
	end

	-- Failing that, check its groups.
	local def = minetest.registered_items[item]
	if def and def.groups then
		local max = -1
		local fuel_group
		for group, _ in pairs(def.groups) do
			if fuels[group] then
				if fuels[group].burntime > max then
					fuel_group = fuels[group] -- track whichever is the longest-burning group
					max = fuel_group.burntime
				end
			end
		end
		if fuel_group then
			return fuel_group
		end
	end
	return nil
end

-- Turns an item list (as returned by inv:get_list) into a form more easily used by crafting functions
local function itemlist_to_countlist(itemlist)
	local count_list = {}
	for _, stack in ipairs(itemlist) do
		if not stack:is_empty() then
			local name = stack:get_name()
			count_list[name] = (count_list[name] or 0) + stack:get_count()
			-- If it is the most common item in a group, alias the group to it
			if minetest.registered_items[name] then
				for group, _ in pairs(minetest.registered_items[name].groups or {}) do
					if not count_list[group] 
					or (count_list[group] and count_list[count_list[group]] < count_list[name]) then
						count_list[group] = name
					end
				end
			end
		end
	end
	return count_list
end

-- returns the number of times the recipe can be crafted from the given input_list
local function get_craft_count(input_list, recipe)
	-- Recipe without groups (most common node in group instead)
	local work_recipe = table.copy(recipe)
	work_recipe.input = {}
	local required_input = work_recipe.input
	for item, count in pairs(recipe.input) do
		if not input_list[item] then
			return 0
		end
		-- Groups are a string alias to most common member item
		if type(input_list[item]) == "string" then
			required_input[input_list[item]] = (required_input[input_list[item]] or 0) + count
		else
			required_input[item] = (required_input[item] or 0) + count
		end
	end
	local number = math.huge
	for ingredient, count in pairs(required_input) do
		local max = input_list[ingredient] / count
		if max < 1 then
			return 0
		elseif max < number then
			number = max
		end
	end
	-- Return number of possible crafts as integer
	return math.floor(number), work_recipe
end

local function get_craftable_number(crafting_type, inv, stack)
	local recipes_by_out = crafting.type[crafting_type].recipes_by_out
	-- Re-calculate the no. items in the stack
	-- This is used in both fixes		
	local count = 0
	local no_per_out = 1
	local name = stack:get_name()
	for i = 1, #recipes_by_out[name] do
		local out, recipe = get_craft_count(itemlist_to_countlist(inv:get_list("store")), recipes_by_out[name][i])
		if out > 0 and out * recipe.output[name] > count then
			count = out * recipe.output[name]
			no_per_out = recipe.output[name]
		end
	end
	-- Stack limit correction
	local max = stack:get_stack_max()
	if max < count then
		count = max - (max % no_per_out)
	end

	return count
end

-- Returns a list of all recipes whose ingredients can be satisfied by the item_list
crafting.get_craftable_recipes = function(craft_type, item_list)
	local count_list = itemlist_to_countlist(item_list)
	local craftable = {}
	local recipes = crafting.type[craft_type].recipes	
	for i = 1, #recipes do
		local number, recipe = get_craft_count(count_list, recipes[i])
		if number > 0 then
			table.insert(craftable, recipe)
		end
	end
	return craftable
end

-- Returns a list of all the possible item stacks that could be crafted from the provided item list
-- if max_craftable is true the returned stacks will have as many items in them as possible to craft,
-- if max_craftable is false or nil the returned stacks will have only the minimum output
crafting.get_craftable_items = function(craft_type, item_list, max_craftable)
	local count_list = itemlist_to_countlist(item_list)
	local craftable_count_list = {}
	local craftable_stacks = {}
	local chosen_recipe = {}
	local recipes = crafting.type[craft_type].recipes	
	for i = 1, #recipes do
		local number, recipe = get_craft_count(count_list, recipes[i])
		if number > 0 then
			if not max_craftable then number = 1 end
			for item, count in pairs(recipe.output) do
				if craftable_count_list[item] and count*number > craftable_count_list[item] then
					craftable_count_list[item] = count*number
					chosen_recipe[item] = recipe
				elseif not craftable_count_list[item] and count*number > 0 then
					craftable_count_list[item] = count*number
					chosen_recipe[item] = recipe
				end
			end
		end
	end
	-- Limit stacks to stack limit
	for item, count in pairs(craftable_count_list) do
		local stack = ItemStack(item)
		local max = stack:get_stack_max()
		if count > max then
			count = max - max % chosen_recipe[item].output[item]
		end
		stack:set_count(count)
		table.insert(craftable_stacks, stack)
	end
	return craftable_stacks
end

-- adds two count lists together, returns a new count list with the sum of the parameters' contents
-- useful for combining a recipe's products and returned items
crafting.count_list_add = function(list1, list2)
	local out_list = {}
	for item, count in pairs(list1) do
		out_list[item] = count
	end
	for item, count in pairs(list2) do
		out_list[item] = (out_list[item] or 0) + count
	end
	return out_list
end

-- Attempts to add the items in count_list to the inventory.
crafting.add_items = function(inv, listname, count_list)
	local old_list = inv:get_list(listname)
	local leftover = nil
	
	for item, count in pairs(count_list) do
		leftover = inv:add_item(listname, ItemStack({name=item, count=count}))
		if leftover:get_count() > 0 then
			inv:set_list(listname, old_list)
			return false
		end
	end
	return true
end

-- removes the items in the count_list (formatted as per recipe standards)
-- from the inventory. Returns true on success, false on failure
crafting.remove_items = function(inv, listname, count_list)
	local can_remove = true
	for item, count in pairs(count_list) do
		if not inv:contains_item(listname, ItemStack({name=item, count=count})) then
			can_remove = false
			break
		end
	end
	if can_remove then
		for item, count in pairs(count_list) do
			inv:remove_item(listname, ItemStack({name=item, count=count}))
		end	
		return true
	end
	return false
end

crafting.count_fixes = function(crafting_type, inv, stack, new_stack, tinv, tlist, player)
	if (not new_stack:is_empty() and new_stack:get_name() ~= stack:get_name())
	-- Only effective if stack limits are ignored by table
	-- Stops below fix being triggered incorrectly when swapping
	or new_stack:get_count() == new_stack:get_stack_max() then
		local excess = tinv:add_item(tlist, new_stack)
		if not excess:is_empty() then
			minetest.item_drop(excess, player, player:getpos())
		end

		-- Delay re-calculation until items are back in input inv
		local count = get_craftable_number(crafting_type, inv, stack)

		-- Whole stack has been taken - calculate how many
		return count, true
	end

	-- Delay re-calculation as condition above may cause items to not be
	-- in the correct inv
	local number = get_craftable_number(crafting_type, inv, stack)

	-- Fix for listring movement causing multiple updates with
	-- incorrect values when trying to move items onto a stack and
	-- exceeding stack max
	-- A second update then tries to move the remaining items
	if (not new_stack:is_empty()
	and new_stack:get_name() == stack:get_name()
	and new_stack:get_count() + stack:get_count() > number) then
		return stack:get_count() - new_stack:get_count(), false
	end
end


crafting.pay_items = function(crafting_type, inv, crafted, to_inv, to_list, player, no_crafted)
	local recipes_by_out = crafting.type[crafting_type].recipes_by_out
	local name = crafted:get_name()
	local no = no_crafted
	local itemlist = itemlist_to_countlist(inv:get_list("store"))
	local max = 0
	local craft_using

	-- Catch items in output without recipe (reported by cx384)
	if not recipes_by_out[name] then
		minetest.log("error", "Item in table output list without recipe: "
			.. name)
		return
	end

	-- Get recipe which can craft the most
	for i = 1, #recipes_by_out[name] do
		local out, recipe = get_craft_count(itemlist, recipes_by_out[name][i])
		if out > 0 and out * recipe.output[name] > max then
			max = out * recipe.output[name]
			craft_using = recipe
		end
	end

	-- Catch items in output without recipe (reported by cx384)
	if not craft_using then
		minetest.log("error", "Item in table output list without valid recipe: "
			.. name)
		return
	end

	-- Increase amount taken if not a multiple of recipe output
	local output_factor = craft_using.output[name]
	if no % output_factor ~= 0 then
		no = no - (no % output_factor)
		if no + output_factor <= crafted:get_stack_max() then
			no = no + output_factor
		end
	end

	-- Take consumed items
	local input = craft_using.input
	local no_crafts = math.floor(no / output_factor)
	for item, count in pairs(input) do
		local to_remove = no_crafts * count
		local stack = ItemStack(item)
		stack:set_count(stack:get_stack_max())
		while to_remove > stack:get_stack_max() do
			inv:remove_item("store", stack)
			to_remove = to_remove - stack:get_stack_max()
		end

		if to_remove > 0 then
			stack:set_count(to_remove)
			inv:remove_item("store", stack)
		end
	end

	-- Add excess items
	local output = craft_using.output
	for item, count in pairs(output) do
		local to_add 
		if item == name then
			to_add = no - no_crafted
		else
			to_add = no_crafts * count
		end
		if no > 0 then
			local stack = ItemStack(item)
			local max = stack:get_stack_max()
			stack:set_count(max)
			while to_add > 0 do
				if to_add > max then
					to_add = to_add - max
				else
					stack:set_count(to_add)
					to_add = 0
				end
				local excess = to_inv:add_item(to_list, stack)
				if not excess:is_empty() then
					minetest.item_drop(excess, player, player:getpos())
				end
			end
		end
	end
	-- Add return items - copied code from above
	for item, count in pairs(craft_using.returns) do
		local to_add 
		to_add = no_crafts * count
		if no > 0 then
			local stack = ItemStack(item)
			local max = stack:get_stack_max()
			stack:set_count(max)
			while to_add > 0 do
				if to_add > max then
					to_add = to_add - max
				else
					stack:set_count(to_add)
					to_add = 0
				end
				local excess = to_inv:add_item(to_list, stack)
				if not excess:is_empty() then
					minetest.item_drop(excess, player, player:getpos())
				end
			end
		end
	end
end