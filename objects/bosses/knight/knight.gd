extends Node2D
class_name KnightBoss


static var deaths := 0


const PROJECTILE = preload("uid://bpyn0rqd6mrg2")

const FRAME_WALK_1 := 648
const FRAME_WALK_2 := 649
const FRAME_ATTACK := 660
const FRAME_SWORD_TIP := 661
const FRAME_HURT := 672
const FRAME_DEAD := 684
const FRAME_EMPTY := 673


@onready var body: CharacterBody2D = %Body
@onready var anchor: Node2D = %Anchor
@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var sprite_2d_2: Sprite2D = %Sprite2D2
@onready var common_enemy: CommonEnemy = %CommonEnemy
@onready var player_detector: Area2D = %PlayerDetector
@onready var detector_circle: CollisionShape2D = %DetectorCircle
@onready var detector_front_shape: CollisionShape2D = %DetectorFrontShape
@onready var sword_shape: CollisionShape2D = %SwordShape
@onready var sword_hazard: Hazard = %SwordHazard
@onready var megaslash: Line2D = %Megaslash
@onready var megaslash_ray: RayCast2D = %MegaslashRay
@onready var floor_detector: RayCast2D = %FloorDetector

var _floor_detect_timer := 0.0

@export var spawn := false

class FightState:
	var _k: KnightBoss
	func _init(knight: KnightBoss) -> void:
		_k = knight
	func setup() -> void: pass
	func update(_delta: float) -> void: pass
	func cleanup() -> void: pass

class Idle extends FightState:
	var timer: float = [1,1,2].pick_random() if randf() < 0.9 else 4.0
	func setup() -> void:
		_k.set_frame_to_walk_1()
	func update(delta: float) -> void:
		_k.body.velocity.x = _k.body.velocity.x - signf(_k.body.velocity.x) * absf(_k.body.velocity.x) * 3 * delta
		_k.body.velocity.y += 300 * delta
		_k.body.move_and_slide()
		if timer <= 0 and _k.body.is_on_floor():
			var rng := RandomNumberGenerator.new()
			var index := rng.rand_weighted([12,12,12,12,12,12])
			match index:
				0: _k._fight_state = JumpAround.new(_k)
				1: _k._fight_state = Walk.new(_k)
				2: _k._fight_state = Square.new(_k)
				3: _k._fight_state = RunAttack.new(_k)
				4: _k._fight_state = BounceAround.new(_k)
				5: _k._fight_state = CometKick.new(_k)
		timer -= delta

class Square extends FightState:
	var phase := 0
	var timer := 0.0
	var timer_dur := 0.3
	var move_speed := 400.0
	var attack_speed := 1000.0
	var draw_megaslash := false
	func cleanup() -> void:
		_k.angle = 0
		_k.megaslash_ray.target_position = Vector2(0,0)
		_k.common_enemy.harmless = false
	func update(delta: float) -> void:
		var joever := false
		
		match phase:
			0:
				_k.body.velocity = Vector2(0, 0)
				phase += 1
			1:
				if timer > timer_dur * _k.get_hp_fraction():
					timer = -INF
					_k.body.velocity = Vector2(0, -move_speed)
				
				_k.body.move_and_slide()
				if _k.body.is_on_ceiling():
					phase += 1
					_k.body.velocity = Vector2(0, 0)
					timer = 0
					_k.body.move_and_collide(Vector2(0,1))
					_k.body.move_and_collide(Vector2(signf(80 - _k.body.global_position.x), 0))
			2:
				if timer > timer_dur * _k.get_hp_fraction():
					timer = -INF
					_k.body.velocity = Vector2(signf(80 - _k.body.global_position.x) * move_speed, 0)
					if _k.body.velocity.x == 0:
						_k.body.velocity.x = move_speed
				
				_k.body.move_and_slide()
				if _k.body.is_on_wall():
					phase += 1
					_k.body.velocity = Vector2(0, 0)
					timer = 0
			3:
				if timer > timer_dur * _k.get_hp_fraction():
					timer = -INF
					_k.body.velocity = Vector2(0, move_speed)
				
				_k.body.move_and_slide()
				if _k.body.is_on_floor():
					phase += 1
					_k.body.velocity = Vector2(0, 0)
					timer = 0
					_k.body.move_and_collide(Vector2(signf(80 - _k.body.global_position.x), 0))
			4:
				if timer > timer_dur * _k.get_hp_fraction():
					timer = -INF
					_k.body.velocity = Vector2(sign(80 - _k.body.global_position.x) * attack_speed, 0)
					if _k.body.velocity.x == 0:
						_k.body.velocity.x = attack_speed
					_k.megaslash.points = [_k.body.position]
					draw_megaslash = true
					_k.fade_megaslash = false
					_k.megaslash_opacity = 1
					_k.common_enemy.harmless = true
				
				_k.body.move_and_slide()
				
				if draw_megaslash:
					_k.megaslash.points = [_k.megaslash.points[0], _k.body.position]
					_k.megaslash_ray.target_position = _k.megaslash.points[0] - _k.body.position
				
				if _k.megaslash_ray.is_colliding():
					var p: Player = Refs.level_manager.player
					p._on_hitbox_area_entered(_k.common_enemy._hazard)
				
				if _k.body.is_on_wall():
					joever = true
					phase += 1
					_k.body.velocity = Vector2(0, 0)
					timer = 0
					_k._fight_state = Idle.new(_k)
					Refs.level_manager.shake_it(0.5, 5)
					_k.fade_megaslash = true
		
		if not joever:
			if _k.body.velocity.is_zero_approx():
				_k.set_frame_to_walk_1()
				_k.look_at_player()
				_k.angle = 0
			else:
				_k.play_flail_animation(delta, 3)
				if _k.body.velocity.y != 0:
					if _k.body.velocity.y > 0:
						_k.angle = _k.direction * PI / 2.0
					else:
						_k.angle = -_k.direction * PI / 2.0
				else:
					_k.angle = 0
					_k.look_at_direction(_k.body.velocity.x)
			
			timer += delta

