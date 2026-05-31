extends Node
class_name Main

const DUNGEON = preload("uid://cdpqnb8c4ak7f")

var is_pause_screen_open := false


@onready var pause_layer: CanvasLayer = %PauseLayer
@onready var pause_screen: PauseScreen = %PauseScreen


var state: GameState:
	set(s):
		if state:
			state.cleanup()
		state = s
		if state:
			state.ctx = self
			state.setup()


class GameState:
	var ctx: Main
	func setup() -> void: pass
	func cleanup() -> void: pass
	func update(_delta: float) -> void: pass


class MainGame extends GameState:
	var is_paused := false
	var ignore_pause_button := false
	func is_message_active() -> bool:
		return MessageDisplayer.has_text() or BinaryChoiceManager.is_active()
	func on_request_unpause() -> void:
		unpause()
		ignore_pause_button = true
	func unpause() -> void:
		if is_paused:
			is_paused = false
			ctx.pause_layer.visible = false
	func toggle_pause() -> void:
		if is_paused:
			if not ctx.pause_screen.block_unpause:
				unpause()
		elif not is_message_active():
			ctx.pause_layer.visible = true
			is_paused = true
	func determine_pause_state() -> void:
		if is_message_active() or is_paused:
			ctx.get_tree().paused = true
		else:
			ctx.get_tree().paused = false
	
	func setup() -> void:
		is_paused = not is_paused
		toggle_pause()
		determine_pause_state()
		ctx.pause_screen.request_unpause.connect(on_request_unpause)
	func cleanup() -> void:
		ctx.pause_screen.request_unpause.disconnect(on_request_unpause)
	func update(_delta: float) -> void:
		if Input.is_action_just_pressed("pause") or (is_paused and Input.is_action_just_pressed("ui_cancel")):
			if not ignore_pause_button:
				toggle_pause()
		
		determine_pause_state()
		
		ignore_pause_button = false


func _ready() -> void:
	state = MainGame.new()


func _physics_process(delta: float) -> void:
	if state:
		state.update(delta)
