extends Node2D


@onready var ray_cast_2d: RayCast2D = %RayCast2D
@onready var arrow: TrapArrow = $Arrow


@export var raycast_start_dir := Global.Direction.RIGHT


var spawn_point := global_position
var spawn_timer := 0.0

func _ready() -> void:
	@warning_ignore("int_as_enum_without_cast")
	arrow.dir = -raycast_start_dir
	var dir := 1 if raycast_start_dir == Global.Direction.RIGHT else -1
	ray_cast_2d.target_position = Vector2(999 * dir, 0)
	ray_cast_2d.force_raycast_update()
	
	arrow.collided.connect(func(): spawn_timer = 1)
	arrow.out_of_bounds.connect(func(): spawn_timer = 0.1)


func _physics_process(delta: float) -> void:
	if ray_cast_2d.enabled:
		ray_cast_2d.force_raycast_update()
		if ray_cast_2d.is_colliding():
			spawn_point = ray_cast_2d.get_collision_point()
		ray_cast_2d.enabled = false
	
	if spawn_timer > 0:
		spawn_timer -= delta
		
		if spawn_timer <= 0:
			arrow.global_position = spawn_point
			arrow.reset()
