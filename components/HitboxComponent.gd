class_name HitboxComponent
extends Area2D

## Hitbox component that deals damage upon overlapping valid HurtboxComponents.
## Distinguishes between player attacks, enemy attacks, and environmental hazards.

enum Faction {
	PLAYER,
	ENEMY,
	HAZARD
}

signal hit_landed(hurtbox: HurtboxComponent)
signal hit_blocked(hurtbox: HurtboxComponent)

@export var faction: Faction = Faction.PLAYER
@export var damage: int = 1
@export var knockback_force: float = 160.0
@export var is_active: bool = true
## Charged (Turquoise Resonance) attacks bypass shields and break guards.
@export var bypass_guard: bool = false
## Creator entity this hitbox must never damage (e.g. a raven and its own mist trail).
var ignore_owner: Node = null

func _ready() -> void:
	# Ensure monitorable is active for collision detection
	monitorable = true
	monitoring = false

## Called by the receiving HurtboxComponent once damage was applied.
func notify_hit(hurtbox: HurtboxComponent) -> void:
	if faction == Faction.PLAYER:
		ScreenShake.add_trauma(0.1)
		ScreenShake.hitstop(0.04)
	hit_landed.emit(hurtbox)

## Called by the receiving HurtboxComponent when the hit was deflected by a guard.
func notify_blocked(hurtbox: HurtboxComponent) -> void:
	hit_blocked.emit(hurtbox)
