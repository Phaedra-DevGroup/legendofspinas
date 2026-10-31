class_name AudioManagerSingleton
extends Node

## Centralized Audio Manager for "The Legend of Espinas".
## Manages SFX voice pooling, randomized pitch variance, looping BGM, crossfading,
## and global volume buses.

signal music_changed(track_name: String)

const SFX_DIR = "res://assets/audio/sfx/"
const MUSIC_DIR = "res://assets/audio/music/"
const SFX_POOL_SIZE = 12
const SETTINGS_PATH = "user://settings.cfg"

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_player: AudioStreamPlayer
var _crossfade_player: AudioStreamPlayer
var _current_music_track: String = ""

var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}

var master_volume: float = 1.0
var music_volume: float = 0.85
var sfx_volume: float = 0.90

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep playing when game is paused
	_load_settings()
	_init_sfx_pool()
	_init_music_players()
	_preload_audio()

func _init_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = &"Master"
		add_child(p)
		_sfx_players.append(p)

func _init_music_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = &"Master"
	_music_player.finished.connect(_on_music_finished)
	add_child(_music_player)

	_crossfade_player = AudioStreamPlayer.new()
	_crossfade_player.name = "CrossfadePlayer"
	_crossfade_player.bus = &"Master"
	add_child(_crossfade_player)

func _preload_audio() -> void:
	# Load standard SFX
	var sfx_files = [
		"jump", "double_jump", "land", "slash", "heavy_slash",
		"bow_shoot", "arrow_hit", "slide", "grapple_shoot", "grapple_latch",
		"player_hurt", "player_die", "enemy_hit", "enemy_die", "wolf_bite",
		"shield_block", "boss_slam", "stalactite_fall", "pickup_scrap",
		"pomegranate_pickup", "keystone_unlock", "beacon_ignite",
		"anvil_hammer", "ui_click", "ui_select"
	]
	for sfx in sfx_files:
		var path: String = SFX_DIR + sfx + ".wav"
		if ResourceLoader.exists(path):
			_sfx_cache[sfx] = load(path)
	
	# Load standard Music
	var music_files = ["menu", "forge", "boss", "forest"]
	for m in music_files:
		var path: String = MUSIC_DIR + "music_" + m + ".wav"
		if ResourceLoader.exists(path):
			_music_cache[m] = load(path)

## Plays a one-shot sound effect with optional pitch randomization.
func play_sfx(sound_name: String, pitch_range: float = 0.05, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx_cache.get(sound_name, null)
	if not stream:
		var path: String = SFX_DIR + sound_name + ".wav"
		if ResourceLoader.exists(path):
			stream = load(path)
			_sfx_cache[sound_name] = stream
		else:
			return
	
	var player: AudioStreamPlayer = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	
	player.stream = stream
	if pitch_range > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	else:
		player.pitch_scale = 1.0
	
	var base_db: float = linear_to_db(sfx_volume * master_volume)
	player.volume_db = base_db + volume_db
	player.play()

## Plays a looping background music track, with smooth crossfading if already playing.
func play_music(track_name: String, fade_duration: float = 0.8) -> void:
	if _current_music_track == track_name and _music_player.is_playing():
		return
	
	var stream: AudioStream = _music_cache.get(track_name, null)
	if not stream:
		var path: String = MUSIC_DIR + "music_" + track_name + ".wav"
		if ResourceLoader.exists(path):
			stream = load(path)
			_music_cache[track_name] = stream
		else:
			push_warning("AudioManager: Track '%s' not found." % track_name)
			return
	
	_current_music_track = track_name
	var target_db: float = linear_to_db(music_volume * master_volume)
	
	if _music_player.is_playing() and fade_duration > 0.0:
		# Crossfade
		_crossfade_player.stream = _music_player.stream
		_crossfade_player.volume_db = _music_player.volume_db
		_crossfade_player.play(_music_player.get_playback_position())
		
		_music_player.stream = stream
		_music_player.volume_db = -80.0
		_music_player.play()
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(_crossfade_player, "volume_db", -80.0, fade_duration)
		tween.tween_property(_music_player, "volume_db", target_db, fade_duration)
		tween.chain().tween_callback(_crossfade_player.stop)
	else:
		_music_player.stream = stream
		_music_player.volume_db = target_db
		_music_player.play()
	
	music_changed.emit(track_name)

func stop_music(fade_duration: float = 0.5) -> void:
	if not _music_player.is_playing():
		return
	_current_music_track = ""
	if fade_duration > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()

func _on_music_finished() -> void:
	if not _current_music_track.is_empty():
		_music_player.play(0.0)

func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	_update_music_volume()

func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	_update_music_volume()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)

## Volume sliders survive app restarts (the sliders call save_settings when released).
func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.save(SETTINGS_PATH)

func _load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_volume = clampf(float(cfg.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)

func _update_music_volume() -> void:
	if _music_player and _music_player.is_playing():
		_music_player.volume_db = linear_to_db(music_volume * master_volume)
