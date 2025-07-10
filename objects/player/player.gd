extends Node2D
class_name Player

const PLAYER_ATTACK = preload("res://objects/player_attack/player_attack.tscn")
const UNDERWATER_BUBBLE = preload("res://objects/underwater_bubble/underwater_bubble.tscn")

signal griffon_ceiling_smash


# TODO: Why hurt state after death during respawn??

# TODO: should always be able to teleport to checkpoint to avoid softlocks

@onready var body: CharacterBody2D = %CharacterBody2D
@onready var anim: CharacterAnimations = %CharacterAnimations
@onready var ladder_detector: Area2D = %LadderDetector
@onready var health: Health = %Health
@onready var hitbox: Area2D = %Hitbox
@onready var bat_mana_center: BatManaCenter = %BatManaCenter
@onready var water_detector: Area2D = %WaterDetector
@onready var water_surface_detector: RayCast2D = %WaterSurfaceDetector
@onready var water_bubble_possible_detector: Area2D = %WaterBubblePossibleDetector
@onready var swim_jump_detector: Area2D = %SwimJumpDetector
@onready var is_in_wall_detector: Area2D = %IsInWallDetector
@onready var interaction_checker: Area2D = %InteractionChecker
#@onready var state_debug_label: Label = %StateDebugLabel

const JUMP_INIT_SPEED := 180.0
const JUMP_ANTICIPATION_DURATION := 0.05
const JUMP_RECOVERY_MIN_DURATION := 0.05
const SLOW_FALL_THRESHOLD := 50.0
const WALK_SPEED := 50.0
const BAT_DURATION := 3.0

var attack: PlayerAttack


func get_room_block_coordinates(room: Room) -> Vector2i:
	return Vector2i(
		clampi(
			floori(body.global_position.x / float(room.BLOCK_WIDTH)),
			0,
			room.size_x - 1
		),
		clampi(
			floori(body.global_position.y / float(room.BLOCK_HEIGHT)),
			0,
			room.size_y - 1
		)
	)


func handle_out_of_bounds():
	_state = State.DAED


enum State {
	NONE,
	NORMAL,
	JUMP_ANTICIPATION,
	JUMP_RECOVERY,
	BACKDASH,
	RUN,
	RECOIL,
	FALLEN,
	ATTACK,
	CLIMB,
	HURT,
	DAED,
	BAT,
	GRIFFON,
	HIT_CEILING,
	WALLJUMP, # TODO?
	SWIM,
	WATER_MOVE #TODO (prbably not as a state but a check for normal movement)
}
var _prev_state := State.NONE
var _state := State.NORMAL:
	set(s):
		# This if statement will ensure cleanup will happen properly if I change more than one states in a single frame
		if _prev_state == _state:
			_prev_state = _state
		_state = s
var _state_countdown := 0.0


var _direction := Global.Direction.RIGHT
var _was_on_floor := Global.Ternary.NULL
var _uncontrolled_jump_x_vel := 0.0
var _can_double_jump := false
var _backdash_cooldown := 0.0
var _jump_cooldown := 0.0
var _momentum_jump := false
var _can_momentum_jump := false
var _should_run_jump := false
var _target_angle := 0.0
var _target_angle_time := 1.0
var _target_angle_min_rotation := 1.0
var _climb_cooldown := 0.0
var _attack_cooldown := 0.0
var _i_frames := 0.0
var _bat_mana := BAT_DURATION
var _griffon_cooldown := 0.0
var _griffon_air_cooldown := 0.0 # can only perform griffon by pressing up when this is > 0
var _last_climb_x := -INF
var _passing_through_semisolids := false
var _semisolid_cooldown := 0.0
var _semisolid_last_y := -INF
var _shake_cooldown := 0.0
var _shake_tick := 0.0
var _lung_capacity := 0.0
var _swim_mode := true
var _fall_peak := INF
var _waterwalk_to_swim_cooldown := 0.0
var _inside_wall_timer := 0.0
var _exhale_timer := 0.0

