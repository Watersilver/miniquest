extends CharacterBody2D

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var sight: Area2D = %Sight

const JUMP_VELOCITY = -100.0


const _PERIOD := 2.0
@export var secs_till_jump := _PERIOD

var _recovery_timer := 0.01

func _physics_process(delta: float) -> void:
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
		
		for pl in sight.get_overlapping_bodies():
			sprite_2d.flip_h = pl.global_position.x - global_position.x < 0
