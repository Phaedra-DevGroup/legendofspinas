class_name MistRaven
extends EnemyBase

## Mist Raven (کلاغ مه‌آلود) - Act 1 aerial harasser.
## Rests camouflaged on ruined archways, then swoops in a fast parabolic arc
## leaving a trail of lingering purple mist.

enum State { PERCHED, SWOOP, RETURN }

@export var swoop_speed: float = 150.0
@export var detection_range: float = 140.0
@export var swoop_gravity: float = 520.0
@export var mist_interval: float = 0.14

@onready var sprite: Sprite2D = $Visuals/Sprite2D

const MIST_SCENE = preload("res://characters/enemies/mist_raven/MistCloud.tscn")
const TEX_PERCH = preload("res://assets/sprites/enemies/mist_raven/raven_perch.png")
const TEX_SWOOP = preload("res://assets/sprites/enemies/mist_raven/raven_swoop.png")

var current_state: State = State.PERCHED
var _home_position: Vector2 = Vector2.ZERO
var _target_player: PlayerController = null
var _swoop_direction: float = 1.0
var _mist_timer: float = 0.0

func _ready() -> void:
	max_health = 1
	scrap_drop_count = 1
	touch_damage = 1
	super._ready()
	_home_position = global_position
	_set_perched(true)

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	_locate_player()
	
	match current_state:
		State.PERCHED:
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			if _target_player and is_instance_valid(_target_player):
				if global_position.distance_to(_target_player.global_position) < detection_range:
					_start_swoop()
		State.SWOOP:
			velocity.x = _swoop_direction * swoop_speed
			velocity.y += swoop_gravity * delta
			_mist_timer -= delta
			if _mist_timer <= 0.0:
				_mist_timer = mist_interval
				_drop_mist()
			if _target_player and global_position.y > _target_player.global_position.y - 12.0:
				_begin_return()
		State.RETURN:
			var home_offset: Vector2 = _home_position - global_position
			if home_offset.length() < 6.0:
				_set_perched(true)
			else:
				velocity = velocity.move_toward(home_offset.normalized() * swoop_speed * 0.7, 300.0 * delta)
	
	if not is_zero_approx(velocity.x):
		visuals.scale.x = 1.0 if velocity.x > 0.0 else -1.0
	move_and_slide()

func _start_swoop() -> void:
	current_state = State.SWOOP
	_set_perched(false)
	_mist_timer = 0.0
	_swoop_direction = signf(_target_player.global_position.x - global_position.x)
	if is_zero_approx(_swoop_direction):
		_swoop_direction = 1.0
	# Launch into a parabolic dive
	velocity = Vector2(_swoop_direction * swoop_speed * 0.8, -40.0)

func _begin_return() -> void:
	current_state = State.RETURN

func _set_perched(perched: bool) -> void:
	if perched:
		current_state = State.PERCHED
		if sprite:
			sprite.texture = TEX_PERCH
		# Camouflaged against the ruins
		modulate.a = 0.4
	else:
		if sprite:
			sprite.texture = TEX_SWOOP
		modulate.a = 1.0

func _drop_mist() -> void:
	if not MIST_SCENE:
		return
	var mist: Node2D = MIST_SCENE.instantiate() as Node2D
	if mist:
		mist.global_position = global_position + Vector2(0, 6)
		# The raven must survive its own trail
		var cloud_hitbox: HitboxComponent = mist.get_node_or_null("HitboxComponent") as HitboxComponent
		if cloud_hitbox:
			cloud_hitbox.ignore_owner = self
		get_parent().call_deferred("add_child", mist)

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