class CometKick extends FightState:
	var spin: float = [1,-1].pick_random()
	var phase := 0
	func setup() -> void:
		_k.angle = 0
		_k.anchor.rotation = 0
		_k.look_at_player()
	func cleanup() -> void:
		_k.angle = 0
	func update(delta: float) -> void:
		match phase:
			0:
				_k.body.velocity = Vector2(-_k.direction, -50)
				_k.body.move_and_slide()
				phase += 1
			1:
				_k.body.velocity.y += 50 * delta
				_k.angle += delta * spin * 6
				_k.body.move_and_slide()
				if absf(_k.anchor.rotation) >= 2 * PI:
					_k.set_frame_to_attack()
					phase += 1
					_k.body.velocity = Refs.level_manager.player.hitbox_shape.global_position - _k.body.global_position
					_k.body.velocity = _k.body.velocity.normalized() * (250 + 100 * (1 - _k.get_hp_fraction()))
					_k.look_at_player()
					_k.angle = _k.body.velocity.angle() if _k.direction == Global.Direction.RIGHT else _k.body.velocity.angle() - PI
			2:
				var prev := _k.body.velocity
				_k.body.move_and_slide()
				if _k.body.is_on_floor() or _k.body.is_on_ceiling() or _k.body.is_on_wall():
					_k._fight_state = Idle.new(_k)
					Refs.level_manager.shake_it(0.5, 6)
					if Refs.level_manager.player.body.is_on_floor():
						Refs.level_manager.player.velocity.y -= 100
					if _k.body.is_on_floor():
						_k.body.velocity.x *= 0.5
						_k.body.velocity.y = -prev.y * 0.7
					if _k.body.is_on_wall():
						_k.body.velocity.x = -prev.x * 0.3

