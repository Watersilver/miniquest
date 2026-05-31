extends Node2D
class_name PauseScreen

@onready var info: Node2D = %Info

@onready var deaths_label: Label = %DeathsLabel
@onready var critical_rate_label: Label = %CriticalRateLabel
@onready var enhancement: Label = %Enhancement
@onready var damage_roll: Label = %DamageRoll
@onready var chests: Label = %Chests
@onready var health: Label = %Health
@onready var max_health: Label = %MaxHealth
@onready var money: Label = %Money
@onready var keys: Label = %Keys
@onready var weapon: Control = %Weapon
@onready var sword_spr: Sprite2D = %SwordSpr
@onready var halberd_spr: Sprite2D = %HalberdSpr
@onready var bow_spr: Sprite2D = %BowSpr
@onready var staff_spr: Sprite2D = %StaffSpr
@onready var green_switch: Control = %GreenSwitch
@onready var advantage: Control = %Advantage
@onready var power: Control = %Power

@onready var jump_label: Label = %JumpLabel
@onready var ice_label: Label = %IceLabel
@onready var dash_label: Label = %DashLabel
@onready var c_fall_label: Label = %CFallLabel
@onready var swim_label: Label = %SwimLabel
@onready var fairy_label: Label = %FairyLabel
@onready var griffon_label: Label = %GriffonLabel
@onready var d_jump_label: Label = %DJumpLabel

@onready var sad: Sprite2D = %Sad
@onready var neutral: Sprite2D = %Neutral
@onready var happy: Sprite2D = %Happy
@onready var very_happy: Sprite2D = %VeryHappy

@onready var press_right: AnimatedSprite2D = %PressRight
@onready var press_left: AnimatedSprite2D = %PressLeft

@onready var menu: VBoxContainer = %Menu

@onready var die_label: Label = %DieLabel
@onready var volume_label: Label = %VolumeLabel
@onready var music_label: Label = %MusicLabel
@onready var sound_label: Label = %SoundLabel
@onready var quit_label: Label = %QuitLabel
@onready var vol_spr: AnimatedSprite2D = %VolSpr
@onready var music_spr: AnimatedSprite2D = %MusicSpr
@onready var sound_spr: AnimatedSprite2D = %SoundSpr
@onready var cursor: AnimatedSprite2D = %Cursor


@export var slide_curve: Curve
## In seconds
@export var slide_duration := 0.5


signal request_unpause()


var _start_pos_x := 0.0
var _is_on_upgrades_screen := true
var _move_progress := -1.0
var menu_index := 0:
	set(mi):
		menu_index = ((mi % 5) + 5) % 5
var block_unpause := false
var vol := 3:
	set(v):
		vol = ((v % 4) + 4) % 4
var mute_bgm := false
var mute_sfx := false


func _dmg_roll_to_str() -> String:
	match Global.session.upgrades.damage:
		Global.Damage.ROLL_1D2: return "1d2"
		Global.Damage.ROLL_1D4: return "1d4"
		Global.Damage.ROLL_1D6: return "1d6"
		Global.Damage.ROLL_1D8: return "1d8"
		Global.Damage.ROLL_1D10: return "1d10"
		Global.Damage.ROLL_2D6: return "2d6"
		Global.Damage.ROLL_4D4: return "4d4"
	return "1"


func _snap_to_upgrades_screen() -> void:
	info.position.x = _start_pos_x
	press_right.visible = false
	press_left.visible = true
	_is_on_upgrades_screen = true


func _snap_to_progress_screen() -> void:
	info.position.x = 0
	press_right.visible = true
	press_left.visible = false
	_is_on_upgrades_screen = false


func _snap_to_screen_after_slide() -> void:
	if _move_progress != -1:
		_move_progress = -1
		if _is_on_upgrades_screen:
			_snap_to_progress_screen()
		else:
			_snap_to_upgrades_screen()


func _get_menu_child_pos(idx: int) -> Vector2:
	var child := menu.get_child(idx)
	if child:
		if child is Control:
			return child.position
		elif child is Node2D:
			return child.position
	return Vector2(0, 0)


