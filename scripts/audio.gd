extends Node
var game
var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index: int = 0
var current_track: String = ""
var sounds: Dictionary = {}
var playback_enabled: bool = true
var last_select_ms: int=-1000

func _ready() -> void:
	# Headless checks have no audio output. Avoid starting silent playback jobs
	# whose asynchronous cleanup can outlive a fast test process.
	playback_enabled = DisplayServer.get_name() != "headless"
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -17
	add_child(music_player)
	for i in range(10):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -16
		add_child(voice)
		voices.append(voice)
	for name in ["buster","item","hurt","hit","explosion","door","select","water","step","plant","enemy_shot","mech_shot","drink","throw","bounce"]:
		var path := "res://assets/audio/%s.ogg" % name
		if ResourceLoader.exists(path): sounds[name] = load(path)

func track(name: String) -> void:
	if current_track == name:
		music_player.stream_paused = not game.state.music
		return
	current_track = name
	var path := "res://assets/audio/%s.ogg" % name
	if ResourceLoader.exists(path):
		var stream: AudioStreamOggVorbis = load(path)
		stream.loop = true
		music_player.stream = stream
		if playback_enabled: music_player.play()
		music_player.stream_paused = not game.state.music

func effect(name: String, pitch: float = 1.0) -> void:
	if not playback_enabled or not game.state.sound or not sounds.has(name): return
	if name=="select":
		var now: int=Time.get_ticks_msec()
		if now-last_select_ms<45:return
		last_select_ms=now
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = sounds[name]
	voice.pitch_scale = pitch
	voice.play()

func refresh() -> void:
	music_player.stream_paused = not game.state.music

func shutdown() -> void:
	# Release playback references before the audio thread and scene tree stop.
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()