class BounceAround extends FightState:
	var speed := 75.0
	var times: int = [4, 8].pick_random()
	var start := true
	func setup() -> void:
		speed = speed + speed * (1 - _k.get_hp_fraction()) * 0.5
		_k.body.velocity = Vector2(speed, 0)
		_k.body.velocity = _k.body.velocity.rotated([PI/4.0, PI/2.0 + PI/4.0].pick_random())
	func cleanup() -> void:
		_k.angle = 0
		_k.body.velocity = Vector2(0, 0)
	func update(delta: float) -> void:
		var prev := _k.body.velocity
		_k.look_at_direction(_k.body.velocity.x)
		_k.angle = _k.body.velocity.angle() if _k.direction == Global.Direction.RIGHT else _k.body.velocity.angle() - PI
		_k.body.move_and_slide()
		_k.play_flail_animation(delta)
		
		if _k.body.is_on_ceiling() or _k.body.is_on_floor():
			if not start:
				Refs.level_manager.shake_it(0.3, 3)
			if _k.body.is_on_floor():
				if not start:
					var p1: Projectile = PROJECTILE.instantiate()
					p1.modulate = Color.YELLOW * 20
					p1.vector_direction = Vector2(1,0)
					p1.shockwave_sprite = true
					p1.position.x = _k.body.position.x
					#p1.position.y = 1
					p1.speed = [10,20,40].pick_random()
					var p2 := p1.duplicate()
					p2.vector_direction.x = -p2.vector_direction.x
					_k.add_child(p1)
					_k.add_child(p2)
					p1.global_position.y = _k.floor_level
					p2.global_position.y = _k.floor_level
				if times <= 0:
					_k._fight_state = Idle.new(_k)
					return
			else:
				var p1: Projectile = PROJECTILE.instantiate()
				p1.modulate = Color.YELLOW * 20
				p1.brick_sprite = true
				p1.direction = _k.direction
				p1.position = _k.body.position
				p1.speed = [5, 10, 15].pick_random()
				#p1.modulate = Color(0.659, 0.392, 0.216)
				var p2 := p1.duplicate()
				p2.direction = Global.Direction.RIGHT if p2.direction == Global.Direction.LEFT else Global.Direction.LEFT
				_k.add_child(p1)
				_k.add_child(p2)
			start = false
			times -= 1
			_k.body.velocity.y = -prev.y
		if _k.body.is_on_wall():
			start = false
			times -= 1
			Refs.level_manager.shake_it(0.3, 3)
			_k.body.velocity.x = -prev.x
			_k.look_at_direction(_k.body.velocity.x)
			var p1: Projectile = PROJECTILE.instantiate()
			p1.modulate = Color.YELLOW * 20
			p1.brick_sprite = true
			p1.direction = _k.direction
			p1.position = _k.body.position
			p1.speed = [33, 49.5, 66].pick_random()
			#p1.modulate = Color(0.659, 0.392, 0.216)
			_k.add_child(p1)

class RunAttack extends FightState:
	var timer := 0.0
	var collided := false
	func setup() -> void:
		_k.look_at_player()
		_k.body.velocity = Vector2(0, 0)
	func update(delta: float) -> void:
		if collided:
			_k.body.velocity.y += 50 * delta
			_k.body.move_and_slide()
			if _k.body.is_on_floor():
				_k._fight_state = Idle.new(_k)
		else:
			if timer > 1:
				if _k.body.is_on_wall():
					_k.body.velocity.x = -_k.direction * 10
					_k.body.velocity.y = -25
					Refs.level_manager.shake_it()
					collided = true
			_k.play_flail_animation(1 + timer * 0.05)
			_k.body.velocity.x += _k.direction * delta * 25 + (_k.body.velocity.x * (1 + 0.5 * (1 - _k.get_hp_fraction()))) * delta
			_k.body.velocity.y += 100 * delta
			_k.body.move_and_slide()
			timer += delta

class Walk extends FightState:
	var timer: float = 0.5 + [0,0,1,1,1,2].pick_random()
	var dir_cooldown := 0.0
	var h_speed := 50.0
	var speed_scale := 1.0
	var dir: int = [1,-1].pick_random()
	var prev_h_speed := 0.0
	func take_step() -> void:
		_k.body.velocity.x = h_speed * dir
		Refs.level_manager.shake_it(0.1, 2)
	func _init(knight: KnightBoss) -> void:
		super(knight)
		h_speed += 50.0 * (1.0 - _k.get_hp_fraction())
		speed_scale += 0.2 * (1.0 - _k.get_hp_fraction())
	func setup() -> void:
		_k.anim_index = 0
		_k.play_walk_animation(0)
		_k.took_step.connect(take_step)
		_k.detector_circle.disabled = true
		_k.detector_front_shape.disabled = false
	func cleanup() -> void:
		_k.took_step.disconnect(take_step)
	func update(delta: float) -> void:
		if dir_cooldown <= 0 and _k.body.is_on_wall():
			dir = signi(floori(_k.body.get_wall_normal().x))
			_k.body.velocity.x = dir * abs(prev_h_speed)
			dir_cooldown = 0.5
		_k.body.velocity.x -= signf(_k.body.velocity.x) * abs(_k.body.velocity.x) * delta * 10
		if _k.common_enemy.is_hurt() or _k.player_detector.has_overlapping_bodies():
			_k.play_flail_animation(delta, speed_scale)
		else:
			_k.play_walk_animation(delta, speed_scale)
		_k.look_at_direction(_k.body.velocity.x)
		_k.body.velocity.y += 50 * delta
		prev_h_speed = _k.body.velocity.x
		_k.detector_front_shape.position.x = dir * abs(_k.detector_front_shape.position.x)
		_k.body.move_and_slide()
		if timer <= 0:
			var idle := Idle.new(_k)
			idle.timer = 0.0
			_k._fight_state = idle
		timer -= delta


