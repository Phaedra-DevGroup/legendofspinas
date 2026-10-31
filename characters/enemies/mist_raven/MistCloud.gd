class_name MistCloud
extends Node2D

## Lingering purple mist left behind by the Mist Raven's dive.
## Damages the hero on contact and fades away after a short while.

@export var lifetime: float = 2.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $HitboxComponent

var _timer: float = 0.0

func _ready() -> void:
	if hitbox:
		hitbox.faction = HitboxComponent.Faction.HAZARD
		hitbox.damage = 1
		hitbox.knockback_force = 120.0
	if sprite:
		sprite.scale = Vector2(0.7, 0.7)
		var grow: Tween = create_tween()
		grow.tween_property(sprite, "scale", Vector2(1.15, 1.15), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var drift: Tween = create_tween().set_loops()
		drift.tween_property(sprite, "position:y", -4.0, 0.6).set_trans(Tween.TRANS_SINE)
		drift.tween_property(sprite, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		set_process(false)
		if hitbox:
			hitbox.set_deferred("monitorable", false)
		var fade: Tween = create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.35)
		fade.tween_callback(queue_free)
