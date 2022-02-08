local digtime = 0.1
local caps = {times = {digtime, digtime, digtime}, uses = 0, maxlevel = 256}
local function destroy(drops, npos, cid, c_air, c_fire,
		on_blast_queue, on_construct_queue,
		ignore_protection, ignore_on_blast, owner)
	if not ignore_protection and minetest.is_protected(npos, owner) then
		return cid
	end

	local def = cid_data[cid]

	if not def then
		return c_air
	elseif not ignore_on_blast and def.on_blast then
		on_blast_queue[#on_blast_queue + 1] = {
			pos = vector.new(npos),
			on_blast = def.on_blast
		}
		return cid
	elseif def.flammable then
		on_construct_queue[#on_construct_queue + 1] = {
			fn = basic_flame_on_construct,
			pos = vector.new(npos)
		}
		return c_fire
	else
		local node_drops = minetest.get_node_drops(def.name, "")
		for _, item in pairs(node_drops) do
			add_drop(drops, item)
		end
		return c_air
	end
end

minetest.register_tool("superpick:pick", {
	description = "Super Pickaxe",
	inventory_image = "superpick.png",
	range = 35,
	groups = {not_in_creative_inventory = 1},
	tool_capabilities = {
		full_punch_interval = 0.1,
		max_drop_level = 256,
		groupcaps = {
			unbreakable =   caps,
			dig_immediate = {times = {[2] = digtime, [3] = digtime}, uses = 0, maxlevel = 256},
			fleshy =	caps,
			choppy =	caps,
			bendy =	caps,
			cracky =	caps,
			crumbly = caps,
			snappy =	caps,
		},
		damage_groups = {fleshy = 1000}
	},
	on_drop = function(itemstack, player)
	local name = player:get_player_name()
	minetest.chat_send_player(name, "Dont drop!") end,

	on_secondary_use = function(itemstack, user)
local meta = itemstack:get_meta()
minetest.show_formspec(user:get_player_name(), "superpick:setrad",
	"size[3,1.5]"..
	"field[0.3,0.5;3,1;rad;SuperPick Radius:;"..meta:get_int('pickradius').."]"..
	"button_exit[0.5,1;2,1;submit;Submit]")
end,

	on_place = function(itemstack, user, pointed_thing)
			if not minetest.check_player_privs(user, "superpick") then
			return {name = ""}
			end

		local pos = minetest.get_pointed_thing_position(pointed_thing)
		if pointed_thing.type == "node" and pos ~= nil then
local meta = itemstack:get_meta()
local ctrl = user:get_player_control()
if ctrl.sneak then
minetest.show_formspec(user:get_player_name(), "superpick:setrad",
	"size[3,1.5]"..
	"field[0.3,0.5;3,1;rad;SuperPick Radius:;"..meta:get_int('pickradius').."]"..
	"button_exit[0.5,1;2,1;submit;Submit]")
else
local radius = meta:get_int("pickradius")
			for z = -radius, radius do
			for y = -radius, radius do
			for x = -radius, radius do
			minetest.remove_node({x = pos.x + x, y = pos.y + y, z = pos.z + z})
			end end end
		end end
end})

minetest.register_on_player_receive_fields(function(player, formname, fields)
if formname == "superpick:setrad" then
local playername = player:get_player_name()
local witem = player:get_wielded_item()
		if witem:get_name() == "superpick:pick" then
			if fields.rad then
				local rad = tonumber(fields.rad)
				if not rad or rad < 0 or rad > 10 then
					minetest.chat_send_player(playername, "Invalid value or out of bounds")
					return
				end
				local meta = witem:get_meta()
				minetest.chat_send_player(playername, "SuperPick Radius set to "..minetest.colorize("#FF0",rad))
				meta:set_int("pickradius", rad)
				player:set_wielded_item(witem)
			end
end end end)

minetest.register_alias("superpick", "superpick:pick")
minetest.register_privilege("superpick", {description = "Ability to wield the mighty admin pickaxe!",give_to_singleplayer = false})

minetest.register_on_punchnode(function(pos, node, puncher)
	if puncher:get_wielded_item():get_name() == "superpick:pick"
	and minetest.get_node(pos).name ~= "air" then
			if not minetest.check_player_privs(
				puncher:get_player_name(), {superpick = true}) then
			puncher:set_wielded_item("")
			minetest.log("action", puncher:get_player_name() ..
			" tried to use a Super Pickaxe!")
			return
		end
		minetest.log(
			"action",
			puncher:get_player_name() ..
			" digs " ..
			minetest.get_node(pos).name ..
			" at " ..
			minetest.pos_to_string(pos) ..
			" using a Superpick."
		)
		-- The node is removed directly, which means it even works
		-- on non-empty containers and group-less nodes
		minetest.remove_node(pos)
		-- Run node update actions like falling nodes
		minetest.check_for_falling(pos)
	end
end)

minetest.register_on_mods_loaded(function()
	for node in pairs(minetest.registered_nodes) do
		local def = minetest.registered_nodes[node]
		for i in pairs(def) do
			if i == "on_punch" then
				local rem = def.on_punch
				local function new_on_punch(pos, new_node, puncher, pointed_thing)
					if puncher:get_wielded_item():get_name() == "superpick:pick"
					and minetest.get_node(pos).name ~= "air" then
					minetest.remove_node(pos)
					minetest.check_for_falling(pos)
					end
					return rem(pos, new_node, puncher, pointed_thing)
				end
				minetest.override_item(node, {
					on_punch = new_on_punch
				})
			end
		end
	end
end)
