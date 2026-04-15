extends Sprite2D

const BAT := preload("uid://bei8vy7qg6bbd")

@export var init_spawns: Array[EnemyBat] = []

## When true, direction is always towards player but spawns from the side that is furthest to player
@export var aim_towards_player := true

@export var frequency := 1.0

@export var init_timer := 0.0

@export var speed := 13.0

## How many bats spawned by this spawner can be on screen simultaneously
@export var max_on_screen := 1

## Negative numbers are infinite
@export var max_spawns_possible := -1

## Bat flight oscillation
@export var oscillation: OscillationResource

@export var top: Marker2D
@export var bottom: Marker2D

@export_multiline() var spawn_direction := "Spawn direction is controlled via the flip_h property. Just a heads up in case I forget."

var _t := 0.0
var spawns: Array[EnemyBat] = []
var spawned_amount := 0

func get_direction() -> Global.Direction:
	return Global.Direction.LEFT if flip_h else Global.Direction.RIGHT


func _ready() -> void:
	_t = init_timer
	self_modulate.a = 0
	%Batimg.self_modulate.a = 0
	spawned_amount = spawns.size()
	for spawn in init_spawns:
		spawns.push_back(spawn)
		spawn.tree_exiting.connect(func(): spawns.erase(spawn))


func _process(delta: float) -> void:
	var d := get_direction()
	
	if Refs.level_manager and Refs.level_manager.camera:
		var c := Refs.level_manager.camera
		var hw := (get_viewport_rect().size * 0.5).x / c.zoom.x
		
		var x := c.get_screen_center_position().x
		
		var left := x - hw
		var right := x + hw
		
		if aim_towards_player and Refs.level_manager.player:
			var p := Refs.level_manager.player
			var l := absf(p.body.global_position.x - left)
			var r := absf(p.body.global_position.x - right)
			if l > r:
				d = Global.Direction.RIGHT
			elif r > l:
				d = Global.Direction.LEFT
		
		if d == Global.Direction.RIGHT:
			global_position.x = left
		else:
			global_position.x = right
	
	if max_spawns_possible < 0 or spawned_amount < max_spawns_possible:
		if spawns.size() < max_on_screen:
			if _t > frequency:
				_t = fmod(_t, frequency)
				var bat: EnemyBat = BAT.instantiate()
				bat.tree_exiting.connect(func(): spawns.erase(bat))
				bat.oscillation = oscillation.duplicate() if oscillation else EnemyBat.get_new_default_oscillation()
				bat.oscillation.initial_phase.y = randf() * TAU
				bat.direction = d
				bat.speed = speed
				spawns.push_back(bat)
				get_parent().add_child(bat)
				bat.global_position.x = global_position.x
				bat.global_position.y = randf_range(top.global_position.y if top else global_position.y, bottom.global_position.y if bottom else global_position.y)
				bat.start_y = bat.position.y
				spawned_amount += 1
			_t += delta
