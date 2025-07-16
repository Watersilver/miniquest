@tool
extends Node2D
class_name Sight

@onready var _area_2d: Area2D = %Area2D
@onready var _collision_shape_2d: CollisionShape2D = %CollisionShape2D
@onready var _ray_cast_2d: RayCast2D = %RayCast2D


@export var radius := 80.0
@export_flags_2d_physics var occlusion_mask := 0
@export_flags_2d_physics var detectables_mask := 256


var _detected_areas: Array[Area2D] = []
func get_detected_areas():
	return _detected_areas.duplicate()

var _detected_bodies: Array[Node2D] = []
func get_detected_bodies():
	return _detected_bodies.duplicate()


func get_detected_average_direction() -> Vector2:
	var v := Vector2(0, 0)
	
	for a in _detected_areas:
		v += a.global_position - global_position
	for b in _detected_bodies:
		v += b.global_position - global_position
	
	return v.normalized()


func _is_target_visible(target: Node2D) -> bool:
	if _ray_cast_2d.collision_mask == 0:
		return true
	var gp := target.global_position
	if target.get_parent() is Player:
		gp.y -= 3
	_ray_cast_2d.target_position = gp - _ray_cast_2d.global_position
	_ray_cast_2d.force_update_transform()
	_ray_cast_2d.force_raycast_update()
	return not _ray_cast_2d.is_colliding()


func force_update_components() -> void:
	_area_2d.collision_mask = detectables_mask
	_collision_shape_2d.shape.radius = radius
	_ray_cast_2d.collision_mask = occlusion_mask


func _ready() -> void:
	force_update_components()


func _physics_process(_delta: float) -> void:
	force_update_components()
	
	if not Engine.is_editor_hint():
		_detected_areas.clear()
		for o in _area_2d.get_overlapping_areas():
			if _is_target_visible(o):
				_detected_areas.push_back(o)
		
		_detected_bodies.clear()
		for o in _area_2d.get_overlapping_bodies():
			if _is_target_visible(o):
				_detected_bodies.push_back(o)
