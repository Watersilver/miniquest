extends TileMapLayer
class_name MainTileset

const BOX = preload("res://objects/box/box.tscn")
const ARROW_TRAP = preload("res://objects/arrow_trap/arrow_trap.tscn")


class _ReplacedTile extends Resource:
	enum Type {
		BOX,
		ARROW_TRAP
	}
	var type: Type
	var coords := Vector2i(0,0)
	var dir := Global.Direction.RIGHT
	var variant := 0
@export_storage var _replacements: Array[_ReplacedTile] = []

## Checks if tileset tile is valid for given values
func _t(c: Vector2i, area: Array[Rect2i] = []) -> bool:
	for r in area:
		var s := r.position
		for x in r.size.x:
			for y in r.size.y:
				if c == s + Vector2i(x,y):
					return true
	return false


func _is_one_of(value, values: Array) -> bool:
	for v in values:
		if value == v: return true
	return false


signal tick

var _tick_countdown := 0.0:
	set(t):
		_tick_countdown = t
		if _tick_countdown <= 0:
			_tick_countdown += 0.125
			tick.emit()

var _tick_counter := 1

var _water_direction := 1.0:
	set(d):
		_water_direction = d
		if abs(_water_direction) > 4:
			_water_direction = -sign(_water_direction)

func _set_next_frame(atlas_coords: Vector2i, start := 0, end := start + 3):
	if start <= end:
		atlas_coords.y += 1
		if atlas_coords.y > end: atlas_coords.y = start
	else:
		atlas_coords.y -= 1
		if atlas_coords.y < end: atlas_coords.y = start
	return atlas_coords

func _set_prev_frame(atlas_coords: Vector2i, start := 0, end := start + 3):
	atlas_coords.y -= 1
	if atlas_coords.y < start: atlas_coords.y = end
	return atlas_coords

var fire: Array[CellData] = []
func _animate_fire():
	var start: int
	var end: int
	for fire_cell in fire:
		if fire_cell.atlas_coords.x > 1:
			if fire_cell.atlas_coords.y <= 2:
				start = 0
				end = 2
			elif fire_cell.atlas_coords.y <= 4:
				start = 2
				end = 4
			elif fire_cell.atlas_coords.y <= 24:
				start = 22
				end = 24
		else:
			start = 2
			end = 4
		
		fire_cell.atlas_coords = _set_next_frame(fire_cell.atlas_coords, start, end)
		set_cell(fire_cell.coords, fire_cell.src, fire_cell.atlas_coords, TileSetAtlasSource.TRANSFORM_FLIP_H if fire_cell.flip_h else 0)

var smoke: Array[CellData] = []
func _animate_smoke():
	var start: int = 3
	var end: int = 0
	for smoke_cell in smoke:
		smoke_cell.atlas_coords = _set_next_frame(smoke_cell.atlas_coords, start, end)
		var coords = smoke_cell.coords
		if smoke_cell.atlas_coords.y == 0:
			coords.y -= 1
		erase_cell(smoke_cell.coords)
		erase_cell(smoke_cell.coords + Vector2i(0,-1))
		set_cell(coords, smoke_cell.src, smoke_cell.atlas_coords, TileSetAtlasSource.TRANSFORM_FLIP_H if smoke_cell.flip_h else 0)

var more_smoke: Array[CellData] = []
func _animate_more_smoke():
	for smoke_cell in more_smoke:
		if smoke_cell.atlas_coords.x == 0 and smoke_cell.atlas_coords.y > 1:
			smoke_cell.atlas_coords.y -= 1
		elif smoke_cell.atlas_coords.y == 0:
			smoke_cell.atlas_coords = Vector2i(0,3)
		else:
			if smoke_cell.atlas_coords.x != 2:
				smoke_cell.atlas_coords.x = 2
				smoke_cell.atlas_coords.y = 3
			else:
				smoke_cell.atlas_coords.y -= 1
		var coords = smoke_cell.coords
		if smoke_cell.atlas_coords.y == 0:
			coords.y -= 1
		if smoke_cell.atlas_coords.x != 0:
			coords.y -= 1
		erase_cell(smoke_cell.coords)
		erase_cell(smoke_cell.coords + Vector2i(0,-1))
		erase_cell(smoke_cell.coords + Vector2i(0,-2))
		set_cell(coords, smoke_cell.src, smoke_cell.atlas_coords, TileSetAtlasSource.TRANSFORM_FLIP_H if smoke_cell.flip_h else 0)
		if smoke_cell.atlas_coords.x == 0 and smoke_cell.atlas_coords.y == 1:
			set_cell(coords + Vector2i(0,-1), smoke_cell.src, Vector2i(0,0), TileSetAtlasSource.TRANSFORM_FLIP_H if smoke_cell.flip_h else 0)


var water_surface: Array[CellData] = []

