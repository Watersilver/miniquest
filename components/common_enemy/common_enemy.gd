@tool
extends Node2D
class_name CommonEnemy

const DAMAGE_NUMBER = preload("uid://dmig0d05okjv7")

@onready var _ice_block: TileMapLayer = %IceBlock
@onready var _hazard: Hazard = %Hazard
@onready var _haz_shape_2d: CollisionShape2D = %HazShape2D
@onready var _hit_shape_2d: CollisionShape2D = %HitShape2D
@onready var _sight: Sight = $Sight
@onready var _hitbox: Area2D = %Hitbox


@export var is_frozen := false
@export var requires_ice := false
@export var immune_to_ice := false

@export var has_iframes := false
@export var extra_iframes := 0.0

@export_group("Hazard")
@export var dmg_dice := Global.Damage.ROLL_1D2
@export var enhancement := 0
@export var haz_shape := Rect2(0,0,8,8)
@export var harmless := false
@export var advantage := false:
	set(a):
		advantage = a
		
		if not is_node_ready():
			await ready
		
		_hazard.advantage = a

@export_group("Hit")
@export var hitpoints := 1
@export var hitbox_shape := Rect2(0,0,8,8)
@export var unhittable := false

var _iframes := 0.0

var _hurt := 0.0
func is_hurt() -> bool:
	return _hurt > 0


func is_on_iframes():
	return has_iframes and (is_hurt() or _iframes > 0)


var _dead := false
func is_dead() -> bool:
	return _dead


signal hitbox_hit(area: Area2D)
signal died()


func can_see_target() -> bool:
	return not _sight.get_detected_average_direction().is_zero_approx()


func get_sight_target_relative_direction() -> Vector2:
	return _sight.get_detected_average_direction()


func take_damage(hit: PlayerAttack.AttackHit, dmg := 1) -> void:
	if is_on_iframes():
		return
	
	_iframes = extra_iframes
	
	if not hit:
		hitpoints -= 1
		DamageNumber.spawn(dmg, _hitbox)
	else:
		if requires_ice and not Global.session.upgrades.element_ice:
			return
		hitpoints -= hit.dmg
		DamageNumber.spawn_from_attack(hit, _hitbox)


func force_update_components() -> void:
	_ice_block.visible = is_frozen
	_ice_block.collision_enabled = is_frozen
	
	_hazard.dmg_dice = dmg_dice
	_hazard.enhancement = enhancement
	
	_haz_shape_2d.position = haz_shape.position
	_haz_shape_2d.shape.size = haz_shape.size
	
	_hit_shape_2d.position = hitbox_shape.position
	_hit_shape_2d.shape.size = hitbox_shape.size


func _on_died():
	_haz_shape_2d.set_deferred("disabled", true)


func _ready() -> void:
	force_update_components()
	
	if Engine.is_editor_hint():
		return
	
	if harmless:
		if not _haz_shape_2d.disabled:
			_haz_shape_2d.set_deferred("disabled", true)
	else:
		if _haz_shape_2d.disabled and not _dead:
			_haz_shape_2d.set_deferred("disabled", false)
	_hitbox.area_entered.connect(_on_hitbox_area_entered)
	died.connect(_on_died)


func _physics_process(delta: float) -> void:
	force_update_components()
	
	if Engine.is_editor_hint():
		return
	
	if harmless:
		if not _haz_shape_2d.disabled:
			_haz_shape_2d.set_deferred("disabled", true)
	else:
		if _haz_shape_2d.disabled and not _dead:
			_haz_shape_2d.set_deferred("disabled", false)
	
	if unhittable:
		_hit_shape_2d.set_deferred("disabled", true)
	else:
		_hit_shape_2d.set_deferred("disabled", false)
	
	if not _dead:
		if hitpoints < 0:
			_haz_shape_2d.set_deferred("disabled", true)
			_dead = true
			died.emit()
		
		if not is_hurt():
			_iframes -= delta
		
		if _hurt > 0:
			_hurt -= delta


func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_on_iframes():
		return
	
	var can_freeze := false
	if area is PlayerAttack:
		if is_frozen and area.shrapnel:
			return
		if requires_ice and not Global.session.upgrades.element_ice:
			return
		can_freeze = not immune_to_ice
		take_damage(area.roll_attack_hit())
	else:
		take_damage(null)
	
	if hitpoints < 0:
		if _dead:
			is_frozen = false
			return
		_dead = true
		if can_freeze and Global.session.upgrades.element_ice:
			is_frozen = true
		_haz_shape_2d.set_deferred("disabled", true)
		hitbox_hit.emit(area)
		died.emit()
	else:
		hitbox_hit.emit(area)
	
	_hurt = 0.3
