@tool
extends Resource
class_name OscillationResource


static func cosV3(v: Vector3) -> Vector3:
	return Vector3(
		cos(v.x),
		cos(v.y),
		cos(v.z)
	)


## x,y are position, z is rotation
@export var amplitude := Vector3(1,1,0)
## x,y are position, z is rotation
@export var frequency := Vector3(0.125,0.25,0)
## x,y are position, z is rotation
@export var initial_phase := Vector3(0,0,0)

var _t := 0.0

var position := Vector2(0, 0)
var rotation := 0.0
## The calculated velocity of the 3 oscillations (z is, again, rotation)
var velocity := Vector3(0, 0, 0)
var _has_updated := false


func has_updated() -> bool:
	return _has_updated

func update(delta: float) -> void:
	_has_updated = true
	# angular frequence = TAU * frequency
	var p := TAU * frequency * _t + initial_phase
	position.x = amplitude.x * sin(p.x)
	position.y = amplitude.y * sin(p.y)
	rotation = amplitude.z * sin(p.z)
	
	velocity = amplitude * TAU * frequency * cosV3(p)
	
	_t += delta