var waterfall: Array[CellData] = []
func _animate_waterfall():
	for wc in waterfall:
		if wc.src == 6:
			var x_offset := 2
			if _is_one_of(wc.atlas_coords.x % 10, [4,8]):
				x_offset = -x_offset
			
			wc.atlas_coords.y += 1
			@warning_ignore("integer_division")
			var max_y := (wc.atlas_coords.y / 4) * 4 + 2
			if wc.atlas_coords.y > max_y:
				wc.atlas_coords.x += x_offset
				wc.atlas_coords.y -= 2
		set_cell(wc.coords, wc.src, wc.atlas_coords, TileSetAtlasSource.TRANSFORM_FLIP_H if wc.flip_h else 0)


var _seaweed_direction := 1.0:
	set(d):
		_seaweed_direction = d
		if abs(_seaweed_direction) > 4:
			_seaweed_direction = -sign(_seaweed_direction)
var seaweed: Array[CellData] = []
func _animate_seaweed():
	for sw in seaweed:
		sw.atlas_coords.y += sw.dir
		if (sw.atlas_coords.y - 2) % 4 == 0:
			sw.dir = -sw.dir
			sw.atlas_coords.y += sw.dir * 2
		set_cell(sw.coords, sw.src, sw.atlas_coords, TileSetAtlasSource.TRANSFORM_FLIP_H if sw.flip_h else 0)


var _sawblade_ranges: Array[Rect2i] = [
	Rect2i(Vector2i(9, 3), Vector2i(2, 11)),
	Rect2i(Vector2i(9, 15), Vector2i(2, 11))
]
## if not returns -1
func _is_sawblade(c: CellData) -> int:
	if c.src != 5: return -1
	if _t(c.atlas_coords, [_sawblade_ranges[0]]):
		return 0
	if _t(c.atlas_coords, [_sawblade_ranges[1]]):
		return 1
	return -1
var sawblades: Array[CellData] = []
func _animate_sawblades():
	for saw in sawblades:
		var type := _is_sawblade(saw)
		saw.atlas_coords.y += 3
		if saw.atlas_coords.y > 13 + type * 12:
			saw.atlas_coords.y -= 12
		set_cell(saw.coords, saw.src, saw.atlas_coords, TileSetAtlasSource.TRANSFORM_FLIP_H if saw.flip_h else 0)

class CellData:
	var src := -1
	var coords := Vector2i(-1,-1)
	var atlas_coords := Vector2i(-1,-1)
	var flip_h
	var dir := 1
	
	func _init(source: int, coordinates: Vector2i, atlas_coordinates: Vector2i, flip_hor := false) -> void:
		src = source
		coords = coordinates
		atlas_coords = atlas_coordinates
		flip_h = flip_hor

class Shake:
	var countdown := 0.0
	var duration := 0.0
	var offset := 0
	var direction := 0.0
	var tick := 0.0
	var tick_duration := 0.015
	var wanes := true
	var scramble := false

static var shake := Shake.new()

var _should_do_tilemap_update := false

## duration: How many seconds it will last
## power: how many pixels will the max displacement be
func apply_shake(duration: float, power: int):
	shake = Shake.new()
	shake.countdown = duration
	shake.duration = duration
	shake.offset = power

