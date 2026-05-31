extends Node2D
class_name Key

@export var enable_flag: String
@export var on_destroyed_flag: String

@onready var rigid_body_2d: RigidBody2D = %RigidBody2D
@onready var area_2d: Area2D = %Area2D
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

var _connected := false

func _on_screen_shake() -> void:
	if rigid_body_2d.move_and_collide(Vector2(0, 1), true):
		rigid_body_2d.apply_force(Vector2(77 * randf() * [1, -1].pick_random(), -222 - 255 * randf()), Vector2(2 * randf() * [1, -1].pick_random(), randf()))


func _on_exit_screen() -> void:
	if on_destroyed_flag != "":
		Global.session.saved_data.object_flags[on_destroyed_flag] = true
	queue_free()


func _on_body_entered(_b: Node2D) -> void:
	Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
	Global.session.saved_data.keys += 1
	queue_free()


func _ready() -> void:
	if not Refs.level_manager: return
	
	if Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self)) and Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)]:
		queue_free()
		return
	
	if on_destroyed_flag != "" and Global.session.saved_data.object_flags.has(on_destroyed_flag) and Global.session.saved_data.object_flags[on_destroyed_flag]:
		queue_free()
		return
	
	if enable_flag != "" and (not Global.session.saved_data.object_flags.has(enable_flag) or not Global.session.saved_data.object_flags[enable_flag]):
		queue_free()
		return
	
	_connected = true
	Refs.level_manager.screen_shake.connect(_on_screen_shake)
	area_2d.body_entered.connect(_on_body_entered)
	visible_on_screen_notifier_2d.screen_exited.connect(_on_exit_screen)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			if not _connected: return
			Refs.level_manager.screen_shake.disconnect(_on_screen_shake)
