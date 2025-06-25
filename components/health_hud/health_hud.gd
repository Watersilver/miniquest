extends Node2D
class_name HealthHud

const OTHER = preload("res://assets/Chroma-Noir-User-Interface-v1.0/Chroma-Noir-User-Interface-8x8/Other.png")

const FULL_X := 40
const HALF_X := 64
const EMPTY_X := 80
const SINGLE_FULL_X := 48
const SINGLE_EMPTY_X := 88

const BAR_Y := 32

const TICK := 8

@onready var bar: Node2D = %Bar
@export var player: Player

var maximum := 0.0
var value := 0.0

func _physics_process(_delta: float) -> void:
	var recalculate := false
	
	if player.health.maximum != maximum:
		maximum = player.health.maximum
		recalculate = true
	
	if recalculate:
		for child in bar.get_children():
			bar.remove_child(child)
		
		for tick in ceili(maximum / 2):
			var s := Sprite2D.new()
			s.texture = OTHER
			s.region_enabled = true
			s.region_rect = Rect2(FULL_X,BAR_Y,TICK,TICK)
			s.position.x = tick * 8
			bar.add_child(s)
		
		if fmod(maximum,2) != 0:
			bar.get_child(-1).region_rect = Rect2(SINGLE_FULL_X,BAR_Y,TICK,TICK)
	
	if player.health.value != value:
		value = player.health.value
		recalculate = true
	
	if recalculate:
		var i := 0
		for child in bar.get_children():
			i += 1
			if int(child.region_rect.position.x) % 40 == 8:
				if value < i:
					child.region_rect.position.x = SINGLE_EMPTY_X
				else:
					child.region_rect.position.x = SINGLE_FULL_X
			else:
				if value < i:
					child.region_rect.position.x = EMPTY_X
					i += 1
				else:
					i += 1
					if value < i:
						child.region_rect.position.x = HALF_X
					else:
						child.region_rect.position.x = FULL_X
