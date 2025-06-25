extends Node2D
class_name BatManaCenter

@export var current := 0.0


var force_fadeout := false

var _visible_countdown := 0.0 # if > 0 _fade increases otherwise decreases
var _fade := 0.0 # 0.0 is transparent, 1.0 is opaque


func _ready() -> void:
	var s := Sprite2D.new()
	s.texture = CanvasTexture.new()
	s.position.x -= 4
	s.position.y -= 6
	s.scale.x = 8
	add_child(s)


func _physics_process(delta: float) -> void:
	if _visible_countdown > 0 and not force_fadeout:
		_fade = min(1, _fade + 2 * delta)
	else:
		_fade = max(0, _fade - 0.9 * delta)
	
	_visible_countdown -= delta
	
	if current < 1:
		_visible_countdown = 1.0
	
	for child in get_children():
		if child is Sprite2D:
			child.scale.x = current * 8.0
	
	modulate.a = round(_fade * 3) / 3.0
