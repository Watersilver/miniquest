@tool
extends Area2D

@onready var label_offset: Node2D = %LabelOffset
@onready var label: Label = %Label

@export var price := 5
@export_multiline var description: Array[String] = []
@export var offset := -12.0

var _cooldown := 0.0

func _process(delta: float) -> void:
	if has_overlapping_bodies() and Input.is_action_just_pressed("ui_accept") and _cooldown <= 0.0:
		_cooldown = 0.2
		
		# TODO: actually make it possible to buy item
		MessageDisplayer.text = description
	
	_cooldown -= delta
	
	label.text = str(price)
	label_offset.position.y = offset
