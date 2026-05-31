extends Node2D
class_name MageBoss

const BOUNCER = preload("uid://c2j3e2efr8s22")
const PROJECTILE = preload("uid://bpyn0rqd6mrg2")

@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var serpent: HellSerpent = %Serpent
@onready var pl_detector: Area2D = %PlDetector
@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var label: Label = %Label
@onready var exclamation_mark: Sprite2D = %ExclamationMark


## Average of serpent cooldown
@export var serpent_cooldown := 3.0
## Actual seprent cooldown per summoning is serpent_cooldown +- this value
@export var serpent_cooldown_variation := 1.0
## Initial serpent cooldown progress.
## Serpent timer is an internal value that counts up until it reaches the internal
## serpent_cooldown (calculated by exported serpent_cooldown and modified randomly by serpent_cooldown_variation)
@export var serpent_init_timer := 0.0

@export var serpent_possible_spawn_points: Array[Node2D]

@export var teleport_points: Array[Node2D]

@export var spawn := false


class FightState:
	var _m: MageBoss
	func _init(mage: MageBoss) -> void:
		_m = mage
	func update(_delta: float) -> void:
		pass
	func setup() -> void:
		pass
	func cleanup() -> void:
		pass

class Idle extends FightState:
	var timer := 0.5 + randf() * 0.3
	var Next := FightState
	var casts := 0
	func _init(mage: MageBoss):
		super(mage)
		Next = Teleport if randf() < 0.75 else Cast
		if not _m.spawn:
			timer += (_m.common_enemy.hitpoints / float(_m._start_hp)) * 0.5
	func setup() -> void:
		_m.animated_sprite_2d.play("idle")
		if casts > 0:
			Next = Cast
			if _m._exclamating > 0:
				_m.animated_sprite_2d.speed_scale = 0
			else:
				_m.animated_sprite_2d.speed_scale = 2
	func cleanup() -> void:
		_m.animated_sprite_2d.speed_scale = 1
	func update(delta):
		_m._face_player()
		if timer <= 0.0:
			var next: FightState
			if _m._should_cast_bouncer():
				_m.cast_bouncy = true
				next = Cast.new(_m)
			else:
				next = Next.new(_m)
			if next is Teleport:
				if randf() < 0.1:
					if randf() < 0.2:
						next.teleports = 8
					else:
						next.teleports = 4
			elif next is Cast:
				next.casts = casts
			_m.fight_state = next
		timer -= delta

class Teleport extends FightState:
	var timer := 0.1
	var teleports := 1
	func setup() -> void:
		_m.animated_sprite_2d.play('dead')
		_m.animated_sprite_2d.modulate = Color(0.973, 0.451, 0.894)
		_m.common_enemy.unhittable = true
	
	func cleanup() -> void:
		_m.animated_sprite_2d.modulate = Color.WHITE
		_m.common_enemy.unhittable = false
	
	func update(delta: float) -> void:
		if timer <= 0.0:
			if teleports > 0:
				if _m.teleport_points.size() == 0:
					printerr("No teleport points provided")
				else:
					var plglpos = Refs.level_manager.player.body.global_position
					_m.animated_sprite_2d.global_position = _m.teleport_points.filter(func(tp: Node2D): return tp.global_position.distance_to(_m.animated_sprite_2d.global_position) > 6 and tp.global_position.distance_to(plglpos) > 32).pick_random().global_position + Vector2(0, -4)
				var t := Teleport.new(_m)
				t.teleports = teleports - 1
				_m.fight_state = t
			else:
				var idle := Idle.new(_m)
				if randf() < 0.1:
					_m._exclamating = 0.5
					idle.casts = 3
				_m.fight_state = idle
		timer -= delta

class Cast extends FightState:
	var _t := 0.2 + randf() * 0.8
	var casts := 0
	func setup() -> void:
		_m.animated_sprite_2d.play("cast")
		if _m.cast_bouncy:
			_m.cast_bouncy = false
			var b: Bouncer = BOUNCER.instantiate()
			b.direction = Vector2([1,-1].pick_random(), [1,-1].pick_random())
			b.position = _m.animated_sprite_2d.position
			_m._bouncers.push_back(b)
			_m.add_child(b)
		else:
			var proj: Projectile = PROJECTILE.instantiate()
			proj.modulate = Color.YELLOW
			proj.vector_direction = Refs.level_manager.player.hitbox_shape.global_position - _m.animated_sprite_2d.global_position
			proj.position = _m.animated_sprite_2d.position
			_m.add_child(proj)
	func update(delta: float) -> void:
		if _t < 0:
			var idle := Idle.new(_m)
			idle.timer = 1
			idle.casts = maxi(0, casts - 1)
			_m.fight_state = idle
		_t -= delta

class Pain extends FightState:
	var _t := 0.5
	func setup() -> void:
		_m.common_enemy.unhittable = true
		_m.animated_sprite_2d.play("hurt")
	func update(delta: float) -> void:
		if _t <= 0:
			_m.fight_state = Teleport.new(_m)
		_t -= delta
	func cleanup() -> void:
		_m.common_enemy.unhittable = false


