extends Node2D

@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var a: AnimatedSprite2D = %AnimatedSprite2D

@export var facing := Global.Direction.LEFT

const DIRECTION_TURN_SPEED := 2.5

const MIN_SPEED := 10.0
const MAX_SPEED := 30.0
const SPEED_ANGVEL := 2.0

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX

var direction := randf() * TAU

var t := randf() * 3
var t2 := randf() * TAU


func _ready() -> void:
	a.flip_h = facing == Global.Direction.LEFT


func _physics_process(delta: float) -> void:
	if common_enemy.is_dead():
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			a.play('dead')
		else:
			a.play('hurt')
		if _death_timer < 0:
			queue_free()
		if not common_enemy.is_frozen:
			_death_timer -= delta
		return
	
	if common_enemy.is_hurt():
		a.play("hurt")
		return
	
	t += delta * 10
	var modt := fmod(t, 3)
	var f := a.frame
	var fp := a.frame_progress
	if modt < 1:
		a.animation = 'red'
	elif modt < 2:
		a.animation = 'orange'
	else:
		a.animation = 'yellow'
	a.frame = f
	a.frame_progress = fp
	if not a.is_playing():
		a.play()
	
	if common_enemy.can_see_target():
		facing = Global.Direction.LEFT if common_enemy.get_sight_target_relative_direction().x < 0 else Global.Direction.RIGHT
		
		var diff := common_enemy.get_sight_target_relative_direction().angle() - direction
		diff = Global.f_modulo(diff + PI, TAU) - PI
		if diff >= 0 and diff < PI:
			direction += delta * DIRECTION_TURN_SPEED
		else:
			direction -= delta * DIRECTION_TURN_SPEED
		direction = Global.f_modulo(direction, TAU)
	
	t2 += delta
	var speed := MIN_SPEED + (MAX_SPEED - MIN_SPEED) * sin(t2 * SPEED_ANGVEL) ** 2
	position += Vector2(1, 0).rotated(direction) * speed * delta
	
	a.flip_h = facing == Global.Direction.LEFT
