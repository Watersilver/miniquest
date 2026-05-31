extends Node2D
class_name Mask

const BIG_SLIME = preload("uid://r1t8xp7ddrca")
const TOWER_GUY = preload("uid://qhcwyryg6cta")
const KNIGHT = preload("uid://cbo3b0ihhv167")
const MAGE = preload("uid://dgyydtca2uksw")

const BAT = preload("uid://bei8vy7qg6bbd")
const FLAME = preload("uid://bq6myq6icny5i")
const ICE_SPIKE = preload("uid://coi2ja0tthnk6")
const JUMPER = preload("uid://cj25b2mpqu35s")
const RANGER = preload("uid://dcfwu8mbjjah4")
const SNAKE = preload("uid://b7qgoa2hyhi12")
const WINGED_HEAD = preload("uid://b5ak85mb0naba")
const WORM = preload("uid://bk7exdv8chgkk")

const PROJECTILE = preload("uid://bpyn0rqd6mrg2")
const NPC = preload("uid://ddtplryl7v5i0")


class State:
	var mask: Mask
	func setup() -> void: pass
	func cleanup() -> void: pass
	func update(_delta: float) -> void: pass

class Init extends State:
	func setup() -> void:
		if mask.final_boss:
			if Global.session.saved_data.object_flags.has("talked_to_mask") and Global.session.saved_data.object_flags["talked_to_mask"]:
				MessageDisplayer.display(
					["How could you survive everything?!", "I'll just have to take care of you myself!", "Me, Myself and...", "THAT ARMY!"],
					func():
						AudioManager.play_music(AudioManager.music_themes.final_boss_theme)
				)
			else:
				MessageDisplayer.display(
					["You didn't even talk to me!", "You shunned me!", "You'll pay for that!"],
					func():
						AudioManager.play_music(AudioManager.music_themes.final_boss_theme)
				)
			mask.state = Attack.new()
		else:
			mask.state = Talk.new()
			mask.z_index = 0

class Talk extends State:
	var talked := false
	var timer := 0.0
	var npc: Npc
	func _flag_is_true(flag: String) -> bool:
		if not Global.session.saved_data.object_flags.has(flag): return false
		return Global.session.saved_data.object_flags[flag]
	func _get_text() -> void:
		if not npc: return
		if mask.hints.size() == 0: return
		var potential: Array[Hint] = []
		for hint in mask.hints:
			if hint.enabled_by_any_of.size() == 0 and hint.disabled_by_any_of.size() == 0:
				potential.push_back(hint)
			else:
				var push := 1 if hint.enabled_by_any_of.size() == 0 else 0
				for e in hint.enabled_by_any_of:
					if e.flags.all(_flag_is_true):
						push += 1
						break
				for e in hint.disabled_by_any_of:
					if e.flags.all(_flag_is_true):
						push -= 1
						break
				if push > 0:
					potential.push_back(hint)
		npc.text = potential[floori(potential.size() * randf())].text
	func _on_dlg_end() -> void:
		mask.move_mouth = true
		talked = true
		Global.session.saved_data.object_flags["talked_to_mask"] = true
		mask.oscillation.frequency.z = 0.0
		mask.oscillation.amplitude.z = 0.0
		_clean_npc()
	func _create_npc() -> void:
		npc = NPC.instantiate()
		mask.add_child(npc)
		npc.getting_text.connect(_get_text)
		npc.end.connect(_on_dlg_end)
	func _clean_npc() -> void:
		if not npc: return
		npc.getting_text.disconnect(_get_text)
		npc.end.disconnect(_on_dlg_end)
		npc.queue_free()
		npc = null
	func setup() -> void:
		mask.uncontrolled_rot_osc = true
		mask.oscillation.frequency.z = 0.5
		mask.oscillation.amplitude.z = 1
	func cleanup() -> void:
		_clean_npc()
	func update(delta: float) -> void:
		if talked:
			if mask.appear_progress <= 0:
				mask.queue_free()
			if timer > 2:
				mask.appear = false
			timer += delta
			return
		
		if not npc:
			if mask.appear_progress >= 1:
				if timer > 0.5:
					timer = 0
					_create_npc()
				timer += delta

