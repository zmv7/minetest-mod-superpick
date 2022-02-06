local digtime = 0.1
local caps = {times = {digtime, digtime, digtime}, uses = 0, maxlevel = 256}
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
	minetest.chat_send_player(name, "Dont drop!")
end
})
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