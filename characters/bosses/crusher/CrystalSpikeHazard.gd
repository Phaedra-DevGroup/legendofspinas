class_name CrystalSpikeHazard
extends Node2D

## Corrupted ground spike erupted during Crusher's seismic attacks.

@export var duration: float = 1.3
@export var damage: int = 1

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group(&"boss_projectiles")
	if hitbox:
		hitbox.damage = damage
		hitbox.faction = HitboxComponent.Faction.ENEMY
		hitbox.knockback_force = 160.0
	
	# Eruption animation: emerge rapidly from ground
	scale = Vector2(1.0, 0.05)
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration)
	tween.tween_property(self, "scale:y", 0.0, 0.2)
	tween.tween_callback(queue_free)
