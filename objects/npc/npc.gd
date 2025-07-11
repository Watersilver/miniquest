extends Area2D


@export_multiline var text: Array[String] = ["I greet you and it's great to meet you"]
@export_multiline var no_shop_items_override: Array[String] = []
## Default facing should be right
@export var face_player := true


## Override for conditional text checks
func get_text():
	if no_shop_items_override.size() > 0:
		if get_tree().get_nodes_in_group("shop_items").size() == 0:
			return no_shop_items_override
	return text


func _physics_process(_delta: float) -> void:
	if face_player:
		var d := Refs.level_manager.player.body.global_position.direction_to(global_position)
		scale.x = -sign(d.x)
		if scale.x == 0: scale.x = 1
	
	if has_overlapping_areas() and Input.is_action_just_pressed("ui_accept"):
		MessageDisplayer.display(get_text())
