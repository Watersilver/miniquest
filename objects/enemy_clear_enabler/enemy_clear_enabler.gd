extends Node2D


var disabled_children: Array[Node] = []


func _do_enemies_exist():
	return get_tree().get_nodes_in_group('enemies').size() > 0


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