class Attack extends State:
	var timer := 1.0
	var summon_timer := -1.0
	func setup() -> void:
		mask.movement_type = mask.MovementType.OSCILLATE
		summon_timer = 3 + randf() * 5 - mask.get_rage()
	func update(delta: float) -> void:
		if timer <= 0 and mask._hurt_timer == INF:
			mask.hostile = true
		timer -= delta
		
		if summon_timer < 1:
			mask.move_mouth = true
			mask._mouth_speed = 10
		else:
			mask.move_mouth = false
			if not mask._hurt:
				mask.mouth_open = false
		
		if summon_timer > 0:
			summon_timer -= delta
			if summon_timer < 0:
				var mgp := mask.global_position
				if mgp.x > 16 and mgp.x < 144 and mgp.y > 16 and mgp.y < 88:
					summon_timer = 3 + randf() * 5 - mask.get_rage()
					if mask.summoned_bosses == 2:
						var proj: Projectile = PROJECTILE.instantiate()
						proj.vector_direction = Refs.level_manager.player.body.global_position - mask.global_position
						proj.modulate = Color.RED * 20
						proj.position = mask.position
						mask.add_sibling(proj)
						proj.hazard.dmg_dice = Global.Damage.ROLL_1D10
						proj.hazard.advantage = true
					else:
						var summon: int = [0,1,2,3,4,5,6,7].pick_random()
						var pl_right := Refs.level_manager.player.body.global_position.x - mask.global_position.x > 0
						match summon:
							0:
								print('Summoning bat')
								var bat: EnemyBat = BAT.instantiate()
								bat.position = mask.position
								bat.direction = Global.Direction.RIGHT if pl_right else Global.Direction.LEFT
								bat.oscillation = OscillationResource.new()
								bat.oscillation.amplitude = Vector3(0, 1 + randf() * 24, 0)
								mask.add_sibling(bat)
								bat.common_enemy.immune_to_ice = true
							1:
								print('Summoning flame')
								var flame: Node2D = FLAME.instantiate()
								flame.position = mask.position
								mask.add_sibling(flame)
								flame.common_enemy.immune_to_ice = true
							2:
								print('Summoning ice spike')
								var ice_spike: IceSpike = ICE_SPIKE.instantiate()
								ice_spike.position = mask.position
								ice_spike.position.y = floor(ice_spike.position.y / 8.0) * 8
								ice_spike.no_prowling = true
								if mask.global_position.y > 52:
									ice_spike.type = ice_spike.Type.FLOOR
								else:
									ice_spike.type = ice_spike.Type.CEIL
								mask.add_sibling(ice_spike)
							3:
								print('Summoning jumper')
								var jumper: Jumper = JUMPER.instantiate()
								jumper.direction = Global.Direction.RIGHT if pl_right else Global.Direction.LEFT
								jumper.position = mask.position
								jumper.type = [jumper.Type.STATIC, jumper.Type.RANDOM, jumper.Type.FORWARD, jumper.Type.FOLLOW].pick_random()
								jumper.start_looking_at_player = true
								mask.add_sibling(jumper)
								jumper.common_enemy.immune_to_ice = true
							4:
								print('Summoning ranger')
								var ranger: EnemyRanger = RANGER.instantiate()
								ranger.position = mask.position
								ranger.type = [ranger.Type.ARCHER, ranger.Type.MAGE].pick_random()
								mask.add_sibling(ranger)
								ranger.character_animations.direction = Global.Direction.RIGHT if pl_right else Global.Direction.LEFT
								ranger.common_enemy.immune_to_ice = true
							5:
								print('Summoning snake')
								var snake: EnemySnake = SNAKE.instantiate()
								snake.position = mask.position
								snake.type = [snake.SnakeType.RED, snake.SnakeType.YELLOW].pick_random()
								snake.face_player_on_start = true
								mask.add_sibling(snake)
								snake.common_enemy.immune_to_ice = true
							6:
								print('Summoning winged head')
								var winged_head: WingedHead = WINGED_HEAD.instantiate()
								winged_head.position = mask.position
								winged_head.type = [winged_head.Type.PINK, winged_head.Type.YELLOW].pick_random()
								winged_head.oscillation = OscillationResource.new()
								winged_head.oscillation.amplitude = Vector3(
									24 * randf(), 24 * randf(), 0
								)
								winged_head.oscillation.frequency = Vector3(
									randf(), randf(), 0
								)
								mask.add_sibling(winged_head)
								winged_head.common_enemy.immune_to_ice = true
							7:
								print('Summoning worm')
								var worm: EnemyWorm = WORM.instantiate()
								worm.position = mask.position
								worm.direction = Global.Direction.RIGHT if pl_right else Global.Direction.LEFT
								mask.add_sibling(worm)
								worm.common_enemy.immune_to_ice = true
				else:
					summon_timer += delta
		
		if mask.summoned_bosses == 0:
			if mask.get_rage() >= 0.33:
				mask.state = SummonBosses.new()
		elif mask.summoned_bosses == 1:
			if mask.get_rage() >= 0.66:
				mask.state = SummonBosses.new()
		else:
			if mask.enem.is_dead():
				mask.state = Dead.new()

