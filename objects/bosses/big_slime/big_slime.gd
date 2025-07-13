extends CharacterBody2D
class_name BigSlime

@onready var hitbox: Area2D = %Hitbox
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var sprite_2d: Sprite2D = %Sprite2D

@export var max_hitpoints := 20.0

@export var hop_height := 16.0
@export var rage_hop_hspeed_multiplier := 3.0

var _hitpoints := max_hitpoints
var _reached_halfpoint := false


enum State {
	NULL,
	START,
	CHOOSE,
	WAIT,
	HOP_AROUND,
	JUMP_OFF_SCREEN,
	RUN_TO_SIDE,
	DYIN
}

var state := State.START
var _last_processed_state := State.NULL
var _state_counter := 0.0 # Will serve as a counter or timer or timeout for states
var _state_flags := 0 # Will serve as a variable for each state
var _interstate_payload := 0 # Payload for when states want to communicate

var _hurt := 0
var _stored_anim := "string"
var _stored_anim_pos := 0.0
var _iframes := 0.0:
	set(f):
		if _iframes == INF:
			if f == 0:
				_iframes = 0
			else:
				_iframes = _iframes
		else:
			_iframes = f

var _hopping_hspeed := 0.0
var _hopping_gravity := 0.0
var _hopping_jump_mult := 1.0

var _was_on_floor := false

# TODO:
# patterns:
# Jump from one side to other (variable amount of jumps)
# Run from one side to other
# Jump off screen, land on player, stun if player is grounded on land
# Summon little slimes when off screen on half hp


func get_rage() -> float:
	return (max_hitpoints - _hitpoints) / max_hitpoints


## Returns 1 for no rage and max_mult for max rage
func get_rage_mutiplier(max_mult: float) -> float:
	return 1 + get_rage() * (max_mult - 1)

# Given:
# h: max height
# d: distance traverced per period
# N: mutiplier of vx when chaging speed
# g: gravity magnitude

# Find:
# vx: horizontal velocity
# vy: init vertical velocity (positive)

# equations of motion (EOM):
# v = a * t + v0
# x = v0 * t + (1/2) * a * t^2

# From EOM when a hop is done on time T we have:
# -vy = -g * T + vy =>
# [1]: T = 2 * vy / g

# From EOM when y = h and thus t = T/2
# h = vy * T / 2 - (1/2) * g * (T / 2)^2 =[1]=>
# h = vy^2 / g - (1/2) * vy^2 / g =[1]=>
# h = (1/2) * vy^2 / g =>
# ==================== |
# vy = sqrt(h * g * 2) |
# ==================== |
func get_vy() -> float:
	return sqrt(hop_height * abs(get_gravity().y) * 2)

# From EOM when a hop is done on time T we have:
# d = vx * T => vx = d / T =[1]=>
# vx = d / (2 * vy / g) =>
# ===================== |
# [2]: vx = d * g / 2vy |
# ===================== |
func get_vx(displacement: float) -> float:
	return 0.5 * displacement * abs(get_gravity().y) / get_vy()

# Given vx' = N * vx
func get_rage_vx(displacement: float) -> float:
	return get_rage_mutiplier(rage_hop_hspeed_multiplier) * get_vx(displacement)

# Given h = h' =>
# (1/2) * vy^2 / g = (1/2) * vy'^2 / g' =>
# g * (2 * vy / g)^2 = g' * (2 * vy' / g')^2 =[2](2 * vy / g = d / vx)=>
# g * (d / vx)^2 = g' * (d / vx')^2 =>
# g / vx^2 = g' / vx'^2 =[Given vx' = N * vx]=>
# g = g' / N^2 =>
# ============ |
# g' = g * N^2 | [3]
# ============ |
func get_rage_gravity() -> float:
	return abs(get_gravity().y) * get_rage_mutiplier(rage_hop_hspeed_multiplier) ** 2


# Given h = h' =>
# (1/2) * vy^2 / g = (1/2) * vy'^2 / g' =[3]=>
# vy^2 = vy'^2 / N^2 =>
# ============ |
# vy' = N * vy |
# ============ |

