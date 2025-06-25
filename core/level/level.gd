@tool

extends Node2D
class_name Level

const _REDRAW_PERIOD := 0.33
var _redraw_timer := randf() * _REDRAW_PERIOD

var _new_room_pos := Vector2(0,0)
var _can_be_interacted_with := false


@export var start := Vector2i(0,0)

@export_tool_button("Add New Room (Insert)") var anr = func():
	const ROOM = preload("res://core/room/room.tscn")
	var new_room := ROOM.instantiate()
	new_room.position = _new_room_pos
	add_child(new_room)
	new_room.name = "Room"
	new_room.owner = get_tree().edited_scene_root


var _scene_layout: Dictionary[Vector2i, PackedScene] = {}
var _room_origin: Dictionary[PackedScene, Vector2i] = {}
func get_room_at(grid_pos: Vector2i) -> PackedScene:
	var room = _scene_layout.get(grid_pos)
	if room: return room
	return null

func get_room_origin_at(grid_pos: Vector2i) -> Vector2i:
	var r := get_room_at(grid_pos)
	var o = _room_origin.get(r)
	if not o: return grid_pos
	return o

func _ready() -> void:
	if Engine.is_editor_hint():
		InputMap.load_from_project_settings()
	else:
		for child in get_children():
			if child is Room:
				var grid_coords: Vector2i = child.get_grid_coords()
				var size := Vector2i(child.size_x, child.size_y)
				for subchild in child.find_children("*"):
					if not subchild.owner: continue
					if is_ancestor_of(subchild.owner): continue
					subchild.owner = child
				remove_child(child)
				child.position = Vector2(0,0)
				var ps := PackedScene.new()
				ps.pack(child)
				
				# Serialize to figure out what's wrong
				#if child.name == "Checkpoint":
					#ResourceSaver.save(ps, "res://fuck.tscn")
				
				_room_origin.set(ps, grid_coords)
				for x in size.x:
					for y in size.y:
						_scene_layout.set(grid_coords + Vector2i(x,y), ps)
				child.queue_free()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		if _redraw_timer > _REDRAW_PERIOD:
			_redraw_timer -= _REDRAW_PERIOD
			queue_redraw()
		_redraw_timer += delta
		
		
		var is_2d_editor_visible := false
		var ems := EditorInterface.get_editor_main_screen()
		for c in ems.get_children():
			if c.name.contains("CanvasItemEditor"):
				is_2d_editor_visible = c.visible
		
		if is_2d_editor_visible:
			for n in EditorInterface.get_selection().get_selected_nodes():
				if is_ancestor_of(n) or n == self:
					_can_be_interacted_with = true
					break
				else:
					_can_be_interacted_with = false
			if _can_be_interacted_with:
				if Input.is_action_just_pressed("ui_text_toggle_insert_mode"):
					anr.call()
				
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					var vr := get_viewport_rect()
					var vt := get_viewport_transform()
					var lmp := get_local_mouse_position()
					var lmp_trans = lmp * get_viewport().global_canvas_transform.y.y
					#print(get_viewport().global_canvas_transform.y.y)
					#print("x: ", lmp.x, "  |  ", -vt.origin.x)
					#print("y: ", lmp.y, "  |  ", -vt.origin.y)
					if lmp_trans.x > -vt.origin.x and lmp_trans.x < -vt.origin.x + vr.size.x:
						if lmp_trans.y > -vt.origin.y and lmp_trans.y < -vt.origin.y + vr.size.y:
							_new_room_pos.x = floor(lmp.x / Room.BLOCK_WIDTH) * Room.BLOCK_WIDTH
							_new_room_pos.y = floor(lmp.y / Room.BLOCK_HEIGHT) * Room.BLOCK_HEIGHT
		
		for child in get_children():
			if child is Room:
				child.position.x = round(child.position.x / Room.BLOCK_WIDTH) * Room.BLOCK_WIDTH
				child.position.y = round(child.position.y / Room.BLOCK_HEIGHT) * Room.BLOCK_HEIGHT
		
		
		# Handle room exits (bugged)
		#if not Input.is_key_pressed(KEY_CTRL):
			#var r: Room
			#var o: Vector2i
			#var offset: Vector2i
			#if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_right"):
				#for child in get_children():
					#if child is Room:
						#o = Vector2i(child.position.x / Room.BLOCK_WIDTH, child.position.y / Room.BLOCK_HEIGHT)
						#offset = Vector2i(floori(_new_room_pos.x / Room.BLOCK_WIDTH), floori(_new_room_pos.y / Room.BLOCK_HEIGHT)) - o
						#if offset.x > child.size_x - 1 or offset.x < 0: continue
						#if offset.y > child.size_y - 1 or offset.y < 0: continue
						#r = child
						#break
			#
			#if r:
				#var arr: Array = []
				#var arr2: Array = []
				#var off: int = 0
				#var valid := false
				#
				#if Input.is_action_just_pressed("ui_left"):
					#arr = r.exit_markers_left
					#arr2 = r.hide_exits_left
					#off = offset.y
					#valid = offset.x == 0
				#elif Input.is_action_just_pressed("ui_right"):
					#arr = r.exit_markers_right
					#arr2 = r.hide_exits_right
					#off = offset.y
					#valid = offset.x == r.size_x - 1
				#elif Input.is_action_just_pressed("ui_up"):
					#arr = r.exit_markers_up
					#arr2 = r.hide_exits_up
					#off = offset.x
					#valid = offset.y == 0
				#elif Input.is_action_just_pressed("ui_down"):
					#arr = r.exit_markers_down
					#arr2 = r.hide_exits_down
					#off = offset.x
					#valid = offset.y == r.size_y - 1
				#
				#if valid:
					#var i := arr.find(off)
					#if i == -1:
						#arr.push_back(off)
						#
						#if Input.is_key_pressed(KEY_SHIFT):
							#arr2.push_back(off)
					#else:
						#arr.remove_at(i)
						#
						#if Input.is_key_pressed(KEY_SHIFT):
							#i = arr2.find(off)
							#if i != -1:
								#arr2.remove_at(off)



func _draw() -> void:
	if Engine.is_editor_hint():
		# Draw grid
		var sc := get_viewport_transform().x.x
		var origin := get_viewport_transform().origin
		var vw := get_viewport_rect().size.x
		var vh := get_viewport_rect().size.y
		
		var start_x := -origin.x/sc
		var start_y := -origin.y/sc
		
		var bx := ceili(start_x / Room.BLOCK_WIDTH) * Room.BLOCK_WIDTH
		var ex := bx + floori(vw / sc)
		
		var by := ceili(start_y / Room.BLOCK_HEIGHT) * Room.BLOCK_HEIGHT
		var ey := by + floori(vh / sc)
		
		# 0.35 is when things start not displaying properly
		if sc > 0.1:
			for x in range(bx,ex,Room.BLOCK_WIDTH):
				draw_dashed_line(Vector2(x,start_y),Vector2(x,start_y + vh/sc),Color.WEB_MAROON,-1,16)
			for y in range(by,ey,Room.BLOCK_HEIGHT):
				draw_dashed_line(Vector2(start_x,y),Vector2(start_x + vw/sc,y),Color.WEB_MAROON,-1,16)
		
		
		# Draw room placement position
		draw_rect(Rect2(_new_room_pos,Vector2(Room.BLOCK_WIDTH,Room.BLOCK_HEIGHT)),Color.CRIMSON,false)
