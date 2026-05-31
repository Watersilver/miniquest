@tool
extends Node2D
class_name TowerGuy

@onready var as2d2: AnimatedSprite2D = %AnimatedSprite2D2

@onready var as2d: AnimatedSprite2D = %AnimatedSprite2D

@onready var common_enemy: CommonEnemy = %CommonEnemy

@export_tool_button("play/stop anims") var toggle_anims_action = toggle_anims

@export var top_height := 16.0
@export var bottom_height := 60.0
@export var leftmost_x := 48.0
@export var rightmost_x := 112.0
@export var no_rage := false

const ONE_OVER_SIN_4_90 := 1 / sin(sin(sin(sin(PI / 2))))

enum State {
	NONE,
	INIT,
	INIT_DESCEND,
	EQUILIBRIUM,
	DESCEND,
	SPAWN,
}

var _state := State.INIT
var _prev_state := State.NONE

var _direction := Global.Direction.LEFT

var _state_x_start := 0.0
var _state_y_start := 0.0
var _state_progress_x := 0.0
var _state_progress_y := 0.0
var _descend_type := 0

var _t := 0.0

var _max_hp := 0.0

var _death_timer := 0.0
var _death_state := 0
var _death_velocity := Vector2()

var _is_spawn := false


func set_flip_h(h: bool):
	as2d.flip_h = h
	as2d2.flip_h = h


func toggle_anims():
	if as2d.is_playing():
		as2d.stop()
		as2d2.stop()
	else:
		play_idle_anim()


func play_idle_anim():
	as2d.play("idle")
	as2d2.play("idle")
	as2d2.modulate.r = 1
	as2d2.modulate.g = 0
	as2d2.modulate.b = 0


func play_hurt_anim():
	as2d.play("hurt")
	as2d2.play("hurt")
	as2d2.modulate.r = 1
	as2d2.modulate.g = 1
	as2d2.modulate.b = 1


func is_right_of_centre():
	return position.x > 80


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_is_spawn = _state == State.SPAWN
	if Global.session.saved_data.object_flags.has("tower_guy") and Global.session.saved_data.object_flags["tower_guy"] and _state != State.SPAWN:
		queue_free()
	_max_hp = common_enemy.hitpoints


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if common_enemy.is_on_iframes() and not common_enemy.is_hurt():
		modulate.a = 0.5
	else:
		modulate.a = 1
	
	var _start_state = _state
	
	
	if common_enemy.is_dead():
		if _death_timer > 4:
			queue_free()
		elif _death_timer > 2:
			if _death_state == 0:
				_death_state = 1
		elif _death_timer > 1:
			as2d2.visible = false
		elif _death_timer > 0.5:
			as2d2.play("dead")
		else:
			play_hurt_anim()
		
		if _death_state == 1:
			_death_state = 2
			_death_velocity.y -= delta
			_death_velocity = Vector2([22,11,-11,-22].pick_random(), -55)
			if not _is_spawn:
				AudioManager.stop_music()
		elif _death_state == 2:
			_death_velocity.y += delta * 255
			position += _death_velocity * delta
			rotate(_death_velocity.x * delta / 11)
		
		_death_timer += delta
		return
	
	
	if common_enemy.is_hurt():
		play_hurt_anim()
		return
	
	play_idle_anim()
	
	match _state:
		State.SPAWN:
			if _prev_state != _state:
				_t = 0
			if _t < 0.5:
				play_hurt_anim()
				as2d2.play("dead")
			else:
				play_hurt_anim()
			if _t > 1:
				_state = State.INIT_DESCEND
				set_flip_h(is_right_of_centre())
				play_idle_anim()
			_t += delta
		State.INIT:
			if Refs.level_manager.player:
				if Refs.level_manager.player.body.global_position.x > global_position.x and Refs.level_manager.player.body.is_on_floor():
					MessageDisplayer.display(
						["You're bothering me!", "WHY are you bothering me??"],
						func():
							_state = State.INIT_DESCEND
							for n in get_tree().get_nodes_in_group("moving_platforms"):
								n.queue_free()
							position.x = [leftmost_x, rightmost_x].pick_random()
							set_flip_h(is_right_of_centre())
							AudioManager.play_music(AudioManager.music_themes.boss_theme)
							,
						false
					)
		State.INIT_DESCEND:
			position.y += delta * 25
			if global_position.y >= top_height:
				global_position.y = top_height
				_state = State.DESCEND
		State.DESCEND:
			if _prev_state != _state:
				set_flip_h(is_right_of_centre())
				_direction = Global.Direction.LEFT if is_right_of_centre() else Global.Direction.RIGHT
				_state_x_start = global_position.x
				_state_y_start = global_position.y
				_state_progress_x = 0.0
				_state_progress_y = 0.0
				_t = 0
				_descend_type = randi() % 7
			
			global_position.x = _state_x_start + _direction * _state_progress_x * (rightmost_x - leftmost_x)
			global_position.y = _state_y_start + _state_progress_y * (bottom_height - top_height)
			
			if no_rage:
				_t += delta
			else:
				_t += delta * (1 + 1 - common_enemy.hitpoints / _max_hp)
			
			match _descend_type:
				0:
					_state_progress_x = _t / PI
					_state_progress_y = sin(sin(sin(sin(_t)))) * ONE_OVER_SIN_4_90
				1:
					_state_progress_x = sin(sin(sin(sin(_t * 0.5)))) * ONE_OVER_SIN_4_90
					_state_progress_y = sin(sin(sin(sin(_t)))) * ONE_OVER_SIN_4_90
				2:
					_state_progress_x = 1 - sin(sin(sin(sin(_t * 0.5 + PI/2)))) * ONE_OVER_SIN_4_90
					_state_progress_y = sin(sin(sin(sin(_t)))) * ONE_OVER_SIN_4_90
				3:
					_state_progress_x = sin(_t)
					_state_progress_y = tanh(3 * sin(_t))
				4:
					_state_progress_x = sin(_t * 0.5)
					_state_progress_y = tanh(5 * sin(_t))
				5:
					_state_progress_x = 1 - sin(_t * 0.5 + PI/2)
					_state_progress_y = tanh(5 * sin(_t))
				6:
					_state_progress_x = _t / PI
					_state_progress_y = tanh(3 * sin(_t))
			
			if _t > PI:
				_state = State.EQUILIBRIUM
		State.EQUILIBRIUM:
			if _prev_state != _state:
				set_flip_h(is_right_of_centre())
				global_position.y = top_height
				global_position.x = rightmost_x if abs(global_position.x - leftmost_x) > abs(global_position.x - rightmost_x) else leftmost_x
			else:
				_state = State.DESCEND
	
	_prev_state = _start_state


func _exit_tree() -> void:
	if common_enemy.is_dead():
		Global.session.saved_data.object_flags["tower_guy"] = true
		Global.session.saved_data.tower_boss = true
