extends Node2D


@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var label: Label = %Label

@onready var button_up_spr: Sprite2D = %ButtonUpSpr
@onready var button_down_spr: Sprite2D = %ButtonDownSpr
@onready var next_graphic: NinePatchRect = %NextGraphic


func has_text():
	return _text.size() > 0

func display(txt: Array[String], on_text_end := _empty, escapable := true):
	_text = txt
	_on_text_end = on_text_end
	_escapable = escapable


func _empty(): pass

var _on_text_end: Callable = _empty
var _escapable := false

var _text: Array[String] = []:
	set(t):
		_text = t
		_i = -1
		_autoload_next = false
var _i := -1

var _blink_timer := 0.0


func _next_exists() -> bool:
	return max(-1, _i + 1) < _text.size()


func _load_next():
	scroll_container.get_v_scroll_bar().value = 0
	if _next_exists():
		_i += 1
		label.text = _text[_i]
	else:
		label.text = ""
		_text = []
	scroll_container.get_v_scroll_bar().value = 0

var _autoload_next := false


func _process(delta: float) -> void:
	var block_frame := false
	if _text.size() > 0:
		visible = true
		if _i < 0:
			_load_next()
			block_frame = true
	else:
		visible = false
		_autoload_next = false
		return
	
	if BinaryChoiceManager.is_active() or block_frame:
		return
	
	if _autoload_next == true:
		_load_next()
	
	
	if _blink_timer > 0.25:
		next_graphic.region_rect.position.x = 24
	else:
		next_graphic.region_rect.position.x = 0
	
	if _blink_timer > 0.4:
		button_up_spr.visible = false
		button_down_spr.visible = false
	else:
		button_up_spr.visible = true
		button_down_spr.visible = true
	
	_blink_timer += delta
	if _blink_timer > 0.5:
		_blink_timer -= 0.5
	
	var vsb := scroll_container.get_v_scroll_bar()
	
	if Input.is_action_pressed("move_down"):
		button_up_spr.visible = true
		button_down_spr.visible = true
		button_down_spr.region_rect.position.x = 16
		vsb.value += delta * 50
	else:
		button_down_spr.region_rect.position.x = 0
	if Input.is_action_pressed("move_up"):
		button_up_spr.visible = true
		button_down_spr.visible = true
		button_up_spr.region_rect.position.x = 16
		vsb.value -= delta * 50
	else:
		button_up_spr.region_rect.position.x = 0
	
	var is_at_top := scroll_container.scroll_vertical == 0
	var is_at_bottom := scroll_container.scroll_vertical + scroll_container.size.y >= vsb.max_value
	
	
	next_graphic.visible = false
	if is_at_top:
		button_up_spr.visible = false
	if is_at_bottom:
		button_down_spr.visible = false
		next_graphic.visible = true
		
		if _next_exists():
			next_graphic.modulate.r = 1
			next_graphic.modulate.g = 1
			next_graphic.modulate.b = 1
		else:
			next_graphic.modulate.r = 93.0/255.0
			next_graphic.modulate.g = 227.0/255.0
			next_graphic.modulate.b = 74.0/255.0
		
		if Input.is_action_just_pressed("ui_accept"):
			if _next_exists():
				_load_next()
			else:
				if _on_text_end == _empty:
					_load_next()
				else:
					_on_text_end.call()
					_on_text_end = _empty
					_autoload_next = true
	
	if not Input.is_action_just_pressed("ui_accept") and Input.is_action_just_pressed("ui_cancel") and _escapable:
		while _next_exists():
			_load_next()
		_load_next()
