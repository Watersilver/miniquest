extends Area2D
class_name Npc


@export_multiline var text: Array[String] = ["I greet you and it's great to meet you"]
@export_multiline var last_item_override: Array[String] = []
@export_multiline var no_shop_items_override: Array[String] = []
## Default facing should be right
@export var face_player := true

@export var enabled_trigger := ""
@export var disabled_trigger := ""

signal getting_text()
signal end()

func _handle_triggers():
	var e := 0
	
	if enabled_trigger != "":
		if Global.session.saved_data.object_flags.has(enabled_trigger) and Global.session.saved_data.object_flags[enabled_trigger]:
			e += 1
		else:
			e -= 1
	else:
		e += 1
	
	if disabled_trigger != "":
		if Global.session.saved_data.object_flags.has(disabled_trigger) and Global.session.saved_data.object_flags[disabled_trigger]:
			e -= 1
		else:
			e += 1
	else:
		e += 1
	
	if e == 0:
		queue_free()


func _emit_end() -> void:
	end.emit()


## Override for conditional text checks
func get_text():
	var si = get_tree().get_nodes_in_group("shop_items").size()
	if si == 1 and last_item_override.size() > 0:
		return last_item_override
	elif si == 0 and no_shop_items_override.size() > 0:
		return no_shop_items_override
	getting_text.emit()
	return text


func is_destroyed() -> bool:
	if not Refs.level_manager: return false
	return Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self)) and Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)]


func _ready() -> void:
	if Refs.level_manager:
		_handle_triggers()
		
		if is_destroyed():
			visible = false
			queue_free()


func _physics_process(_delta: float) -> void:
	if face_player:
		var d := Refs.level_manager.player.body.global_position.direction_to(global_position)
		scale.x = -sign(d.x)
		if scale.x == 0: scale.x = 1
	
	if has_overlapping_areas() and Input.is_action_just_pressed("ui_accept"):
		var display := true
		for c in get_children():
			if c is DlgTree:
				c.activate()
				display = false
		if display:
			MessageDisplayer.display(get_text(), _emit_end)
