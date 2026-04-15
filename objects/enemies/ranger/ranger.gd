@tool

extends CharacterBody2D

const PROJECTILE = preload("uid://bpyn0rqd6mrg2")

@onready var character_animations: CharacterAnimations = %CharacterAnimations

@onready var common_enemy: CommonEnemy = %CommonEnemy

enum Type {
	ARCHER,
	MAGE
}

@export var type := Type.ARCHER

@export var attack_period := 2.0

var _attack_timer := 0.0

const _DEATH_TIMER_MAX := 0.15
var _death_timer := _DEATH_TIMER_MAX

var _attacking := false
var _hurting := 0.0

var _attack_variant := randi_range(1, 3)


func _on_died():
	character_animations.animation = character_animations.AnimationId.DISAPPEAR


func _on_anim_finished():
	if Engine.is_editor_hint():
		return
	
	if character_animations.animation == character_animations.AnimationId.ATTACK and _attacking:
		_attacking = false
		character_animations.animation = character_animations.AnimationId.IDLE
		character_animations.speed_scale = 1
		var p: Projectile = PROJECTILE.instantiate()
		p.direction = character_animations.direction
		p.position = position + Vector2(6 * p.direction, -4)
		p.modulate = modulate
		get_parent().add_child(p)
		if type == Type.ARCHER:
			p.speed = _attack_variant * p.speed
			_attack_variant += 1
			if _attack_variant > 3:
				_attack_variant = 1
		elif type == Type.MAGE:
			p.gravity = 0
			p.speed = 50
			p.hazard.dmg_dice = Global.Damage.ROLL_1D4
			p.hazard.enhancement = 2
			p.oscillation = p.oscillation.duplicate()
			p.oscillation.amplitude.y = 2
			p.oscillation.frequency.y = 1 + randf() * (TAU - 1)


func _update_type_visuals():
	if type == Type.ARCHER:
		character_animations.skin = CharacterAnimations.SkinType.GUARD
		character_animations.weapon = Global.Weapon.BOW
		modulate = Color(1,1,0)
	elif type == Type.MAGE:
		character_animations.skin = CharacterAnimations.SkinType.FARMER
		character_animations.weapon = Global.Weapon.STAFF
		modulate = Color(1,0,1)


func _ready() -> void:
	_update_type_visuals()
	
	if Engine.is_editor_hint():
		return
	
	common_enemy.died.connect(_on_died)
	character_animations.animation_finished.connect(_on_anim_finished)
	
	_attack_timer = attack_period * randf() + attack_period


func _physics_process(delta: float) -> void:
	_update_type_visuals()
	
	if Engine.is_editor_hint():
		return
	
	if common_enemy.is_dead():
		modulate = Color(1,1,1,1)
		if _death_timer < 0:
			queue_free()
		if common_enemy.is_frozen:
			character_animations.speed_scale = 0
		else:
			character_animations.speed_scale = 1
			_death_timer -= delta
		return
	
	if common_enemy.is_hurt():
		_hurting = 0.5
		modulate = Color(1,1,1,1)
		character_animations.animation = character_animations.AnimationId.HURT
		return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	
	_hurting -= delta
	
	if not _attacking:
		_attack_timer -= delta
		
		if _hurting <= 0:
			character_animations.animation = character_animations.AnimationId.IDLE
		
		if _attack_timer <= delta:
			_attack_timer = attack_period
			_attacking = true
			character_animations.animation = character_animations.AnimationId.ATTACK
			character_animations.speed_scale = 0.3
	
	if common_enemy.can_see_target():
		character_animations.direction = Global.Direction.LEFT if common_enemy.get_sight_target_relative_direction().x < 0 else Global.Direction.RIGHT
