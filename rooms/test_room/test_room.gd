extends Node2D

@onready var tile_map_layer: MainTileset = $TileMapLayer

func shake_it():
	tile_map_layer.apply_shake(0.3,4)
