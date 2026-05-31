@tool
extends Node2D
class_name Spawner

static var rng := RandomNumberGenerator.new()


@onready var spawn_area: Area2D = %SpawnArea
@onready var spawn_area_shape: CollisionShape2D = %SpawnAreaShape

## What will be spawned
@export var spawn_scene: PackedScene
## How many spawns spawned by this spawner can be on screen simultaneously
@export var max_on_screen := 1
## Negative numbers are infinite
@export var max_spawns_possible := -1
## In seconds
@export var init_timer := 0.0
## In seconds
@export var period := 1.0
## Spawn period is between `period` +- this value
@export var period_variance := 0.0
@export var spawn_area_width := 16
@export var spawn_area_height := 16
## If this spawner has child spawners, the spawn chance is proportional
## to the spawner area (min width and height = 1). If this is set to true
## each spawner has equal chance
@export var equal_chance_per_spawner := false
@export var on_spawns_end_flag: String


@export var ice_spike_params: IceSpikeParams


var _spawns: Array[Node] = []
var _sub_spawners: Array[Spawner] = []
var _is_parent_spawner := false
var _total_spawns := 0
var _t := 0.0
var _period := 0.0


func _on_child_entered_tree(node: Node):
	if node is Spawner:
		_add_subspawner(node)


func _on_child_exiting_tree(node: Node):
	if node is Spawner:
		_sub_spawners.erase(node)


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	for child in get_children():
		if child is Spawner:
			_add_subspawner(child)
	
	if Engine.is_editor_hint():
		return
	
	spawn_area.queue_free()
	_calc_next_period()
	_t = init_timer


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		var s: RectangleShape2D = spawn_area_shape.shape
		if _sub_spawners.size() > 0:
			s.size.x = 0
			s.size.y = 0
		else:
			s.size.x = spawn_area_width
			s.size.y = spawn_area_height
		return
	
	if not _is_parent_spawner:
		if max_spawns_possible > -1 and _total_spawns > max_spawns_possible:
			if on_spawns_end_flag != "":
				Global.session.saved_data.object_flags[on_spawns_end_flag] = true
			queue_free()
			return
		if _spawns.size() >= max_on_screen:
			return
		
		if _t >= _period:
			_calc_next_period()
			_t -= _period
			spawn()
		_t += delta


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_is_parent_spawner = get_parent() is Spawner


func _is_non_0(number: float) -> bool:
	return number != 0


class SpawnParams:
	var location: Vector2
	var spawner: Spawner


func _get_spawn_params() -> SpawnParams:
	if _sub_spawners.size() > 0:
		if equal_chance_per_spawner:
			var s: Spawner = _sub_spawners.pick_random()
			return s._get_spawn_params()
		else:
			var weights: Array[float] = []
			for s in _sub_spawners:
				weights.push_back(s.get_spawn_area())
			if not weights.any(_is_non_0):
				weights.clear()
				for s in _sub_spawners:
					weights.push_back(s.get_spawn_area_largest_dimension())
			var s := _sub_spawners[rng.rand_weighted(weights)]
			return s._get_spawn_params()
	var sp := SpawnParams.new()
	sp.location = Vector2(
		maxf(1, spawn_area_width * randf() - spawn_area_width * 0.5),
		maxf(1, spawn_area_height * randf() - spawn_area_height * 0.5)
	)
	sp.spawner = self
	return sp


func _calc_next_period():
	_period = period + period_variance * randf() - period_variance * 0.5


func _add_subspawner(sub: Spawner):
	if not _sub_spawners.has(sub):
		_sub_spawners.push_back(sub)


func get_spawn_area() -> float:
	if _sub_spawners.size() > 0:
		var a := 0.0
		for ss in _sub_spawners:
			a += ss.get_spawn_area()
		return a
	return spawn_area_width * spawn_area_height


## useful for size comparisons when spawn areas are one dimentional
func get_spawn_area_largest_dimension() -> float:
	if _sub_spawners.size() > 0:
		var a := 0.0
		for ss in _sub_spawners:
			a += ss.get_spawn_area_largest_dimension()
		return a
	return maxf(spawn_area_width, spawn_area_height)


func spawn() -> void:
	var sp := _get_spawn_params()
	var sp_scene: PackedScene = null
	var s := sp.spawner
	while s:
		sp_scene = s.spawn_scene
		if sp_scene: break
		var p := s.get_parent()
		if not p is Spawner: return
		s = p
	if not sp_scene: return
	if sp_scene.can_instantiate():
		var instance := sp_scene.instantiate()
		instance.tree_entered.connect(func(): _spawns.push_back(instance))
		instance.tree_exiting.connect(func(): _spawns.erase(instance))
		if instance is Node2D:
			instance.position = position + sp.location + sp.spawner.global_position - global_position
		if instance is IceSpike:
			s = sp.spawner
			var params: IceSpikeParams = null
			while s:
				params = s.ice_spike_params
				if params: break
				var p := s.get_parent()
				if not p is Spawner: break
				s = p
			if params:
				instance.type = params.type
				instance.no_prowling = params.no_prowling
		add_sibling(instance)
		_total_spawns += 1