# Niw8w perierga na vgazw apotelesma apo to h = h' kai na xrhsimopoiw
# to apotelesma pali sto h = h' gia na vgalw auto pou 8elw,
# opote na ki enas enalaktikos tropos:

# Given d = d' =>
# vx * T = vx' * T' =[Given vx' = N * vx]=>
# [4]: T' = T / N

# From [1] (T = 2 * vy / g) and [4]=>
# T = N * T' =>
# 2 * vy / g = N * 2 * vy' / g' =[3]=>
# vy = vy' / N =>
# ============ |
# vy' = N * vy |
# ============ |
func get_rage_vy() -> float:
	return get_rage_mutiplier(rage_hop_hspeed_multiplier) * get_vy()


func _ready() -> void:
	_hitpoints = max_hitpoints
	_hopping_gravity = get_rage_gravity()
	
	hitbox.area_entered.connect(
		func(area: Area2D):
			if _iframes > 0.0: return
			var dmg := 1
			if area is PlayerAttack:
				dmg = area.roll_attack_hit().dmg
			_hitpoints -= dmg
			_hurt = 1
	)


func _physics_process(delta: float) -> void:
	$Label.text = str(_hitpoints)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += _hopping_gravity * delta
	
	if _hurt == 1:
		_hurt = 2
		_stored_anim = animation_player.assigned_animation
		_stored_anim_pos = animation_player.current_animation_position
		animation_player.play("damage")
	if _hurt == 2:
		if not animation_player.is_playing():
			_hurt = 0
			animation_player.play(_stored_anim)
			animation_player.seek(_stored_anim_pos)
			_iframes = 0.4
			
			if _hitpoints <= 0:
				animation_player.play("damage")
				state = State.DYIN
		return
	
	if _hitpoints <= 10 and not _reached_halfpoint:
		_reached_halfpoint = true
		_iframes = INF
		state = State.JUMP_OFF_SCREEN
	
	_iframes -= delta
	if _iframes > 0 and state != State.DYIN:
		modulate.a = 0.5
	else:
		modulate.a = 1
	
	# Handle state init
	if _last_processed_state != state:
		_hopping_gravity = 0
		match state:
			State.DYIN:
				animation_player.play("damage")
				_state_flags = 0
			State.START:
				_state_flags = 0
				_state_counter = 0
			State.WAIT:
				animation_player.play("idle")
				_state_flags = _interstate_payload
				_state_counter = 2 - 1.5 * get_rage()
			State.CHOOSE:
				_state_flags = _interstate_payload
			State.HOP_AROUND:
				if _interstate_payload == 1:
					# Pick random side
					_state_flags = [-1,1].pick_random()
				else:
					# Pick farthest side
					if global_position.x > 80:
						_state_flags = -1
					else:
						_state_flags = 1
				animation_player.play("jump_start")
				sprite_2d.flip_h = _state_flags == -1
				_hopping_jump_mult = [1,2,3].pick_random()
				_hopping_hspeed = 0
				_state_counter = 16 * [1,2,4.1].pick_random()
				_was_on_floor = true
			State.RUN_TO_SIDE:
				if _interstate_payload == 1:
					# Pick random side
					_state_flags = [-1,1].pick_random()
				else:
					# Pick farthest side
					if global_position.x > 80:
						_state_flags = -1
					else:
						_state_flags = 1
				animation_player.play("walk")
				sprite_2d.flip_h = _state_flags == -1
				_state_counter = 0
			State.JUMP_OFF_SCREEN:
				if is_on_floor():
					_state_flags = 1
				else:
					_state_flags = 0
				_state_counter = 0
	
	_interstate_payload = 0
	_last_processed_state = state
	
	# Handle state
	match state:
		State.DYIN:
			velocity.x = 0
			velocity.y = 0
			if not animation_player.is_playing():
				if _state_flags != 4:
					_state_flags += 1
					animation_player.play("damage")
					if _state_flags == 3:
						animation_player.play("die")
						_state_flags = 4
						_state_counter = 0.0
				else:
					if _state_counter > 1:
						queue_free()
					_state_counter += delta
		State.START:
			if Refs.level_manager.player.body.is_on_floor():
				_state_flags = 1
			if _state_flags > 0:
				_state_counter += delta
			if _state_counter > 0.3:
				MessageDisplayer.display(
					["Welcome to the Slime Pit!", "Prepare to get Slimed!"],
					func(): state = State.CHOOSE,
					false
				)
		State.WAIT:
			if _state_counter <= 0:
				state = State.CHOOSE
				_interstate_payload = _state_flags
			_state_counter -= delta
		State.CHOOSE:
			var rng := RandomNumberGenerator.new()
			var states := [State.HOP_AROUND, State.JUMP_OFF_SCREEN, State.RUN_TO_SIDE]
			var weights = PackedFloat32Array([0.9, 0.3, 1])
			state = states[rng.rand_weighted(weights)]
			_interstate_payload = _state_flags
		State.RUN_TO_SIDE:
			velocity.x = _state_flags * 50 * (1 + get_rage())
			
			if is_on_wall():
				if _state_flags == -get_wall_normal().x:
					state = State.WAIT
					sprite_2d.flip_h = not sprite_2d.flip_h
		State.HOP_AROUND:
			if _state_flags == 0:
				if animation_player.assigned_animation == "jump_start":
					if is_on_floor():
						animation_player.play("jump_land")
				elif not animation_player.is_playing():
					state = State.WAIT
			else:
				if not is_on_floor():
					velocity.x = _hopping_hspeed
				else:
					velocity.x = 0
				if animation_player.assigned_animation == "jump_start":
					if not animation_player.is_playing():
						if is_on_floor():
							if _was_on_floor:
								var prev_h := hop_height
								hop_height = hop_height * _hopping_jump_mult
								
								_hopping_hspeed = _state_flags * get_rage_vx(_state_counter)
								_hopping_gravity = get_rage_gravity()
								velocity.y = -abs(get_rage_vy())
								
								hop_height = prev_h
								_was_on_floor = false
							else:
								animation_player.play("jump_land")
				elif animation_player.assigned_animation == "jump_land":
					if not animation_player.is_playing():
						animation_player.play("jump_start")
						_was_on_floor = true
				
				if (_state_flags == 1 and global_position.x >= 144) or (_state_flags == -1 and global_position.x <= 16):
					velocity.x = 0
					_state_flags = 0
					sprite_2d.flip_h = not sprite_2d.flip_h
				
				#if is_on_wall():
					#if _state_flags == -get_wall_normal().x:
						#velocity.y = abs(velocity.y)
						#_state_flags = 0
						#sprite_2d.flip_h = not sprite_2d.flip_h
		State.JUMP_OFF_SCREEN:
			sprite_2d.flip_h = global_position.x > Refs.level_manager.player.body.global_position.x
			match _state_flags:
				0:
					velocity.x = 0
					velocity.y = abs(velocity.y)
					if is_on_floor():
						animation_player.play("jump_land",-1,1.5)
					_state_flags = 1
				1:
					if animation_player.current_animation != "jump_land" and animation_player.assigned_animation != "jump_start":
						animation_player.play("jump_start",-1,1.5)
					if not animation_player.is_playing():
						_state_flags = 2
				2:
					velocity.y = -200
					if position.y < -10:
						_state_flags = 3
				3:
					velocity.y = 0
					_iframes = 0.0
					_state_flags = 4
				4:
					if _state_counter > get_rage_mutiplier(3):
						_state_flags = 5
					_state_counter += delta
				5:
					global_position.x = Refs.level_manager.player.body.global_position.x
					_state_flags = 6
				6:
					velocity.y = 175 * get_rage_mutiplier(2)
					if is_on_floor():
						animation_player.play("jump_land")
						_state_flags = 7
				7:
					if not animation_player.is_playing():
						state = State.CHOOSE
						_interstate_payload = 1
	
	# Change state
	if state != State.DYIN:
		if _hitpoints <= 0:
			state = State.DYIN
	
	move_and_slide()