class SummonBosses extends State:
	var timer := 2.0
	var summoned := false
	func setup() -> void:
		mask.hostile = false
		mask.ct_target_global_position = Vector2(80.0, 32.0)
		mask.movement_type = mask.MovementType.CONSTANT_TIME
		mask.move_mouth = true
		mask._mouth_speed = 5
		mask.oscillate_rotation = true
		mask.destroy_enemies()
	func cleanup() -> void:
		mask.oscillate_rotation = false
	func update(delta: float) -> void:
		mask.hostile = false
		if summoned:
			if timer <= 0:
				var bosses := mask.get_tree().get_nodes_in_group("bosses")
				bosses.erase(mask)
				if bosses.size() == 0:
					mask.state = Attack.new()
		else:
			if timer <= 0:
				if mask.summoned_bosses == 1:
					mask.summon_second_bosses()
					mask.summoned_bosses = 2
				else:
					mask.summon_first_bosses()
					mask.summoned_bosses = 1
				summoned = true
				timer = 3
			else:
				mask.destroy_enemies()
		timer -= delta

class Dead extends State:
	var timer := 4.0
	var exploding := 1.0
	func setup() -> void:
		mask.destroy_enemies()
		mask.movement_type = mask.MovementType.CONSTANT_TIME
		mask.ct_target_global_position = Vector2(80.0, 48.0)
		mask.mouth_open = true
		mask.hostile = false
		MessageDisplayer.display([
			"Oh really?",
			"Let's see how you do against ALL FOUR BOSSES!",
			"jk I'm dead",
		])
	func update(delta: float) -> void:
		mask.oscillation.amplitude += (Vector3(0, 0, 0) - mask.oscillation.amplitude) * delta / 2.0
		mask.oscillation.frequency += (Vector3(0, 0, 0) - mask.oscillation.frequency) * delta / 2.0
		if timer < 0:
			if exploding == 1:
				mask.circle = true
				mask.appear = false
			exploding -= delta
			if exploding < 0:
				AudioManager.stop_music()
				mask.queue_free()
		else:
			timer -= delta

var state: State:
	set(s):
		if state:
			state.cleanup()
		s.mask = self
		state = s
		if state:
			state.setup()


@onready var anchor: Node2D = %Anchor
@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var enem: CommonEnemy = %CommonEnemy

@export var enable_flag: String
@export var disable_flag: String
@export var move_flag: String
@export var move_flag_relative_target: Vector2

@export var hints: Array[Hint]

enum Colour {
	YELLOW,
	RED
}

