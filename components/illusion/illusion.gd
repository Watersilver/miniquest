extends Node2D

@export var break_area: Area2D

var _broken := false
var _delay := 0.0

func is_broken() -> bool:
	if _broken: return true
	if not Refs.level_manager: return false
	return Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self))

func _ready() -> void:
	_delay = 0.0
	modulate.a = 1
	if is_broken():
		queue_free()
		visible = false
		return

func _process(delta: float) -> void:
	if is_broken():
		modulate.a -= delta * 3
		if modulate.a <= 0:
			modulate.a = 0
			queue_free()
	elif break_area.get_overlapping_bodies().size() > 0:
		if _delay > 0:
			_break_illusion()
		_delay += delta

func _break_illusion():
	_broken = true
	Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
