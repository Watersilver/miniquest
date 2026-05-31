extends Node2D


@export var trigger_area: Area2D
@export var fall_speed := 55.0
@export var delay := 2.0

const TARGET_Y := 88.0


var _done := false
var t := 0.0


func get_id() -> String:
	if not Refs.level_manager: return ""
	return Refs.level_manager.get_unique_name(self)


func is_triggered() -> bool:
	if not Refs.level_manager: return false
	return Global.session.saved_data.object_flags.has(get_id()) and Global.session.saved_data.object_flags[get_id()]


func trigger() -> void:
	if not Refs.level_manager: return
	Global.session.saved_data.object_flags[get_id()] = true


func _on_trigger_area_entered(_node) -> void:
	trigger()


func _ready() -> void:
	if is_triggered():
		position.y = TARGET_Y
		_done = true
	else:
		if is_instance_valid(trigger_area):
			trigger_area.body_entered.connect(_on_trigger_area_entered)
			trigger_area.area_entered.connect(_on_trigger_area_entered)


func _process(delta: float) -> void:
	if not _done:
		if is_triggered():
			if t > delay:
				position.y += delta * fall_speed
				if position.y >= TARGET_Y:
					_done = true
					position.y = TARGET_Y
			t += delta
