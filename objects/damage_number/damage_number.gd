extends Node2D
class_name DamageNumber

@onready var label: Label = %Label
@onready var _s: Node2D = %Shake

@export var opacity_curve: Curve

const DURATION := 0.5

var speed := 55.0
var remaining_time := DURATION

var shake_factor := 0.0


const _DAMAGE_NUMBER := preload("uid://dmig0d05okjv7")


static func spawn(dmg: int, target: Node2D) -> DamageNumber:
	var dn: DamageNumber = _DAMAGE_NUMBER.instantiate()
	dn.set_value(dmg)
	dn.set_type(0)
	target.get_viewport().add_child(dn)
	dn.global_position = target.global_position
	return dn

static func spawn_from_attack(hit: PlayerAttack.AttackHit, target: Node2D) -> DamageNumber:
	var dn := spawn(hit.dmg, target)
	dn.shake_factor = hit.crit_mult
	return dn


func _process(delta: float) -> void:
	position.y -= delta * speed
	speed = speed * 0.9
	modulate.a = opacity_curve.sample(remaining_time / DURATION)
	remaining_time -= delta
	if shake_factor > 0:
		_s.position = Vector2(1 * shake_factor, 0).rotated(randf() * TAU)
	if remaining_time <= 0:
		queue_free()


func set_value(val: int) -> void:
	if not is_node_ready():
		await ready
	label.text = "-" + str(val)
	label.set_anchors_preset(Control.LayoutPreset.PRESET_CENTER_BOTTOM)

## type cases:
## 0 = enemy
## 1 = player
func set_type(type: int):
	match type:
		1:
			modulate = Color(1,0,0,modulate.a)
		_:
			modulate = Color(1,1,1,modulate.a)
