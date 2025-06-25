@tool

extends Area2D

@onready var sprite: Sprite2D = %Sprite
@onready var static_body_2d: StaticBody2D = %StaticBody2D
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D

func _determine_state():
	var new_reg_rect := Rect2(8,48 + 8 * color,8,8)
	var h := sprite.texture.get_height()
	
	if new_reg_rect.position.y >= h:
		new_reg_rect.position.x += 32
		new_reg_rect.position.y -= 32
	
	if solid:
		static_body_2d.set_collision_layer_value(1, true)
		static_body_2d.set_collision_layer_value(2, false)
		collision_shape_2d.one_way_collision = false
	else:
		static_body_2d.set_collision_layer_value(1, false)
		static_body_2d.set_collision_layer_value(2, true)
		collision_shape_2d.one_way_collision = true
		new_reg_rect.position.x += 16
	
	sprite.region_rect = new_reg_rect
	
	if enabled == EnabledState.INHERIT:
		if Engine.is_editor_hint():
			collision_shape_2d.set_deferred("disabled", false)
		else:
			collision_shape_2d.set_deferred("disabled", not Global.session.is_switch_active(color))
	elif enabled == EnabledState.ENABLED:
		collision_shape_2d.set_deferred("disabled", false)
	else:
		collision_shape_2d.set_deferred("disabled", true)

@export var solid := true:
	set(s):
		solid = s
		if not is_node_ready(): return
		_determine_state()

@export var color := Global.Switch.GREEN:
	set(c):
		color = c
		if not is_node_ready(): return
		_determine_state()

enum EnabledState {
	INHERIT,
	ENABLED,
	DISABLED
}

@export var enabled := EnabledState.INHERIT:
	set(e):
		enabled = e
		if not is_node_ready(): return
		_determine_state()

func _ready() -> void:
	_determine_state()

func _enter_tree() -> void:
	if is_node_ready(): _determine_state()
	if not Engine.is_editor_hint():
		Global.session.switch_activated.connect(_determine_state)

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		Global.session.switch_activated.disconnect(_determine_state)
