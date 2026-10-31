extends Node

## ScreenShake autoload: trauma-driven camera shake plus hitstop (frame freeze).
## Cameras need no setup; the active Camera2D of the current viewport is shaken.

@export var trauma_decay: float = 1.6
@export var max_offset: float = 10.0

var trauma: float = 0.0
var _hitstop_active: bool = false

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func shake(amount: float = 0.3, _optional_param: float = 0.0) -> void:
	add_trauma(minf(1.0, amount))

func _process(delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	if trauma <= 0.0:
		camera.offset = Vector2.ZERO
		return
	trauma = maxf(trauma - trauma_decay * delta, 0.0)
	var strength: float = trauma * trauma * max_offset
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength

func hitstop(duration: float = 0.04) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_hitstop_active = false
