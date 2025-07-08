extends Node2D

@onready var nine_patch_rect: NinePatchRect = %NinePatchRect

var _t := 0.0


func _process(delta: float) -> void:
	if fmod(_t,1) > 0.5:
		nine_patch_rect.region_rect.position.x = 24
	else:
		nine_patch_rect.region_rect.position.x = 0
	
	_t += delta
