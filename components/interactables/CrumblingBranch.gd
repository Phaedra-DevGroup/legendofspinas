class_name CrumblingBranch
extends StaticBody2D

## Brittle, blight-rotted branch (شاخه شکننده). A one-way platform that creaks and shakes
## once the hero stands on it, snaps and falls away, then regrows a few seconds later.

@export var hold_time: float = 0.45
@export var shake_time: float = 0.4
@export var regrow_time: float = 3.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sensor: Area2D = $Sensor

enum State { SOLID, SHAKING, FALLEN }

var _state: State = State.SOLID
var _timer: float = 0.0
var _sprite_home: Vector2 = Vector2.ZERO

func _ready() -> void:
	_sprite_home = sprite.position

func _physics_process(delta: float) -> void:
	match _state:
		State.SOLID:
			if _hero_on_top():
				_timer += delta
				if _timer >= hold_time:
					_state = State.SHAKING
					_timer = 0.0
					if has_node("/root/AudioManager"):
						get_node("/root/AudioManager").call("play_sfx", "enemy_hit", 0.2, -8.0)
			else:
				_timer = maxf(0.0, _timer - delta)
		State.SHAKING:
			_timer += delta
			sprite.position = _sprite_home + Vector2(randf_range(-1.5, 1.5), randf_range(-0.5, 1.0))
			if _timer >= shake_time:
				_snap()
		State.FALLEN:
			_timer += delta
			if _timer >= regrow_time:
				_regrow()

func _hero_on_top() -> bool:
	for body in sensor.get_overlapping_bodies():
		var hero: PlayerController = body as PlayerController
		if hero and hero.is_on_floor():
			return true
	return false

func _snap() -> void:
	_state = State.FALLEN
	_timer = 0.0
	collision.set_deferred("disabled", true)
	FX.debris(get_parent(), global_position + Vector2(0, -2), 8, 90.0)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "stalactite_fall", 0.1, -6.0)
	var fall: Tween = create_tween().set_parallel(true)
	fall.tween_property(sprite, "position:y", _sprite_home.y + 90.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(sprite, "rotation", randf_range(-0.5, 0.5), 0.5)
	fall.tween_property(sprite, "modulate:a", 0.0, 0.5)

func _regrow() -> void:
	_state = State.SOLID
	_timer = 0.0
	sprite.position = _sprite_home
	sprite.rotation = 0.0
	collision.set_deferred("disabled", false)
	var grow: Tween = create_tween()
	sprite.scale = Vector2(0.4, 1.0)
	grow.set_parallel(true)
	grow.tween_property(sprite, "modulate:a", 1.0, 0.35)
	grow.tween_property(sprite, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
