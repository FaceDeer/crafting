local function refresh_output(inv)
	local craftable = crafting.get_craftable_items("table", inv:get_list("store"))
	inv:set_size("output", #craftable + ((8*6) - (#craftable%(8*6))))
	inv:set_list("output", craftable)
end

local function make_formspec(row, noitems)
	if noitems < (8*6) then
		row = 0
	elseif (row*8)+(8*6) > noitems then
		row = (noitems - (8*6)) / 8
	end

	local inventory = {
		"size[10.2,10.2]"
		, "list[context;store;0,0.5;2,5;]"
		, "list[context;output;2.2,0;8,6;" , tostring(row*8), "]"
		, "list[current_player;main;1.1,6.2;8,4;]"
		, "listring[context;output]"
		, "listring[current_player;main]"
		, "listring[context;store]"
		, "listring[current_player;main]"
	}
	if row >= 6 then
		inventory[#inventory+1] = "button[9.3,6.7;1,0.75;prev;«]"
	end
	if noitems > ((row/6)+1) * (8*6) then
		inventory[#inventory+1] = "button[9.1,6.2;1,0.75;next;»]"
	end
	inventory[#inventory+1] = "label[0,6.5;Row " .. tostring(row) .. "]"

	return table.concat(inventory), row
end

local function refresh_inv(meta)
	local inv = meta:get_inventory()
	refresh_output(inv)

	local page = meta:get_int("page")
	local form, page = make_formspec(page, inv:get_size("output"))
	meta:set_int("page", page)
	meta:set_string("formspec", form)
end

minetest.register_node("crafting:table", {
	description = "Crafting Table",
	drawtype = "normal",
	tiles = {"crafting.table_top.png", "default_chest_top.png",
		"crafting.table_front.png", "crafting.table_front.png",
		"crafting.table_side.png", "crafting.table_side.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {oddly_breakable_by_hand = 1, choppy=3},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("store", 2*5)
		inv:set_size("output", 8*6)
		meta:set_int("row", 0)
		meta:set_string("formspec", make_formspec(0, 0))
	end,
	allow_metadata_inventory_move = function(pos, flist, fi, tlist, ti, no, player)
		if tlist == "output" then
			return 0
		end
		return no
	end,
	allow_metadata_inventory_put = function(pos, lname, i, stack, player)
		if lname == "output" then
			return 0
		end
		return stack:get_count()
	end,
	on_metadata_inventory_move = function(pos, flist, fi, tlist, ti, no, player)
		local meta = minetest.get_meta(pos)
		if flist == "output" and tlist == "store" then
			local inv = meta:get_inventory()

			local stack = inv:get_stack(tlist, ti)
			local new_stack = inv:get_stack(flist, fi)
			-- Set count to no, for the use of count_fixes
			stack:set_count(no)
			local count, refresh = crafting.count_fixes("table", inv, stack, new_stack, inv, "store", player)

			if not count then
				count = no
				refresh = true
			end

			crafting.pay_items("table", inv, stack, inv, "store", player, count)

			if refresh then
				refresh_inv(meta)
			end
			return
		end
		refresh_inv(meta)
	end,
	on_metadata_inventory_take = function(pos, lname, i, stack, player)
		local meta = minetest.get_meta(pos)
		if lname == "output" then
			local inv = meta:get_inventory()
			local new_stack = inv:get_stack(lname, i)
			local count, refresh = crafting.count_fixes("table", inv, stack, new_stack, player:get_inventory(), "main", player) 

			if not count then
				count = stack:get_count()
				refresh = true
			end

			crafting.pay_items("table", inv, stack, player:get_inventory(), "main", player, count)

			if refresh then
				refresh_inv(meta)
			end
			return
		end
		refresh_inv(meta)
	end,
	on_metadata_inventory_put = function(pos, lname, i, stack, player)
		local meta = minetest.get_meta(pos)
		refresh_inv(meta)
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local size = inv:get_size("output")
		local row = meta:get_int("row")
		if fields.next then
			row = row + 6
		elseif fields.prev  then
			row = row - 6
		else
			return
		end
		local form, row = make_formspec(row, size)
		meta:set_int("row", row)
		meta:set_string("formspec", form)
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("store")
	end,
	--allow_metadata_inventory_take = function(pos,lname,i,stack,player) end,
})
