extends Area2D

const PROGRESS_SPEED := 6.0

@onready var tile_map_layer: TileMapLayer = %TileMapLayer

@export var action: Activatable

@export var flag := ""
@export var flag_disabler := false
## Can be switched off and on instead of just activating
@export var toggleable := false
@export_multiline var text: Array[String] = []


var _cooldown := 0.0


var _progress := 0.0:
	set(p):
		_progress = clampf(p, 0, 1)


func _get_flag():
	return flag if flag != "" else Refs.level_manager.get_unique_name(self)


func is_enabled() -> bool:
	if not Refs.level_manager: return false
	if flag_disabler:
		return not Global.session.saved_data.object_flags.has(_get_flag()) or not Global.session.saved_data.object_flags[_get_flag()]
	else:
		return Global.session.saved_data.object_flags.has(_get_flag()) and Global.session.saved_data.object_flags[_get_flag()]


func _determine_tile() -> void:
	if _progress >= 1:
		tile_map_layer.set_cell(Vector2i(0, 0), 5, Vector2i(6, 46))
	elif _progress > 0.5:
		tile_map_layer.set_cell(Vector2i(0, 0), 5, Vector2i(1, 46))
	else:
		tile_map_layer.set_cell(Vector2i(0, 0), 5, Vector2i(0, 46))


func _ready() -> void:
	if is_enabled():
		_progress = 1
		_determine_tile()


func _process(delta: float) -> void:
	if is_enabled():
		_progress += delta * PROGRESS_SPEED
		_determine_tile()
	else:
		_progress -= delta * PROGRESS_SPEED
		_determine_tile()
	
	if _cooldown > 0:
		_cooldown -= delta * PROGRESS_SPEED
		return
	
	if (not is_enabled() or toggleable) and (get_overlapping_bodies().size() > 0 or get_overlapping_areas().size() > 0):
		Global.session.saved_data.object_flags[_get_flag()] = not flag_disabler if not is_enabled() else flag_disabler
		_cooldown = 1.2
		if is_enabled():
			if action:
				action.activate()
			if text.size() > 0:
				MessageDisplayer.display(text)
