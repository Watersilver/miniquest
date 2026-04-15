extends Node2D
class_name Projectile

@onready var sprite: Sprite2D = %Sprite
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var hazard: Hazard = %Hazard

@export var direction := Global.Direction.RIGHT

@export var gravity := 66.0

@export var speed := 33.0

@export var oscillation: OscillationResource

var start_y := 0.0

var velocity := Vector2()

func _on_screen_exited():
	queue_free()


func _ready() -> void:
	sprite.flip_h = direction == Global.Direction.LEFT
	visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exited)


func _process(_delta: float) -> void:
	sprite.flip_h = direction == Global.Direction.LEFT


func _physics_process(delta: float) -> void:
	if oscillation.amplitude.y > 0:
		if not oscillation.has_updated():
			start_y = position.y
		oscillation.update(delta)
		position.y = start_y + oscillation.position.y
	
	velocity.x = speed * direction
	velocity.y += delta * gravity
	position += delta * velocity
