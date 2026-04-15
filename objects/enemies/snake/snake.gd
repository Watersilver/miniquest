@tool

extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D

@onready var common_enemy: CommonEnemy = %CommonEnemy

@onready var wall_checker: Area2D = %WallChecker
@onready var wall_checker_shape: CollisionShape2D = %WallCheckerShape
@onready var floor_checker: Area2D = %FloorChecker
@onready var floor_checker_shape: CollisionShape2D = %FloorCheckerShape
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

enum SnakeType {
	## Red snakes patrol
	RED,
	## Yellow snakes fall off
	YELLOW
}

enum Facing {
	LEFT = -1,
	RIGHT = 1,
	RANDOM = 0
}

@export var type = SnakeType.RED

@export var init_facing := Facing.RANDOM:
	set(f):
		init_facing = f
		if Engine.is_editor_hint():
			if is_node_ready():
				initialise_facing()

@export var face_player_on_start := false

@export_range(1.0,100.0) var speed := 33.0

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX
const _TURNAROUND_COOLDOWN_DURATION := 0.1
var _turnaround_cooldown := _TURNAROUND_COOLDOWN_DURATION

var facing := Global.Direction.LEFT:
	set(f):
		facing = f
		
		if not is_node_ready():
			await ready
		
		wall_checker_shape.position.x = abs(wall_checker_shape.position.x) * facing
		floor_checker_shape.position.x = abs(floor_checker_shape.position.x) * facing

func initialise_facing():
	if init_facing == Facing.RANDOM:
		facing = Global.Direction.LEFT if randf() < 0.5 else Global.Direction.RIGHT
	elif init_facing == Facing.LEFT:
		facing = Global.Direction.LEFT
	else:
		facing = Global.Direction.RIGHT


func _on_died():
	animated_sprite_2d.play("death")


func _ready() -> void:
	initialise_facing()
	
	if not Engine.is_editor_hint():
		common_enemy.died.connect(_on_died)
		
		if face_player_on_start and Refs.level_manager and Refs.level_manager.player:
			var diff = Refs.level_manager.player.global_position.x - global_position.x
			if diff < 0:
				facing = Global.Direction.LEFT
			else:
				facing = Global.Direction.RIGHT
	
	animated_sprite_2d.flip_h = facing == Global.Direction.LEFT
	
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	animated_sprite_2d.flip_h = facing == Global.Direction.LEFT
	
	if not Engine.is_editor_hint():
		if common_enemy.is_dead():
			if _death_timer < _DEATH_TIMER_MAX * 0.5:
				animated_sprite_2d.play("death")
			if _death_timer < 0:
				queue_free()
			if common_enemy.is_frozen:
				animated_sprite_2d.play("damage")
			else:
				_death_timer -= delta
			return
		
		if common_enemy.is_hurt():
			animated_sprite_2d.play("damage")
			
			## WARNING: If I don't call move_and_slide before returning
			## children areas get_overlapping_bodies DONT WORK ANYMORE
			velocity.x = 0
			move_and_slide()
			
			return
		
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		move_and_slide()
		
		if is_on_floor():
			_turnaround_cooldown -= delta
			
			if _turnaround_cooldown <= 0:
				if wall_checker.get_overlapping_bodies().size() > 0:
					if facing == Global.Direction.LEFT: facing = Global.Direction.RIGHT
					else: facing = Global.Direction.LEFT
					_turnaround_cooldown = _TURNAROUND_COOLDOWN_DURATION
			
			if _turnaround_cooldown <= 0:
				if type == SnakeType.RED and floor_checker.get_overlapping_bodies().size() < 1:
					if facing == Global.Direction.LEFT: facing = Global.Direction.RIGHT
					else: facing = Global.Direction.LEFT
					_turnaround_cooldown = _TURNAROUND_COOLDOWN_DURATION
			
			if type == SnakeType.RED:
				animated_sprite_2d.play("red_walk")
			elif type == SnakeType.YELLOW:
				animated_sprite_2d.play("yellow_walk")
			
			velocity.x = speed * facing
		else:
			velocity.x = 0
	else:
		if type == SnakeType.RED:
			if animated_sprite_2d.animation != "red_walk":
				animated_sprite_2d.play("red_walk")
		elif type == SnakeType.YELLOW:
			if animated_sprite_2d.animation != "yellow_walk":
				animated_sprite_2d.play("yellow_walk")
