extends Area2D
class_name PlayerAttack

@onready var arrow_spr: Sprite2D = %ArrowSpr
@onready var attack_spr: Sprite2D = %AttackSpr
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var collision_shape_2d: CollisionShape2D = %CollisionShape2D

var weapon := Global.Weapon.NONE:
	set(w):
		weapon = w
		if _duration == -INF:
			match weapon:
				Global.Weapon.NONE:
					_duration = -INF
				Global.Weapon.SWORD:
					_duration = 0.1
				Global.Weapon.HALBERD:
					_duration = 0.15
				Global.Weapon.BOW:
					_duration = INF
				Global.Weapon.STAFF:
					_duration = INF
var damage := Global.Damage.ROLL_1D2
var enhancement := 0
 ## % percentage
var crit_chance := 0

var direction := Global.Direction.RIGHT
var push := true
var pos_start := Vector2(0,0)

var _duration := -INF

var split := false
var split_target := Vector2(0, 0)
var split_duration := 0.0
var shrapnel := false


func init_from_global():
	weapon = Global.session.upgrades.weapon
	crit_chance = Global.session.upgrades.crit_chance
	damage = Global.session.upgrades.damage
	enhancement = Global.session.upgrades.enhancement
	split = Global.session.upgrades.element_fire


func destroy() -> void:
	collision_mask = 0
	collision_layer = 0
	queue_free()


class AttackHit:
	func _init(_mult, _dmg) -> void:
		crit_mult = _mult
		dmg = _dmg
	
	var crit_mult := 0
	var dmg := 0


func roll_attack_hit() -> AttackHit:
	var mult := 0
	var is_crit := (randi() % 100) < crit_chance
	while is_crit and mult < 100:
		mult += 1
		crit_chance = floori(crit_chance / 2.0)
		is_crit = (randi() % 100) < crit_chance
	
	var dmg := enhancement
	for _times in mult + 1:
		dmg += Global.roll_damage(damage)
	return AttackHit.new(mult, dmg)


func _create_split(target: Vector2) -> PlayerAttack:
	var s: PlayerAttack = duplicate()
	add_sibling(s)
	s.split = false
	s.damage = Global.Damage.ROLL_1D2
	s.crit_chance = floori(crit_chance / 3.0)
	s.enhancement = 0
	s.direction = direction
	s.split_duration = 0.1
	s.split_target = target
	s.modulate = Color.SLATE_GRAY
	s.shrapnel = true
	s.push = false
	return s


func _move_node_to_split_target(n: Node2D, delta: float) -> void:
	if split_duration == 0:
		n.position = split_target
	else:
		var to_target_vec := split_target - n.position
		n.position += (split_target - n.position) * delta / split_duration
		if to_target_vec.dot(split_target - n.position) < 0:
			n.position = split_target


func _ready() -> void:
	init_from_global()
	
	body_shape_entered.connect(_on_body_shape_entered)
	area_entered.connect(_on_area_entered)
	visible_on_screen_notifier_2d.screen_exited.connect(destroy)
	
	pos_start = global_position
	
	if weapon != Global.Weapon.STAFF:
		AudioManager.play_attack_sound()
	else:
		AudioManager.play_magic_attack_sound()


func _process(_delta: float) -> void:
	arrow_spr.flip_h = direction == Global.Direction.LEFT
	attack_spr.flip_h = direction == Global.Direction.LEFT
	match weapon:
		Global.Weapon.NONE:
			arrow_spr.visible = false
			attack_spr.visible = false
		Global.Weapon.SWORD:
			arrow_spr.visible = false
			attack_spr.visible = true
			attack_spr.region_rect.position.y = 440.0
		Global.Weapon.HALBERD:
			arrow_spr.visible = false
			attack_spr.visible = true
			attack_spr.region_rect.position.y = 440.0
		Global.Weapon.BOW:
			arrow_spr.visible = true
			attack_spr.visible = false
		Global.Weapon.STAFF:
			arrow_spr.visible = false
			attack_spr.visible = true
			attack_spr.region_rect.position.x = 17.0
			attack_spr.region_rect.position.y = 471.0
			attack_spr.region_rect.size.x = 6.0
			attack_spr.region_rect.size.y = 7.0


func _physics_process(delta: float) -> void:
	match weapon:
		Global.Weapon.NONE:
			destroy()
		Global.Weapon.SWORD:
			position.x += delta * 25 * direction
			if _duration < 0:
				destroy()
		Global.Weapon.HALBERD:
			position.x += delta * 33 * direction
			if _duration < 0:
				destroy()
		Global.Weapon.BOW:
			position.x += delta * 66 * direction
		Global.Weapon.STAFF:
			position.x += delta * 100 * direction
	
	if split:
		split = false
		_create_split(Vector2(-direction * 4, -8))
		_create_split(Vector2(-direction * 8, -4))
		_create_split(Vector2(-direction * 8, 4))
		_create_split(Vector2(-direction * 4, 8))
	
	if not split_target.is_zero_approx():
		_move_node_to_split_target(arrow_spr, delta)
		_move_node_to_split_target(attack_spr, delta)
		_move_node_to_split_target(collision_shape_2d, delta)
		_move_node_to_split_target(visible_on_screen_notifier_2d, delta)
	
	_duration -= delta



func _on_body_shape_entered(body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	var l := PhysicsServer2D.body_get_collision_layer(body_rid)
	if (l & 1) == 1:
		if weapon != Global.Weapon.STAFF:
			if body is TileMapLayer and body is MainTileset:
				destroy()
			elif body.get_parent() is SwitchBlock:
				destroy()
	if (l & 1024) == 1024:
		destroy()
	if (l & 8192) == 8192:
		set_deferred("push", false)


func _on_area_entered(area: Area2D) -> void:
	if (area.collision_layer & 1024) == 1024:
		destroy()
	if (area.collision_layer & 65536) == 65536:
		await get_tree().process_frame
		destroy()
