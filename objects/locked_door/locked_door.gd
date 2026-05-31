extends Node2D


@onready var closed: MainTileset = %Closed
@onready var open: MainTileset = %Open
@onready var lock_body: RigidBody2D = %LockBody
@onready var lock: Sprite2D = %Lock
@onready var player_detector: Area2D = %PlayerDetector


func _ready() -> void:
	if Refs.level_manager:
		var uid := Refs.level_manager.get_unique_name(self)
		open.enable_trigger = uid
		if Global.session.saved_data.object_flags.has(uid) and Global.session.saved_data.object_flags[uid]:
			closed.queue_free()
			lock_body.queue_free()
			player_detector.queue_free()


func _process(_delta: float) -> void:
	if Global.session.saved_data.keys <= 0: return
	if not lock_body: return
	if not player_detector: return
	if not Refs.level_manager: return
	
	if player_detector.has_overlapping_bodies():
		var b := player_detector.get_overlapping_bodies()[0]
		if b.get_parent() is Player:
			var p: Player = b.get_parent()
			if p.body.is_on_wall():
				Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
				Global.session.saved_data.keys -= 1
				player_detector.queue_free()
				closed.queue_free()
				lock.region_rect.position.x += 16
				lock_body.freeze = false
				lock_body.apply_impulse(Vector2(randf() * 50 * [1,-1].pick_random(), -randf() * 50 - 50))
				lock_body.apply_torque_impulse(randf() * 100 * [1,-1].pick_random() + 50 * [1,-1].pick_random())