enum Face {
	SMILE,
	FROWN,
	POKER,
	SURPRISED,
	SCARED,
	DISAPPOINTED,
	SAD,
	CRYING
}

@export var hostile := false
@export var final_boss := false

enum MovementType {
	OSCILLATE,
	CONSTANT_SPEED,
	CONSTANT_TIME,
	STILL
}

@export var movement_type := MovementType.STILL

@export var oscillation: OscillationResource
@export var circle := false:
	set(c):
		circle = c
		target_circle = c
@export var colour := Colour.YELLOW:
	set(c):
		colour = c
		target_colour = c
@export var mouth_open := false
@export var face := Face.SMILE
@export var appear := true
@export_range(0, 1) var appear_progress := 0.0:
	set(a):
		appear_progress = clampf(a, 0, 1)
@export var move_mouth := false
@export var target_circle := false
@export var target_colour := Colour.YELLOW

@export var oscillate_rotation := false


@export_group("oscillation movement type")
## Movement dimensional spring constants
@export var k := Vector2(1, 1)
## Acceleration
@export var a := Vector2(0, 0)
## Velocity
@export var v := Vector2(0, 0)
## Mass
@export var m := 1.0
## Displacement
@export var r := Vector2(0, 0)

@export var equilibrium := Vector2(80.0, 52.0)

@export_group("constant speed movement type", "cs")
@export var cs_speed := 25.0
@export var cs_target_global_position := Vector2(80.0, 52.0)

@export_group("constant time movement type", "ct")
@export var ct_secs := 2.0
@export var ct_target_global_position := Vector2(80.0, 52.0)

func get_energy(amplitude: Vector2) -> Vector2:
	return (k / 2.0) * amplitude * amplitude

func get_current_energy() -> Vector2:
	return (m / 2.0) * v * v + (k / 2.0) * r * r



var _t := 0.0

var max_health := 0.0
var _hurt := false
var _hurt_timer := INF
var summoned_bosses := 0
var _mouth_speed := 5.0
var _mouth_timer := 0.0
var uncontrolled_rot_osc := false


func get_rage() -> float:
	return 1 - enem.hitpoints/max_health


func destroy_enemies() -> void:
	for p in get_tree().get_nodes_in_group("projectiles"):
		if p: p.queue_free()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is CommonEnemy and e != enem:
			e.is_frozen = false
			e.hitpoints = -1


func summon_first_bosses() -> void:
	MessageDisplayer.display([
		"Big slime, Tower guy!",
		"Rise from the dead and serve me once more!",
		"I summon you to torment my enemy!",
	])
	var bs: BigSlime = BIG_SLIME.instantiate()
	var flip_bs := false
	if Refs.level_manager.player.body.global_position.x > 80:
		bs.position.x = 16
	else:
		flip_bs = true
		bs.position.x = 144
	bs.position.y = 88
	bs.state = bs.State.SPAWN
	bs.no_rage = true
	add_sibling(bs)
	bs.animation_player.play("die")
	bs.animation_player.seek(0.13)
	bs.sprite_2d.flip_h = flip_bs
	var tg: TowerGuy = TOWER_GUY.instantiate()
	tg._state = tg.State.SPAWN
	tg.leftmost_x = 10
	tg.rightmost_x = 150
	if Refs.level_manager.player.body.global_position.x <= 80:
		tg.position.x = tg.leftmost_x
	else:
		tg.position.x = tg.rightmost_x
	tg.top_height = 16
	tg.bottom_height = 92
	tg.position.y = tg.top_height
	tg.no_rage = true
	add_sibling(tg)
	tg.play_hurt_anim()
	tg.as2d2.play("dead")
	tg.set_flip_h(tg.is_right_of_centre())


