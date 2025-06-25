extends Node
class_name Health

signal changed(amount: float)

func _ready() -> void:
	value = value # limit value to max

@export var maximum := 1.0
@export var value := 1.0:
	set(v):
		var prev := value
		value = min(v, maximum)
		var diff := value - prev
		if diff != 0:
			changed.emit(value - prev)
