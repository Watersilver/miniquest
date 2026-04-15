@tool
extends Node2D

@onready var sprite_2d: Sprite2D = %Sprite2D

@onready var common_enemy: CommonEnemy = %CommonEnemy

enum Type {
	FLOOR,
	CEIL
}
@export var type := Type.FLOOR

@export var direction := Global.Direction.LEFT

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX


func _on_died():
	sprite_2d.frame_coords.y = 36


func _ready() -> void:
	sprite_2d.flip_h = direction == Global.Direction.LEFT
	sprite_2d.flip_v = type == Type.CEIL
	common_enemy.position.y = -2 if type == Type.CEIL else 0
	
	if Engine.is_editor_hint():
		return
	
	common_enemy.died.connect(_on_died)


func _physics_process(_delta: float) -> void:
	sprite_2d.flip_h = direction == Global.Direction.LEFT
	sprite_2d.flip_v = type == Type.CEIL
	common_enemy.position.y = -2 if type == Type.CEIL else 0
	
	if Engine.is_editor_hint():
		sprite_2d.frame_coords.x = 2
		sprite_2d.frame_coords.y = 35
		return
	
	if common_enemy.is_dead():
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			sprite_2d.frame_coords.y = 37
		if _death_timer < 0:
			queue_free()
		return
	
	if common_enemy.is_hurt():
		sprite_2d.frame_coords.y = 36
		return
