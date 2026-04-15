extends Area2D

@onready var tile_map_layer: TileMapLayer = %TileMapLayer

@export var action: Activatable

@export var flag := ""
@export_multiline var text: Array[String] = []

var _progress := 0.0

func _get_flag():
	return flag if flag != "" else Refs.level_manager.get_unique_name(self)

func is_enabled() -> bool:
	if not Refs.level_manager: return false
	return Global.session.saved_data.object_flags.has(_get_flag())

func _determine_tile() -> void:
	if _progress > 1:
		tile_map_layer.set_cell(Vector2i(0, 0), 5, Vector2i(2, 46))
	elif _progress > 0.5:
		tile_map_layer.set_cell(Vector2i(0, 0), 5, Vector2i(1, 46))

func _ready() -> void:
	if is_enabled():
		_progress = 1
		_determine_tile()

func _process(delta: float) -> void:
	if is_enabled():
		_progress += delta * 6
		_determine_tile()
	elif get_overlapping_bodies().size() > 0:
		if action: action.activate()
		if text.size() > 0:
			MessageDisplayer.display(text)
		Global.session.saved_data.object_flags[_get_flag()] = true
