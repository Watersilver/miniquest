@tool
extends Level

func query_room_info() -> void:
	var i := 0
	
	var supspiciously_named_rooms: Array[Room] = []
	
	if search_room_keyword != "":
		print("Printing rooms containing '" + search_room_keyword + "' (case insensitive)")
	for c in get_children():
		if c is Room:
			i += 1
			
			if c.name.contains("Room"):
				supspiciously_named_rooms.push_back(c)
			
			if search_room_keyword != "":
				if c.name.containsn(search_room_keyword):
					print(c.name, ' .. coords:', Vector2i(int(c.position.x / float(Room.BLOCK_WIDTH)), int(c.position.y / float(Room.BLOCK_HEIGHT))))
	
	print("Rooms amount: ", i)
	for r in supspiciously_named_rooms:
		print(
			r.name,
			' .. coords:',
			Vector2i(int(r.position.x / float(Room.BLOCK_WIDTH)), int(r.position.y / float(Room.BLOCK_HEIGHT)))
		)

@export_tool_button("Get room info") var room_info_query_action = query_room_info
@export var search_room_keyword := ""

func query_chest_info() -> void:
	var chests := get_tree().get_nodes_in_group("chests")
	print("placed chests: ", chests.size())
	
	var gold_amount := 0
	var life_amount := 0
	var crit_amount := 0
	var enha_amount := 0
	
	for chest in chests:
		if chest is Chest:
			match chest.content_type:
				Chest.Content.GOLD:
					gold_amount += chest.amount
				Chest.Content.LIFE:
					life_amount += chest.amount
				Chest.Content.CRIT:
					crit_amount += chest.amount
				Chest.Content.ENHANCEMENT:
					enha_amount += chest.amount
	
	print("Gold amount: ", gold_amount)
	print("Life amount: ", life_amount)
	print("Crit amount: ", crit_amount)
	print("Enhancement amount: ", enha_amount)

@export_tool_button("Get chest info") var query_chest_info_action = query_chest_info

func _npc_amount_recursion(node: Node, amount := 0) -> int:
	for child in node.get_children():
		amount += _npc_amount_recursion(child, amount)
	if node is DlgTree:
		amount += node.cost
	return amount

func query_expenses_info() -> void:
	var shop_items := get_tree().get_nodes_in_group("shop_items")
	var required_shop_items_amount := 0
	var optional_shop_items_amount := 0
	var shop_items_amount := 0
	for shop_item in shop_items:
		if shop_item is ShopItem:
			shop_items_amount += shop_item.price
			if shop_item.item == ShopItem.Item.WEAPON:
				required_shop_items_amount += shop_item.price
			else:
				optional_shop_items_amount += shop_item.price
	print("Required shop items amount: ", required_shop_items_amount)
	print("Optional shop items amount: ", optional_shop_items_amount)
	print("Total shop items amount: ", shop_items_amount)
	
	var npcs := get_tree().get_nodes_in_group("npcs")
	var npcs_amount := 0
	for node in npcs:
		npcs_amount += _npc_amount_recursion(node)
	print("Npcs amount: ", npcs_amount)
	
	print("Total amount: ", shop_items_amount + npcs_amount)

@export_tool_button("Get expenses info") var query_expenses_info_action = query_expenses_info