func summon_second_bosses():
	MessageDisplayer.display([
		"Lich witch, Wight knight! My lieutenants!",
		"From the lowest pits of hell I summon you to walk again!",
		"Rid me of this nuisance!",
	])
	var ma: MageBoss = MAGE.instantiate()
	var tp: Array[Node2D] = []
	for child in get_parent().get_node("MageTeleportLocations").get_children():
		if child is Node2D:
			tp.push_back(child)
	ma.teleport_points = tp
	ma.position = tp.pick_random().position
	var spsp: Array[Node2D] = []
	for child in get_parent().get_node("SerpentSpawns").get_children():
		if child is Node2D:
			spsp.push_back(child)
	ma.serpent_possible_spawn_points = spsp
	ma.spawn = true
	add_sibling(ma)
	ma.animated_sprite_2d.play("dead")
	ma._face_player()
	var kn: KnightBoss = KNIGHT.instantiate()
	kn.position = Vector2(80, 48)
	kn.spawn = true
	add_sibling(kn)
	kn.set_frame_to_dead()


func determine_sprite() -> void:
	if appear_progress != 1:
		if appear_progress == 0:
			sprite_2d.frame_coords = Vector2i(2, 3)
		elif appear:
			if appear_progress < 0.5:
				sprite_2d.frame_coords = Vector2i(0, 0)
			else:
				sprite_2d.frame_coords = Vector2i(1, 0)
		else:
			if appear_progress < 0.5:
				sprite_2d.frame_coords = Vector2i(1, 3)
			else:
				sprite_2d.frame_coords = Vector2i(0, 3)
	else:
		sprite_2d.frame_coords = Vector2i(face, 2 if mouth_open else 1)
	
	if circle:
		sprite_2d.frame_coords.y += 9
	if colour == Colour.RED:
		sprite_2d.frame_coords.y += 4


func _on_hitbox_hit(_a: Area2D):
	var rand_num := randf()
	if rand_num <= 0.33:
		v.x = randf() * 300 * [1,-1].pick_random()
		v.y = randf() * 300 * [1,-1].pick_random()
	elif rand_num <= 0.66:
		v.x = randf() * 300 * [1,-1].pick_random()
	else:
		v.y = randf() * 300 * [1,-1].pick_random()
	enem.harmless = true
	_hurt_timer = 1.0
	_hurt = true


func _ready() -> void:
	if not Refs.level_manager: return
	
	r = global_position - equilibrium
	max_health = enem.hitpoints
	enem.hitbox_hit.connect(_on_hitbox_hit)
	target_circle = circle
	target_colour = colour
	
	if hostile:
		enem.harmless = true
		enem.unhittable = true
	else:
		enem.harmless = false
		enem.unhittable = false
	
	state = Init.new()
	
	if disable_flag != "":
		if Global.session.saved_data.object_flags.has(disable_flag) and Global.session.saved_data.object_flags[disable_flag]:
			queue_free()
	
	if enable_flag != "":
		if not Global.session.saved_data.object_flags.has(disable_flag) or not Global.session.saved_data.object_flags[disable_flag]:
			queue_free()
	
	if move_flag != "":
		if Global.session.saved_data.object_flags.has(move_flag) and Global.session.saved_data.object_flags[move_flag]:
			position += move_flag_relative_target


