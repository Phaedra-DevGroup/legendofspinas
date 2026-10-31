class_name RootSpike
extends Node2D

## A thorned root that bursts out of the forest floor (ضربه ریشه از کف زمین).
## Telegraphs with a glowing crack and trembling soil, erupts, lingers, then sinks back.

@export var warn_time: float = 0.6
@export var up_time: float = 0.45
@export var damage: int = 1

@onready var root_sprite: Sprite2D = $Root
@onready var crack: Polygon2D = $Crack
@onready var hitbox: HitboxComponent = $HitboxComponent

var _root_rest_y: float = 0.0

func _ready() -> void:
	hitbox.damage = damage
	hitbox.faction = HitboxComponent.Faction.ENEMY
	hitbox.set_deferred("monitorable", false)
	_root_rest_y = root_sprite.position.y
	root_sprite.position.y = _root_rest_y + root_sprite.texture.get_height()
	root_sprite.visible = false
	crack.modulate.a = 0.0
	_run()

func _run() -> void:
	# Warning: a pulsing violet crack and kicked-up soil
	var warn: Tween = create_tween()
	warn.tween_property(crack, "modulate:a", 1.0, warn_time * 0.3)
	warn.tween_property(crack, "scale:x", 1.25, warn_time * 0.35).set_trans(Tween.TRANS_SINE)
	warn.tween_property(crack, "scale:x", 1.0, warn_time * 0.35).set_trans(Tween.TRANS_SINE)
	FX.dust(get_parent(), global_position, 5, 40.0)
	await warn.finished
	if not is_inside_tree():
		return

	# Eruption
	root_sprite.visible = true
	hitbox.monitorable = true
	FX.debris(get_parent(), global_position, 6, 130.0)
	ScreenShake.add_trauma(0.12)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.15, -9.0)
	var rise: Tween = create_tween()
	rise.tween_property(root_sprite, "position:y", _root_rest_y, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(up_time, false).timeout
	if not is_inside_tree():
		return

	# Retract
	hitbox.set_deferred("monitorable", false)
	var sink: Tween = create_tween().set_parallel(true)
	sink.tween_property(root_sprite, "position:y", _root_rest_y + root_sprite.texture.get_height(), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sink.tween_property(crack, "modulate:a", 0.0, 0.3)
	await sink.finished
	queue_free()
