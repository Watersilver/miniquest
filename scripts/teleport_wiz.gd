extends Activatable

func activate() -> void:
	#var new_player_pos := Vector2(80, 84)
	#Refs.level_manager.call_deferred("go_to_room", dest, new_player_pos)
	var dest := Refs.level_manager.get_player_coordinates() + Vector2i(0, -1)
	Refs.level_manager.call_deferred("go_to_room", dest, Refs.level_manager.player.body.global_position)
