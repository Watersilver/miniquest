extends Area2D


@onready var sprite_2d: Sprite2D = $Sprite2D


func is_active():
	if not Refs.level_manager: return false
	return Global.session.checkpoint.room == Refs.level_manager.get_room_coordinates()

var _toggled := 0.0:
	set(t):
		_toggled = maxf(0,t)
func _toggle(_fuckyou):
	Refs.level_manager.player.health.value = Refs.level_manager.player.health.maximum
	Global.session.checkpoint.room = Refs.level_manager.get_room_coordinates()
	Global.session.checkpoint.pos = Refs.level_manager.player.body.global_position
	Global.session.checkpoint.upgrades = Global.session.upgrades.duplicate()
	Global.session.checkpoint.saved_data = Global.session.saved_data.duplicate()
	
	sprite_2d.region_rect.position.x = 0
	_toggled = 0.5


func _ready() -> void:
	body_entered.connect(_toggle)
	area_entered.connect(_toggle)
	
	if is_active():
		sprite_2d.region_rect.position.x = 0
	else:
		sprite_2d.region_rect.position.x = 8


var _t := 0.0
func _physics_process(delta: float) -> void:
	sprite_2d.position.y = sin(_t) * 2
	_t += delta
	if _toggled > 0:
		_t += delta * 30
	_toggled -= delta