func _physics_process(delta: float) -> void:
	determine_sprite()
	if target_colour != colour or target_circle != circle:
		var prev_appear := appear
		appear = false
		determine_sprite()
		appear = prev_appear
		appear_progress -= delta * 5
		if appear_progress <= 0:
			colour = target_colour
			circle = target_circle
	elif appear:
		appear_progress += delta * 5
	else:
		appear_progress -= delta * 5
	if oscillation:
		oscillation.update(delta)
		anchor.position = oscillation.position
		anchor.rotation = oscillation.rotation
	
	match movement_type:
		MovementType.OSCILLATE:
			a = - (k / m) * r
			v += a * delta
			r += v * delta
			
			var desired_energy := get_energy(Vector2(72.0, 44.0))
			var energy := get_current_energy()
			if desired_energy.x > energy.x:
				v.x += delta * signf(v.x) * abs(v.x)
			if desired_energy.y > energy.y:
				v.y += delta * signf(v.y) * abs(v.y)
			if desired_energy.x < energy.x:
				v.x -= delta * signf(v.x) * abs(v.x)
			if desired_energy.y < energy.y:
				v.y -= delta * signf(v.y) * abs(v.y)
			if v.x == 0:
				v.x += 0.5 - randf() * delta
			if v.y == 0:
				v.y += 0.5 - randf() * delta
		MovementType.CONSTANT_TIME:
			global_position += (ct_target_global_position - global_position) * delta * ct_secs
			r = global_position - equilibrium
		MovementType.CONSTANT_SPEED:
			var dir := (cs_target_global_position - global_position).normalized()
			global_position += cs_speed * dir * delta
			if (cs_target_global_position - global_position).normalized().dot(dir) < 0:
				global_position = cs_target_global_position
			r = global_position - equilibrium
	
	
	global_position = equilibrium + r
	enem.global_position = sprite_2d.global_position
	
	var rage := get_rage()
	
	var prev := fmod(_t, 3)
	_t += delta
	if fmod(_t, 5) < prev:
		k.x = 0.3 + rage * 2 + randf() * 2
		k.y = 0.3 + rage * 2 + randf() * 2
	
	if rage <= 0.125:
		face = Face.SMILE
	elif rage <= 0.25:
		face = Face.FROWN
	elif rage <= 0.375:
		face = Face.POKER
	elif rage <= 0.5:
		face = Face.SURPRISED
	elif rage <= 0.625:
		face = Face.SCARED
	elif rage <= 0.75:
		face = Face.DISAPPOINTED
	elif rage <= 0.875:
		face = Face.SAD
	else:
		face = Face.CRYING
	
	if _hurt:
		face = Face.SURPRISED
		mouth_open = true
		modulate = Color.WHITE * 20
	else:
		modulate = Color.WHITE
		
		if move_mouth and not _hurt:
			if fmod(_mouth_timer, 1) < 0.5:
				mouth_open = false
			else:
				mouth_open = true
			_mouth_timer += delta * _mouth_speed
	
	if state:
		state.update(delta)
	
	if _hurt_timer <= 0:
		_hurt_timer = INF
		_hurt = false
	_hurt_timer -= delta
	
	if not uncontrolled_rot_osc:
		if oscillate_rotation:
			if oscillation.frequency.z > 0.1:
				oscillation.frequency.z -= delta * 0.1
				if oscillation.frequency.z < 0.1:
					oscillation.frequency.z = 0.1
			if oscillation.frequency.z < 0.1:
				oscillation.frequency.z += delta * 0.1
				if oscillation.frequency.z > 0.1:
					oscillation.frequency.z = 0.1
			if oscillation.amplitude.z > 1.571:
				oscillation.amplitude.z -= delta
				if oscillation.amplitude.z < 1.571:
					oscillation.amplitude.z = 1.571
			if oscillation.amplitude.z < 1.571:
				oscillation.amplitude.z += delta
				if oscillation.amplitude.z > 1.571:
					oscillation.amplitude.z = 1.571
		else:
			if oscillation.frequency.z > 0:
				oscillation.frequency.z -= delta * 0.1
				if oscillation.frequency.z < 0:
					oscillation.frequency.z = 0
			if oscillation.frequency.z < 0:
				oscillation.frequency.z += delta * 0.1
				if oscillation.frequency.z > 0:
					oscillation.frequency.z = 0
			if oscillation.amplitude.z > 0:
				oscillation.amplitude.z -= delta
				if oscillation.amplitude.z < 0:
					oscillation.amplitude.z = 0
			if oscillation.amplitude.z < 0:
				oscillation.amplitude.z += delta
				if oscillation.amplitude.z > 0:
					oscillation.amplitude.z = 0
	
	if _hurt_timer == INF:
		if hostile:
			target_colour = Colour.RED
			enem.harmless = false
			enem.unhittable = false
		else:
			target_colour = Colour.YELLOW
			enem.harmless = true
			enem.unhittable = true
	
