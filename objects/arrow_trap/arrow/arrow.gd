extends RayCast2D
class_name TrapArrow


@onready var hitbox_shape: CollisionShape2D = %HitboxShape
@onready var arrowback: Sprite2D = %Arrowback
@onready var arrowfront: Sprite2D = %Arrowfront
@onready var arrowback_ray: RayCast2D = %ArrowbackRay


@export var dir := Global.Direction.RIGHT:
	set(d):
		dir = d
		if is_node_ready():
			_handle_rot()


signal collided


## How often does it move (secs)
@export var freq := 0.125

## How much it moves on every tick (pixels)
@export var speed := 4.0

## How long before it disappears after hitting wall (-1 stays forever)
@export var linger_time := 0.5

var _t := 0.0
var _collided := false


func has_collided():
	return _collided


func reset():
	hitbox_shape.disabled = false
	
	arrowback_ray.enabled = true
	arrowback_ray.force_raycast_update()
	if arrowback_ray.is_colliding():
		arrowback.visible = false
	else:
		arrowback.visible = true
	arrowback_ray.enabled = false
	
	arrowfront.visible = true
	_collided = false
	_t = 0


func _handle_rot():
	if dir == Global.Direction.RIGHT:
		arrowfront.flip_h = false
		arrowback.flip_h = false
	else:
		arrowfront.flip_h = true
		arrowback.flip_h = true
	arrowback.position.x = -2 * dir
	arrowback_ray.position.x = 2 * dir
	arrowback_ray.target_position.x = -3 * dir
	arrowfront.position.x = 2 * dir
	hitbox_shape.position.x = 1.5 * dir
	target_position.x = 3.5 * dir
	force_raycast_update()


func _ready() -> void:
	_handle_rot()
	reset()


func _process(delta: float) -> void:
	if not _collided:
		if _t >= freq:
			arrowback.visible = true
			_t -= freq
			position.x += dir * speed
			force_raycast_update()
			if is_colliding():
				hitbox_shape.disabled = true
				arrowfront.visible = false
				_collided = true
				collided.emit()
	else:
		if linger_time != -1 and arrowback.visible:
			if _t >= linger_time:
				arrowback.visible = false
	_t += delta
