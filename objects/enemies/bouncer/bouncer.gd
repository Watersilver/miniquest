extends CharacterBody2D
class_name Bouncer

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var hazard: Hazard = %Hazard

@export var direction = Vector2(0, 0)
@export var speed := 20.0

@export var dmg_dice := Global.Damage.ROLL_1D4:
	set(d):
		dmg_dice = d
		if not is_node_ready():
			await ready
		hazard.dmg_dice = d
@export var enhancement := 0:
	set(e):
		enhancement = e
		if not is_node_ready():
			await ready
		hazard.enhancement = e
@export var advantage := false:
	set(a):
		advantage = a
		if not is_node_ready():
			await ready
		hazard.advantage = a

const COLLISION_COOLDOWN_DURATION := 0.05

var _cooldown := 0.0
var _can_collide := true
var _t := 0.0


func _ready() -> void:
	hazard.dmg_dice = dmg_dice
	hazard.enhancement = enhancement
	hazard.advantage = advantage


func _physics_process(delta: float) -> void:
	sprite_2d.rotation = floorf(_t * 10 / (TAU/4.0)) * TAU/4.0
	sprite_2d.rotation = fmod(sprite_2d.rotation, TAU)
	_t += delta
	
	if direction.is_zero_approx():
		queue_free()
	
	velocity = direction.normalized() * speed
	
	move_and_slide()
	
	if _can_collide:
		if is_on_ceiling() or is_on_floor():
			direction.y = -direction.y
			_can_collide = false
		if is_on_wall():
			direction.x = -direction.x
			_can_collide = false
	else:
		if _cooldown > COLLISION_COOLDOWN_DURATION:
			_cooldown = 0
			_can_collide = true
		_cooldown += delta
