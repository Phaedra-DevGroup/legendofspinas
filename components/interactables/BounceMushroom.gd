class_name BounceMushroom
extends StaticBody2D

## Springy Misty-Forest mushroom (قارچ ارتجاعی). Its cap is a one-way platform:
## landing on it launches the hero high into the canopy and refreshes their double jump.
## Holding Jump while landing gives an extra-tall bounce.

@export var bounce_velocity: float = 560.0
@export var held_jump_bonus: float = 1.22

@onready var cap: Sprite2D = $Cap
@onready var sensor: Area2D = $Sensor

var _cooldown: float = 0.0
var _cap_base_scale: Vector2 = Vector2.ONE
var _time: float = 0.0
var _squash: Tween = null

func _ready() -> void:
	_cap_base_scale = cap.scale
	_time = randf() * TAU

func _physics_process(delta: float) -> void:
	# Gentle idle breathing so the pads read as alive (paused while a bounce squash plays)
	_time += delta
	if _squash == null or not _squash.is_running():
		var b: float = sin(_time * 3.4) * 0.035
		cap.scale = _cap_base_scale * Vector2(1.0 + b, 1.0 - b)
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	for body in sensor.get_overlapping_bodies():
		var hero: PlayerController = body as PlayerController
		# Only bounce a hero standing on (or landing onto) the cap, never one passing upward through it
		if hero and hero.velocity.y >= -1.0 and hero.global_position.y <= global_position.y + 4.0:
			_launch(hero)
			return

func _launch(hero: PlayerController) -> void:
	_cooldown = 0.2
	var power: float = bounce_velocity
	if Input.is_action_pressed(&"jump"):
		power *= held_jump_bonus
	hero.velocity.y = -power
	hero.reset_air_abilities()
	if hero.state_machine:
		hero.state_machine.transition_to("Fall")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "jump", 0.15, 2.0)
	FX.burst(get_parent(), global_position + Vector2(0, -6), Color(0.55, 0.95, 0.85, 0.9), 10, 70.0, true, 2.0, 0.45)
	# Squash then overshoot
	if _squash:
		_squash.kill()
	_squash = create_tween()
	_squash.tween_property(cap, "scale", _cap_base_scale * Vector2(1.3, 0.62), 0.06)
	_squash.tween_property(cap, "scale", _cap_base_scale * Vector2(0.86, 1.18), 0.1)
	_squash.tween_property(cap, "scale", _cap_base_scale, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
