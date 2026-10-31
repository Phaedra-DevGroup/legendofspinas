class_name MargMayehThorns
extends Node2D

## Toxic purple thorns of Marg-mayeh (خارهای سمی مرگ‌مایه).
## Deals hazard damage and knocks the player upward/away upon contact.

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var _pulse_time: float = 0.0

func _ready() -> void:
	if hitbox:
		hitbox.faction = HitboxComponent.Faction.HAZARD
		hitbox.damage = 1
		hitbox.knockback_force = 220.0

func _process(delta: float) -> void:
	_pulse_time += delta
	# Subtle eerie glow breathing effect
	if sprite:
		var glow: float = 0.9 + sin(_pulse_time * 4.0) * 0.15
		sprite.modulate = Color(glow, glow * 0.8, glow * 1.2, 1.0)
