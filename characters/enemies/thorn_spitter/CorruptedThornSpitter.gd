class_name CorruptedThornSpitter
extends EnemyBase

## Stationary floral hazard that shoots aimed violet thorn spikes at rhythmic intervals.

@export var fire_interval: float = 2.0
@export var detection_range: float = 200.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D

const THORN_SCENE = preload("res://characters/enemies/thorn_spitter/ThornProjectile.tscn")
const TEX_IDLE = preload("res://assets/sprites/enemies/thorn_spitter/spitter_idle.png")
const TEX_SPIT = preload("res://assets/sprites/enemies/thorn_spitter/spitter_spit.png")

var _timer: float = 0.0
var _is_blooming: bool = false
var _target_player: PlayerController = null

func _ready() -> void:
	max_health = 3
	scrap_drop_count = 2
	touch_damage = 1
	knockback_resistance = 0.0 # Stationary rooted plant
	super._ready()

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	_locate_player()
	
	if not _target_player or not is_instance_valid(_target_player):
		return
	
	var dist: float = global_position.distance_to(_target_player.global_position)
	if dist > detection_range:
		return
	
	_timer += delta
	
	if not _is_blooming and _timer >= fire_interval - 0.4:
		_is_blooming = true
		sprite.texture = TEX_SPIT
		# Pulse squash
		var tween: Tween = create_tween()
		tween.tween_property(visuals, "scale", Vector2(1.2, 0.8), 0.2)
		tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.2)
	
	if _timer >= fire_interval:
		_timer = 0.0
		_is_blooming = false
		_fire_thorn()
		sprite.texture = TEX_IDLE

func _fire_thorn() -> void:
	if not THORN_SCENE or not _target_player:
		return
	var thorn: CharacterBody2D = THORN_SCENE.instantiate() as CharacterBody2D
	if thorn:
		thorn.global_position = global_position + Vector2(0, -12)
		var dir: Vector2 = (_target_player.global_position + Vector2(0, -12)) - thorn.global_position
		if thorn.has_method("launch"):
			thorn.call("launch", dir)
		get_parent().add_child(thorn)

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
