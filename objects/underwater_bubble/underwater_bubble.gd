extends Node2D
class_name UnderwaterBubble


@onready var sprite: Sprite2D = %Sprite
@onready var water_detector: Area2D = %WaterDetector
@onready var is_above_visible: VisibleOnScreenNotifier2D = %IsAboveVisible
@onready var is_below_visible: VisibleOnScreenNotifier2D = %IsBelowVisible


var rises := false

## Values: 0 - 1 - 2
var starting_frame := 0

const PERIOD := 3
var t := randf() * PERIOD
var _start_pos_set := false
var start_pos := Vector2(0,0)


func _ready() -> void:
	if rises:
		starting_frame = 0
		t = 0
	
	sprite.frame_coords.y += starting_frame


func _physics_process(delta: float) -> void:
	if not _start_pos_set:
		_start_pos_set = true
		start_pos = position
	
	if rises:
		if starting_frame == 0 and t > 0.5:
			sprite.frame_coords.y += 1
			starting_frame += 1
		if starting_frame == 1 and t > 1:
			position.x -= 1
			sprite.frame_coords.y += 1
			starting_frame += 1
		
		position.x = start_pos.x + sin(t * TAU)
		position.y = start_pos.y - t * 10 + sin(t * TAU / PERIOD)
		
		if t > 0.1:
			if is_above_visible.is_on_screen() and not water_detector.has_overlapping_areas():
				queue_free()
			if not is_below_visible.is_on_screen():
				queue_free()
		t += delta
	else:
		position.y = start_pos.y + sin(t * TAU / PERIOD) * (2 - (starting_frame + 1) * 2.0 / 3.0)
		t += delta
		t = fmod(t, PERIOD)
