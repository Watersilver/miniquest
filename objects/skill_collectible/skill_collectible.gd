@tool
extends Node2D
class_name SkillCollectible


# Might need the same class for weapons and the rest of the upgrades:
	# extra_lung_capacity := 0.0
	#
	# element_fire := false
	# element_ice := false
	#
	# weapon := Weapon.NONE


enum Type {
	NULL,
	CONTROLLED_FALL,
	JUMP,
	DOUBLE_JUMP,
	BACKDASH,
	RUN,
	BAT,
	GRIFFON,
	SWIM,
	WATER_WALK
}

@export var type := Type.NULL

@export_multiline var acquisition_text := ""


static func has_type(t: Type) -> bool:
	var u := Global.session.upgrades
	match t:
		Type.CONTROLLED_FALL:
			return u.controlled_fall
		Type.JUMP:
			return u.jump
		Type.DOUBLE_JUMP:
			return u.double_jump
		Type.BACKDASH:
			return u.backdash
		Type.RUN:
			return u.run
		Type.BAT:
			return u.bat
		Type.GRIFFON:
			return u.griffon
		Type.SWIM:
			return u.swim
		Type.WATER_WALK:
			return u.water_walk
	return false


func _ready() -> void:
	if not Engine.is_editor_hint():
		if has_type(type):
			queue_free()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if has_type(type):
			queue_free()


func _on_area_2d_body_entered(_body: Node2D) -> void:
	var u := Global.session.upgrades
	
	match type:
		Type.CONTROLLED_FALL:
			u.controlled_fall = true
		Type.JUMP:
			u.jump = true
		Type.DOUBLE_JUMP:
			u.double_jump = true
		Type.BACKDASH:
			u.backdash = true
		Type.RUN:
			u.run = true
		Type.BAT:
			u.bat = true
		Type.GRIFFON:
			u.griffon = true
		Type.SWIM:
			u.swim = true
		Type.WATER_WALK:
			u.water_walk = true
	
	queue_free()
