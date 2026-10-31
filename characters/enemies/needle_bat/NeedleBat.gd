class_name NeedleBat
extends EnemyBase

## Needle Bat (خفاش تیغ‌بنفش) - Flying enemy of Act 1.
## Hovers with sinusoidal motion and swoops down at player upon detection.

@export var detection_range: float = 140.0
@export var swoop_speed: float = 130.0
@export var return_speed: float = 75.0

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D

var _home_position: Vector2 = Vector2.ZERO
var _target_player: PlayerController = null
var _is_swooping: bool = false
var _swoop_target: Vector2 = Vector2.ZERO
var _hover_time: float = 0.0

func _ready() -> void:
	super._ready()
	_home_position = global_position
	max_health = 1
	touch_damage = 1
	scrap_drop_count = 1
	if animated_sprite:
		animated_sprite.play("fly")

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	_hover_time += delta
	_locate_player()
	
	if _target_player and not _is_swooping:
		var dist_sq: float = global_position.distance_squared_to(_target_player.global_position)
		if dist_sq < detection_range * detection_range:
			_is_swooping = true
			_swoop_target = _target_player.global_position + Vector2(0, -10)
	
	if _is_swooping:
		# Fly toward swoop target
		var dir: Vector2 = (_swoop_target - global_position).normalized()
		velocity = dir * swoop_speed
		if global_position.distance_squared_to(_swoop_target) < 16.0 * 16.0 or global_position.y >= _swoop_target.y + 10:
			_is_swooping = false # Swoop finished, return home
	else:
		# Return towards home position with sinusoidal hover
		var hover_offset: Vector2 = Vector2(sin(_hover_time * 2.5) * 20.0, cos(_hover_time * 3.0) * 8.0)
		var desired_pos: Vector2 = _home_position + hover_offset
		var dir: Vector2 = (desired_pos - global_position).normalized()
		var dist: float = global_position.distance_to(desired_pos)
		if dist > 4.0:
			velocity = dir * return_speed
		else:
			velocity = Vector2.ZERO
	
	# Flip sprite facing movement
	if not is_zero_approx(velocity.x) and visuals:
		visuals.scale.x = 1.0 if velocity.x > 0 else -1.0
	
	move_and_slide()

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
