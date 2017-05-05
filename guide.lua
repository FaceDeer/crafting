crafting.guide = {}
crafting.guide.outputs = {}
crafting.guide.playerdata = {}

-- internationalization boilerplate
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local function get_group_examples()
	if crafting.guide.groups then return crafting.guide.groups end
	crafting.guide.groups = {}
	for item, def in pairs(minetest.registered_items) do
		for group, _ in pairs(def.groups) do
			crafting.guide.groups[group] = item
		end
	end	
	return crafting.guide.groups
end

local function get_output_list(craft_type)
	if crafting.guide.outputs[craft_type] then return crafting.guide.outputs[craft_type] end
	crafting.guide.outputs[craft_type] = {}
	outputs = crafting.guide.outputs[craft_type]
	for item, _ in pairs(crafting.type[craft_type].recipes_by_out) do
		if minetest.get_item_group(item, "not_in_craft_guide") == 0 then
			table.insert(outputs, item)
		end
	end
	
	table.sort(outputs)

	return outputs
end

local function get_playerdata(craft_type, player_name)
	if not crafting.guide.playerdata[craft_type] then
		crafting.guide.playerdata[craft_type] = {}
	end
	if crafting.guide.playerdata[craft_type][player_name] then
		return crafting.guide.playerdata[craft_type][player_name]
	end
	crafting.guide.playerdata[craft_type][player_name] = {["page"] = 0, ["selection"] = 0}
	return crafting.guide.playerdata[craft_type][player_name]
end

local function make_formspec(craft_type, player_name)
	local groups = get_group_examples()
	local outputs = get_output_list(craft_type)
	local playerdata = get_playerdata(craft_type, player_name)
	
	local formspec = {
		"size[10,9.2]",
		default.gui_bg,
		default.gui_bg_img,
		default.gui_slots,
	}

	local x = 1
	local y = 1

	for i = 1, 8*4 do
		local current_item_index = i + playerdata.page * 8 * 4
		local current_item = outputs[current_item_index]
		if current_item then
			table.insert(formspec, "item_image_button[" ..
				x + (i-1)%8 .. "," .. y + math.floor((i-1)/8) ..
				";1,1;" .. current_item .. ";product_" .. current_item_index ..
				";]")
		else
			table.insert(formspec, "item_image_button[" ..
				x + (i-1)%8 .. "," .. y + math.floor((i-1)/8) ..
				";1,1;;;]")
		end
	end

	if playerdata.selection == 0 then
		table.insert(formspec,  "item_image_button[" ..
			x + 3.5 .. "," .. y + 4 .. ";1,1;;;]")
	else
		table.insert(formspec, "item_image_button[" ..
			x + 3.5 .. "," .. y + 4 .. ";1,1;" ..
			outputs[playerdata.selection] .. ";;]")
	end

	table.insert(formspec, "button[" .. x .. "," .. y + 4 .. ";1,1;previous_page;Prev]")
	table.insert(formspec, "button[" .. x + 7 .. "," .. y + 4 .. ";1,1;next_page;Next]")

	local recipes
	if playerdata.selection > 0 then
		recipes = crafting.type[craft_type].recipes_by_out[outputs[playerdata.selection]]
	end

	minetest.debug(dump(recipes))
	
	return table.concat(formspec)
end

local function crafting_guide_on_use(itemstack, user)
	minetest.show_formspec(user:get_player_name(), "crafting:craftguide", make_formspec("table",user:get_player_name()))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "crafting:craftguide" then return false end

	local playerdata = get_playerdata("table", player:get_player_name())
	local outputs = get_output_list("table")
	
	for field, _ in pairs(fields) do
		if field == "previous_page" and playerdata.page > 0 then
			playerdata.page = playerdata.page - 1
		elseif field == "next_page" and playerdata.page < #outputs/(8*4) then
			playerdata.page = playerdata.page + 1
		elseif string.sub(field, 1, 8) == "product_" then
			playerdata.selection = tonumber(string.sub(field, 9))
		elseif field == "exit" then
			return true
		end
	end

	minetest.show_formspec(player:get_player_name(), "crafting:craftguide", make_formspec("table",player:get_player_name()))
	return true

end)


minetest.register_craftitem("crafting:guide", {
	description = S("Crafting Guide (Table)"),
	inventory_image = "crafting_guide_contents.png^(crafting_guide_cover.png^[multiply:#0088ff)",
	wield_image = "crafting_guide_contents.png^(crafting_guide_cover.png^[multiply:#0088ff)",
	stack_max = 1,
	groups = {book = 1},
	on_use = crafting_guide_on_use,
})
