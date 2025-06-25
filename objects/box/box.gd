extends Node2D
class_name Box

## 0 - 3
@export var variant := 0

@onready var sprite: Sprite2D = %Sprite


func _ready() -> void:
	sprite.region_rect.position.x = variant * 2 * 8 