class JumpAround extends FightState:
	var times := 3
	var dir_cooldown := 0.0
	var h_speed := 30.0
	var times_jumped := 0
	var power := 1.0 + (randi() % 4) / 3.0
	var random := randf() < 0.5
	func setup() -> void:
		_k.play_flail_animation(0)
		_k.body.velocity.x = h_speed * [1, -1].pick_random()
	func cleanup() -> void:
		_k.body.velocity.x = 0
	func update(delta: float) -> void:
		_k.play_flail_animation(delta)
		if dir_cooldown <= 0 and _k.body.is_on_wall():
			_k.body.velocity.x = _k.body.get_wall_normal().x * h_speed
			dir_cooldown = 0.5
		dir_cooldown -= delta
		if _k.body.is_on_floor():
			if times_jumped > 0:
				var p1: Projectile = PROJECTILE.instantiate()
				p1.modulate = Color.YELLOW * 20
				p1.vector_direction = Vector2(1,0)
				p1.shockwave_sprite = true
				p1.lifetime = power - _k.get_hp_fraction()
				p1.position.x = _k.body.position.x
				#p1.position.y = 1
				var p2 := p1.duplicate()
				p2.vector_direction.x = -p2.vector_direction.x
				_k.add_child(p1)
				_k.add_child(p2)
				p1.global_position.y = _k.floor_level
				p2.global_position.y = _k.floor_level
				Refs.level_manager.shake_it(0.2 * power, floori(2 * power))
				if Refs.level_manager.player.body.is_on_floor():
					Refs.level_manager.player.velocity.y = -25
			if times > 0:
				times -= 1
				times_jumped += 1
				_k.body.velocity.y -= 250 * power
				_k.angle += TAU * [1, -1].pick_random() * [1,2,3].pick_random()
				if random:
					_k.body.velocity.x = [1, -1].pick_random() * h_speed
			else:
				_k._fight_state = Idle.new(_k)
		else:
			_k.body.velocity.y += (25 + abs(_k.body.velocity.y) * 10) * delta
		_k.body.move_and_slide()
		_k.look_at_direction(_k.body.velocity.x)



enum Phase {
	INIT,
	WAITING,
	FIGHT,
	DYING,
	SPAWN
}


var _phase := Phase.INIT

var _fight_state: FightState:
	set(f):
		if _fight_state: _fight_state.cleanup()
		_fight_state = f
		if _fight_state: _fight_state.setup()


func set_frame_to_walk_1() -> void:
	sprite_2d.frame = FRAME_WALK_1
	sprite_2d_2.frame = FRAME_EMPTY

func set_frame_to_walk_2() -> void:
	sprite_2d.frame = FRAME_WALK_2
	sprite_2d_2.frame = FRAME_EMPTY

func set_frame_to_attack() -> void:
	sprite_2d.frame = FRAME_ATTACK
	sprite_2d_2.frame = FRAME_SWORD_TIP

func set_frame_to_hurt() -> void:
	sprite_2d.frame = FRAME_HURT
	sprite_2d_2.frame = FRAME_EMPTY

func set_frame_to_dead() -> void:
	sprite_2d.frame = FRAME_DEAD
	sprite_2d_2.frame = FRAME_EMPTY


func look_at_player() -> void:
	var dir := signf(Refs.level_manager.player.body.global_position.x - body.global_position.x)
	look_at_direction(dir)

func look_at_direction(dir: float) -> void:
	if dir > 0:
		direction = Global.Direction.RIGHT
	elif dir < 0:
		direction = Global.Direction.LEFT


var anim_index := 0.0
signal took_step

func play_walk_animation(delta: float, speed_scale := 1.0):
	if fmod(anim_index, 0.4) < 0.2:
		set_frame_to_walk_1()
	else:
		if sprite_2d.frame != FRAME_WALK_2:
			took_step.emit()
		set_frame_to_walk_2()
	anim_index += delta * speed_scale

func play_flail_animation(delta: float, speed_scale := 1.0):
	if fmod(anim_index, 0.34) < 0.17:
		set_frame_to_walk_1()
	else:
		if sprite_2d.frame != FRAME_ATTACK:
			took_step.emit()
		set_frame_to_attack()
	anim_index += delta * speed_scale


func get_hp_fraction() -> float:
	if spawn: return 1
	return common_enemy.hitpoints / float(start_hitpoints)


var direction := Global.Direction.RIGHT
var angle := 0.0
var _t := 0.0
var start_hitpoints := 0
var fade_megaslash := false
var megaslash_opacity := 1.0
var one_liner := 1.0
var floor_level = 1.0


