extends Node2D

## If provided must be truthy before this can be enabled
@export var flag := ""

var disabled_children: Array[Node] = []


func _is_enemy_alive(node: Node) -> bool:
	if node is CommonEnemy:
		if node.is_dead():
			return false
		elif node.is_frozen:
			return false
	return true


func _do_enemies_exist():
	if flag != "":
		if Global.session.saved_data.object_flags.has(flag):
			if not Global.session.saved_data.object_flags[flag]:
				return true
		else:
			return true
	return get_tree().get_nodes_in_group('enemies').filter(_is_enemy_alive).size() > 0


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for c in disabled_children:
			c.queue_free()


func _ready() -> void:
	if not Refs.level_manager:
		return
	
	if Global.session.saved_data.object_flags.has(Refs.level_manager.get_unique_name(self)):
		return
	
	if _do_enemies_exist():
		for c in get_children():
			disabled_children.push_back(c)
			remove_child(c)


func _process(_delta: float) -> void:
	if disabled_children.size() > 0:
		if not _do_enemies_exist():
			for c in disabled_children:
				add_child(c)
			disabled_children.clear()
			Global.session.saved_data.object_flags[Refs.level_manager.get_unique_name(self)] = true
