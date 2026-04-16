@tool
extends Node2D

@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var node_2d: Node2D = %Node2D

@export var oscillation: OscillationResource

enum Type {
	YELLOW,
	PINK
}

@export var type := Type.YELLOW

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX

func animate_type():
	match type:
		Type.YELLOW:
			animated_sprite_2d.play("yellow")
		Type.PINK:
			animated_sprite_2d.play("pink")

func _ready() -> void:
	if not Engine.is_editor_hint():
		node_2d.scale.x = [1, -1].pick_random()
	animate_type()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		animate_type()
	else:
		if animated_sprite_2d.animation == "yellow" or animated_sprite_2d.animation == "pink":
			match animated_sprite_2d.frame:
				0:
					common_enemy.position.y = 2
				2:
					common_enemy.position.y = -2
				_:
					common_enemy.position.y = 1
		else:
			common_enemy.position.y = 2
		
		if common_enemy.is_dead():
			if _death_timer < _DEATH_TIMER_MAX * 0.5:
				animated_sprite_2d.play("death")
			if _death_timer < 0:
				queue_free()
			if common_enemy.is_frozen:
				animated_sprite_2d.play("hurt")
			else:
				_death_timer -= delta
			return
		
		if common_enemy.is_hurt():
			animated_sprite_2d.play("hurt")
			return
		
		animate_type()
		
		if oscillation:
			oscillation.update(delta)
			node_2d.position = oscillation.position
			node_2d.rotation = oscillation.rotation
			common_enemy.position = oscillation.position
			common_enemy.rotation = oscillation.rotation
	
	if Refs.level_manager:
		var diff := Refs.level_manager.player.body.position.x - position.x
		if diff != 0:
			node_2d.scale.x = signf(diff)
