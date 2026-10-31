class_name CorruptedShieldBearer
extends EnemyBase

## Corrupted Shield-Bearer (نگهبان سپردار مسخ‌شده) - heavy Act 1 front-liner.
## Deflects everything hitting its reinforced stone shield and answers with a bash.
## Strike from behind with a double jump or shatter the guard with Turquoise Resonance.

enum State { PATROL, BASH, STUNNED }

@export var patrol_speed: float = 30.0
@export var gravity: float = 900.0
@export var detection_range: float = 130.0
@export var bash_knockback: float = 230.0
@export var stun_duration: float = 1.5
## Delay before turning around when player flanks or jumps behind shield
@export var turn_delay: float = 1.35

@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var guard_hurtbox: GuardHurtbox = $HurtboxComponent
@onready var floor_detector: RayCast2D = $Visuals/FloorDetector

const TEX_IDLE = preload("res://assets/sprites/enemies/shield_bearer/bearer_idle.png")
const TEX_BASH = preload("res://assets/sprites/enemies/shield_bearer/bearer_bash.png")
const TEX_STUN = preload("res://assets/sprites/enemies/shield_bearer/bearer_stun.png")

var current_state: State = State.PATROL
var is_stunned: bool = false
var _facing_direction: float = -1.0
var _state_timer: float = 0.0
var _turn_timer: float = 0.0
var _target_player: PlayerController = null

func _ready() -> void:
	max_health = 4
	scrap_drop_count = 4
	touch_damage = 1
	knockback_resistance = 2.4
	super._ready()
	_set_texture(TEX_IDLE)
	if guard_hurtbox:
		guard_hurtbox.guarded.connect(_on_guarded)
		guard_hurtbox.guard_broken.connect(_on_guard_broken)

func is_hit_from_front(from_position: Vector2) -> bool:
	return signf(from_position.x - global_position.x) == _facing_direction

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	
	_locate_player()
	
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.BASH:
			velocity.x = _facing_direction * 150.0
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.PATROL
				_set_texture(TEX_IDLE)
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_is_stunned_recover()
	
	move_and_slide()

func _process_patrol(delta: float) -> void:
	if _target_player and is_instance_valid(_target_player):
		var diff: Vector2 = _target_player.global_position - global_position
		if absf(diff.y) < 100.0 and absf(diff.x) < detection_range:
			var target_dir: float = signf(diff.x)
			if not is_zero_approx(target_dir):
				if target_dir != _facing_direction:
					# Player flanked or jumped behind! Heavy shield turning delay allows back attack!
					_turn_timer += delta
					velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
					if _turn_timer >= turn_delay:
						_turn_timer = 0.0
						_facing_direction = target_dir
						visuals.scale.x = _facing_direction
					_turn_at_ledge()
					return
				else:
					# Facing player: reset turn timer and advance with heavy shield forward
					_turn_timer = 0.0
					velocity.x = _facing_direction * patrol_speed * 1.4
					_turn_at_ledge()
					return
	
	_turn_timer = 0.0
	velocity.x = _facing_direction * patrol_speed
	_turn_at_ledge()

func _turn_at_ledge() -> void:
	var at_ledge: bool = floor_detector and not floor_detector.is_colliding()
	if is_on_floor() and (is_on_wall() or at_ledge):
		_facing_direction *= -1.0
		visuals.scale.x = _facing_direction

func _face(dir_x: float) -> void:
	var dir: float = signf(dir_x)
	if not is_zero_approx(dir) and dir != _facing_direction:
		_facing_direction = dir
		visuals.scale.x = _facing_direction

func _on_damaged(amount: int, knockback: Vector2) -> void:
	super._on_damaged(amount, knockback)
	# Hits from behind reset the turn timer, allowing the player to combo without instant turns
	_turn_timer = 0.0

func _on_guarded(_hitbox: HitboxComponent) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "shield_block")
	# Metallic clink + shield bash that shoves the attacker back
	current_state = State.BASH
	_state_timer = 0.25
	_set_texture(TEX_BASH)
	visuals.modulate = Color(1.6, 1.6, 1.8)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "modulate", Color.WHITE, 0.2)
	
	if _target_player and is_instance_valid(_target_player):
		var push: Vector2 = (_target_player.global_position - global_position).normalized()
		_target_player.velocity = Vector2(push.x * bash_knockback, -120.0)

func _on_guard_broken(_hitbox: HitboxComponent) -> void:
	is_stunned = true
	current_state = State.STUNNED
	_state_timer = stun_duration
	_set_texture(TEX_STUN)
	ScreenShake.add_trauma(0.15)

func _is_stunned_recover() -> void:
	is_stunned = false
	current_state = State.PATROL
	_set_texture(TEX_IDLE)

func _set_texture(tex: Texture2D) -> void:
	if sprite and tex:
		sprite.texture = tex

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
