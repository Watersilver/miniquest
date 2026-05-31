@tool
extends Node2D
class_name HellSerpent

@onready var sprite_2d: Sprite2D = $Sprites/Sprite2D
@onready var common_enemy: CommonEnemy = $Sprites/Sprite2D/CommonEnemy
@onready var sprites: Node2D = %Sprites

const FRAME_HEAD_1 := 0
const FRAME_HEAD_2 := 1
const FRAME_HEAD_3 := 2
const FRAME_BODY_1 := 4
const FRAME_BODY_2_AND_3 := 6

const RECURSIONS := 13

@export_range(0, 160) var distance := 0.0
@export var direction := Global.Direction.RIGHT
@export var target := 0
@export var speed_factor := 2.5
@export var sin_recursions := 10

var _current_target := 0
var _moving := false
var _t := 0.0
var _dead := false
var _death_timer := 0.0
var _death_phase := 0


func is_moving() -> bool:
	return _moving


func stop() -> void:
	target = 0
	_moving = false


func is_dead() -> bool:
	return _dead


func die() -> void:
	_dead = true
	sprites.modulate.r = 20
	sprites.modulate.g = 20
	sprites.modulate.b = 20
	for spr in sprites.get_children():
		if spr is Sprite2D:
			if spr.frame_coords.x != FRAME_BODY_1 and spr.frame_coords.x != FRAME_BODY_2_AND_3:
				spr.frame_coords.y += 1
			var ce: CommonEnemy = spr.get_node("CommonEnemy")
			ce.harmless = true
			ce.hitpoints = -1


func _vanish() -> void:
	for spr in sprites.get_children():
		if spr is Sprite2D:
			if spr.frame_coords.x != FRAME_BODY_1 and spr.frame_coords.x != FRAME_BODY_2_AND_3:
				spr.frame_coords.y += 1
			else:
				spr.frame_coords.x = 0
				spr.frame_coords.y -= 2


func _recursive_sin(x: float, recursions: int) -> float:
	if recursions > 0:
		recursions -= 1
		x = _recursive_sin(x, recursions)
	return sin(x)


var _calculated_recursions := sin_recursions
var _normalizer := 0.5 / _recursive_sin(-cos(PI), sin_recursions)
func _get_distance_progress(time_secs: float):
	if _calculated_recursions != sin_recursions:
		print('recalculating recursions normalizer')
		_normalizer = 0.5 / _recursive_sin(-cos(PI), sin_recursions)
		_calculated_recursions = sin_recursions
	return _recursive_sin(-cos(time_secs * speed_factor), sin_recursions) * _normalizer + 0.5


func _ready() -> void:
	sprite_2d.flip_h = direction != Global.Direction.RIGHT
	
	for spr in sprites.get_children():
		if spr is Sprite2D:
			if sprite_2d.flip_h:
				spr.flip_h = not spr.flip_h


func _physics_process(delta: float) -> void:
	if _dead:
		match _death_phase:
			0:
				if _death_timer > 2:
					_death_phase = 1
					_vanish()
			1:
				if _death_timer > 4:
					_death_phase = 2
					queue_free()
		_death_timer += delta
		return
	
	sprite_2d.flip_h = direction != Global.Direction.RIGHT
	
	var segments := floori(distance / 8.0)
	var prev_pos := sprite_2d.position.x
	sprite_2d.position.x = direction * (segments * 8.0 + 4)
	
	if prev_pos != sprite_2d.position.x:
		common_enemy.harmless = true
		common_enemy._haz_shape_2d.disabled = true
	else:
		common_enemy.harmless = false
		common_enemy._haz_shape_2d.disabled = false
	
	var sprchil: Array[Sprite2D] = []
	
	for spr in sprites.get_children():
		if spr is Sprite2D:
			sprchil.push_back(spr)
	
	sprchil.erase(sprite_2d)
	
	if segments > sprchil.size():
		for _i in segments - sprchil.size():
			var new_seg := sprite_2d.duplicate()
			var comen: CommonEnemy = new_seg.get_child(0)
			comen.haz_shape = Rect2(0, 0, 8, 8)
			comen.harmless = false
			sprites.add_child(new_seg)
			comen._haz_shape_2d.disabled = false
			comen._haz_shape_2d.shape = comen._haz_shape_2d.shape.duplicate()
			var sh := comen._haz_shape_2d.shape
			comen._haz_shape_2d.position = Vector2(0, 0)
			if sh is RectangleShape2D:
				sh.size = Vector2(8, 8)
			if Engine.is_editor_hint():
				new_seg.owner = get_tree().edited_scene_root
				comen.owner = get_tree().edited_scene_root
			sprchil.push_back(new_seg)
	elif segments < sprchil.size():
		for _i in sprchil.size() - segments:
			var old_spr: Sprite2D = sprchil.pop_back()
			if old_spr:
				old_spr.queue_free()
	
	var i := 0
	for seg in sprchil:
		i += 1
		seg.position.x = sprite_2d.position.x - 8 * i * direction
	
	var flip := sprite_2d.flip_h
	if sprite_2d.frame_coords.x == FRAME_HEAD_1:
		flip = not flip
		if sprchil.size() > 0:
			sprchil[0].frame_coords.x = FRAME_BODY_1
			sprchil.pop_front()
	
	for seg in sprchil:
		seg.frame_coords.x = FRAME_BODY_2_AND_3
		seg.flip_h = flip
	
	var prog := fmod(distance, 8)
	if prog < 2.6666666666666665:
		sprite_2d.frame_coords.x = FRAME_HEAD_1
		common_enemy.haz_shape.position.x = -2.5 * direction
		common_enemy.haz_shape.size.x = 3
	elif prog < 5.333333333333333:
		sprite_2d.frame_coords.x = FRAME_HEAD_2
		common_enemy.haz_shape.position.x = -1 * direction
		common_enemy.haz_shape.size.x = 6
	else:
		sprite_2d.frame_coords.x = FRAME_HEAD_3
		common_enemy.haz_shape.position.x = 0
		common_enemy.haz_shape.size.x = 8
	
	if not _moving:
		if target != 0:
			_t = 0.0
			_moving = true
			_current_target = absi(target)
			if target < 0:
				direction = Global.Direction.LEFT if direction == Global.Direction.RIGHT else Global.Direction.RIGHT
	else:
		_t += delta
		var prev_d := distance
		distance = _get_distance_progress(_t) * _current_target * 8
		if prev_d > distance and abs(distance) - 0.05 <= 0:
			distance = 0
			target = 0
			_moving = false
			_current_target = 0
	
	if Engine.is_editor_hint():
		return
