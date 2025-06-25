@tool

extends Node2D
class_name CharacterAnimations

const HERO = preload("res://assets/Chroma-Noir-v2.1/Chroma-Noir-8x8/Hero.png")
const HERO_ALTS = preload("res://assets/Chroma-Noir-v2.1/Chroma-Noir-8x8/Hero-Alts.png")

## Notifies when an animation finished playing.[br][br]
## [b]Note[/b]: This signal is not emitted if an animation is looping.
signal animation_finished

## Notifies when an animation finished a loop.[br][br]
## [b]Note[/b]: This signal is not emitted if an animation finished playing.
signal animation_looped

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var sprite: Sprite2D = %Sprite
@onready var facing_scaler: Node2D = %FacingScaler
@onready var center: Node2D = %Center
@onready var fairy_transform: AnimatedSprite2D = %FairyTransform

enum SkinType {
	DEFAULT,
	GUARD,
	GUARD_HORN,
	BOBA_FETT,
	DEVIL,
	ROBOT,
	FARMER
}

@export var skin := SkinType.DEFAULT

@export var weapon := Global.Weapon.NONE

@export var direction := Global.Direction.RIGHT

@export var speed_scale := 1.0


enum AnimationId {
	IDLE,
	WALK,
	CLIMB,
	SWIM,
	ATTACK,
	FALL_SLOW,
	FALL_FAST,
	FALL_LAND,
	FALL_FLAT,
	APPEAR,
	DISAPPEAR,
	HURT,
	SPRINT_START,
	FAIRY
}

var _prev_anim := AnimationId.IDLE # doesn't matter, gets initialized in ready
@export var animation := AnimationId.IDLE:
	set(a):
		animation = a
		if animation != _prev_anim:
			_init_anim()
		_prev_anim = animation
var previous_animation := animation # doesn't matter, gets initialized in ready

var _anim_enum_name_map: Dictionary[AnimationId, StringName] = {
	AnimationId.IDLE: &"idle",
	AnimationId.WALK: &"walk",
	AnimationId.CLIMB: &"climb",
	AnimationId.SWIM: &"swim",
	AnimationId.ATTACK: &"attack",
	AnimationId.FALL_SLOW: &"fall_slow",
	AnimationId.FALL_FAST: &"fall_fast",
	AnimationId.FALL_LAND: &"fall_land",
	AnimationId.FALL_FLAT: &"fall_flat",
	AnimationId.APPEAR: &"appear",
	AnimationId.DISAPPEAR: &"disappear",
	AnimationId.HURT: &"hurt",
	AnimationId.SPRINT_START: &"sprint_start",
	AnimationId.FAIRY: &"disappear"
}

func _init_anim():
	if animation_player:
		var was_blocking_signals := animation_player.is_blocking_signals()
		animation_player.set_block_signals(true)
		animation_player.play("RESET")
		animation_player.advance(0)
		animation_player.play(_anim_enum_name_map[animation])
		animation_player.set_block_signals(was_blocking_signals)


var _prev_progress := 0.0
var _progress := 0.0


var _prev_rect := Rect2()

var _rect_offset_x := 0
var _rect_offset_y := 0

func _ready() -> void:
	previous_animation = animation
	_prev_anim = animation
	_init_anim()

func _process(_delta: float) -> void:
	animation_player.process_priority = process_priority - 1
	
	animation_player.speed_scale = speed_scale
	
	if direction == Global.Direction.RIGHT:
		facing_scaler.scale.x = 1
	else:
		facing_scaler.scale.x = -1
	
	
	_prev_rect.position.x += _rect_offset_x
	_prev_rect.position.y += _rect_offset_y
	
	if not sprite.region_rect.is_equal_approx(_prev_rect):
		sprite.region_rect.position.x += _rect_offset_x
		sprite.region_rect.position.y += _rect_offset_y
	
	sprite.region_rect.position.x -= _rect_offset_x
	sprite.region_rect.position.y -= _rect_offset_y
	
	_prev_rect = sprite.region_rect
	
	_rect_offset_x = 0
	
	match weapon:
		Global.Weapon.SWORD:
			_rect_offset_x = 72
		Global.Weapon.HALBERD:
			_rect_offset_x = 48
		Global.Weapon.STAFF:
			_rect_offset_x = 24
		Global.Weapon.BOW:
			_rect_offset_x = 96
	
	var texture := HERO_ALTS
	_rect_offset_y = 0
	match skin:
		SkinType.DEFAULT:
			texture = HERO
		SkinType.GUARD_HORN:
			_rect_offset_y = 72
		SkinType.BOBA_FETT:
			_rect_offset_y = 144
		SkinType.DEVIL:
			_rect_offset_y = 216
		SkinType.ROBOT:
			_rect_offset_y = 288
		SkinType.FARMER:
			_rect_offset_y = 360
	
	sprite.texture = texture
	
	sprite.region_rect.position.x += _rect_offset_x
	sprite.region_rect.position.y += _rect_offset_y
	
	_prev_progress = _progress
	_progress = animation_player.current_animation_position
	if animation == previous_animation:
		if animation_player.get_playing_speed() > 0:
			if _prev_progress > _progress:
				animation_looped.emit()
		else:
			if _prev_progress < _progress:
				animation_looped.emit()
	
	
	if animation == AnimationId.FAIRY:
		fairy_transform.visible = true
		if fairy_transform.animation != "fly":
			if fairy_transform.animation == "appear":
				if not fairy_transform.is_playing():
					fairy_transform.play("fly")
			else:
				fairy_transform.play("appear")
	else:
		if fairy_transform.visible:
			if fairy_transform.animation != "disappear":
				fairy_transform.play("disappear")
			else:
				if not fairy_transform.is_playing():
					fairy_transform.visible = false
	
	previous_animation = animation


func set_progress(p: float):
	animation_player.seek(p)
	animation_player.advance(0)


func _on_animation_player_current_animation_changed(anim_name: String) -> void:
	var _new_anim = _anim_enum_name_map.find_key(anim_name)
	if _new_anim == null: return
	_prev_anim = _new_anim
	animation = _new_anim


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	animation_finished.emit()
