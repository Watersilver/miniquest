extends Node2D
class_name Projectile

@onready var sprite: Sprite2D = %Sprite
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var hazard: Hazard = %Hazard

@export var direction := Global.Direction.RIGHT

@export var gravity := 66.0

@export var speed := 33.0

@export var oscillation: OscillationResource

## Ignored when zero
@export var vector_direction := Vector2(0, 0)

@export var lifetime := INF

## Use alternative sprite (the sword enemy one)
@export var shockwave_sprite := false

## Use alternative sprite (just a line)
@export var brick_sprite := false


var start_y := 0.0

var velocity := Vector2()

func _on_screen_exited():
	queue_free()


func _ready() -> void:
	sprite.flip_h = direction == Global.Direction.LEFT
	visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exited)
	if shockwave_sprite:
		sprite.region_rect = Rect2(16, 440, 5, 4)
	elif brick_sprite:
		sprite.region_rect = Rect2(2.0, 330.0, 4.0, 4.0)
	else:
		sprite.region_rect = Rect2(16, 472, 6, 5)


func _process(_delta: float) -> void:
	if shockwave_sprite:
		sprite.region_rect = Rect2(16, 440, 5, 4)
	elif brick_sprite:
		sprite.region_rect = Rect2(2.0, 330.0, 4.0, 4.0)
	else:
		sprite.region_rect = Rect2(16, 472, 6, 5)
	if vector_direction.is_zero_approx():
		sprite.flip_h = direction == Global.Direction.LEFT
	else:
		if sprite.flip_h:
			sprite.flip_h = false
		sprite.rotation = vector_direction.angle()


func _physics_process(delta: float) -> void:
	if lifetime < 0:
		queue_free()
	lifetime -= delta
	
	if vector_direction.is_zero_approx():
		if oscillation.amplitude.y > 0:
			if not oscillation.has_updated():
				start_y = position.y
			oscillation.update(delta)
			position.y = start_y + oscillation.position.y
		
		velocity.x = speed * direction
		velocity.y += delta * gravity
		position += delta * velocity
	else:
		velocity = vector_direction.normalized() * speed
		position += delta * velocity
