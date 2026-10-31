class_name ZoneBackdrop
extends Node2D

## Per-zone parallax backdrops (Act I ruins → summit, Act II forest → sacred grove).
## Each zone painting is a seamless strip repeated by a Parallax2D; as the camera travels between
## zones the strips crossfade, so the ruins, forge, mine, colosseum and summit each have their own sky.

const BLEND_WIDTH: float = 220.0
const SCROLL_SCALE: float = 0.35

## [texture path, zone start x, zone end x]
const ACT1_ZONES: Array = [
	["res://assets/sprites/environment/bg_terraces.png", -2000.0, 1000.0],
	["res://assets/sprites/environment/bg_forge.png", 1000.0, 1820.0],
	["res://assets/sprites/environment/bg_mine.png", 1820.0, 3560.0],
	["res://assets/sprites/environment/bg_colosseum.png", 3560.0, 5320.0],
	["res://assets/sprites/environment/bg_summit.png", 5320.0, 8000.0],
]

## Zone list for this level; empty uses the Act I layout.
@export var zones: Array = []

var _layers: Array[Parallax2D] = []

func _ready() -> void:
	if zones.is_empty():
		zones = ACT1_ZONES
	for zone in zones:
		var tex: Texture2D = load(zone[0]) as Texture2D
		var layer: Parallax2D = Parallax2D.new()
		layer.scroll_scale = Vector2(SCROLL_SCALE, 1.0)
		layer.repeat_size = Vector2(tex.get_width() if tex else 1280.0, 0.0)
		layer.repeat_times = 3
		# Line the strip up so each zone opens on the start of its painting
		layer.scroll_offset = Vector2(zone[1] * SCROLL_SCALE, 0.0)
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = tex
		sprite.centered = false
		layer.add_child(sprite)
		add_child(layer)
		_layers.append(layer)
	_update_blend()

func _process(_delta: float) -> void:
	_update_blend()

func _update_blend() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var x: float = camera.get_screen_center_position().x
	for i in _layers.size():
		var start_x: float = zones[i][1]
		var end_x: float = zones[i][2]
		var fade_in: float = clampf((x - start_x) / BLEND_WIDTH + 0.5, 0.0, 1.0)
		var fade_out: float = clampf((end_x - x) / BLEND_WIDTH + 0.5, 0.0, 1.0)
		# Later zones draw on top, so only the incoming layer needs alpha; the one beneath stays
		# opaque until it is fully covered (no dark dip mid-transition).
		_layers[i].visible = fade_in > 0.0 and fade_out > 0.0
		_layers[i].modulate.a = fade_in
