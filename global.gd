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
	
	#@export var extra_lung_capacity := 0.0
	@export var max_health := 1.0
	
	@export var element_fire := false
	@export var element_ice := false
	
	@export var weapon := Weapon.NONE:
		set(w):
			weapon = clampi(0, w, 4) as Weapon

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
	
	var _pressed_switches: Dictionary[Switch, bool] = {}
	
	func get_lung_capacity_max():
		return upgrades.extra_lung_capacity and (3 if upgrades.water_walk else 1 if upgrades.swim else 0)
	
	func is_switch_active(col: Switch) -> bool:
		if not _pressed_switches.has(col): return false
		return _pressed_switches[col]
	
	func activate_switch(col: Switch) -> void:
		var prev := _pressed_switches[col]
		_pressed_switches[col] = true
		if prev != true: switch_activated.emit(col)
	
	func load_checkpoint():
		Global.session.upgrades = Global.session.checkpoint.upgrades
		Global.session.saved_data = Global.session.checkpoint.saved_data

var session := Session.new()
