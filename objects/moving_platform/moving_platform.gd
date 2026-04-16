@tool

extends Node2D

@export var path_follow_2d: PathFollow2D

@export var speed := 20.0
@export_range(0,1) var init_progress_ratio := 0.0
@export var init_inverse := false:
	set(i):
		init_inverse = i
		if not is_node_ready(): await ready
		if Engine.is_editor_hint():
			inverse = init_inverse
@export var active := true
@export var active_in_editor := false

@export var activation_trigger := ""

@export var repeats := -1

var inverse := false

var r := -1

func _ready() -> void:
	r = repeats
	inverse = init_inverse
	if path_follow_2d:
		path_follow_2d.progress_ratio = init_progress_ratio

func _process(delta: float) -> void:
	if activation_trigger == null:
		activation_trigger = ""
	
	var a := active
	
	if Engine.is_editor_hint():
		a = active_in_editor and active
	else:
		if not active and activation_trigger != "":
			if Global.session.saved_data.object_flags.has(activation_trigger) and Global.session.saved_data.object_flags[activation_trigger]:
				active = true
	
	if a and path_follow_2d:
		var velocity := speed * (-1 if inverse else 1)
		path_follow_2d.progress += delta * velocity
		
		if not path_follow_2d.loop and not r == 1:
			if velocity > 0:
				if path_follow_2d.progress_ratio == 1:
					r -= 1
					inverse = not inverse
			elif velocity < 0:
				if path_follow_2d.progress_ratio == 0:
					r -= 1
					inverse = not inverse
