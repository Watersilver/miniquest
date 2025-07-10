extends Control

@onready var canvas_layer: CanvasLayer = %CanvasLayer

@onready var yes_focus: NinePatchRect = %YesFocus
@onready var yes_unfocus: NinePatchRect = %YesUnfocus
@onready var no_focus: NinePatchRect = %NoFocus
@onready var no_unfocus: NinePatchRect = %NoUnfocus

@onready var confirm: Label = %Confirm
@onready var decline: Label = %Decline

func empty_func(): pass

var on_yes: Callable = empty_func
var on_no: Callable = empty_func

var _active := false

var _cursor := 1:
	set(c):
		_cursor = posmod(c,2)

func prompt(accept: String, refuse: String, accept_callback := empty_func, refuse_callback := empty_func):
	_active = true
	confirm.text = accept
	decline.text = refuse
	on_yes = accept_callback
	on_no = refuse_callback
	_cursor = 1

func is_active():
	return _active


func _ready() -> void:
	no_focus.visible = true
	yes_unfocus.visible = true


func _physics_process(_delta: float) -> void:
	if not _active:
		visible = false
		canvas_layer.visible = false
		return
	else:
		visible = true
		canvas_layer.visible = true
	
	if _cursor == 0:
		no_focus.visible = false
		no_unfocus.visible = true
		yes_focus.visible = true
		yes_unfocus.visible = false
	else:
		no_focus.visible = true
		no_unfocus.visible = false
		yes_focus.visible = false
		yes_unfocus.visible = true
	
	if Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		_cursor -= 1
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		_cursor = 1
	elif Input.is_action_just_pressed("ui_accept"):
		if _cursor == 0:
			on_yes.call()
		else:
			on_no.call()
		_active = false
