class_name RootStalker
extends EnemyBase

## Root Stalker (پیچک جهنده) - Act II ambusher.
## Lurks underground as a twitching mound of soil. When the hero comes close it bursts out,
## sprays a fan of thorn spikes, stays exposed for a moment, then burrows again.
## Only hittable while above ground.

enum State { HIDDEN, EMERGING, ATTACK, EXPOSED, BURROWING }

@export var detection_range: float = 175.0
@export var spike_count: int = 3
@export var spike_spread_deg: float = 26.0
@export var hidden_cooldown: float = 1.4

@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var mound: Sprite2D = $Mound

const THORN_SCENE = preload("res://characters/enemies/thorn_spitter/ThornProjectile.tscn")
const TEX_EMERGED = preload("res://assets/sprites/enemies/root_stalker/stalker_emerged.png")
const TEX_SHOOT = preload("res://assets/sprites/enemies/root_stalker/stalker_shoot.png")

var current_state: State = State.HIDDEN
var _state_timer: float = 0.0
var _target_player: PlayerController = null
var _facing: float = -1.0
var _sprite_rest_y: float = 0.0
var _anim_time: float = 0.0

func _ready() -> void:
	max_health = 3
	scrap_drop_count = 2
	touch_damage = 1
	knockback_resistance = 0.0
	super._ready()
	_sprite_rest_y = sprite.position.y
	_enter_hidden()
	_state_timer = randf_range(0.0, 0.6)

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	_locate_player()
	_state_timer += delta
	_anim_time += delta

	match current_state:
		State.HIDDEN:
			# The mound twitches as if something breathes beneath it
			mound.scale = Vector2(1.0 + sin(_anim_time * 5.0) * 0.06, 1.0 + cos(_anim_time * 5.0) * 0.06)
			if _state_timer > hidden_cooldown and _player_in_range():
				_enter_emerging()
		State.EMERGING:
			sprite.position.y = lerpf(_sprite_rest_y + 34.0, _sprite_rest_y, clampf(_state_timer / 0.3, 0.0, 1.0))
			if _state_timer >= 0.3:
				_enter_attack()
		State.ATTACK:
			if _state_timer >= 0.35 and sprite.texture != TEX_SHOOT:
				sprite.texture = TEX_SHOOT
				_fire_spikes()
			if _state_timer >= 0.7:
				current_state = State.EXPOSED
				_state_timer = 0.0
				sprite.texture = TEX_EMERGED
		State.EXPOSED:
			sprite.position.y = _sprite_rest_y + sin(_anim_time * 8.0) * 1.0
			if _state_timer >= 1.1:
				_enter_burrowing()
		State.BURROWING:
			sprite.position.y = lerpf(_sprite_rest_y, _sprite_rest_y + 34.0, clampf(_state_timer / 0.3, 0.0, 1.0))
			if _state_timer >= 0.3:
				_enter_hidden()

	velocity = Vector2.ZERO
	move_and_slide()

func _player_in_range() -> bool:
	return _target_player != null and is_instance_valid(_target_player) \
		and global_position.distance_to(_target_player.global_position) < detection_range

func _enter_hidden() -> void:
	current_state = State.HIDDEN
	_state_timer = 0.0
	sprite.visible = false
	mound.visible = true
	_set_vulnerable(false)

func _enter_emerging() -> void:
	current_state = State.EMERGING
	_state_timer = 0.0
	if _target_player:
		_facing = signf(_target_player.global_position.x - global_position.x)
		if is_zero_approx(_facing):
			_facing = -1.0
	visuals.scale.x = _facing
	sprite.texture = TEX_EMERGED
	sprite.position.y = _sprite_rest_y + 34.0
	sprite.visible = true
	mound.visible = false
	_set_vulnerable(true)
	FX.dust(get_parent(), global_position, 10, 90.0)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "land", 0.15, -2.0)

func _enter_attack() -> void:
	current_state = State.ATTACK
	_state_timer = 0.0
	sprite.position.y = _sprite_rest_y
	# Wind-up squash so the volley is readable
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.2)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)

func _enter_burrowing() -> void:
	current_state = State.BURROWING
	_state_timer = 0.0
	_set_vulnerable(false)
	FX.dust(get_parent(), global_position, 6, 60.0)

func _set_vulnerable(enabled: bool) -> void:
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", enabled)
	if hitbox_component:
		hitbox_component.set_deferred("monitorable", enabled)

func _fire_spikes() -> void:
	if not THORN_SCENE or not _target_player:
		return
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "bow_shoot", 0.2, -4.0)
	var origin: Vector2 = global_position + Vector2(_facing * 8.0, -26.0)
	var aim: Vector2 = (_target_player.global_position + Vector2(0, -16) - origin).normalized()
	for i in spike_count:
		var t: float = 0.0 if spike_count == 1 else float(i) / float(spike_count - 1) - 0.5
		var thorn: ThornProjectile = THORN_SCENE.instantiate() as ThornProjectile
		thorn.speed = 150.0
		get_parent().add_child(thorn)
		thorn.global_position = origin
		thorn.launch(aim.rotated(deg_to_rad(spike_spread_deg) * t * 2.0))

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
