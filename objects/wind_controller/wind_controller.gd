extends Node2D
class_name WindController

const BLOWING_WIND_GRAPHIC = preload("uid://dvj1d31c8qim8")

enum Type {
	STATIC,
	OSCILLATING
}

@export var type := Type.STATIC

@export_group("static")
@export var wind := 0.0

@export_group("oscillating")
## Only x axis matters
@export var oscillation: OscillationResource

const WIDTH := 160.0
const HEIGHT := 104.0
## Higher makes it more probable to spawn
const STEEPNESS := 1.0

func get_spawn_probability_per_sec():
	return (-1 / (abs(wind * STEEPNESS) + 1)) + 1


func update_wind_from_oscillation(delta: float):
	oscillation.update(delta)
	wind = oscillation.position.x


func _ready() -> void:
	if type == Type.OSCILLATING:
		update_wind_from_oscillation(0)


func _process(delta: float) -> void:
	if randf() < get_spawn_probability_per_sec() * delta:
		var b: BlowingWindGraphic = BLOWING_WIND_GRAPHIC.instantiate()
		b.position.x = randf() * WIDTH
		b.position.y = randf() * HEIGHT
		b.faded = randf() < 0.5
		b.type = b.Type.Circle if randf() < 0.5 else b.Type.Square
		add_child(b)
	
	if type == Type.OSCILLATING:
		update_wind_from_oscillation(delta)
