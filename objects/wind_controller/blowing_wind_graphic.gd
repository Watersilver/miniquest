extends Node2D
class_name BlowingWindGraphic

@onready var spr: AnimatedSprite2D = %Spr

enum Type {
	Circle,
	Square
}

@export var type := Type.Circle
@export var faded := false


var t := 1 + randf() * 3.0

var _death_timer := 1.0
var _opacity := 0.0


func get_wind() -> float:
	var wind := 0.0
	var wcs := get_tree().get_nodes_in_group("wind_controllers")
	for n in wcs:
		if n is WindController:
			wind += n.wind
	return wind


func update_anim(wind: float, delta: float):
	var big := absf(wind) > 25
	
	if wind > 0:
		spr.flip_h = false
	else:
		spr.flip_h = true
	
	if absf(wind) > 0.1:
		_opacity += delta
	else:
		_opacity -= delta
	_opacity = clampf(0, _opacity, 1)
	
	match type:
		Type.Circle:
			if faded:
				if big:
					spr.play("bigcirclefaded")
				else:
					spr.play("circlefaded")
			else:
				if big:
					spr.play("bigcircle")
				else:
					spr.play("circle")
		Type.Square:
			if faded:
				if big:
					spr.play("bigsquarefaded")
				else:
					spr.play("squarefaded")
			else:
				if big:
					spr.play("bigsquare")
				else:
					spr.play("square")


func _ready() -> void:
	update_anim(get_wind(), 0)
	modulate.a = _death_timer * _opacity


func _process(delta: float) -> void:
	var w := get_wind()
	
	update_anim(w, delta)
	
	position.x += w * delta * 3
	
	modulate.a = _death_timer * _opacity
	
	if t < 0:
		if _death_timer < 0:
			queue_free()
		
		_death_timer -= delta * 4
	
	t -= delta