func _ready() -> void:
	tick.connect(_on_tick)
	
	var waterfall_ranges: Array[Rect2i] = []
	var water_ranges: Array[Rect2i] = [
		Rect2i(Vector2i(10,0),Vector2i(1,4)),
		Rect2i(Vector2i(0,24),Vector2i(1,4))
	]
	for y in 3:
		for x in 2:
			waterfall_ranges.push_back(Rect2i(Vector2i(2 + 10 * x, 12 * y),Vector2i(7,3)))
			waterfall_ranges.push_back(Rect2i(Vector2i(6 + 10 * x, 4 + 12 * y),Vector2i(3,3)))
			
			water_ranges.push_back(Rect2i(Vector2i(10 * x, 12 * y), Vector2i(1, 4)))
		
		waterfall_ranges.push_back(Rect2i(Vector2i(2, 8 + 12 * y),Vector2i(17,3)))

	for coords in get_used_cells():
		if water_surface.find_custom(func(cd: CellData): return cd.coords == coords) != -1: continue
		var src := get_cell_source_id(coords)
		var atlas_coords := get_cell_atlas_coords(coords)
		
		if src == 6 and _t(atlas_coords, water_ranges):
			water_surface.push_back(CellData.new(src, coords, atlas_coords))
			
			while true:
				coords.x += 1
				src = get_cell_source_id(coords)
				var new_atlas_coords := get_cell_atlas_coords(coords)
				if src == 6 and _t(new_atlas_coords, water_ranges):
					@warning_ignore("integer_division")
					var start := (atlas_coords.y / 12) * 12
					
					new_atlas_coords.y = start + atlas_coords.y % 12
					
					atlas_coords = _set_next_frame(new_atlas_coords, start)
					set_cell(coords, src, atlas_coords)
					water_surface.push_back(CellData.new(src, coords, atlas_coords))
				else:
					break
		elif src == 5 and atlas_coords.y == 8:
			var rt := _ReplacedTile.new()
			rt.type = _ReplacedTile.Type.BOX
			rt.variant = int(atlas_coords.x / 2.0)
			rt.coords = coords
			_replacements.push_back(rt)
			
			erase_cell(coords)
		elif src == 5 and _t(atlas_coords, [Rect2i(Vector2i(11,0),Vector2(3,2))]):
			var rt := _ReplacedTile.new()
			rt.type = _ReplacedTile.Type.ARROW_TRAP
			rt.coords = coords
			if atlas_coords.x == 11:
				rt.dir = Global.Direction.LEFT
			else:
				rt.dir = Global.Direction.RIGHT
			_replacements.push_back(rt)
			
			erase_cell(coords)
		elif src == 4 and atlas_coords.x >= 22 and (atlas_coords.y <= 2 or (atlas_coords.y >= 22 and atlas_coords.y <= 24)):
			fire.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
		elif src == 1 and ((atlas_coords.x == 1 and atlas_coords.y <= 4) or ((atlas_coords.x == 10 or atlas_coords.x == 11) and atlas_coords.y <= 2)):
			fire.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
		elif src == 1 and (atlas_coords.x == 2 and atlas_coords.y <= 3):
			smoke.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
		elif src == 1 and (atlas_coords.x == 0 and atlas_coords.y <= 3):
			more_smoke.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
		elif src == 5 and _t(atlas_coords, _sawblade_ranges):
			sawblades.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
		elif src == 6 and _t(atlas_coords, [Rect2i(Vector2i(20, 7), Vector2i(2, 7)), Rect2i(Vector2i(20, 15), Vector2i(1, 7))]):
			seaweed.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
		elif src == 6 and (_t(atlas_coords, waterfall_ranges)):
			if waterfall.find_custom(func(cd: CellData): return cd.coords == coords) != -1: continue
			waterfall.push_back(CellData.new(src, coords, atlas_coords, is_cell_flipped_h(coords)))
			
			while true:
				coords.y += 1
				src = get_cell_source_id(coords)
				var new_atlas_coords := get_cell_atlas_coords(coords)
				if src == 6 and _t(new_atlas_coords, waterfall_ranges):
					if _is_one_of(atlas_coords.x % 10, [2,6]):
						atlas_coords.x += 2
					else:
						atlas_coords.x -= 2
					new_atlas_coords.x = atlas_coords.x
					
					set_cell(coords, src, new_atlas_coords)
					waterfall.push_back(CellData.new(src, coords, new_atlas_coords))
				else:
					break
	
	for r in _replacements:
		match r.type:
			_ReplacedTile.Type.ARROW_TRAP:
				var at := ARROW_TRAP.instantiate()
				at.position = r.coords * 8
				at.position.x += 4
				at.position.y += 4
				at.raycast_start_dir = r.dir
				add_child(at)
			_ReplacedTile.Type.BOX:
				var box := BOX.instantiate()
				box.variant = r.variant
				box.position = r.coords
				box.position *= 8
				add_child(box)

func _physics_process(delta: float) -> void:
	_should_do_tilemap_update = false
	if shake.countdown <= 0 and shake.offset > 0:
		shake.offset = 0
		_should_do_tilemap_update = true
	elif shake.countdown > 0 and shake.tick <= 0:
		shake.tick = shake.tick_duration
		_should_do_tilemap_update = true
	
	_tick_countdown -= delta
	shake.countdown -= delta
	shake.tick -= delta
	
	if _should_do_tilemap_update:
		shake.direction = randf_range(0,TAU)
		notify_runtime_tile_data_update()

func _use_tile_data_runtime_update(_coords: Vector2i) -> bool:
	return _should_do_tilemap_update

func _tile_data_runtime_update(_coords: Vector2i, tile_data: TileData) -> void:
	var offset := shake.offset
	if shake.wanes:
		offset = roundi(offset * (shake.countdown / shake.duration))
	tile_data.texture_origin = Vector2(offset,0).rotated(randf_range(0,TAU) if shake.scramble else shake.direction)

func _on_tick() -> void:
	if _tick_counter % 4 == 0:
		for water_surface_cell in water_surface:
			@warning_ignore("integer_division")
			var start := (water_surface_cell.atlas_coords.y / 12) * 12
			if _water_direction > 0:
				water_surface_cell.atlas_coords = _set_next_frame(water_surface_cell.atlas_coords, start)
			else:
				water_surface_cell.atlas_coords = _set_prev_frame(water_surface_cell.atlas_coords, start)
			set_cell(water_surface_cell.coords, water_surface_cell.src, water_surface_cell.atlas_coords)
		
		_animate_seaweed()
		
		_water_direction *= 2
	
	if _tick_counter % 2 == 0:
		_animate_fire()
	
	_animate_smoke()
	
	_animate_more_smoke()
	
	_animate_waterfall()
	
	_animate_sawblades()
	
	_tick_counter += 1
