extends Node2D
class_name EnemyBat

@onready var sprite_2d: Sprite2D = %Sprite2D

@onready var common_enemy: CommonEnemy = %CommonEnemy

@onready var vosn: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

@export var direction := Global.Direction.LEFT
@export var speed := 13.0
@export var oscillation: OscillationResource

var start_y := position.y
var y_displ := 0.0

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX
var _timer := 0.0


static func get_new_default_oscillation() -> OscillationResource:
	var osc := OscillationResource.new()
	osc.amplitude.x = 0
	osc.amplitude.y = 4
	osc.frequency.x = 0
	osc.frequency.y = 0.5
	return osc


func update_y_pos():
	position.y = start_y + oscillation.position.y


func _on_died():
	sprite_2d.flip_v = false
	sprite_2d.frame_coords.x = 0
	sprite_2d.frame_coords.y = 74


func _ready() -> void:
	start_y = position.y
	common_enemy.died.connect(_on_died)
	if not oscillation:
		oscillation = get_new_default_oscillation()
	visible = false


func _physics_process(delta: float) -> void:
	visible = true
	
	if common_enemy.is_dead():
		if _death_timer < _DEATH_TIMER_MAX * 0.5:
			sprite_2d.frame_coords.x = 0
			sprite_2d.frame_coords.y = 74
		if _death_timer < 0:
			queue_free()
		if not common_enemy.is_frozen:
			_death_timer -= delta
		return
	
	if common_enemy.is_hurt():
		sprite_2d.frame_coords.x = 0
		sprite_2d.frame_coords.y = 73
		return
	
	if not vosn.is_on_screen() and _timer > 1:
		queue_free()
	
	sprite_2d.frame_coords.y = 72
	sprite_2d.frame_coords.x = floori(fmod(_timer * 2, 1.0) * 3)
	_timer += delta
	
	sprite_2d.flip_h = direction == -1
	position.x += direction * speed * delta
	oscillation.update(delta)
	update_y_pos()
