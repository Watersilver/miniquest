extends Node

@onready var controlled_fall: CheckBox = %ControlledFall
@onready var jump: CheckBox = %Jump
@onready var double_jump: CheckBox = %DoubleJump
@onready var backdash: CheckBox = %Backdash
@onready var run: CheckBox = %Run
@onready var bat: CheckBox = %Bat
@onready var griffon: CheckBox = %Griffon
@onready var swim: CheckBox = %Swim
@onready var water_walk: CheckBox = %WaterWalk

func _ready() -> void:
	controlled_fall.button_pressed = Global.session.upgrades.controlled_fall
	jump.button_pressed = Global.session.upgrades.jump
	double_jump.button_pressed = Global.session.upgrades.double_jump
	backdash.button_pressed = Global.session.upgrades.backdash
	run.button_pressed = Global.session.upgrades.run
	bat.button_pressed = Global.session.upgrades.bat
	griffon.button_pressed = Global.session.upgrades.griffon
	swim.button_pressed = Global.session.upgrades.swim
	water_walk.button_pressed = Global.session.upgrades.water_walk


func _on_controlled_fall_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.controlled_fall = toggled_on


func _on_double_jump_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.double_jump = toggled_on


func _on_backdash_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.backdash = toggled_on


func _on_run_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.run = toggled_on


func _on_jump_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.jump = toggled_on


func _on_bat_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.bat = toggled_on


func _on_griffon_jump_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.griffon = toggled_on


func _on_swim_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.swim = toggled_on


func _on_water_walk_toggled(toggled_on: bool) -> void:
	Global.session.upgrades.water_walk = toggled_on
