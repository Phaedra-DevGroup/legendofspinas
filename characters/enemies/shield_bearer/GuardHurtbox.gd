class_name GuardHurtbox
extends HurtboxComponent

## Hurtbox that deflects attacks arriving from the shielded side.
## Charged (Turquoise Resonance) hits bypass the guard and break it instead.

signal guarded(hitbox: HitboxComponent)
signal guard_broken(hitbox: HitboxComponent)

func _can_be_hurt_by(hitbox: HitboxComponent) -> bool:
	var bearer: CorruptedShieldBearer = get_parent() as CorruptedShieldBearer
	if bearer == null or bearer.is_stunned:
		return true
	if hitbox.bypass_guard:
		guard_broken.emit(hitbox)
		return true
	
	# Determine if hit came from the front (shielded side)
	var is_frontal: bool = false
	var proj_parent = hitbox.get_parent()
	if proj_parent and "velocity" in proj_parent and absf(proj_parent.velocity.x) > 10.0:
		# Flying projectile: hits front if moving against bearer's facing direction
		var travel_dir: float = signf(proj_parent.velocity.x)
		is_frontal = (travel_dir == -bearer._facing_direction)
	else:
		# Melee or stationary attack: evaluate attacker entity's origin rather than the forward-extending hitbox edge
		var attacker_x: float = hitbox.global_position.x
		if hitbox.owner and hitbox.owner is Node2D:
			attacker_x = (hitbox.owner as Node2D).global_position.x
		elif proj_parent and proj_parent is Node2D:
			attacker_x = (proj_parent as Node2D).global_position.x
		
		is_frontal = (signf(attacker_x - bearer.global_position.x) == bearer._facing_direction)
	
	if not is_frontal:
		return true
	
	guarded.emit(hitbox)
	return false
