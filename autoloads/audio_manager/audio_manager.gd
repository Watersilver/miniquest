extends Node

const BUS_NAME_MASTER = "Master"
const BUS_NAME_SFX = "Sfx"
const BUS_NAME_BGM = "Bgm"

@onready var bgm: AudioStreamPlayer = %Bgm

@export var music_themes: MusicThemes
@export var sound_effects: SoundEffects
var sfx_players_dict: Dictionary[String, AudioStreamPlayer]


func play_sfx(sound_name: String, fallbacks: Array[String] = []) -> void:
	if not sfx_players_dict.has(sound_name):
		var f := fallbacks.duplicate()
		play_sfx(f.pop_front(), f)
	else:
		sfx_players_dict[sound_name].play()


func _gbi(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)


func set_volume(vol: float) -> void:
	AudioServer.set_bus_volume_linear(_gbi(BUS_NAME_MASTER), clampf(vol, 0, 1))


func get_volume() -> float:
	return AudioServer.get_bus_volume_linear(_gbi(BUS_NAME_MASTER))


func set_sfx_mute(enable: bool) -> void:
	AudioServer.set_bus_mute(_gbi(BUS_NAME_SFX), enable)


func get_sfx_mute() -> bool:
	return AudioServer.is_bus_mute(_gbi(BUS_NAME_SFX))


func set_bgm_mute(enable: bool) -> void:
	AudioServer.set_bus_mute(_gbi(BUS_NAME_BGM), enable)


func get_bgm_mute() -> bool:
	return AudioServer.is_bus_mute(_gbi(BUS_NAME_BGM))


func play_music(stream: AudioStream, force_restart := false) -> void:
	if force_restart or bgm.stream != stream or not bgm.playing:
		bgm.stream = stream
		restart_music()


func restart_music() -> void:
	bgm.play()


func stop_music() -> void:
	bgm.stop()


func play_footstep_sound() -> void:
	play_sfx('walk_steps')


func play_run_footstep_sound() -> void:
	play_sfx('run_steps')


func play_jump_sound() -> void:
	play_sfx('jump')


func play_double_jump_sound() -> void:
	play_sfx('double_jump', ["jump"])


func play_player_hurt_sound() -> void:
	play_sfx('player_hurt')


func play_fall_down_sound() -> void:
	play_sfx('fall_down')


func play_player_death_sound() -> void:
	play_sfx('player_death')


func play_attack_sound() -> void:
	play_sfx('attack')


func play_magic_attack_sound() -> void:
	play_sfx('magic_attack')


func load_sounds_to_player(pl: AudioStreamPlayer, folder_name: String, fallbacks: Array[String] = []) -> void:
	var walk_steps_dir := DirAccess.open("res://assets/audio/sfx/" + folder_name + "/")
	if walk_steps_dir == null:
		if fallbacks.size() > 0:
			fallbacks = fallbacks.duplicate()
			load_sounds_to_player(pl, fallbacks.pop_front(), fallbacks)
		printerr("Failed opening " + folder_name + " directory")
	else:
		var rando := AudioStreamRandomizer.new()
		pl.stream = rando
		for file in walk_steps_dir.get_files():
			if file.ends_with(".import"): continue
			var resource := load(walk_steps_dir.get_current_dir() + "/" + file)
			rando.add_stream(-1, resource)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for sound in sound_effects.sounds:
		var audstr := AudioStreamPlayer.new()
		audstr.bus = BUS_NAME_SFX
		audstr.stream = sound_effects.sounds[sound]
		add_child(audstr)
		sfx_players_dict.set(sound, audstr)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
