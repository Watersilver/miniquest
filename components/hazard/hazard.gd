extends Area2D
class_name Hazard

@export var dmg_dice := Global.Damage.ROLL_1D2
@export var enhancement := 0


func roll_damage():
	return Global.roll_damage(dmg_dice) + enhancement
