@tool
extends Area2D

@onready var label_offset: Node2D = %LabelOffset
@onready var label: Label = %Label

@export var price := 5
@export_multiline var description: Array[String] = []
@export var offset := -12.0
@export var offset_x := 0
@export var amount := 1

#@export var spawn_on_buy: PackedScene = null

enum Item {
	NULL,
	AIR_CONTROL,
	ADVANTAGE,
	ENHANCEMENT,
	CRIT_CHANCE,
	LIFE_UP,
	WEAPON,
	BOW,
	FIRE,
	ICE,
	DOUBLE_JUMP
}

@export var item := Item.NULL


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
	label_offset.position.x = offset_x

func _on_description_end():
	BinaryChoiceManager.prompt("Buy", "Don't buy", _on_buy_attempt)

func _on_buy_attempt():
	if Global.session.saved_data.money >= price:
		Global.session.saved_data.money -= price
		#if spawn_on_buy:
			#var s = spawn_on_buy.instantiate()
			#s.position = position
			#add_sibling(s)
			#s.global_position = Refs.level_manager.player.body.global_position
		match item:
			Item.AIR_CONTROL:
				Global.session.upgrades.controlled_fall = true
			Item.LIFE_UP:
				Global.session.upgrades.max_health += amount
			Item.ENHANCEMENT:
				Global.session.upgrades.enhancement += amount
			Item.CRIT_CHANCE:
				Global.session.upgrades.crit_chance += amount
			Item.ADVANTAGE:
				Global.session.upgrades.advantage = true
			Item.FIRE:
				Global.session.upgrades.element_fire = true
			Item.ICE:
				Global.session.upgrades.element_ice = true
			Item.WEAPON:
				Global.session.upgrades.set_weapon_upgrade(Global.Weapon.SWORD)
			Item.BOW:
				Global.session.upgrades.set_weapon_upgrade(Global.Weapon.BOW)
				Global.session.upgrades.raise_dmg_die(1)
			Item.DOUBLE_JUMP:
				Global.session.upgrades.double_jump = true
		Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
		queue_free()
	else:
		MessageDisplayer.display(["Not enough money..."])
