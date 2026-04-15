@tool

extends Area2D
class_name SwitchBlock

@onready var sprite: Sprite2D = %Sprite
@onready var static_body_2d: StaticBody2D = %StaticBody2D
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D

func _determine_state() -> void:
	# Figure out our sprite
	var new_reg_rect := Rect2(8,48 + 8 * color,8,8)
	var h := sprite.texture.get_height()
	
	if new_reg_rect.position.y >= h:
		new_reg_rect.position.x += 32
		new_reg_rect.position.y -= 32
	
	# Solid or semisolid?
	if solid:
		static_body_2d.set_collision_layer_value(1, true)
		static_body_2d.set_collision_layer_value(2, false)
		collision_shape_2d.one_way_collision = false
	else:
		static_body_2d.set_collision_layer_value(1, false)
		static_body_2d.set_collision_layer_value(2, true)
		collision_shape_2d.one_way_collision = true
		new_reg_rect.position.x += 16
	
	# Disable collisions
	var is_disabled := false
	if enabled == EnabledState.INHERIT:
		if not Engine.is_editor_hint():
			is_disabled = not Global.session.is_switch_active(color)
	elif enabled == EnabledState.DISABLED:
		is_disabled = true
	
	is_disabled = is_disabled != solid
	collision_shape_2d.set_deferred("disabled", is_disabled)
	if not is_disabled:
		new_reg_rect.position.x -= 8
	
	# Set new sprite
	sprite.region_rect = new_reg_rect

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
		var un := Refs.level_manager.get_position_name(self)
		match e:
			EnabledState.INHERIT:
				Global.session.saved_data.object_flags.erase(un)
			EnabledState.ENABLED:
				Global.session.saved_data.object_flags.set(un, true)
			EnabledState.DISABLED:
				Global.session.saved_data.object_flags.set(un, false)
		if not is_node_ready(): return
		_determine_state()
	get():
		if not Refs.level_manager:
			return EnabledState.INHERIT
		var un := Refs.level_manager.get_position_name(self)
		if not Global.session.saved_data.object_flags.has(un):
			return EnabledState.INHERIT
		if Global.session.saved_data.object_flags.get(un):
			return EnabledState.ENABLED
		else:
			return EnabledState.DISABLED

func _ready() -> void:
	add_to_group("switch_blocks")
	_determine_state()

func _enter_tree() -> void:
	if is_node_ready(): _determine_state()
	if not Engine.is_editor_hint():
		Global.session.switch_activated.connect(_determine_state)

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		Global.session.switch_activated.disconnect(_determine_state)
