class_name ArborisBarkHurtbox
extends HurtboxComponent

## The Arboris' ironbark shrugs off attacks from the front; only blows from behind reach the
## Marg-mayeh crystal in its back. While its arms are buried after a slam it is open from any side.

signal deflected(hit_position: Vector2)

var boss: CorruptedArboris = null

func _can_be_hurt_by(hitbox: HitboxComponent) -> bool:
	if boss == null or boss.is_crystal_exposed():
		return true
	var facing: float = boss.get_facing()
	var is_frontal: bool = false
	var source: Node = hitbox.get_parent()
	if source and "velocity" in source and absf(source.velocity.x) > 10.0:
		# Projectile: frontal when it flies against the way the tree faces
		is_frontal = signf(source.velocity.x) == -facing
	else:
		# Melee: judge by where the attacker stands, not the reach of the swing
		var attacker_x: float = hitbox.global_position.x
		if hitbox.owner is Node2D:
			attacker_x = (hitbox.owner as Node2D).global_position.x
		elif source is Node2D:
			attacker_x = (source as Node2D).global_position.x
		is_frontal = signf(attacker_x - boss.global_position.x) == facing
	if is_frontal:
		deflected.emit(hitbox.global_position)
		return false
	return true
