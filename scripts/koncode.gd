extends Node2D

const CHEST = preload("uid://bg6fkjj0kc0tx")


var keys: Array[String] = []


var disabled_children: Array[Node]


func _ready() -> void:
	if not Refs.level_manager:
		return
	
	if not (Global.session.saved_data.object_flags.has('konami') and Global.session.saved_data.object_flags['konami']):
		disabled_children = get_children().duplicate()
		for c in get_children():
			remove_child(c)


func _process(_delta: float) -> void:
	if Global.session.saved_data.object_flags.has('konami') and Global.session.saved_data.object_flags['konami']:
		return
	
	if Input.is_action_just_pressed("move_up"):
		keys.push_back('u')
	elif Input.is_action_just_pressed('move_down'):
		keys.push_back('d')
	elif Input.is_action_just_pressed('move_left'):
		keys.push_back('l')
	elif Input.is_action_just_pressed('move_right'):
		keys.push_back('r')
	elif Input.is_action_just_pressed('attack'):
		keys.push_back('b')
	elif Input.is_action_just_pressed('jump'):
		keys.push_back('a')
	elif Input.is_action_just_pressed("dash"):
		keys.push_back('n')
	elif Input.is_action_just_pressed('dodge'):
		keys.push_back('n')
	
	if keys.size() > 10:
		keys.pop_front()
	
	if ''.join(keys) == "uuddlrlrba":
		Global.session.saved_data.object_flags['konami'] = true
		for c in disabled_children:
			add_child(c)
		disabled_children.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for c in disabled_children:
			c.queue_free()
		disabled_children.clear()
