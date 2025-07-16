extends CharacterBody2D

@onready var sprite_2d: Sprite2D = %Sprite2D

@onready var common_enemy: CommonEnemy = %CommonEnemy

const JUMP_VELOCITY = -100.0


const _PERIOD := 2.0
@export var secs_till_jump := _PERIOD

var _recovery_timer := 0.01

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX


func _on_died():
	sprite_2d.flip_v = false
	sprite_2d.frame_coords.x = 0
	sprite_2d.frame_coords.y = 18


func _ready() -> void:
	common_enemy.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	
	if common_enemy.is_dead():
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			sprite_2d.frame_coords.y = 19
		if _death_timer < 0:
			queue_free()
		if not common_enemy.is_frozen:
			_death_timer -= delta
		return
	
	if common_enemy.is_hurt():
		sprite_2d.frame_coords.y = 18
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if secs_till_jump <= 0 and is_on_floor() and _recovery_timer <= 0:
		velocity.y = JUMP_VELOCITY
		secs_till_jump = _PERIOD
	
	var prev_floor := is_on_floor()
	
	move_and_slide()
	
	if is_on_floor():
		if not prev_floor:
			_recovery_timer = 0.1
		
		if _recovery_timer > 0:
			sprite_2d.frame_coords.y = 8
		elif _PERIOD - secs_till_jump > 1.5:
			sprite_2d.frame_coords.y = 8
		else:
			sprite_2d.frame_coords.y = 6
		
		secs_till_jump -= delta
		_recovery_timer -= delta
	else:
		sprite_2d.frame_coords.y = 7
		
		if velocity.y < 0:
			sprite_2d.flip_v = true
		else:
			sprite_2d.flip_v = false
		
		if common_enemy.can_see_target():
			sprite_2d.flip_h = common_enemy.get_sight_target_relative_direction().x < 0
