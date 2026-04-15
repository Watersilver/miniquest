extends Activatable


func activate() -> void:
	Global.session.saved_data.object_flags['ts_ladder'] = true
