@tool
extends Area2D

const SKILL_COLLECTIBLE = preload("res://objects/skill_collectible/skill_collectible.tscn")

@onready var label_offset: Node2D = %LabelOffset
@onready var label: Label = %Label

@export var price := 5
@export_multiline var description: Array[String] = []
@export var offset := -12.0

@export var spawn_on_buy: PackedScene = null
@export var skill_type := SkillCollectible.Type.NULL

var _cooldown := 0.0

func _is_bought() -> bool:
	if not Refs.level_manager: return true
	return Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self))


func _ready() -> void:
	if not Engine.is_editor_hint():
		if _is_bought():
			visible = false
			var collision_shape_2d: CollisionShape2D = $CollisionShape2D
			collision_shape_2d.disabled = true
			queue_free()
		else:
			visible = true


func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		if has_overlapping_bodies() and Input.is_action_just_pressed("ui_accept") and _cooldown <= 0.0:
			_cooldown = 0.2
			
			MessageDisplayer.display(description, _on_description_end)
		
		_cooldown -= delta
	
	label.text = str(price)
	label_offset.position.y = offset

func _on_description_end():
	BinaryChoiceManager.prompt("Buy", "Don't buy", _on_buy_attempt)

func _on_buy_attempt():
	if Global.session.saved_data.money >= price:
		Global.session.saved_data.money -= price
		if spawn_on_buy:
			var s = spawn_on_buy.instantiate()
			s.position = position
			add_sibling(s)
			s.global_position = Refs.level_manager.player.body.global_position
		if skill_type != SkillCollectible.Type.NULL:
			var sk = SKILL_COLLECTIBLE.instantiate()
			sk.type = skill_type
			sk.position = position
			add_sibling(sk)
			sk.global_position = Refs.level_manager.player.body.global_position
		Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
		queue_free()
	else:
		MessageDisplayer.display(["Not enough money..."])