var fight_state := FightState.new(self):
	set(s):
		if fight_state:
			fight_state.cleanup()
		fight_state = s
		if fight_state:
			fight_state.setup()


enum Phase {
	INIT,
	WAITING,
	FIGHT,
	DYING,
	SPAWN
}

var phase := Phase.INIT
var _player_prev_x := INF
var _serp_timer := 0.0
var _serp_cd := _calc_serp_cd()
var cast_bouncy := false
var _exclamating := 0.0
var _death_timer := 0.0
var _bouncers: Array[Bouncer] = []
var _start_hp := 0
var _spawn_timer := 0.0


func _should_cast_bouncer() -> bool:
	return _bouncers.size() < 1 or common_enemy.hitpoints <= 20 and _bouncers.size() < 2


func _calc_serp_cd() -> float:
	return serpent_cooldown + randf() * serpent_cooldown_variation * [1,-1].pick_random()


func _face_player() -> void:
	if not Refs.level_manager: return
	if Refs.level_manager.player.body.global_position.x > animated_sprite_2d.global_position.x:
		animated_sprite_2d.flip_h = false
	else:
		animated_sprite_2d.flip_h = true


func _ready() -> void:
	if Global.session.saved_data.mage_boss and not spawn:
		queue_free()
	
	_start_hp = maxi(0, common_enemy.hitpoints)
	_serp_timer = serpent_init_timer
	fight_state = Idle.new(self)
	serpent.visible = true
	
	if spawn:
		phase = Phase.SPAWN
		animated_sprite_2d.play("dead")


func _physics_process(delta: float) -> void:
	label.text = str(common_enemy.hitpoints)
	if _exclamating > 0:
		exclamation_mark.visible = true
	else:
		exclamation_mark.visible = false
	_exclamating -= delta
	match phase:
		Phase.SPAWN:
			await get_tree().physics_frame
			_face_player()
			if _spawn_timer >= 1:
				phase = Phase.WAITING
				animated_sprite_2d.play("idle")
			if _spawn_timer < 0.5:
				animated_sprite_2d.play("dead")
			else:
				animated_sprite_2d.play("hurt")
			_spawn_timer += delta
		Phase.INIT:
			await get_tree().physics_frame
			_face_player()
			phase = Phase.WAITING
		Phase.WAITING:
			if not Refs.level_manager: return
			if _player_prev_x != INF or spawn:
				var player_seen := pl_detector.has_overlapping_bodies()
				var player_crossed := signf(Refs.level_manager.player.body.global_position.x - 80) != signf(_player_prev_x - 80)
				
				if player_seen or player_crossed or common_enemy.is_hurt() or spawn:
					var txt: Array[String] = [
						"I will tear you asunder with my arcane might!",
						"And feed you to Cuddles!",
						"My pet demon serpent from HEEEELL!"
					]
					if common_enemy.is_hurt():
						txt.push_front("Why you little...")
					if not spawn:
						MessageDisplayer.display(
							txt,
							func() -> void:
								AudioManager.play_music(AudioManager.music_themes.boss_theme)
						)
					phase = Phase.FIGHT
					Global.session.saved_data.object_flags["mage_fight"] = true
					if common_enemy.is_hurt():
						fight_state = Teleport.new(self)
			_player_prev_x = Refs.level_manager.player.body.global_position.x
		Phase.FIGHT:
			if common_enemy.is_dead():
				Global.session.saved_data.mage_boss = true
				phase = Phase.DYING
				for b in _bouncers:
					b.direction = Vector2(0,0)
				_bouncers.clear()
				if serpent and not serpent.is_dead():
					serpent.stop()
					serpent.die()
				if not spawn:
					MessageDisplayer.display(
						[
							"For hate's sake I spit my last breath at thee!!"
						],
					)
			
			if common_enemy.is_hurt():
				fight_state = Pain.new(self)
			
			fight_state.update(delta)
			
			if serpent and not serpent.is_dead():
				if not serpent.is_moving():
					serpent.global_position.y = -5000
					if _serp_timer >= _serp_cd:
						_serp_cd = _calc_serp_cd()
						_serp_timer = 0.0
						serpent.target = 12
						var sp: Node2D = serpent_possible_spawn_points.pick_random()
						if not sp:
							printerr("No serpent possible spawn points provided")
						else:
							serpent.global_position = sp.global_position
							if serpent.global_position.x > 80:
								serpent.direction = Global.Direction.LEFT
							else:
								serpent.direction = Global.Direction.RIGHT
					else:
						_serp_timer += delta
		Phase.DYING:
			if _death_timer > 2:
				animated_sprite_2d.play("dead")
			if _death_timer > 4:
				if not spawn:
					AudioManager.stop_music()
				queue_free()
			_death_timer += delta
