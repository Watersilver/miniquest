@tool
extends CharacterBody2D
class_name IceSpike

@onready var sprite_2d: Sprite2D = %Sprite2D

@onready var common_enemy: CommonEnemy = %CommonEnemy

@onready var player_detector: Area2D = %PlayerDetector:
	set(pd):
		player_detector = pd
		
		_sync_pl_det_radius()
@onready var prowling_shape: CollisionShape2D = %ProwlingShape
@onready var ceiling_shape: CollisionShape2D = %CeilingShape

@onready var floor_checker: Area2D = %FloorChecker
@onready var ceil_checker: Area2D = %CeilChecker
@onready var player_seer: RayCast2D = %PlayerSeer
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var frost: CollisionShape2D = %Frost

enum State {
	PROWLING,
	RISING,
	MOVING,
	FALLING
}

enum Type {
	FLOOR,
	CEIL
}
@export var type := Type.FLOOR

@export var direction := Global.Direction.LEFT

@export var detect_radius := 48:
	set(dr):
		detect_radius = dr
		
		_sync_pl_det_radius()

@export var start_speed := 25

@export var gravity := 200

@export var no_prowling := false

const _RISING_DURATION := 0.5

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX
var _state := State.PROWLING
var _state_timer := 0.0
var _init_placement_done := false
var _out_of_bounds_timer := 0.0
var _ceil_grav_timer := 0.0

const _INIT_DURATION := 0.05
var _init_timer := _INIT_DURATION


func _sync_pl_det_radius():
	if not player_detector: return
	
	var c := player_detector.get_children()[0]
	if c is CollisionShape2D:
		var s = c.shape
		if s is CircleShape2D:
			s.radius = detect_radius


func _on_died():
	sprite_2d.frame_coords.y = 36


func _ready() -> void:
	sprite_2d.flip_h = direction == Global.Direction.LEFT
	sprite_2d.flip_v = type == Type.CEIL
	common_enemy.position.y = -2 if type == Type.CEIL else 0
	
	if Engine.is_editor_hint():
		return
	
	sprite_2d.visible = _state != State.PROWLING
	common_enemy.died.connect(_on_died)
	prowling_shape.set_deferred("disabled", true)
	ceiling_shape.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	sprite_2d.flip_h = direction == Global.Direction.LEFT
	sprite_2d.flip_v = type == Type.CEIL
	common_enemy.position.y = -2 if type == Type.CEIL else 0
	
	if Engine.is_editor_hint():
		sprite_2d.frame_coords.x = 2
		sprite_2d.frame_coords.y = 35
		return
	
	if visible_on_screen_notifier_2d.is_on_screen():
		_out_of_bounds_timer = 0
	else:
		_out_of_bounds_timer += delta
	if _out_of_bounds_timer > 1:
		queue_free()
	
	if no_prowling and detect_radius < 202:
		detect_radius = 202
	
	if not _init_placement_done:
		_init_placement_done = true
		var y := 160.0
		move_and_collide(Vector2(0, -y if type == Type.CEIL else y))
		if type == Type.CEIL:
			move_and_collide(Vector2(0, 0.01))
		return
	
	if common_enemy.is_dead():
		frost.disabled = true
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			sprite_2d.frame_coords.y = 37
		if _death_timer < 0:
			queue_free()
		_death_timer -= delta
		return
	
	if common_enemy.is_hurt():
		sprite_2d.frame_coords.y = 36
		return
	
	sprite_2d.frame_coords.y = 35
	
	sprite_2d.visible = _state != State.PROWLING
	prowling_shape.set_deferred("disabled", _state != State.PROWLING)
	ceiling_shape.set_deferred("disabled", not (_state == State.MOVING and type == Type.CEIL))
	match _state:
		State.PROWLING:
			var can_see_player := no_prowling and _init_timer <= 0
			_init_timer -= delta
			if not can_see_player:
				if Refs.level_manager and Refs.level_manager.player:
					player_seer.target_position = Refs.level_manager.player.hitbox_shape.global_position - player_seer.global_position
					player_seer.force_update_transform()
					player_seer.force_raycast_update()
					can_see_player = not player_seer.is_colliding() and not player_seer.target_position.is_zero_approx()
			if can_see_player and player_detector.has_overlapping_bodies():
				_state = State.RISING
				frost.disabled = false
				_state_timer = 0
				var b := player_detector.get_overlapping_bodies()[0]
				var dir = b.global_position - global_position
				if dir.x > 0:
					direction = Global.Direction.RIGHT
				else:
					direction = Global.Direction.LEFT
		State.RISING:
			_state_timer += delta
			if _state_timer < _RISING_DURATION * 0.33:
				sprite_2d.frame_coords.x = 0
			elif _state_timer < _RISING_DURATION * 0.66:
				sprite_2d.frame_coords.x = 1
			else:
				sprite_2d.frame_coords.x = 2
			if _state_timer > _RISING_DURATION:
				_state = State.MOVING
				velocity.x = direction * start_speed
		State.MOVING:
			common_enemy.harmless = false
			common_enemy.unhittable = false
			var apply_grav := true
			if type == Type.CEIL:
				apply_grav = false
				if ceil_checker.has_overlapping_areas() or ceil_checker.has_overlapping_bodies():
					_ceil_grav_timer -= delta
					_ceil_grav_timer = maxf(0, _ceil_grav_timer)
				else:
					if _ceil_grav_timer > 0.05:
						apply_grav = true
					_ceil_grav_timer += delta
			if type == Type.FLOOR and (floor_checker.has_overlapping_areas() or floor_checker.has_overlapping_bodies()):
				apply_grav = false
			if apply_grav:
				velocity.y += gravity * delta
				player_detector.collision_mask = 0
			
			if type == Type.CEIL and player_detector.has_overlapping_bodies():
				velocity.x = 0
				ceil_checker.collision_mask = 0
				_ceil_grav_timer = INF
			
			move_and_slide()
			
			velocity.x += velocity.x * delta
			
			if is_on_wall() or (type == Type.CEIL and is_on_floor()):
				common_enemy.hitpoints = -1
