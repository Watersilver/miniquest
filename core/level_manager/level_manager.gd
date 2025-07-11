extends Node2D
class_name LevelManager

@onready var room_name: Label = %RoomName
@onready var health_hud: HealthHud = %HealthHud
@onready var money_lbl: Label = %MoneyLbl

@onready var top_exit_shape: CollisionShape2D = %TopExitShape
@onready var right_exit_shape: CollisionShape2D = %RightExitShape
@onready var bottom_exit_shape: CollisionShape2D = %BottomExitShape
@onready var left_exit_shape: CollisionShape2D = %LeftExitShape

@export var level: Level:
	set(l):
		level = l
		if is_node_ready():
			_spawn_to_level()
@export var player: Player
@export var camera: Camera2D

var _room_coordinates := Vector2i(0,0)
func get_room_coordinates() -> Vector2i:
	return _room_coordinates

var current_room: Room

func shake_it():
	if is_instance_valid(current_room):
		for child in current_room.get_children():
			if child is MainTileset:
				(child as MainTileset).apply_shake(0.3,4)

func get_player_coordinates() -> Vector2i:
	return player.get_room_block_coordinates(current_room) + _room_coordinates

func go_to_room(destination: Vector2i, new_player_pos: Vector2 = player.body.global_position):
	# Check that room exists
	var room_scene := level.get_room_at(destination)
	if not room_scene: return
	
	
	# Clear old room
	var old_room := current_room
	if is_instance_valid(current_room) and current_room.is_inside_tree():
		current_room.queue_free()
		current_room = null
	
	
	# Load new room
	current_room = room_scene.instantiate()
	if old_room: old_room.name = "to." + current_room.name # Ensure there won't be a name collision
	_room_coordinates = level.get_room_origin_at(destination)
	add_child(current_room)
	
	room_name.text = current_room.name
	
	
	# Adjust camera limits
	camera.limit_left = roundi(current_room.global_position.x)
	camera.limit_top = roundi(current_room.global_position.y)
	camera.limit_right = camera.limit_left + current_room.get_width()
	camera.limit_bottom = camera.limit_top + current_room.get_height() + 16
	
	
	# Adjust room exits
	(top_exit_shape.shape as RectangleShape2D).size.x = current_room.get_width()
	(bottom_exit_shape.shape as RectangleShape2D).size.x = current_room.get_width()
	
	top_exit_shape.position.x = current_room.get_width() * 0.5
	bottom_exit_shape.position.x = current_room.get_width() * 0.5
	bottom_exit_shape.position.y = current_room.get_height() + 4
	
	(left_exit_shape.shape as RectangleShape2D).size.y = current_room.get_height()
	(right_exit_shape.shape as RectangleShape2D).size.y = current_room.get_height()
	
	left_exit_shape.position.y = current_room.get_height() * 0.5
	right_exit_shape.position.y = current_room.get_height() * 0.5
	right_exit_shape.position.x = current_room.get_width() + 4
	
	
	# Determine new player position
	var room_size_offset := destination - _room_coordinates
	new_player_pos.x += room_size_offset.x * Room.BLOCK_WIDTH
	#new_player_pos.x -= player_room_position_offset.x * Room.BLOCK_WIDTH
	new_player_pos.y += room_size_offset.y * Room.BLOCK_HEIGHT
	#new_player_pos.y -= player_room_position_offset.y * Room.BLOCK_HEIGHT
	player.body.global_position = new_player_pos


func get_unique_name(node: Node) -> String:
	var u := ""
	while (node):
		u += node.name + "/"
		node = node.get_parent()
		if node == self:
			u += node.name + "/"
			break
	return u


func _spawn_to_level():
	var p := level.spawn_point.position if level.spawn_point else Vector2(level.position.x + Room.BLOCK_WIDTH / 2.0, level.position.y + Room.BLOCK_HEIGHT / 2.0)
	var room_coords := p
	room_coords.x /= Room.BLOCK_WIDTH
	room_coords.y /= Room.BLOCK_HEIGHT
	room_coords = room_coords.floor()
	var player_pos := p
	player_pos.x -= room_coords.x * Room.BLOCK_WIDTH
	player_pos.y -= room_coords.y * Room.BLOCK_HEIGHT
	
	go_to_room(Vector2i(room_coords), player_pos)
	
	var s := current_room.st_up_skills
	
	var check_bitflag := func(flag: int, index: int) -> bool:
		var value := 2 ** index
		return (flag & value) == value
	
	if check_bitflag.call(s, 0):
		Global.session.upgrades.controlled_fall = true
	if check_bitflag.call(s, 1):
		Global.session.upgrades.jump = true
	if check_bitflag.call(s, 2):
		Global.session.upgrades.double_jump = true
	if check_bitflag.call(s, 3):
		Global.session.upgrades.backdash = true
	if check_bitflag.call(s, 4):
		Global.session.upgrades.run = true
	if check_bitflag.call(s, 5):
		Global.session.upgrades.bat = true
	if check_bitflag.call(s, 6):
		Global.session.upgrades.griffon = true
	if check_bitflag.call(s, 7):
		Global.session.upgrades.swim = true
	if check_bitflag.call(s, 8):
		Global.session.upgrades.water_walk = true
	if check_bitflag.call(s, 9):
		Global.session.upgrades.element_ice = true
	if check_bitflag.call(s, 10):
		Global.session.upgrades.element_fire = true
	
	Global.session.saved_data.money = current_room.st_up_gold
	Global.session.upgrades.max_health = current_room.st_up_health
	Global.session.upgrades.weapon = current_room.st_up_weapon
	
	Checkpoint.mark()


