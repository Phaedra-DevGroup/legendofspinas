class_name AncientScrapCollectible
extends Area2D

## Collectible Ancient Scrap (قطعه باستانی) dropped by enemies or found in world.
## Can be spent at Master Poolad's anvil for upgrades.

@export var scrap_value: int = 1
@export var magnet_speed: float = 180.0

@onready var sprite: Sprite2D = $Sprite2D

var _player: PlayerController = null
var _base_y: float = 0.0
var _time_alive: float = 0.0

func _ready() -> void:
	_base_y = position.y
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time_alive += delta
	# Floating bob effect if not pulled to player
	if not _player and sprite:
		sprite.position.y = sin(_time_alive * 5.0) * 3.0
	elif _player:
		# Magnet pull to player
		var dir: Vector2 = (_player.global_position + Vector2(0, -18) - global_position).normalized()
		global_position += dir * magnet_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player = body
		_collect(body as PlayerController)

func _collect(player: PlayerController) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "pickup_scrap")
	set_deferred("monitoring", false)
	player.add_scraps(scrap_value)
	
	# Pickup pop effect
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	await tween.finished
	queue_free()
