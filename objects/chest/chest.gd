@tool
extends Area2D
class_name Chest


@onready var sprite: Sprite2D = %Sprite
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D

@onready var little_money: AnimatedSprite2D = %LittleMoney
@onready var decent_money: AnimatedSprite2D = %DecentMoney
@onready var good_money: AnimatedSprite2D = %GoodMoney
@onready var great_money: AnimatedSprite2D = %GreatMoney
@onready var life: AnimatedSprite2D = %Life

var _item: AnimatedSprite2D = null

enum Col {
	BROWN,
	WHITE,
	DARK_BROWN,
	GREY
}

enum Content {
	LIFE,
	GOLD
}

@export var color := Col.BROWN
@export var content_type := Content.LIFE
@export var amount := 1

var _open_anim_timer := -1.0

func _is_opened() -> bool:
	if not Refs.level_manager: return true
	return Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self))


func _ready() -> void:
	if not Engine.is_editor_hint():
		if _is_opened():
			sprite.region_rect.position.y += 16
			collision_shape_2d.disabled = true
		
		body_entered.connect(_open)


func _process(delta: float) -> void:
	match color:
		Col.BROWN:
			sprite.region_rect.position.x = 16
		Col.WHITE:
			sprite.region_rect.position.x = 0
		Col.DARK_BROWN:
			sprite.region_rect.position.x = 32
		Col.GREY:
			sprite.region_rect.position.x = 48
	
	if not Engine.is_editor_hint():
		if _open_anim_timer >= 0:
			if _open_anim_timer > 0.3:
				sprite.region_rect.position.y = 184
			elif _open_anim_timer > 0.15:
				sprite.region_rect.position.y = 176
			
			var item_timer := _open_anim_timer - 0.2
			if item_timer > 0:
				if content_type == Content.LIFE:
					_item = life
				else:
					if amount <= 5:
						_item = little_money
					elif amount <= 15:
						_item = decent_money
					elif amount <= 40:
						_item = good_money
					else:
						_item = great_money
				_item.play(&"default")
				
				_item.visible = true
				_item.position = Vector2(5,4 + 8 * (((4 / (item_timer * 5 + 1)) - 4) / 4))
			
			_open_anim_timer += delta


func _open(_fuckyou) -> void:
	if _is_opened(): return
	Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
	collision_shape_2d.set_deferred("disabled", true)
	
	_open_anim_timer = 0
	
	if content_type == Content.LIFE:
		Global.session.upgrades.max_health += amount
		Refs.level_manager.player.health.maximum = Global.session.upgrades.max_health
		Refs.level_manager.player.health.value = Refs.level_manager.player.health.maximum
	elif content_type == Content.GOLD:
		Global.session.saved_data.money += amount