func _ready() -> void:
	Refs.level_manager = self
	
	health_hud.player = player
	
	call_deferred("_spawn_to_level")


func _process(_delta: float) -> void:
	money_lbl.text = str(Global.session.saved_data.money)
	if money_lbl.text.length() == 1:
		money_lbl.text = "0" + money_lbl.text
	money_lbl.text = ":" + money_lbl.text


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			player.griffon_ceiling_smash.connect(shake_it)
		NOTIFICATION_EXIT_TREE:
			player.griffon_ceiling_smash.disconnect(shake_it)


var scroll_displacement := 8


func _on_top_exit_body_entered(_body: Node2D) -> void:
	var new_player_pos := global_position
	new_player_pos.x = player.body.global_position.x
	new_player_pos.y += current_room.get_height() - scroll_displacement
	new_player_pos.x = fposmod(new_player_pos.x, Room.BLOCK_WIDTH)
	new_player_pos.y = fposmod(new_player_pos.y, Room.BLOCK_HEIGHT)
	if current_room:
		var has_exit := current_room.exit_markers_up.has(player.get_room_block_coordinates(current_room).x)
		if not has_exit:
			player.handle_out_of_bounds()
			return
	var dest := get_player_coordinates() + Vector2i(0, -1)
	var target_room := level.get_room_at(dest)
	if not target_room:
		player.handle_out_of_bounds()
		return
	call_deferred("go_to_room", dest, new_player_pos)


func _on_right_exit_body_entered(_body: Node2D) -> void:
	var new_player_pos := global_position
	new_player_pos.x += scroll_displacement
	new_player_pos.y = player.body.global_position.y
	new_player_pos.x = fposmod(new_player_pos.x, Room.BLOCK_WIDTH)
	new_player_pos.y = fposmod(new_player_pos.y, Room.BLOCK_HEIGHT)
	if current_room:
		var has_exit := current_room.exit_markers_right.has(player.get_room_block_coordinates(current_room).y)
		if not has_exit:
			player.handle_out_of_bounds()
			return
	var dest := get_player_coordinates() + Vector2i(1,0)
	var target_room := level.get_room_at(dest)
	if not target_room:
		player.handle_out_of_bounds()
		return
	call_deferred("go_to_room", dest, new_player_pos)


func _on_bottom_exit_body_entered(_body: Node2D) -> void:
	var new_player_pos := global_position
	new_player_pos.x = player.body.global_position.x
	new_player_pos.y += scroll_displacement
	new_player_pos.x = fposmod(new_player_pos.x, Room.BLOCK_WIDTH)
	new_player_pos.y = fposmod(new_player_pos.y, Room.BLOCK_HEIGHT)
	if current_room:
		var has_exit := current_room.exit_markers_down.has(player.get_room_block_coordinates(current_room).x)
		if not has_exit:
			player.handle_out_of_bounds()
			return
	var dest := get_player_coordinates() + Vector2i(0,1)
	var target_room := level.get_room_at(dest)
	if not target_room:
		player.handle_out_of_bounds()
		return
	call_deferred("go_to_room", dest, new_player_pos)


func _on_left_exit_body_entered(_body: Node2D) -> void:
	var new_player_pos := global_position
	new_player_pos.x += current_room.get_width() - scroll_displacement
	new_player_pos.y = player.body.global_position.y
	new_player_pos.x = fposmod(new_player_pos.x, Room.BLOCK_WIDTH)
	new_player_pos.y = fposmod(new_player_pos.y, Room.BLOCK_HEIGHT)
	if current_room:
		var has_exit := current_room.exit_markers_left.has(player.get_room_block_coordinates(current_room).y)
		if not has_exit:
			player.handle_out_of_bounds()
			return
	var dest := get_player_coordinates() + Vector2i(-1,0)
	var target_room := level.get_room_at(dest)
	if not target_room:
		player.handle_out_of_bounds()
		return
	call_deferred("go_to_room", dest, new_player_pos)
