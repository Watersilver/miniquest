@tool
extends Resource
class_name SoundEffects

@export var sounds: Dictionary[String, AudioStream]
@export_tool_button("Reload souds") var load_sounds_action := load_sounds

func load_sounds_from_folder(path: String, folder_name: String) -> void:
	var folder := DirAccess.open(path + folder_name)
	if folder == null:
		printerr("Failed to open " + folder_name + " directory")
	else:
		#folder.list_dir_begin()
		var rando := AudioStreamRandomizer.new()
		if not sounds.has(folder_name):
			sounds.set(folder_name, rando)
		for file in folder.get_files():
			if file.ends_with(".import") or file == "": continue
			var resource := load(folder.get_current_dir() + "/" + file)
			rando.add_stream(-1, resource)
		for dir in folder.get_directories():
			load_sounds_from_folder(path, folder_name + "/" + dir)
		#folder.list_dir_end()

func load_sounds() -> void:
	var sfx_dir := DirAccess.open("res://assets/audio/sfx")
	sounds.clear()
	for folder_name in sfx_dir.get_directories():
		load_sounds_from_folder("res://assets/audio/sfx/", folder_name)
