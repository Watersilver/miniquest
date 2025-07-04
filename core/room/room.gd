@tool

extends Node2D
class_name Room

@export_group("Starting Upgrades", "st_up_")
@export_flags("controlled_fall", "jump", "double_jump", "backdash", "run", "bat", "griffon", "swim", "water_walk") var st_up_skills := 0

const BLOCK_WIDTH := 160
const BLOCK_HEIGHT := 120 - 16 #(Screen size - 16 to allow for hud on the bottom)

@onready var room_shape: CollisionShape2D = %RoomShape
var room_shape_rect: RectangleShape2D

const MAIN_TILESET_GD = preload("res://main_tileset.gd")
const MAIN_TILESET_TRES = preload("res://main_tileset.tres")
@export_tool_button("Add tilemap layer") var atl := func():
	var tml := TileMapLayer.new()
	tml.tile_set = MAIN_TILESET_TRES
	tml.set_script(MAIN_TILESET_GD)
	
	var rg := RegEx.new()
	var i := 1
	rg.compile("^TileLayer\\d+$")
	for child in get_children():
		var result := rg.search(child.name)
		if result:
			var n := int(child.name)
			if n >= i: i = n + 1
	
	add_child(tml)
	tml.name = "TileLayer" + str(i)
	tml.owner = get_tree().edited_scene_root

@export_range(1,5,1) var size_x := 1
@export_range(1,5,1) var size_y := 1

@export var is_empty := false

@export_group("Exits")
@export var exit_markers_up: Array[int] = []
@export var exit_markers_down: Array[int] = []
@export var exit_markers_left: Array[int] = []
@export var exit_markers_right: Array[int] = []
@export_subgroup("Hide Exits")
@export var hide_exits_up: Array[int] = []
@export var hide_exits_down: Array[int] = []
@export var hide_exits_left: Array[int] = []
@export var hide_exits_right: Array[int] = []

const _REDRAW_PERIOD := 0.2
var _redraw_timer := randf() * _REDRAW_PERIOD

var _incomplete := false


func get_grid_coords() -> Vector2i:
	return Vector2i(roundi(position.x / float(BLOCK_WIDTH)), roundi(position.y / float(BLOCK_HEIGHT)))


func get_width() -> int:
	return size_x * BLOCK_WIDTH

func get_height() -> int:
	return size_y * BLOCK_HEIGHT



func _get_configuration_warnings() -> PackedStringArray:
	if _incomplete:
		return ["Room is incomplete"]
	else:
		return []


func _ready() -> void:
	room_shape_rect = room_shape.shape


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		room_shape_rect.size.x = size_x * BLOCK_WIDTH
		room_shape_rect.size.y = size_y * BLOCK_HEIGHT
		room_shape.position.x = room_shape_rect.size.x * 0.5
		room_shape.position.y = room_shape_rect.size.y * 0.5
		
		if _redraw_timer > _REDRAW_PERIOD:
			_redraw_timer -= _REDRAW_PERIOD
			queue_redraw()
		_redraw_timer += delta
		
		var prev := _incomplete
		if not is_empty and get_children().size() < 2:
			_incomplete = true
		else:
			_incomplete = false
		if prev != _incomplete:
			update_configuration_warnings()


func _draw() -> void:
	if Engine.is_editor_hint():
		if _incomplete:
			draw_rect(Rect2(Vector2(0,0),Vector2(size_x * BLOCK_WIDTH, size_y * BLOCK_HEIGHT)),Color.CRIMSON)
		
		var line_w := 4 / get_viewport().global_canvas_transform.get_scale().x
		var offset := line_w / 2
		for i in size_x:
			var from := Vector2(0,0)
			from.x = i * BLOCK_WIDTH
			var to := Vector2(0,0)
			to.x = from.x + BLOCK_WIDTH
			# draw top
			if exit_markers_up.has(i):
				draw_line(from + Vector2(0,offset), from + Vector2(16,offset), Color.DODGER_BLUE,line_w)
				if hide_exits_up.has(i):
					draw_dashed_line(from + Vector2(16,offset), to - Vector2(16,-offset), Color.DODGER_BLUE,line_w,4)
				draw_line(to - Vector2(16,-offset), to + Vector2(0,offset), Color.DODGER_BLUE,line_w)
			else:
				draw_line(from + Vector2(0,offset), to + Vector2(0,offset), Color.DODGER_BLUE,line_w)
			# draw bottom
			from.y += BLOCK_HEIGHT * size_y
			to.y += BLOCK_HEIGHT * size_y
			if exit_markers_down.has(i):
				draw_line(from - Vector2(0,offset), from + Vector2(16,-offset), Color.DODGER_BLUE,line_w)
				if hide_exits_down.has(i):
					draw_dashed_line(from + Vector2(16,-offset), to - Vector2(16,offset), Color.DODGER_BLUE,line_w,4)
				draw_line(to - Vector2(16,offset), to - Vector2(0,offset), Color.DODGER_BLUE,line_w)
			else:
				draw_line(from - Vector2(0,offset), to - Vector2(0,offset), Color.DODGER_BLUE,line_w)
		
		for i in size_y:
			var from := Vector2(0,0)
			from.y = i * BLOCK_HEIGHT
			var to := Vector2(0,0)
			to.y = from.y + BLOCK_HEIGHT
			# draw left
			if exit_markers_left.has(i):
				draw_line(from + Vector2(offset,0), from + Vector2(offset,16), Color.DODGER_BLUE,line_w)
				if hide_exits_left.has(i):
					draw_dashed_line(from + Vector2(offset,16), to - Vector2(-offset,16), Color.DODGER_BLUE,line_w,4)
				draw_line(to - Vector2(-offset,16), to + Vector2(offset,0), Color.DODGER_BLUE,line_w)
			else:
				draw_line(from + Vector2(offset,0), to + Vector2(offset,0), Color.DODGER_BLUE,line_w)
			# draw right
			from.x += BLOCK_WIDTH * size_x
			to.x += BLOCK_WIDTH * size_x
			if exit_markers_right.has(i):
				draw_line(from - Vector2(offset,0), from + Vector2(-offset,16), Color.DODGER_BLUE,line_w)
				if hide_exits_right.has(i):
					draw_dashed_line(from + Vector2(-offset,16), to - Vector2(offset,16), Color.DODGER_BLUE,line_w,4)
				draw_line(to - Vector2(offset,16), to - Vector2(offset,0), Color.DODGER_BLUE,line_w)
			else:
				draw_line(from - Vector2(offset,0), to - Vector2(offset,0), Color.DODGER_BLUE,line_w)
