@tool
extends CharacterBody2D
class_name EnemyWorm

@onready var sprite: AnimatedSprite2D = %Sprite
@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var rc: RayCast2D = %RayCast2D
@onready var rc2: RayCast2D = %RayCast2D2

@export var direction := Global.Direction.RIGHT
@export var max_speed := 30.0

@export var init_delay := 1.0
var _init_delay_timer := init_delay

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX
var target_x := 0.0

func _on_died():
	sprite.play("hurt")


func _ready() -> void:
	sprite.flip_h = direction == Global.Direction.LEFT
	
	if Engine.is_editor_hint():
		return
	
	target_x = position.x
	common_enemy.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	sprite.flip_h = direction == Global.Direction.LEFT
	
	if Engine.is_editor_hint():
		return
	
	var init_delay_done := _init_delay_timer <= 0
	_init_delay_timer -= delta
	
	if common_enemy.is_dead():
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			sprite.play("dead")
		if _death_timer < 0:
			queue_free()
		if not common_enemy.is_frozen:
			_death_timer -= delta
		return
	
	if common_enemy.is_hurt():
		sprite.play("hurt")
		return
	
	if sprite.animation != "move":
		sprite.play('move')
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
	if is_on_floor() and init_delay_done:
		var c: Object = rc.get_collider()
		if not c or (c is Node and not c.get_parent() is Player):
			c = rc2.get_collider()
		if c:
			if c is Node:
				if c.get_parent() is Player:
					var p: Player = c.get_parent()
					if p.body.is_on_floor():
						target_x = p.body.global_position.x
		if global_position.x == target_x:
			velocity.x = 0
			sprite.speed_scale = 0
		else:
			sprite.speed_scale = 1
			var prev_x := position.x
			var sign_prev := signf(target_x - global_position.x)
			velocity.x = sign_prev * max_speed
			move_and_slide()
			var sign_after := signf(target_x - global_position.x)
			if sign_prev != sign_after:
				global_position.x = target_x
				velocity.x = 0
				move_and_slide()
				target_x = global_position.x
			else:
				direction = Global.Direction.LEFT if sign_after < 0 else Global.Direction.RIGHT if sign_after > 0 else direction
			if prev_x == position.x:
				sprite.speed_scale = 0
	else:
		velocity.x = 0
		sprite.speed_scale = 0
		sprite.flip_h = direction == Global.Direction.LEFT
