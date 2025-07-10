extends Node

@onready var debug: Control = %Debug
@onready var player: Player = %Player

var _is_pressing_p := false

func _ready() -> void:
	remove_child(debug)
	
	player.griffon_ceiling_smash.connect(_on_player_griffon_ceiling_smash)

func _physics_process(_delta: float) -> void:
	# Handle child pause
	if MessageDisplayer.has_text() or BinaryChoiceManager.is_active():
		for child in get_children():
			child.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		for child in get_children():
			child.process_mode = Node.PROCESS_MODE_INHERIT
	
	if Input.is_physical_key_pressed(KEY_P):
		if not _is_pressing_p:
			if debug.is_inside_tree():
				remove_child(debug)
			else:
				add_child(debug)
		_is_pressing_p = true
	else:
		_is_pressing_p = false


func _on_player_griffon_ceiling_smash() -> void:
	pass
