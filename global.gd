extends Node

enum Ternary {
	FALSE,
	TRUE,
	NULL
}

enum Direction {
	LEFT = -1,
	RIGHT = 1
}

enum Weapon {
	NONE,
	SWORD,
	HALBERD,
	BOW,
	STAFF
}

enum Damage {
	ROLL_1D2,
	ROLL_1D4,
	ROLL_1D6,
	ROLL_1D8,
	ROLL_1D10,
	ROLL_2D6,
	ROLL_4D4
}


func roll_damage(damage_dice: Damage):
	match damage_dice:
		Damage.ROLL_1D2:
			return (randi() % 2) + 1
		Damage.ROLL_1D4:
			return (randi() % 4) + 1
		Damage.ROLL_1D6:
			return (randi() % 6) + 1
		Damage.ROLL_1D8:
			return (randi() % 8) + 1
		Damage.ROLL_1D10:
			return (randi() % 10) + 1
		Damage.ROLL_2D6:
			return (randi() % 6) + (randi() % 6) + 2
		Damage.ROLL_4D4:
			return (randi() % 4) + (randi() % 4) + (randi() % 4) + (randi() % 4) + 4


enum Switch {
	GREEN,
	BLUE,
	PURPLE,
	RED,
	YELLOW,
	GREY,
	ORANGE
}

class _SavedData extends Resource:
	@export var money := 0
	@export var object_flags: Dictionary[String, bool] = {}
	@export var keys := 0
	@export var pressed_switches: Dictionary[Switch, bool] = {}
	@export var slime_boss := false:
		set(b):
			slime_boss = b
			object_flags['slime_dead'] = b
			_check_if_all_bosses_dead()
	@export var tower_boss := false:
		set(b):
			tower_boss = b
			object_flags['tower_dead'] = b
			_check_if_all_bosses_dead()
	@export var knight_boss := false:
		set(b):
			knight_boss = b
			object_flags['knight_dead'] = b
			_check_if_all_bosses_dead()
	@export var mage_boss := false:
		set(b):
			mage_boss = b
			object_flags['mage_dead'] = b
			_check_if_all_bosses_dead()
	
	func _check_if_all_bosses_dead():
		if slime_boss and tower_boss and knight_boss and mage_boss:
			object_flags['bosses_dead'] = true

class _Upgrades extends Resource:
	@export var controlled_fall := false
	@export var jump := false
	@export var double_jump := false
	@export var backdash := true
	@export var run := false
	@export var bat := false
	@export var griffon := false
	@export var swim := false
	@export var water_walk := false
	@export var advantage := false
	
	#@export var extra_lung_capacity := 0.0
	@export var max_health := 1.0
	
	@export var element_fire := false
	@export var element_ice := false
	
	@export var weapon := Weapon.NONE:
		set(w):
			weapon = clampi(0, w, 4) as Weapon
	
	## upgrades weapon to given value, but doesn't degrade
	func set_weapon_upgrade(w: Weapon) -> void:
		if w > weapon: weapon = w
	
	## upgrades weapon to given value, but doesn't degrade
	func raise_dmg_die(amount: int) -> void:
		damage = (damage + amount) as Damage
	
	@export var damage := Damage.ROLL_1D2:
		set(d):
			damage = clampi(0, d, 6) as Damage
	@export var enhancement := 0
	
	 ## % percentage
	@export var crit_chance := 0

class _Checkpoint:
	var room := Vector2i(0,0)
	var pos := Vector2(0,0)
	var upgrades: _Upgrades
	var saved_data: _SavedData

class Session:
	signal switch_activated(col: Switch)
	
	var upgrades := _Upgrades.new()
	var checkpoint := _Checkpoint.new()
	var saved_data := _SavedData.new()
	
	var is_underwater := false
	
	func get_lung_capacity_max():
		return upgrades.extra_lung_capacity and (3 if upgrades.water_walk else 1 if upgrades.swim else 0)
	
	func is_switch_active(col: Switch) -> bool:
		if not saved_data.pressed_switches.has(col): return false
		return saved_data.pressed_switches[col]
	
	func activate_switch(col: Switch) -> void:
		if saved_data.pressed_switches.has(col):
			var prev := saved_data.pressed_switches[col]
			saved_data.pressed_switches[col] = true
			if prev != true: switch_activated.emit(col)
		else:
			saved_data.pressed_switches[col] = true
			switch_activated.emit(col)
	
	func load_checkpoint():
		Global.session.upgrades = Global.session.checkpoint.upgrades.duplicate(true)
		Global.session.saved_data = Global.session.checkpoint.saved_data.duplicate(true)

var session := Session.new()

func i_modulo(a: int, n: int) -> int:
	return (a % n + n) % n

func f_modulo(a: float, n: float) -> float:
	return fmod(fmod(a, n) + n, n)
