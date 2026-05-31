extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(_b: Node2D):
	if Refs.level_manager and Refs.level_manager.player:
		Refs.level_manager.player._state = Player.State.RECOIL
		Refs.level_manager.player.still_recoil = true
