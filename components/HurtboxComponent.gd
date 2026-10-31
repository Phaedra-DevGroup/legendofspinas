class_name HurtboxComponent
extends Area2D

## Hurtbox component that receives damage from opposing HitboxComponents.
## Routes damage to an associated HealthComponent and applies knockback.

signal hit_received(damage: int, attacker_hitbox: HitboxComponent)

@export var faction: HitboxComponent.Faction = HitboxComponent.Faction.PLAYER
@export var health_component: HealthComponent

func _ready() -> void:
	monitoring = true
	monitorable = false
	area_entered.connect(_on_area_entered)

## The hero keeps taking contact damage while standing inside thorns or an enemy body:
## area_entered alone would only fire once, letting players idle inside hazards after i-frames.
func _physics_process(_delta: float) -> void:
	if faction != HitboxComponent.Faction.PLAYER or not monitoring:
		return
	if not is_instance_valid(health_component) or health_component.is_invulnerable:
		return
	for area in get_overlapping_areas():
		if area is HitboxComponent and (area as HitboxComponent).monitorable:
			_on_area_entered(area)
			if health_component.is_invulnerable:
				break

func _on_area_entered(area: Area2D) -> void:
	if not (area is HitboxComponent):
		return
	
	var hitbox: HitboxComponent = area as HitboxComponent
	if not hitbox.is_active:
		return
	
	# Faction discrimination:
	# 1. Enemies are immune to hazards, friendly fire, and each other; ONLY player attacks can hurt enemies.
	if faction == HitboxComponent.Faction.ENEMY and hitbox.faction != HitboxComponent.Faction.PLAYER:
		return
	
	# 2. Same-faction discrimination (players don't hurt players)
	if hitbox.faction == faction:
		return
	
	# Creators never damage themselves (e.g. a mist raven flying through its own trail)
	if hitbox.ignore_owner != null and hitbox.ignore_owner == get_parent():
		return
	
	# Guard check (e.g. shield-bearer deflecting frontal attacks)
	if not _can_be_hurt_by(hitbox):
		hitbox.notify_blocked(self)
		return
	
	# Calculate directional knockback vector pointing away from hitbox
	var knockback_dir: Vector2 = (global_position - hitbox.global_position).normalized()
	if is_zero_approx(knockback_dir.length_squared()):
		knockback_dir = Vector2.UP
	
	var knockback_vector: Vector2 = knockback_dir * hitbox.knockback_force
	
	if is_instance_valid(health_component):
		var applied: bool = health_component.take_damage(hitbox.damage, knockback_vector)
		if applied:
			hit_received.emit(hitbox.damage, hitbox)
			hitbox.notify_hit(self)

## Override in subclasses (e.g. GuardHurtbox) to deflect incoming hits.
func _can_be_hurt_by(_hitbox: HitboxComponent) -> bool:
	return true
