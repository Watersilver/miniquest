extends Node

@export var delay := 1.0
@export_multiline var text: Array[String]

func delete_self() -> void:
	set_object_flag(true)
	queue_free()

func get_unique_name() -> String:
	return Refs.level_manager.get_unique_name(self)

func get_object_flag() -> bool:
	return Global.session.saved_data.object_flags.has(get_unique_name()) and Global.session.saved_data.object_flags[get_unique_name()]

func set_object_flag(val: bool) -> void:
	Global.session.saved_data.object_flags[get_unique_name()] = val

func _ready() -> void:
	if not Refs.level_manager: return
	if get_object_flag(): queue_free()

func _process(delta: float) -> void:
	if not Refs.level_manager: return
	if delay <= 0:
		delay = INF
		MessageDisplayer.display(
			text,
			delete_self
		)
	delay -= delta
