class_name BlightedWolf
extends EnemyBase

## Blighted Wolf (سایه‌گرگ فاسد) - Agile ground enemy of Act 1.
## Patrols platforms, turns at ledges and walls, and charges forward when player is in sight.

@export var patrol_speed: float = 60.0
@export var charge_speed: float = 145.0
@export var gravity: float = 850.0
@export var vision_range: float = 120.0

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var floor_detector: RayCast2D = $Visuals/FloorDetector

var _facing_direction: float = 1.0
var _is_charging: bool = false
var _target_player: PlayerController = null

func _ready() -> void:
	super._ready()
	max_health = 2
	touch_damage = 1
	scrap_drop_count = 2
	if animated_sprite:
		animated_sprite.play("run")

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	
	_locate_player()
	
	# Check if player is ahead in sight
	_is_charging = false
	if _target_player and is_instance_valid(_target_player):
		var diff: Vector2 = _target_player.global_position - global_position
		# If within range and roughly on the same vertical level
		if absf(diff.y) < 40.0 and absf(diff.x) < vision_range:
			if signf(diff.x) == _facing_direction:
				_is_charging = true
	
	# Edge / Wall detection for turning
	if is_on_floor():
		var at_wall: bool = is_on_wall()
		var at_ledge: bool = floor_detector and not floor_detector.is_colliding()
		if at_wall or at_ledge:
			_facing_direction = -_facing_direction
	
	var current_speed: float = charge_speed if _is_charging else patrol_speed
	velocity.x = _facing_direction * current_speed
	
	# Visual orientation
	if visuals:
		visuals.scale.x = _facing_direction
	
	move_and_slide()

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
