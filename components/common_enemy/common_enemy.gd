@tool
extends Node2D
class_name CommonEnemy


@onready var _ice_block: TileMapLayer = %IceBlock
@onready var _hazard: Hazard = %Hazard
@onready var _haz_shape_2d: CollisionShape2D = %HazShape2D
@onready var _hit_shape_2d: CollisionShape2D = %HitShape2D
@onready var _sight: Sight = $Sight
@onready var _hitbox: Area2D = %Hitbox


@export var is_frozen := false

@export_group("Hazard")
@export var dmg_dice := Global.Damage.ROLL_1D2
@export var enhancement := 0
@export var haz_shape := Rect2(0,0,8,8)

@export_group("Hit")
@export var hitpoints := 1
@export var hitbox_shape := Rect2(0,0,8,8)


var _hurt := 0.0
func is_hurt() -> bool:
	return _hurt > 0

var _dead := false
func is_dead() -> bool:
	return _dead


signal hitbox_hit(area: Area2D)
signal died()


func can_see_target() -> bool:
	return not _sight.get_detected_average_direction().is_zero_approx()


func get_sight_target_relative_direction() -> Vector2:
	return _sight.get_detected_average_direction()


func force_update_components() -> void:
	_ice_block.visible = is_frozen
	_ice_block.collision_enabled = is_frozen
	
	_hazard.dmg_dice = dmg_dice
	_hazard.enhancement = enhancement
	
	_haz_shape_2d.position = haz_shape.position
	_haz_shape_2d.shape.size = haz_shape.size
	
	_hit_shape_2d.position = hitbox_shape.position
	_hit_shape_2d.shape.size = hitbox_shape.size


func _ready() -> void:
	force_update_components()
	
	_hitbox.area_entered.connect(_on_hitbox_area_entered)


func _physics_process(delta: float) -> void:
	force_update_components()
	
	if not _dead:
		if hitpoints < 0:
			_haz_shape_2d.disabled = true
			_dead = true
			died.emit()
		
		if _hurt > 0:
			_hurt -= delta


func _on_hitbox_area_entered(area: Area2D) -> void:
	var can_freeze := false
	if area is PlayerAttack:
		can_freeze = true
		var dmg = area.roll_attack_hit().dmg
		hitpoints -= dmg
	else:
		hitpoints -= 1
	
	if hitpoints < 0:
		if _dead:
			is_frozen = false
			return
		_dead = true
		if can_freeze and Global.session.upgrades.element_ice:
			is_frozen = true
		set_deferred("_haz_shape_2d", true)
		hitbox_hit.emit(area)
		died.emit()
	else:
		hitbox_hit.emit(area)
	
	_hurt = 0.3
