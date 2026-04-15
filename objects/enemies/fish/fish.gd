@tool
extends Node
class_name Fish

@onready var sprite: Sprite2D = %Sprite
@onready var body: Node2D = %Body
@onready var water_detector: Area2D = %WaterDetector
@onready var water_detector_2: Area2D = %WaterDetector2
@onready var arrow: RayCast2D = %Arrow
@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var detection_shape: CollisionShape2D = %DetectionShape
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

enum Type {
	PATROL,
	RANDOM,
	CHASE
}

class State:
	var _f: Fish
	func _init(fish: Fish) -> void:
		_f = fish
	func update(_delta: float):
		pass

class Still extends State:
	var _t := 2.0
	var _t2 := 0.0
	var _chasing := false
	func _init(fish: Fish) -> void:
		super(fish)
		if _f.type == _f.Type.CHASE:
			_t = 1
	func update(delta: float):
		_f._velocity -= _f._velocity * 1.5 * delta
		if not _f.water_detector.has_overlapping_areas():
			_f._state = _f.Airborne.new(_f)
			return
		match _f.type:
			_f.Type.RANDOM, _f.Type.PATROL:
				var yd := ceili(signf(_f.direction.y))
				if yd == 0: yd = 1
				if _t > 1.85:
					_f.sprite.frame_coords.x = 1 + yd
				elif _t > 1.5:
					_f.sprite.frame_coords.x = 1
				elif _t > 1.25:
					_f.sprite.frame_coords.x = 1 - yd
				elif _t > 1:
					_f.sprite.frame_coords.x = 1
				if _t <= 0.0:
					_f._state = _f.Swimming.new(_f)
				_t -= delta
			_f.Type.CHASE:
				if _chasing:
					var yd := ceili(signf(_f.direction.y))
					if yd == 0: yd = 1
					if _t > 0.9:
						_f.sprite.frame_coords.x = 1 + yd
					elif _t > 0.8:
						_f.sprite.frame_coords.x = 1
					elif _t > 0.7:
						_f.sprite.frame_coords.x = 1 - yd
					elif _t > 0.5:
						_f.sprite.frame_coords.x = 1
				else:
					_t2 += delta
					_f.sprite.frame_coords.x = floor(fmod(_t2 * 2, 4))
				_f._velocity -= _f._velocity * 1.5 * delta
				_t -= delta
				var d := Refs.level_manager.player.body.global_position - _f.body.global_position
				if _t < 0:
					_chasing = false
					if d.length() < _f.chase_distance:
						_f.direction = d
						_f._state = _f.Swimming.new(_f)

class Swimming extends State:
	var _move := false
	var _select_new := true
	func update(_delta: float):
		var chase := false
		match _f.type:
			_f.Type.RANDOM:
				if _select_new:
					_f.direction = Vector2(1, 0).rotated(randf() * TAU)
					_f.water_detector_2.position = _f._get_wd2pos()
					_select_new = false
				elif not _f.water_detector_2.has_overlapping_areas():
					_select_new = true
				else:
					_move = true
			_f.Type.CHASE:
				_move = true
				chase = true
			_f.Type.PATROL:
				if _f.patrol_directions.size() > 0:
					_f.direction = _f.patrol_directions[_f._patrol_dir_i % _f.patrol_directions.size()]
					_f._patrol_dir_i += 1
				_move = true
		
		if _move:
			_f._velocity = _f.direction * 30
			var s := Still.new(_f)
			s._chasing = chase
			_f._state = s

class Airborne extends State:
	var _t := 0.0
	var _grav := 50
	func _init(fish: Fish) -> void:
		super(fish)
		_f._velocity *= 10
		if _f._velocity.length() < _f.jump_min_speed:
			_f._velocity = _f._velocity.normalized() * _f.jump_min_speed
		if _f._velocity.length() > _f.jump_max_speed:
			_f._velocity = _f._velocity.normalized() * _f.jump_max_speed
	
	func update(delta: float):
		_f.sprite.frame_coords.x = floor(fmod(_t * 4, 4))
		
		_t += delta
		
		_f._velocity.y += _grav * delta
		
		_f.sprite.rotation = _f._velocity.angle() + (PI if _f.sprite.flip_h else 0.0)
		
		if _f.water_detector.has_overlapping_areas():
			var s := _f.Still.new(_f)
			s._t = 4.0
			_f._state = s


const SWIM_FRAME := 44
const HURT_FRAME := 47
const DEATH_FRAME := 48
const _DEATH_TIMER_MAX := 0.15

@export var type := Type.PATROL
@export var can_leave_water := true
@export var direction := Vector2(1, 0)
@export var patrol_directions: Array[Vector2] = []
@export var patrol_left_lim: Marker2D
@export var patrol_right_lim: Marker2D
@export var chase_distance := 32.0
@export var jump_min_speed := 30.0
@export var jump_max_speed := 50.0
@export var detection_radius := 24.0

var _state: State = Still.new(self)
var _velocity := Vector2(0, 0)
var _updated_once := false
var _death_timer := _DEATH_TIMER_MAX
var _patrol_dir_i := 0

func _get_wd2pos() -> Vector2:
	return direction.normalized() * detection_radius


func _determine_flip_h():
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false


func _ready() -> void:
	sprite.frame_coords.y = SWIM_FRAME + type
	_determine_flip_h()
	if Engine.is_editor_hint():
		return
	else:
		$Body/Area2D.queue_free()
		arrow.queue_free()


func _physics_process(delta: float) -> void:
	_determine_flip_h()
	
	if Engine.is_editor_hint():
		sprite.frame_coords.y = SWIM_FRAME + type
		water_detector_2.position = _get_wd2pos()
		arrow.target_position = water_detector_2.position
		var s := detection_shape.shape
		if s is CircleShape2D:
			s.radius = detection_radius
		return
	
	direction = direction.normalized()
	water_detector_2.position = _get_wd2pos()
	match type:
		Type.PATROL:
			if patrol_right_lim and body.position.x > patrol_right_lim.position.x:
				direction.x = -abs(direction.x)
				_velocity.x = -abs(_velocity.x)
			if patrol_left_lim and body.position.x < patrol_left_lim.position.x:
				direction.x = abs(direction.x)
				_velocity.x = abs(_velocity.x)
	
	sprite.frame_coords.y = SWIM_FRAME + type
	
	sprite.rotation = 0
	
	if common_enemy.is_dead():
		sprite.frame_coords.x = 0
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			sprite.frame_coords.y = DEATH_FRAME
		if _death_timer < 0:
			queue_free()
		if not common_enemy.is_frozen:
			_death_timer -= delta
	elif common_enemy.is_hurt():
		sprite.frame_coords.x = 0
		sprite.frame_coords.y = HURT_FRAME
	elif _updated_once:
		_state.update(delta)
		
		body.position += _velocity * delta
		
		#if not visible_on_screen_notifier_2d.is_on_screen():
			#queue_free()
	
	if patrol_directions.size() > 0:
		_patrol_dir_i = _patrol_dir_i % patrol_directions.size()
	_updated_once = true
