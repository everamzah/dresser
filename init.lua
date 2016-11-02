--[[ Dresser mod for Minetest
     skins.txt, inside world directory,
     is formatted as `name:description'
     (without the quotes), and is auto-
     generated.

     Copyright 2016 James Stevenson (everamzah)
     Licensed under the LGPL 3.0, see LICENSE.
     Textures licensed separately, see README.]]

local dresser = {}	-- Position of Dresser as a string.
local skin_db = {}

local mod_name = minetest.get_current_modname()
local world_path = minetest.get_worldpath()

local load = function ()
	local fh, err = io.open(world_path .. "/skins.txt", "r")
	if err then
		skin_db = {{"sam", "Sam"}, {"c55", "Celeron55"}}
		minetest.log("action", "[" .. mod_name .. "] No skins.txt found!  Loading default skins.")

		local fh, err = io.open(world_path .. "/skins.txt", "w")
		if err then
			minetest.log("action", "[" .. mod_name .. "] Unable to write skins.txt!")
			return
		end

		fh:write("sam:Sam\nc55:Celeron55")
		minetest.log("action", "[" .. mod_name .. "] Created skins.txt.")
		return
	end
	while true do
		local line = fh:read()
		if line == nil then
			break
		end
		local paramlist = string.split(line, ":")
		local w = {
			paramlist[1],
			paramlist[2]
		}
		table.insert(skin_db, w)
	end
	fh:close()
	minetest.log("action", "[" .. mod_name .. "] " .. table.getn(skin_db) .. " skins loaded.")
end

load()


local function get_skin(player)
	local skin = player:get_properties().textures[1]
	return skin
end

local function show_formspec(name, skin, spos)
	minetest.show_formspec(name, "dresser:dresser",
		"size[8,8.5]" ..
		default.gui_bg_img ..
		default.gui_slots ..
		"label[0,1;Skin]" ..
		"list[detached:skin_" .. name .. ";main;0,1.5;1,1]" ..
		"image[0.75,0.1;4,4;dresser_skin_" .. skin .. "_item.png]" ..
		"label[4,0;Storage]" ..
		"list[nodemeta:" .. spos .. ";main;4,0.5;4,3]" ..
		"list[current_player;main;0,4.25;8,1;]" ..
		"list[current_player;main;0,5.5;8,3;8]" ..
		default.get_hotbar_bg(0, 4.25))
end

-- Dresser node and its craft recipe:
minetest.register_node("dresser:dresser", {
	description = "Dresser",
	paramtype2 = "facedir",
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"dresser_dresser.png",
		"dresser_dresser.png",
	},
	sounds = default.node_sound_wood_defaults(),
	groups = {choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Dresser")
		local inv = meta:get_inventory()
		inv:set_size("main", 4 * 3)
	end,
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local spos = pos.x .. "," .. pos.y .. "," .. pos.z
		dresser[clicker:get_player_name()] = spos
		local skin
		local current_skin = get_skin(clicker)

		for _, v in pairs(skin_db) do
			if current_skin == "dresser_skin_" .. v[1] .. ".png" then
				skin = v[1]
			elseif not skin then
				skin = "sam"
			end
		end

		show_formspec(clicker:get_player_name(), skin, spos)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.get_item_group(stack:get_name(), "skin") == 1 then
			return 1
		else
			return 0
		end
	end
})

minetest.register_craft({
	output = "dresser:dresser",
	recipe = {
		{"group:wood", "group:stick", "group:wood"},
                {"group:wood", "group:wool", "group:wood"},
                {"group:wood", "group:wool", "group:wood"},
	}
})

-- Register skin craftitems.
for _, v in pairs(skin_db) do
	minetest.register_craftitem("dresser:skin_" .. v[1], {
		description = v[2],
		inventory_image = "dresser_skin_" .. v[1] .. "_item.png",
		groups = {skin = 1},
		stack_max = 1
	})
end


---[[
minetest.register_on_newplayer(function(player)
	local name = player:get_player_name()
	minetest.after(0.1, function ()
		local inv = minetest.get_inventory{type = "player", name = name}
		inv:set_stack("skin", 1, {name = "dresser:skin_sam"})

		local detached = minetest.get_inventory{type = "detached", name = "skin_" .. name}
		detached:set_stack("main", 1, {name = "dresser:skin_sam"})
	end)
end)
--]]

minetest.register_on_joinplayer(function(player)
	-- FIXME Old players missing the skin inventory do not receive their skin

	local skin_inv = player:get_inventory()
	skin_inv:set_size("skin", 1)

	for _, v in pairs(skin_db) do
		if skin_inv:contains_item("skin", {name = "dresser:skin_" .. v[1]}) then
			player:set_properties({textures = {"dresser_skin_" .. v[1] .. ".png"}})
		end
	end

	local skin = minetest.create_detached_inventory("skin_" .. player:get_player_name(), {
		allow_put = function(inv, listname, index, stack, player)
			if minetest.get_item_group(stack:get_name(), "skin") == 1 then
				return 1
			else
				return 0
			end
		end,
		allow_take = function(inv, listname, index, stack, player)
			return 0
		end,
		on_put = function(inv, listname, index, stack, player)
			local name = player:get_player_name()

			for _, v in pairs(skin_db) do
				if stack:get_name() == "dresser:skin_" .. v[1] then
					player:set_properties({textures = {"dresser_skin_" .. v[1] .. ".png"}})
					skin_inv:set_stack("skin", 1, {name = "dresser:skin_" .. v[1]})
					return show_formspec(name, v[1], dresser[player:get_player_name()])
				end
			end
		end,
	})
	skin:set_size("main", 1)

	for _, v in pairs(skin_db) do
		if skin_inv:contains_item("skin", {name = "dresser:skin_" .. v[1]}) then
			skin:set_stack("main", 1, {name = "dresser:skin_" .. v[1]})
		end
	end
end)

minetest.register_on_leaveplayer(function(player)
	dresser[player:get_player_name()] = nil
end)
