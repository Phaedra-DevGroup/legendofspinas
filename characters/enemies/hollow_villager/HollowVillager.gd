class_name HollowVillager
extends EnemyBase

## Corrupted Villager enemy in "The Legend of Espinas".
## Possesses higher resilience, patrols platforms, and performs telegraphed heavy pickaxe swings.

enum State { PATROL, WINDUP, SWING, COOLDOWN }

@export var patrol_speed: float = 38.0
@export var detection_range: float = 130.0
@export var attack_range: float = 36.0
@export var gravity: float = 900.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var strike_hitbox: HitboxComponent = $Visuals/StrikeHitbox
@onready var floor_detector: RayCast2D = $Visuals/FloorDetector

const TEX_WALK_0 = preload("res://assets/sprites/enemies/hollow_villager/villager_walk_0.png")
const TEX_WALK_1 = preload("res://assets/sprites/enemies/hollow_villager/villager_walk_1.png")
const TEX_WINDUP = preload("res://assets/sprites/enemies/hollow_villager/villager_windup.png")
const TEX_SWING = preload("res://assets/sprites/enemies/hollow_villager/villager_swing.png")
const TEX_HURT = preload("res://assets/sprites/enemies/hollow_villager/villager_hurt.png")

var current_state: State = State.PATROL
var _facing_direction: float = -1.0
var _walk_timer: float = 0.0
var _walk_frame: int = 0
var _state_timer: float = 0.0
var _target_player: PlayerController = null

func _ready() -> void:
	max_health = 4
	scrap_drop_count = 3
	touch_damage = 1
	knockback_resistance = 1.6
	super._ready()
	
	if strike_hitbox:
		strike_hitbox.faction = HitboxComponent.Faction.ENEMY
		strike_hitbox.damage = 2
		strike_hitbox.knockback_force = 180.0
		strike_hitbox.monitoring = false
		strike_hitbox.monitorable = false

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
		State.WINDUP:
			velocity.x = 0.0
			_state_timer -= delta
			if _state_timer <= 0.0:
				_execute_swing()
		State.SWING:
			velocity.x = 0.0
			_state_timer -= delta
			if _state_timer <= 0.0:
				_end_swing()
		State.COOLDOWN:
			velocity.x = 0.0
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.PATROL
				sprite.texture = TEX_WALK_0
	
	move_and_slide()

func _process_patrol(delta: float) -> void:
	# Check if player is in attack range
	if _target_player and is_instance_valid(_target_player):
		var dist_x: float = absf(_target_player.global_position.x - global_position.x)
		var dist_y: float = absf(_target_player.global_position.y - global_position.y)
		
		if dist_y < 45.0 and dist_x < detection_range:
			_facing_direction = signf(_target_player.global_position.x - global_position.x)
			visuals.scale.x = _facing_direction
			
			if dist_x <= attack_range:
				_start_windup()
				return
	
	# Patrol movement
	velocity.x = _facing_direction * patrol_speed
	
	# Turn around on walls and at platform ledges (no falling off high mine platforms)
	var at_ledge: bool = floor_detector and not floor_detector.is_colliding()
	if is_on_floor() and (is_on_wall() or at_ledge):
		_facing_direction *= -1.0
		visuals.scale.x = _facing_direction
	
	# Animate walking
	_walk_timer += delta
	if _walk_timer >= 0.22:
		_walk_timer = 0.0
		_walk_frame = 1 - _walk_frame
		sprite.texture = TEX_WALK_1 if _walk_frame == 1 else TEX_WALK_0

func _start_windup() -> void:
	current_state = State.WINDUP
	_state_timer = 0.45
	sprite.texture = TEX_WINDUP
	
	# Visual anticipation squash
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 0.85, 1.2), 0.45)

func _execute_swing() -> void:
	current_state = State.SWING
	_state_timer = 0.28
	sprite.texture = TEX_SWING
	visuals.scale = Vector2(_facing_direction * 1.15, 0.9)
	
	if strike_hitbox:
		strike_hitbox.monitorable = true
	
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.28)

func _end_swing() -> void:
	if strike_hitbox:
		strike_hitbox.monitorable = false
	current_state = State.COOLDOWN
	_state_timer = 0.6
	sprite.texture = TEX_WALK_0

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
