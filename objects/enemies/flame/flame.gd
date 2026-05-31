extends Node2D

@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var a: AnimatedSprite2D = %AnimatedSprite2D

@export var facing := Global.Direction.LEFT

## Angular velocity of the sin that modifies speed between min and max value
@export var speed_angvel := 2.0
@export var min_speed := 10.0
@export var max_speed := 30.0

@export var turning_speed := 2.5
@onready var fire_area: Area2D = %FireArea

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX

var direction := randf() * TAU

var t := randf() * 3
var t2 := randf() * TAU


func die_by_ice_spike(frost: Area2D):
	common_enemy.is_frozen = true
	common_enemy.hitpoints = -1
	var f := frost.get_parent()
	if f is IceSpike:
		f.common_enemy.hitpoints = -1


func _ready() -> void:
	a.flip_h = facing == Global.Direction.LEFT
	fire_area.area_entered.connect(die_by_ice_spike)


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
	
	#if common_enemy.can_see_target():
	#var strd := common_enemy.get_sight_target_relative_direction()
	if Refs.level_manager and Refs.level_manager.player:
		var to_player := Refs.level_manager.player.hitbox_shape.global_position
		to_player = to_player - global_position
		facing = Global.Direction.LEFT if to_player.x < 0 else Global.Direction.RIGHT
		
		var diff := to_player.angle() - direction
		diff = Global.f_modulo(diff + PI, TAU) - PI
		if diff >= 0 and diff < PI:
			direction += delta * turning_speed
		else:
			direction -= delta * turning_speed
		direction = Global.f_modulo(direction, TAU)
	
	t2 += delta
	var speed := min_speed + (max_speed - min_speed) * sin(t2 * speed_angvel) ** 2
	position += Vector2(1, 0).rotated(direction) * speed * delta
	
	a.flip_h = facing == Global.Direction.LEFT