func _ready() -> void:
	_fight_state = Idle.new(self)
	start_hitpoints = common_enemy.hitpoints
	
	if spawn:
		set_frame_to_hurt()
		_phase = Phase.SPAWN
	else:
		if Global.session.saved_data.knight_boss:
			queue_free()


func _physics_process(delta: float) -> void:
	if _floor_detect_timer < 1:
		_floor_detect_timer += delta
		if _floor_detect_timer >= 1:
			floor_level = floor_detector.get_collision_point().y - 2
	
	if fade_megaslash:
		megaslash_opacity -= delta
		if megaslash_opacity <= 0:
			megaslash_opacity = 0
			fade_megaslash = false
	megaslash.modulate.a = floorf(megaslash_opacity * 3) / 3.0
	
	if common_enemy.is_on_iframes() and not common_enemy.is_dead():
		anchor.modulate.a = 0.5
	else:
		anchor.modulate.a = 1
	
	if sprite_2d_2.frame == FRAME_SWORD_TIP:
		if common_enemy.harmless:
			sword_shape.disabled = true
		else:
			sword_shape.disabled = false
	else:
		sword_shape.disabled = true
	
	var p := (sprite_2d_2.global_position - sprite_2d.global_position).normalized() * 3
	sword_hazard.global_position = sprite_2d.global_position + p
	
	match direction:
		Global.Direction.RIGHT:
			anchor.scale.x = 1
		Global.Direction.LEFT:
			anchor.scale.x = -1
	
	if anchor.rotation != angle:
		anchor.rotation += (angle - anchor.rotation) * delta * 4
		var prev_sign := signf(angle - anchor.rotation)
		anchor.rotation += prev_sign * delta * TAU * 0.1
		if prev_sign != signf(angle - anchor.rotation):
			anchor.rotation = angle
	
	match _phase:
		Phase.SPAWN:
			if _t >= 1:
				_phase = Phase.WAITING
				set_frame_to_walk_1()
			if _t < 0.5:
				set_frame_to_dead()
			else:
				set_frame_to_hurt()
			_t += delta
		Phase.INIT:
			if _t > 0.1:
				_phase = Phase.WAITING
			_t += delta
		Phase.WAITING:
			look_at_player()
			if player_detector.has_overlapping_bodies() or common_enemy.is_hurt() or spawn:
				var txt: Array[String] = [
					"You be dead!"
				]
				if common_enemy.is_hurt():
					txt.push_front("Ow!")
				if not spawn:
					MessageDisplayer.display(
						txt,
						func():
							AudioManager.play_music(AudioManager.music_themes.boss_theme)
					)
				_phase = Phase.FIGHT
				if spawn:
					var ja := JumpAround.new(self)
					ja.times = 0
					ja.times_jumped = 1
					ja.h_speed = 0
					_fight_state = ja
				Global.session.saved_data.object_flags["knight_fight"] = true
		Phase.FIGHT:
			if common_enemy.is_dead():
				if not spawn:
					MessageDisplayer.display(["AIEEEEEE!"])
				Global.session.saved_data.knight_boss = true
				_phase = Phase.DYING
				_t = 0
				# Destroy children to avoid cheap shots
				for child in get_children():
					if child != body and child != megaslash:
						child.queue_free()
			else:
				_fight_state.update(delta)
				
				if one_liner > 0 and Refs.level_manager.player.health.value <= 0 and not spawn:
					one_liner -= delta
					if one_liner < 0:
						deaths += 1
						if deaths % 15 == 0:
							MessageDisplayer.display([
								"You're a persistent pest, aren't you?",
								"You just never learn.",
								str(deaths) + "th time I had to teach you this lesson.",
								"Insert misattributed quote about insanity here."
							])
						else:
							MessageDisplayer.display([[
								"Enough about my interests, what about yours?",
								"What a grand and intoxicating innocence.",
								"Quit and take up knitting.",
								"Rest in pieces.",
								"Predictable.",
								"Too hard?",
								"See?",
								"Ha.",
								"I did you a favour.",
								"Still got it.",
								"Undefeated.",
								"And stay down.",
								"I'm good.",
								"As I said.",
								"You do be dead.",
								"That'll learn ya.",
								"Try without a blindfold.",
								"Better luck next time.",
								"You're going to have to git good.",
								"It's joever joker.",
								"Don't fight drunk, kids.",
								"A bold strategy.",
								"You should have stayed out.",
								"These are a few of my favourite things.",
								"Not good enough.",
							].pick_random()])
		Phase.DYING:
			if _t < 2:
				set_frame_to_hurt()
			else:
				set_frame_to_dead()
			
			if _t > 4:
				if not spawn:
					AudioManager.stop_music()
				queue_free()
			
			_t += delta
