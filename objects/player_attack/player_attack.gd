extends Area2D
class_name PlayerAttack

@onready var arrow_spr: Sprite2D = %ArrowSpr
@onready var attack_spr: Sprite2D = %AttackSpr
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D

var weapon := Global.Weapon.NONE:
	set(w):
		weapon = w
		if _life == -INF:
			match weapon:
				Global.Weapon.NONE:
					_life = -INF
				Global.Weapon.SWORD:
					_life = 0.1
				Global.Weapon.HALBERD:
					_life = 0.15
				Global.Weapon.BOW:
					_life = INF
				Global.Weapon.STAFF:
					_life = INF

var direction := Global.Direction.RIGHT
var pierce := 0
var push := true
var pos_start := Vector2(0,0)

var _life := -INF


func destroy() -> void:
	collision_mask = 0
	collision_layer = 0
	queue_free()


func _ready() -> void:
	body_shape_entered.connect(_on_body_shape_entered)
	area_entered.connect(_on_area_entered)
	visible_on_screen_notifier_2d.screen_exited.connect(destroy)
	
	pos_start = global_position


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
			attack_spr.region_rect.position.y = 472.0


func _physics_process(delta: float) -> void:
	match weapon:
		Global.Weapon.NONE:
			destroy()
		Global.Weapon.SWORD:
			position.x += delta * 25 * direction
			if _life < 0:
				destroy()
		Global.Weapon.HALBERD:
			position.x += delta * 33 * direction
			if _life < 0:
				destroy()
		Global.Weapon.BOW:
			position.x += delta * 66 * direction
		Global.Weapon.STAFF:
			position.x += delta * 100 * direction
	
	_life -= delta


func _on_piercable_hit():
	pierce -= 1
	if pierce < 0:
		destroy()


func _on_body_shape_entered(body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	var l := PhysicsServer2D.body_get_collision_layer(body_rid)
	if (l & 1) == 1:
		if weapon != Global.Weapon.STAFF:
			destroy()
	if (l & 1024) == 1024:
		_on_piercable_hit()
	if (l & 8192) == 8192:
		set_deferred("push", false)


func _on_area_entered(area: Area2D) -> void:
	if (area.collision_layer & 1024) == 1024:
		_on_piercable_hit()