var _init_vel := Vector2(0,0)
var velocity: Vector2:
	set(v):
		if Global.session.is_underwater and not _swim_mode:
			if _state == State.BACKDASH:
				v.x *= 0.95
			elif _state == State.RUN:
				v.x *= 0.9
			else:
				v.x *= 0.5
				v.y *= 0.95
		
		if not is_node_ready():
			_init_vel = v
		else:
			body.velocity = v
	get():
		if not is_node_ready():
			return _init_vel
		return body.velocity

func _jump(speed: float):
	velocity.y = -speed
	_waterwalk_to_swim_cooldown = 0.25

func _normal_movement():
	if body.is_on_floor() or Global.session.upgrades.controlled_fall:
		var x_speed := WALK_SPEED
		if not body.is_on_floor():
			if _momentum_jump:
				x_speed = 0.9 * x_speed
			else:
				x_speed = 0.66 * x_speed
			
			if Input.is_action_just_pressed("move_down"):
				velocity.y = max(SLOW_FALL_THRESHOLD, velocity.y)
		
		velocity.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * x_speed
		
		if velocity.x:
			_direction = sign(velocity.x)
		
		if Input.is_action_pressed("move_down") and body.is_on_floor():
			velocity.x = 0
	else:
		var axis := Input.get_axis("move_left", "move_right")
		_direction = Global.Direction.RIGHT if axis > 0 else Global.Direction.LEFT if axis < 0 else _direction
		if _uncontrolled_jump_x_vel != 0:
			velocity.x = _uncontrolled_jump_x_vel
		elif velocity.x != 0:
			velocity.x = sign(velocity.x) * WALK_SPEED * 0.5

func _move():
	if velocity.y > JUMP_INIT_SPEED:
		velocity.y = JUMP_INIT_SPEED
	
	if Global.session.is_underwater and not _swim_mode:
		if velocity.y > JUMP_INIT_SPEED * 0.25:
			velocity.y = JUMP_INIT_SPEED * 0.25
	
	var semisolid_collision := body.get_collision_mask_value(2)
	if _passing_through_semisolids:
		body.set_collision_mask_value(2, false)
	
	body.move_and_slide()
	
	body.set_collision_mask_value(2, semisolid_collision)

func _update_lung_capacity(delta: float):
	if Global.session.is_underwater:
		if _lung_capacity <= 0.0:
			health.value -= delta
		
		_lung_capacity -= delta
	else:
		_lung_capacity = Global.session.get_lung_capacity_max()

func _should_backdash():
	return _backdash_cooldown <= 0 and body.is_on_floor() and Global.session.upgrades.backdash and Input.is_action_just_pressed("dodge")

func _should_attack():
	return not is_instance_valid(attack) and _attack_cooldown <= 0 and Input.is_action_just_pressed("attack") and Global.session.upgrades.weapon != Global.Weapon.NONE

func _should_climb():
	return Input.is_action_pressed("move_up") and ladder_detector.has_overlapping_bodies() and _climb_cooldown <= 0

func _should_bat():
	return not Global.session.is_underwater and Global.session.upgrades.bat and Input.is_action_just_pressed("dash") and not body.is_on_floor() and _bat_mana > 0

func _should_griffon():
	return Global.session.upgrades.griffon and Input.is_action_just_pressed("dodge") and ((not body.is_on_floor() and _griffon_air_cooldown <= 0) or (Input.is_action_pressed("move_up") and not body.is_on_floor())) and _griffon_cooldown <= 0

func _handle_underwater():
	Global.session.is_underwater = water_detector.has_overlapping_areas() or water_detector.has_overlapping_bodies()
	if velocity.y > 0:
		if not Global.session.upgrades.swim and not Global.session.upgrades.water_walk:
			if Global.session.is_underwater:
				_state = State.DAED
		elif _state == State.BAT:
			if Global.session.is_underwater:
				if Global.session.upgrades.water_walk:
					_swim_mode = false
					_state = State.NORMAL
				elif Global.session.upgrades.swim:
					_swim_mode = true
					_state = State.SWIM
		elif Global.session.upgrades.swim and _state != State.SWIM and _swim_mode:
			if Global.session.is_underwater:
				if _swim_mode and Global.session.upgrades.water_walk and Input.is_action_pressed("move_down"):
					_swim_mode = false
				else:
					_state = State.SWIM


