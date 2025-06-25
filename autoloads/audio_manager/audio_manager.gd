extends Node

class Footsteps extends Node:
	var walk := AudioStreamPlayer.new()
	var run := AudioStreamPlayer.new()
	var walk_hard := AudioStreamPlayer.new()
	var run_hard := AudioStreamPlayer.new()
	var jump := AudioStreamPlayer.new()
	var jump_hard := AudioStreamPlayer.new()
	var land := AudioStreamPlayer.new()
	var land_hard := AudioStreamPlayer.new()
	
	func _init(path: String) -> void:
		add_child(walk)
		add_child(run)
		add_child(walk_hard)
		add_child(run_hard)
		add_child(jump)
		add_child(jump_hard)
		add_child(land)
		add_child(land_hard)
		
		var dir := DirAccess.open(path)
		if dir == null: printerr("Could not open folder: " + path); return
		dir.list_dir_begin()
		for subdir_name: String in dir.get_directories():
			if subdir_name.ends_with("Walk"):
				var subdir := DirAccess.open(path + subdir_name)
				if subdir == null: printerr("Could not open folder: " + path + subdir_name); return
				subdir.list_dir_begin()
				for file: String in subdir.get_files():
					if file.ends_with(".import"): continue
					
					var stream_playa := walk
					if file.contains("Hard_Walk"):
						stream_playa = walk_hard
					
					var rando_stream: AudioStreamRandomizer
					if not stream_playa.stream:
						rando_stream = AudioStreamRandomizer.new()
						stream_playa.stream = rando_stream
						rando_stream.playback_mode = rando_stream.PLAYBACK_RANDOM
					else:
						rando_stream = stream_playa.stream
					
					var resource := load(subdir.get_current_dir() + "/" + file)
					rando_stream.add_stream(-1,resource)
				subdir.list_dir_end()
			elif subdir_name.ends_with("Run"):
				var subdir := DirAccess.open(path + subdir_name)
				if subdir == null: printerr("Could not open folder: " + path + subdir_name); return
				subdir.list_dir_begin()
				for file: String in subdir.get_files():
					if file.ends_with(".import"): continue
					
					var stream_playa := run
					if file.contains("Hard_Run"):
						stream_playa = run_hard
					
					var rando_stream: AudioStreamRandomizer
					if not stream_playa.stream:
						rando_stream = AudioStreamRandomizer.new()
						stream_playa.stream = rando_stream
						rando_stream.playback_mode = rando_stream.PLAYBACK_RANDOM
					else:
						rando_stream = stream_playa.stream
					
					var resource := load(subdir.get_current_dir() + "/" + file)
					rando_stream.add_stream(-1,resource)
				subdir.list_dir_end()
			elif subdir_name.ends_with("Jump") or subdir_name.ends_with("Land"):
				var subdir := DirAccess.open(path + subdir_name)
				if subdir == null: printerr("Could not open folder: " + path + subdir_name); return
				subdir.list_dir_begin()
				for file: String in subdir.get_files():
					if file.ends_with(".import"): continue
					
					var stream_playa := jump
					if file.contains("Hard_Jump_Land"):
						stream_playa = land_hard
					elif file.contains("Hard_Jump_Start"):
						stream_playa = jump_hard
					elif file.contains("Land"):
						stream_playa = land
					
					var rando_stream: AudioStreamRandomizer
					if not stream_playa.stream:
						rando_stream = AudioStreamRandomizer.new()
						stream_playa.stream = rando_stream
						rando_stream.playback_mode = rando_stream.PLAYBACK_RANDOM
					else:
						rando_stream = stream_playa.stream
					
					var resource := load(subdir.get_current_dir() + "/" + file)
					rando_stream.add_stream(-1,resource)
				subdir.list_dir_end()
		dir.list_dir_end()

#func _setup_random_sfx(asp: AudioStreamPlayer, path: String, pm := AudioStreamRandomizer.PLAYBACK_RANDOM):
	#var rando_stream = AudioStreamRandomizer.new()
	#rando_stream.playback_mode = pm
	#asp.stream = rando_stream
	#
	#var dir := DirAccess.open(path)
	#if dir == null: printerr("Could not open folder"); return
	#dir.list_dir_begin()
	#for file: String in dir.get_files():
		#if file.ends_with(".import"): continue
		#var resource := load(dir.get_current_dir() + "/" + file)
		#rando_stream.add_stream(-1, resource)

#var rock_footsteps: Footsteps
#
#func _ready() -> void:
	#rock_footsteps = Footsteps.new("res://assets/audio/sfx/rock/")
	#add_child(rock_footsteps)
