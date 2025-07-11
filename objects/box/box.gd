extends Node2D
class_name Box

const PUSH_SPEED := 80.0

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = %VisibleOnScreenNotifier2D
@onready var animatable_body_2d: AnimatableBody2D = %AnimatableBody2D
@onready var pushable_area: Area2D = %PushableArea
@onready var down: RayCast2D = %Down
@onready var right: RayCast2D = %Right
@onready var left: RayCast2D = %Left

## 0 - 3 Changes box visuals
@export var variant := 0

@onready var sprite: Sprite2D = %Sprite


var falling := false
var velocity := Vector2(0, 0)
var _box_below: Box = null
var _forget_box_below_on_rest := false
var _target_x_pos := INF
var _idle_frames := 2


func is_resting() -> bool:
	return not falling and velocity.is_zero_approx()


func _get_down_col_diff(y: float) -> float:
	return down.get_collision_point().y - y


func _get_down_box() -> Box:
	if not down.is_colliding(): return null
	var c := down.get_collider()
	if c is AnimatableBody2D and c.get_parent() is Box:
		return c.get_parent()
	return null


func _ready() -> void:
	sprite.region_rect.position.x = variant * 2 * 8
	
	pushable_area.area_entered.connect(_on_area_entered)
	visible_on_screen_notifier_2d.screen_exited.connect(queue_free)


func _physics_process(delta: float) -> void:
	if _idle_frames > 0:
		_idle_frames -= 1
		_box_below = _get_down_box()
		return
	
	if not down.is_colliding() or _get_down_col_diff(animatable_body_2d.global_position.y) + 8 > 0:
		if not _box_below or _box_below.is_resting():
			falling = true
	
	if abs(velocity.x) > 0:
		var x = animatable_body_2d.position.x
		
		x += velocity.x * delta
		velocity.x -= sign(velocity.x) * (PUSH_SPEED / 0.25) * delta
		
		var stop := false
		
		if velocity.x > 0:
			if x >= _target_x_pos:
				stop = true
		else:
			if x <= _target_x_pos:
				stop = true
		
		if stop:
			velocity.x = 0
			animatable_body_2d.position.x = _target_x_pos
		else:
			animatable_body_2d.position.x = x
		
	elif falling:
		var y = animatable_body_2d.global_position.y
		var prev = y
		y += velocity.y * delta
		if y - prev > 3.5:
			y = prev + 3.5
		
		velocity += animatable_body_2d.get_gravity() * delta
		
		if down.is_colliding() and _get_down_col_diff(y) - 8 <= 0:
			falling = false
			velocity.y = 0
			animatable_body_2d.global_position.y = down.get_collision_point().y - 8
		else:
			animatable_body_2d.global_position.y = y
	else:
		if down.is_colliding() and down.get_collision_normal() == Vector2(0,0):
			animatable_body_2d.position.y -= 8
	
	if not _box_below:
		_box_below = _get_down_box()
	
	if _box_below:
		if _forget_box_below_on_rest and _box_below.is_resting():
			_box_below = null
		
		if _box_below and not _box_below.is_resting():
			_forget_box_below_on_rest = true


func _move(dir: Global.Direction) -> void:
	velocity.x = dir * PUSH_SPEED
	_target_x_pos = floor(animatable_body_2d.position.x / 8.0) * 8.0 + dir * 8


func _on_area_entered(area: Area2D) -> void:
	if velocity.x != 0: return
	if area is PlayerAttack:
		if not area.push: return
		
		var d: Global.Direction = area.direction
		
		if area.pos_start.distance_to(area.global_position) > 16:
			if area.weapon == Global.Weapon.STAFF:
				d = -d as Global.Direction
			else:
				return
		
		if d > 0:
			if right.is_colliding(): return
		else:
			if left.is_colliding(): return
		
		_move(d)