func _ready() -> void:
	anim.animation_finished.connect(_on_character_animations_animation_finished)
	anim.animation_looped.connect(_on_character_animations_animation_looped)
	velocity = _init_vel
	
	health.maximum = Global.session.upgrades.max_health
	
	for child in get_children():
		if child is Camera2D:
			child.reparent(body)
			break


func _physics_process(delta: float) -> void:
	health.maximum = Global.session.upgrades.max_health
	
	anim.weapon = Global.session.upgrades.weapon
	
	_backdash_cooldown -= delta
	_jump_cooldown -= delta
	_climb_cooldown -= delta
	_attack_cooldown -= delta
	_griffon_cooldown -= delta
	_griffon_air_cooldown -= delta
	_i_frames -= delta
	_shake_cooldown -= delta
	_shake_tick -= delta
	_semisolid_cooldown -= delta
	_waterwalk_to_swim_cooldown -= delta
	
	if body.position.y > _semisolid_last_y + 1:
		_semisolid_cooldown = 0.0
	
	if _semisolid_cooldown <= 0:
		_passing_through_semisolids = false
	
	if _i_frames <= 0:
		modulate.a = 1
	else:
		modulate.a = 0.75
	
	var do_init_state := true
	var save_me_from_infiloops := 10
	while do_init_state:
		do_init_state = false
		if _state != _prev_state:
			var normal_shape: CollisionShape2D = %NormalShape
			var bat_shape: CollisionShape2D = %BatShape
			
			normal_shape.disabled = false
			bat_shape.disabled = true
			bat_mana_center.force_fadeout = false
			
			# Cleanup prev
			match _prev_state:
				State.CLIMB:
					_climb_cooldown = 0.5
				State.GRIFFON:
					_target_angle = 0
					anim.center.rotation = 0
				State.BACKDASH:
					_griffon_air_cooldown = 0
				State.RUN:
					_griffon_air_cooldown = 0
			
			# Init new
			match _state:
				State.JUMP_ANTICIPATION:
					if _prev_state != State.JUMP_RECOVERY:
						_state_countdown = JUMP_ANTICIPATION_DURATION
				State.JUMP_RECOVERY:
					_state_countdown = JUMP_RECOVERY_MIN_DURATION
				State.BACKDASH:
					velocity.x = -_direction * WALK_SPEED * 2
					_jump(25)
					_griffon_cooldown = 0.15
					_griffon_air_cooldown = 0.25
				State.HURT:
					velocity.x = -20 * _direction
					_jump(45)
					_state_countdown = 1
				State.DAED:
					_state_countdown = 3
					bat_mana_center.force_fadeout = true
				State.RUN:
					_can_momentum_jump = false
					_should_run_jump = false
					_state_countdown = 0.25
					velocity.x = 0
				State.ATTACK:
					_state_countdown = 0.1
					var att := PLAYER_ATTACK.instantiate()
					att.weapon = Global.session.upgrades.weapon
					att.direction = _direction
					att.position = position + body.position + Vector2(_direction * 6,-4)
					add_sibling(att)
					att.reparent(Refs.level_manager.current_room)
					#var i := att.get_index()
					#att.get_parent().move_child(att, i - 1)
					attack = att
				State.BAT:
					normal_shape.disabled = true
					bat_shape.disabled = false
					_state_countdown = _bat_mana
				State.GRIFFON:
					#_jump(JUMP_INIT_SPEED * 2)
					_target_angle = deg_to_rad(360 * 10)
					_jump(JUMP_INIT_SPEED * 5)
					_griffon_cooldown = 0.75
					_can_double_jump = true
				State.HIT_CEILING:
					_state_countdown = 0.1
				State.SWIM:
					#body.global_position.y = min(water_surface_detector.get_collision_point().y + 5, body.global_position.y)
					
					var height := body.position.y - _fall_peak
					var max_speed := 5
					
					if height > 50:
						max_speed = 50
					elif height > 30:
						max_speed = 45
					elif height > 22:
						max_speed = 35
					elif height > 14:
						max_speed = 27
					
					velocity.y = min(velocity.y, max_speed)
					_can_double_jump = true
					_swim_mode = true
					
					_fall_peak = body.position.y
		_prev_state = _state
		save_me_from_infiloops -= 1
		if save_me_from_infiloops == 0:
			do_init_state = false
			printerr("Oh shiet, infiloop in player.gd init state")
	
	match _state:
		State.NORMAL:
			
			# Gravity stuff
			var grav = body.get_gravity()
			velocity += grav * delta * max(abs(velocity.y) / JUMP_INIT_SPEED, 0.1) * 5
			
			if body.is_on_floor():
				_uncontrolled_jump_x_vel = 0
				_can_double_jump = true
				_momentum_jump = false
				
				if not Global.session.is_underwater:
					_swim_mode = true
			
			var _descending := false
			# Switch commented and uncommented statements to prevent holding down + jump to fall through floor
			#if Input.is_action_pressed("move_down") and Input.is_action_just_pressed("jump"):
			if Input.is_action_pressed("move_down") and Input.is_action_pressed("jump"):
				_passing_through_semisolids = true
				if body.is_on_floor():
					_descending = true
				_semisolid_cooldown = 0.5
				_semisolid_last_y = body.position.y
			
			_normal_movement()
			
			# Trying to jump
			var is_double_jump := (not body.is_on_floor() and _can_double_jump and velocity.y > 0)
			var is_jump_available := Global.session.upgrades.double_jump if is_double_jump else Global.session.upgrades.jump
			if not _descending and Input.is_action_just_pressed("jump") and _jump_cooldown <= 0 and is_jump_available:
				if body.is_on_floor() or is_double_jump:
					# Initiate jump or double jump if jump is possible
					if is_double_jump:
						_target_angle = 0
						anim.center.rotation = deg_to_rad(-360)
						_target_angle_time = 0.2
					if not body.is_on_floor():
						_can_double_jump = false
					if JUMP_ANTICIPATION_DURATION > 0 and not Global.session.upgrades.controlled_fall:
						_state = State.JUMP_ANTICIPATION
					else:
						_jump(JUMP_INIT_SPEED)
				else:
					# Failed jump penalty
					_jump_cooldown = 0.25
			
			if Global.session.upgrades.controlled_fall:
				if not Input.is_action_pressed("jump"):
					velocity.y = max(velocity.y, -SLOW_FALL_THRESHOLD)
			
			_move()
			
			if body.is_on_floor() and _was_on_floor == Global.Ternary.FALSE and not Global.session.upgrades.controlled_fall:
				_state = State.JUMP_RECOVERY
			
			if body.is_on_floor() and Input.is_action_pressed("dash") and Global.session.upgrades.run:
				_state = State.RUN
			
			if Global.session.is_underwater and Global.session.upgrades.swim and Input.is_action_pressed("move_up") and _waterwalk_to_swim_cooldown <= 0:
				_state = State.SWIM
			
			if _should_climb():
				_state = State.CLIMB
			
			if _should_attack():
				_state = State.ATTACK
			
			_handle_underwater()
			
			if _should_bat():
				_state = State.BAT
			
			if _should_backdash():
				_state = State.BACKDASH
			
			if _should_griffon():
				_state = State.GRIFFON
			
			#if Input.is_action_pressed("dodge"):
				#var s := Sprite2D.new()
				#s.global_position = anim.sprite.global_position
				#s.texture = anim.sprite.texture
				#s.region_enabled = true
				#s.region_rect = anim.sprite.region_rect
				#s.offset = anim.sprite.offset
				#s.scale = anim.sprite.scale
				#s.scale *= anim.facing_scaler.scale
				#s.modulate.a = 0.1
				#get_parent().add_child(s)
			
		State.JUMP_ANTICIPATION:
			if _state_countdown <= 0:
				_state = State.NORMAL
				_jump(JUMP_INIT_SPEED if Input.is_action_pressed("jump") else JUMP_INIT_SPEED * 0.5)
				_uncontrolled_jump_x_vel = 0
				var axis := Input.get_axis("move_left", "move_right")
				if axis != 0:
					if _momentum_jump:
						_uncontrolled_jump_x_vel = WALK_SPEED * 0.9 * axis
					else:
						_uncontrolled_jump_x_vel = WALK_SPEED * 0.5 * axis
				velocity.x = _uncontrolled_jump_x_vel
				_move()
			else:
				_state_countdown -= delta
				if not body.is_on_floor():
					velocity.y = 0
				_move()
			
			if _should_backdash():
				_state = State.BACKDASH
			
			if _should_griffon():
				_state = State.GRIFFON
			
		State.JUMP_RECOVERY:
			if _state_countdown <= 0:
				_state = State.NORMAL
			
			if Input.is_action_just_pressed("jump") and Global.session.upgrades.jump:
				_state = State.JUMP_ANTICIPATION
			
			_state_countdown -= delta
			
			if _should_backdash():
				_state = State.BACKDASH
			
			if _should_griffon():
				_state = State.GRIFFON
			
		State.BACKDASH:
			var grav = body.get_gravity()
			velocity += grav * delta * max(abs(velocity.y) / JUMP_INIT_SPEED, 0.1) * 5
			velocity.x = velocity.x - velocity.x * delta * 7
			_move()
			
			if body.is_on_floor():
				velocity.x = 0
				_state = State.JUMP_RECOVERY
			
			if _should_bat():
				_state = State.BAT
			
			if _should_attack():
				_attack_cooldown = 0.1
				_state = State.ATTACK
			
			_handle_underwater()
			
			if _should_griffon():
				_state = State.GRIFFON
			
		State.RUN:
			if _momentum_jump:
				_momentum_jump = false
				_state_countdown = 0.1
				_can_momentum_jump = true
			
			var grav = body.get_gravity()
			velocity += grav * delta * max(abs(velocity.y) / JUMP_INIT_SPEED, 0.1) * 5
			
			var ground_speed := 0.0 if not _can_momentum_jump else _direction * WALK_SPEED * 0.9
			velocity.x = ground_speed if body.is_on_floor() else velocity.x - velocity.x * delta
			
			_should_run_jump = (_should_run_jump or Input.is_action_just_pressed("jump")) and Global.session.upgrades.jump
			if _should_run_jump and Input.is_action_just_released("jump"):
				_should_run_jump = false
			
			if _state_countdown <= 0:
				if _should_run_jump:
					_should_run_jump = false
					if _can_momentum_jump:
						_momentum_jump = true
						_state = State.NORMAL
						_jump(JUMP_INIT_SPEED * 0.9)
						_uncontrolled_jump_x_vel = _direction * WALK_SPEED * 0.9
					else:
						_state = State.NORMAL
						_jump(JUMP_INIT_SPEED)
						_uncontrolled_jump_x_vel = _direction * WALK_SPEED * 0.5
				elif Input.is_action_pressed("dash"):
					_state_countdown = 0.1
					_jump(12)
					velocity.x = _direction * WALK_SPEED * 1.75
					_can_momentum_jump = true
				else:
					_state = State.NORMAL
			
			_move()
			
			if _should_attack():
				_state = State.ATTACK
			
			if body.is_on_floor():
				_griffon_air_cooldown = 0.25
				_uncontrolled_jump_x_vel = 0
				_can_double_jump = true
				_state_countdown -= delta
			else:
				if body.is_on_wall() and signf(body.get_wall_normal().x) == -_direction:
					_state = State.RECOIL
					_jump(44)
			
			if _should_bat():
				_state = State.BAT
			
			_handle_underwater()
			
			if _should_griffon():
				_state = State.GRIFFON
		
		State.RECOIL:
			var grav = body.get_gravity()
			velocity += grav * delta
			velocity.x = -_direction * 30
			
			_move()
			
			if body.is_on_floor():
				_state = State.FALLEN
				_state_countdown = 0.2
			
			_handle_underwater()
		
		State.HURT:
			var grav = body.get_gravity()
			velocity += grav * delta
			
			_move()
			
			if body.is_on_floor() or _state_countdown <= 0:
				_state = State.NORMAL
			
			if _swim_mode and Global.session.is_underwater:
				if (_state_countdown <= 0 or velocity.y >= 0):
					_state = State.SWIM
			elif body.is_on_floor() or _state_countdown <= 0:
				_state = State.NORMAL
		
		State.FALLEN:
			if _state_countdown <= 0:
				_jump(40)
				_state = State.NORMAL
				anim.center.rotation = deg_to_rad(-180)
				_target_angle = 0
				_target_angle_time = 0.1
				_uncontrolled_jump_x_vel = 0
				velocity.x = 0
				_move()
			
			_state_countdown -= delta
		
		State.ATTACK:
			anim.center.rotation = 0
			
			if _state_countdown <= 0:
				_attack_cooldown = 0.1
				_state = State.NORMAL
			
			var grav = body.get_gravity()
			velocity += grav * delta * max(abs(velocity.y) / JUMP_INIT_SPEED, 0.1) * 5
			
			if body.is_on_floor():
				velocity.x = 0
				
				if _should_backdash():
					_state = State.BACKDASH
			else:
				_normal_movement()
			
			_move()
			
			if _was_on_floor == Global.Ternary.FALSE and body.is_on_floor():
				if Global.session.upgrades.controlled_fall:
					_state = State.NORMAL
				else:
					_state = State.JUMP_RECOVERY
			
			_handle_underwater()
			
			_state_countdown -= delta
			
			if _should_griffon():
				_state = State.GRIFFON
		
		State.CLIMB:
			_passing_through_semisolids = true
			anim.center.rotation = 0
			_can_double_jump = true
			_last_climb_x = body.position.x
			if ladder_detector.has_overlapping_bodies():
				var v := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
				var h := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
				velocity = Vector2(h,v).normalized() * 15
				_move()
				_uncontrolled_jump_x_vel = WALK_SPEED * 0.5 * sign(velocity.x)
				if sign(_uncontrolled_jump_x_vel) != 0:
					_direction = Global.Direction.LEFT if _uncontrolled_jump_x_vel < 0 else Global.Direction.RIGHT
				
				if Input.is_action_just_pressed("jump") and Global.session.upgrades.jump:
					if JUMP_ANTICIPATION_DURATION > 0 and not Global.session.upgrades.controlled_fall:
						_state = State.JUMP_ANTICIPATION
					else:
						_state = State.NORMAL
						_jump(JUMP_INIT_SPEED)
			else:
				_jump(25)
				_state = State.NORMAL
		
		State.BAT:
			_passing_through_semisolids = true
			anim.center.rotation = 0
			velocity = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized() * WALK_SPEED
			
			if velocity.x != 0:
				_direction = Global.Direction.LEFT if velocity.x < 0 else Global.Direction.RIGHT
			
			_move()
			
			_handle_underwater()
			
			_uncontrolled_jump_x_vel = WALK_SPEED * 0.5 * sign(velocity.x)
			
			if Input.is_action_just_pressed("dash") or _bat_mana <= 0:
				_state_countdown = 0.0
		
		State.GRIFFON:
			var grav = body.get_gravity()
			velocity += grav * delta * max(abs(velocity.y) / JUMP_INIT_SPEED, 0.1) * 10
			_move()
			
			if abs(velocity.x) > WALK_SPEED * 0.3:
				velocity.x = sign(velocity.x) * WALK_SPEED * 0.3
			
			if velocity.y >= 0:
				_state = State.NORMAL
			
			if body.is_on_ceiling():
				_state = State.HIT_CEILING
				griffon_ceiling_smash.emit()
		
		State.HIT_CEILING:
			if _state_countdown <= 0.0:
				_state = State.NORMAL
			
			_state_countdown -= delta
		
		State.SWIM:
			var immersion := 0.0
			
			var surface_dist := water_surface_detector.get_collision_point().y - water_surface_detector.global_position.y
			if water_surface_detector.is_colliding():
				if surface_dist >= 3:
					immersion = 0
				elif surface_dist <= 2:
					immersion = 1
				else:
					immersion = 1 - (surface_dist - 2)
			else:
				immersion = 1
			
			#var grav := body.get_gravity()
			#var buoy := -grav.y
			var grav := Vector2(0,75)
			var buoy := -grav.y
			
			# Apply gravity
			velocity += grav * delta
			
			# Apply buoyancy
			velocity.y += immersion * (buoy - grav.y) * delta
			
			# Limit velocity
			velocity.y = max(velocity.y,-12)
			
			velocity.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * WALK_SPEED * 0.25
			
			if velocity.x:
				_direction = sign(velocity.x)
			
			_move()
			
			_uncontrolled_jump_x_vel = velocity.x
			
			if Input.is_action_just_pressed("move_down") and Global.session.upgrades.water_walk:
				_swim_mode = false
				_state = State.NORMAL
			
			Global.session.is_underwater = water_detector.has_overlapping_areas() or water_detector.has_overlapping_bodies()
			if not Global.session.is_underwater and not water_surface_detector.is_colliding():
				_state = State.NORMAL
			
			# Trying to jump
			var can_swim_jump := not swim_jump_detector.has_overlapping_areas() and not swim_jump_detector.has_overlapping_bodies()
			if can_swim_jump and Input.is_action_just_pressed("jump") and _jump_cooldown <= 0 and Global.session.upgrades.jump:
				# Initiate jump
				if JUMP_ANTICIPATION_DURATION > 0 and not Global.session.upgrades.controlled_fall:
					_state = State.JUMP_ANTICIPATION
				else:
					_jump(JUMP_INIT_SPEED)
					_state = State.NORMAL
		State.DAED:
			if _state_countdown < 0:
				Global.session.load_checkpoint()
				Refs.level_manager.go_to_room(Global.session.checkpoint.room, Global.session.checkpoint.pos)
				health.value = health.maximum
				_i_frames = 0.01
				_uncontrolled_jump_x_vel = 0
				velocity.x = 0
				velocity.y = 0
				
				_state = State.NORMAL
			
			_state_countdown -= delta
	
	if body.is_on_floor():
		_fall_peak = body.position.y
	else:
		_fall_peak = min(_fall_peak, body.position.y)
	
	_was_on_floor = Global.Ternary.TRUE if body.is_on_floor() else Global.Ternary.FALSE
	
	# Failed backdash penalty
	if _backdash_cooldown <= 0 and Global.session.upgrades.backdash and Input.is_action_just_pressed("dodge") and not _should_backdash():
		_backdash_cooldown = 0.5
	
	# Bat mana drain and recovery
	if _state != State.BAT:
		if body.is_on_floor() or _state == State.CLIMB or _state == State.SWIM:
			_bat_mana = min(_bat_mana + delta, BAT_DURATION)
	else:
		_bat_mana = max(0, _bat_mana - delta)
	
	# Nullify climb cooldown if away from ladder that caused it
	if abs(_last_climb_x - body.position.x) > 2:
		_climb_cooldown = 0
	
	# Die if no health
	if _state != State.DAED and health.value <= 0:
		_state = State.DAED
	
	
	# Animation
	anim.direction = _direction
	anim.speed_scale = 1
	if _state == State.DAED:
		anim.animation = anim.AnimationId.DISAPPEAR
	elif _state == State.BAT:
		if _state_countdown <= 0:
			anim.animation = anim.AnimationId.APPEAR
		else:
			anim.animation = anim.AnimationId.FAIRY
	elif _state == State.ATTACK:
		anim.animation = anim.AnimationId.ATTACK
	elif _state == State.CLIMB:
		anim.animation = anim.AnimationId.CLIMB
		anim.speed_scale = velocity.length() / 20
	elif _state == State.SWIM:
		anim.animation = anim.AnimationId.SWIM
	elif body.is_on_floor():
		if _state == State.RUN:
			anim.speed_scale = 1.5
			anim.animation = anim.AnimationId.SPRINT_START
		else:
			if velocity.x == 0:
				anim.animation = anim.AnimationId.IDLE
			else:
				anim.animation = anim.AnimationId.WALK
				anim.speed_scale = absf(velocity.x) / 40.0
	else:
		if abs(velocity.y) < SLOW_FALL_THRESHOLD:
			anim.animation = anim.AnimationId.FALL_SLOW
			if _state == State.RUN and velocity.y > 0:
				anim.animation = anim.AnimationId.WALK
				anim.speed_scale = 0
				anim.set_progress(0.1)
		else:
			anim.animation = anim.AnimationId.FALL_FAST
	
	if _state == State.JUMP_ANTICIPATION or _state == State.JUMP_RECOVERY:
		anim.animation = anim.AnimationId.FALL_LAND
	
	if _state == State.RECOIL:
		anim.animation = anim.AnimationId.FALL_FAST
	elif _state == State.HURT:
		anim.animation = anim.AnimationId.HURT
	elif _state == State.FALLEN:
		anim.animation = anim.AnimationId.FALL_FLAT
	
	if anim.center.rotation != _target_angle:
		var dir := signf(_target_angle - anim.center.rotation)
		var rot := (_target_angle - anim.center.rotation) if abs((_target_angle - anim.center.rotation)) > _target_angle_min_rotation else dir * _target_angle_min_rotation
		anim.center.rotation = anim.center.rotation + rot * delta / _target_angle_time
		if signf(_target_angle - anim.center.rotation) != dir:
			anim.center.rotation = _target_angle
	
	if body.is_on_floor():
		anim.center.rotation = 0
	
	if _shake_cooldown > 0:
		if _shake_tick <= 0:
			anim.position = Vector2(1,0).rotated([0.0,PI * 0.5,PI,PI * 1.5].pick_random())
			_shake_tick = 0.025
	else:
		anim.position = Vector2(0,0)
	
	
	# MISC
	for _are in hitbox.get_overlapping_areas():
		_take_damage()
	for _bod in hitbox.get_overlapping_bodies():
		_take_damage()
	
	#var state_names := [
		#"NONE",
		#"NORMAL",
		#"JUMP_ANTICIPATION",
		#"JUMP_RECOVERY",
		#"BACKDASH",
		#"RUN",
		#"RECOIL",
		#"FALLEN",
		#"ATTACK",
		#"CLIMB",
		#"HURT",
		#"DAED",
		#"BAT",
		#"GRIFFON",
		#"HIT_CEILING",
		#"WALLJUMP",
		#"SWIM",
		#"WATER_MOVE"
	#]
	#state_debug_label.text = state_names[_state]
	
	bat_mana_center.current = _bat_mana / BAT_DURATION
	
	#if velocity.x == 0 and (_state == State.NORMAL or body.is_on_wall()):
		#var t = Time.get_ticks_msec() - start_time
		#if t > 1000:
			#print(t)
		#start_time = Time.get_ticks_msec()
	
	if _state != State.BAT and _state != State.DAED:
		if is_in_wall_detector.has_overlapping_bodies():
			if _inside_wall_timer > 0.25:
				_inside_wall_timer = 0
				_state = State.DAED
			_inside_wall_timer += delta
		else:
			_inside_wall_timer -= delta
			_inside_wall_timer = max(0, _inside_wall_timer)
	
	
	if _state != State.DAED:
		_exhale_timer -= delta
		
		if water_bubble_possible_detector.has_overlapping_areas():
			
			if _exhale_timer < 0:
				var ub := UNDERWATER_BUBBLE.instantiate()
				ub.rises = true
				Refs.level_manager.current_room.add_child(ub)
				ub.global_position = body.global_position
				ub.position.x += 1
				ub.position.y -= 6
		
		if _exhale_timer < 0:
			_exhale_timer = 1 + randf()
	
	if interaction_checker.has_overlapping_areas():
		interaction_checker.visible = true
	else:
		interaction_checker.visible = false
#
#var start_time := 0


func _take_damage(dmg: int = 1):
	if _state == State.DAED: return
	if _state == State.HURT: return
	if _i_frames > 0: return
	_i_frames = 3
	health.value -= max(dmg,0)
	if health.value <= 0:
		_state = State.DAED
		_i_frames = 0
	else:
		_state = State.HURT


func _on_hitbox_area_entered(_area: Area2D) -> void:
	_take_damage()


func _on_hitbox_body_entered(_body: Node2D) -> void:
	_take_damage()


func _on_character_animations_animation_finished() -> void:
	if anim.animation == anim.AnimationId.APPEAR:
		_state = State.NORMAL


func _on_griffon_ceiling_smash() -> void:
	_shake_cooldown = 0.2


func _on_character_animations_animation_looped() -> void:
	pass
	#if anim.animation == anim.AnimationId.WALK:
		#AudioManager.rock_footsteps.walk.play()
