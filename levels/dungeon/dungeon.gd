@tool
extends Level

func query_room_info():
	var i := 0
	
	for c in get_children():
		if c is Room:
			i += 1
	
	print("Rooms amount: ", i)

@export_tool_button("Get room info") var room_info_query_action = query_room_info
