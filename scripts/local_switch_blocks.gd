extends Activatable

func activate() -> void:
	for n in get_tree().get_nodes_in_group("switch_blocks"):
		if n is SwitchBlock:
			n.enabled = SwitchBlock.EnabledState.ENABLED
