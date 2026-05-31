extends Node2D

@onready var floor_tiles: MainTileset = %FloorTiles
@onready var floor_tiles_2: MainTileset = %FloorTiles2
@onready var polygon_2d: Polygon2D = %Polygon2D
@onready var polygon_2d_2: Polygon2D = %Polygon2D2
@onready var left: Node2D = %Left
@onready var right: Node2D = %Right


@export var speed := 3.0
@export var delay := 1.0


var _joever := false


func _ready() -> void:
	floor_tiles.visible = true
	floor_tiles_2.visible = true
	polygon_2d.visible = true
	polygon_2d_2.visible = true
	
	if Refs.level_manager:
		if Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self)) and Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)]:
			left.global_position.x = 80
			right.global_position.x = 80
			_joever = true


func _physics_process(delta: float) -> void:
	if _joever: return
	
	if delay > 0:
		delay -= delta
		if delay <= 0:
			Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
		return
	
	var done := 0
	
	left.global_position.x += delta * speed
	if left.global_position.x >= 80:
		left.global_position.x = 80
		done += 1
	right.global_position.x -= delta * speed
	if right.global_position.x <= 80:
		right.global_position.x = 80
		done += 1
	
	if done == 2:
		Refs.level_manager.shake_it(0.3, 3)
		_joever = true
