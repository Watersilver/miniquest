@tool
extends Node2D

@onready var collision_tileset: MainTileset = %CollisionTileset
@onready var rotator: Node2D = %Rotator
@onready var point_1: Node2D = %Point1
@onready var point_2: Node2D = %Point2
@onready var point_3: Node2D = %Point3
@onready var point_4: Node2D = %Point4
@onready var _br: AnimatedSprite2D = %BR
@onready var _tr: AnimatedSprite2D = %TR
@onready var _tl: AnimatedSprite2D = %TL
@onready var _bl: AnimatedSprite2D = %BL
@onready var area_1: Area2D = %Area1
@onready var area_2: Area2D = %Area2
@onready var area_3: Area2D = %Area3
@onready var area_4: Area2D = %Area4


## If not provided unique id will be attempted to be generated
@export var id := ""

@export var rotated := false:
	set(r):
		rotated = r
		_rotating = true
var _rotating := false
var _player: Player = null
var _player_anchor: Node2D = null


func get_id():
	if id != "": return id
	if not Refs.level_manager: return ""
	return Refs.level_manager.get_unique_name(self)


func _update_rotation():
	if rotated:
		rotator.rotation_degrees = -90
		_br.play("left")
		_tr.play("down")
		_tl.play("right")
		_bl.play("up")
		_br.frame = 0
		_br.frame_progress = 0
		_tr.frame = 0
		_tr.frame_progress = 0.5
		_tl.frame = 1
		_tl.frame_progress = 0
		_bl.frame = 1
		_bl.frame_progress = 0.5
	else:
		rotator.rotation_degrees = 0
		_br.play("up")
		_tr.play("left")
		_tl.play("down")
		_bl.play("right")
		_br.frame = 0
		_br.frame_progress = 0
		_tr.frame = 0
		_tr.frame_progress = 0.5
		_tl.frame = 1
		_tl.frame_progress = 0
		_bl.frame = 1
		_bl.frame_progress = 0.5
	_rotating = false
	if _player:
		_player.dial = null


func _on_player_enter_area(body: Node2D, area: Area2D):
	if _player: return
	if _player_anchor: return
	if body.get_parent() is Player:
		_player = body.get_parent()
		_player.dial = self
		_player_anchor = area
		rotated = not rotated


func _on_player_exit_area(_body: Node2D):
	if _player:
		_player.dial = null
	_player = null
	_player_anchor = null


func _ready() -> void:
	if Engine.is_editor_hint():
		_update_rotation()
		return
	
	if get_id() == "":
		return
	
	if Global.session.saved_data.object_flags.has(get_id()):
		rotated = Global.session.saved_data.object_flags[get_id()]
	else:
		Global.session.saved_data.object_flags[get_id()] = rotated
	
	_update_rotation()
	
	area_1.body_entered.connect(_on_player_enter_area.bind(area_1))
	area_2.body_entered.connect(_on_player_enter_area.bind(area_2))
	area_3.body_entered.connect(_on_player_enter_area.bind(area_3))
	area_4.body_entered.connect(_on_player_enter_area.bind(area_4))
	area_1.body_exited.connect(_on_player_exit_area)
	area_2.body_exited.connect(_on_player_exit_area)
	area_3.body_exited.connect(_on_player_exit_area)
	area_4.body_exited.connect(_on_player_exit_area)


func _process(delta: float) -> void:
	area_1.global_position = point_1.global_position
	area_2.global_position = point_2.global_position
	area_3.global_position = point_3.global_position
	area_4.global_position = point_4.global_position
	
	if not _br.is_playing():
		_br.play()
	if not _tr.is_playing():
		_tr.play()
	if not _tl.is_playing():
		_tl.play()
	if not _bl.is_playing():
		_bl.play()
	
	if _rotating:
		collision_tileset.collision_enabled = false
		if rotated:
			rotator.rotation_degrees = rotator.rotation_degrees + (-90 - rotator.rotation_degrees) * delta * 5 - delta * 15
			if rotator.rotation_degrees <= -89.5:
				_update_rotation()
				Global.session.saved_data.object_flags[get_id()] = rotated
		else:
			rotator.rotation_degrees = rotator.rotation_degrees + (- rotator.rotation_degrees) * delta * 5 + delta * 15
			if rotator.rotation_degrees >= -0.5:
				_update_rotation()
				Global.session.saved_data.object_flags[get_id()] = rotated
		
		if _player and _player_anchor:
			_player.body.global_position = _player.body.global_position + (_player_anchor.global_position + Vector2(0, 2) - _player.body.global_position) * delta * 20
			_player.body.velocity = Vector2(0, 0)
	else:
		collision_tileset.collision_enabled = true