func force_update() -> void:
	if not is_visible_in_tree(): return
	if not Refs.level_manager: return
	if not Refs.level_manager.player: return
	_snap_to_screen_after_slide()
	deaths_label.text = "Deaths: " + str(Global.session.deaths)
	critical_rate_label.text = "Critical Rate: " + str(Global.session.upgrades.crit_chance) + "%"
	enhancement.text = "Enhancement: +" + str(Global.session.upgrades.enhancement)
	damage_roll.text = "Damage roll: " + _dmg_roll_to_str()
	chests.text = "Chests: " + str(floori((Global.session.saved_data.chests / 58.0) * 100)) + "%"
	health.text = ": " + str(floori(Refs.level_manager.player.health.value)) + "/"
	max_health.text = str(floori(Refs.level_manager.player.health.maximum))
	money.text = ": " + str(Global.session.saved_data.money)
	keys.text = ": " + str(Global.session.saved_data.keys)
	sword_spr.visible = false
	halberd_spr.visible = false
	bow_spr.visible = false
	staff_spr.visible = false
	if Global.session.upgrades.weapon == Global.Weapon.NONE:
		weapon.visible = false
	else:
		weapon.visible = true
		match Global.session.upgrades.weapon:
			Global.Weapon.SWORD: sword_spr.visible = true
			Global.Weapon.HALBERD: halberd_spr.visible = true
			Global.Weapon.BOW: bow_spr.visible = true
			Global.Weapon.STAFF: staff_spr.visible = true
	green_switch.visible = Global.session.saved_data.pressed_switches.has(Global.Switch.GREEN) and Global.session.saved_data.pressed_switches[Global.Switch.GREEN]
	advantage.visible = Global.session.upgrades.advantage
	power.visible = Global.session.upgrades.element_fire
	
	jump_label.visible = Global.session.upgrades.jump
	ice_label.visible = Global.session.upgrades.element_ice
	dash_label.visible = Global.session.upgrades.run
	c_fall_label.visible = Global.session.upgrades.controlled_fall
	swim_label.visible = Global.session.upgrades.swim and Global.session.upgrades.water_walk
	fairy_label.visible = Global.session.upgrades.bat
	griffon_label.visible = Global.session.upgrades.griffon
	d_jump_label.visible = Global.session.upgrades.double_jump
	
	var happiness := int(jump_label.visible) + int(ice_label.visible) + int(dash_label.visible) + int(c_fall_label.visible) + int(swim_label.visible) + int(fairy_label.visible) + int(griffon_label.visible) + int(d_jump_label.visible)
	sad.visible = false
	neutral.visible = false
	happy.visible = false
	very_happy.visible = false
	if happiness < 1:
		sad.visible = true
	elif happiness < 4:
		neutral.visible = true
	elif happiness > 7:
		very_happy.visible = true
	else:
		happy.visible = true
	
	vol = roundi(AudioManager.get_volume() * 3)
	mute_bgm = AudioManager.get_bgm_mute()
	mute_sfx = AudioManager.get_sfx_mute()
	update_sound_graphics()


func update_sound_graphics() -> void:
	match vol:
		0:
			vol_spr.play("min")
		1:
			vol_spr.play("one_third")
		2:
			vol_spr.play("two_thirds")
		3:
			vol_spr.play("max")
	if mute_bgm:
		music_spr.play("off")
	else:
		music_spr.play("on")
	if mute_sfx:
		sound_spr.play("off")
	else:
		sound_spr.play("on")


func _ready() -> void:
	_start_pos_x = info.position.x
	visibility_changed.connect(force_update)
	force_update()
	_snap_to_upgrades_screen()


func _physics_process(delta: float) -> void:
	if not is_visible_in_tree(): return
	
	var cursor_target := Vector2(-6, 8 + _get_menu_child_pos(menu_index).y)
	cursor.position = cursor.position + (cursor_target - cursor.position) * delta * 10
	
	block_unpause = false
	if _move_progress != -1:
		if slide_duration <= 0:
			_move_progress = 1
		else:
			_move_progress += delta / slide_duration
		if _move_progress >= 1:
			_snap_to_screen_after_slide()
		else:
			if _is_on_upgrades_screen:
				info.position.x = _start_pos_x * (1.0 - slide_curve.sample(_move_progress))
			else:
				info.position.x = slide_curve.sample(_move_progress) * _start_pos_x
	else:
		if _is_on_upgrades_screen:
			if Input.is_action_just_pressed("move_left"):
				press_left.visible = false
				press_right.visible = false
				_move_progress = 0
		else:
			# uncomment and replace other check if I want to use left and right to adjust vol
			#if Input.is_action_just_pressed("move_right") and not menu_index == 1:
			if Input.is_action_just_pressed("move_right"):
				press_left.visible = false
				press_right.visible = false
				_move_progress = 0
			else:
				if Input.is_action_just_pressed("move_down"):
					menu_index += 1
				if Input.is_action_just_pressed("move_up"):
					menu_index -= 1
				if Input.is_action_just_pressed("ui_accept"):
					block_unpause = true
				if block_unpause:
					match menu_index:
						0:
							vol += 1
							AudioManager.set_volume(vol / 3.0)
							update_sound_graphics()
						1:
							mute_bgm = not mute_bgm
							AudioManager.set_bgm_mute(mute_bgm)
							update_sound_graphics()
						2:
							mute_sfx = not mute_sfx
							AudioManager.set_sfx_mute(mute_sfx)
							update_sound_graphics()
						3:
							request_unpause.emit()
							if Refs.level_manager and Refs.level_manager.player:
								Refs.level_manager.player.health.value = -1
						4:
							# TODO: go to title screen
							pass
