extends Node2D


## x,y are position, z is rotation
@export var amplitude := Vector3(1,1,0)
## x,y are position, z is rotation
@export var frequency := Vector3(0.125,0.25,0)
## x,y are position, z is rotation
@export var initial_phase := Vector3(0,0,0)

var _equilibrium: Vector3
var _t := 0.0


func _ready() -> void:
	_equilibrium = Vector3(position.x, position.y, rotation)


func _process(delta: float) -> void:
	var p := TAU * frequency * _t + initial_phase
	position.x = _equilibrium.x + amplitude.x * sin(p.x)
	position.y = _equilibrium.y + amplitude.y * sin(p.y)
	rotation = _equilibrium.z + amplitude.z * sin(p.z)
	
	_t += delta
