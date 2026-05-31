extends Area2D
class_name Hazard

@export var dmg_dice := Global.Damage.ROLL_1D2
@export var enhancement := 0
@export var advantage := false


func roll_damage() -> int:
	return Global.roll_damage(dmg_dice) + enhancement
