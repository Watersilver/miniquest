extends Node2D


@onready var area_2d: Area2D = %Area2D


@export var col := Global.Switch.GREEN
@export var trigger := ""
@export_multiline() var activation_msg: Array[String] = []


var _t := 0.0


func _ready() -> void:
	if Global.session.is_switch_active(col):
		if trigger != "":
			Global.session.saved_data.object_flags[trigger] = true
		queue_free()


func _process(delta: float) -> void:
	_t += delta
	modulate.r = 1.2 + sin(_t) * 0.5
	modulate.g = 1.2 + sin(_t) * 0.5
	modulate.b = 1.2 + sin(_t) * 0.5
	modulate.a = 0.7 + sin(_t) * 0.3
	scale.x = 1 + sin(_t) * 0.1
	scale.y = scale.x
	if area_2d.get_overlapping_areas().size() > 0:
		Global.session.activate_switch(col)
		Global.session.saved_data.object_flags[trigger] = true
		queue_free()
		if activation_msg.size() > 0:
			MessageDisplayer.display(activation_msg)
