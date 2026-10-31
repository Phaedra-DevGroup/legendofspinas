class_name FallingStalactite
extends CharacterBody2D

## Ceiling Stalactite dislodged by Crusher's wall impact.
## Shows a ground warning indicator before plummeting down.

@export var fall_speed: float = 380.0
@export var damage: int = 1

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var reticle_sprite: Sprite2D = $ReticleSprite

var _is_falling: bool = false
var _warning_timer: float = 0.55
var _target_ground_y: float = 340.0

func _ready() -> void:
	add_to_group(&"boss_projectiles")
	if hitbox:
		hitbox.damage = damage
		hitbox.faction = HitboxComponent.Faction.ENEMY
		hitbox.knockback_force = 150.0
		hitbox.monitoring = false
		hitbox.monitorable = false
	
	if reticle_sprite:
		reticle_sprite.top_level = true
		reticle_sprite.global_position = Vector2(global_position.x, _target_ground_y)
		var tween: Tween = create_tween().set_loops(2)
		tween.tween_property(reticle_sprite, "modulate:a", 0.3, 0.14)
		tween.tween_property(reticle_sprite, "modulate:a", 1.0, 0.14)

func setup(ground_y: float) -> void:
	_target_ground_y = ground_y
	if reticle_sprite:
		reticle_sprite.global_position = Vector2(global_position.x, _target_ground_y)

func _physics_process(delta: float) -> void:
	if not _is_falling:
		_warning_timer -= delta
		if _warning_timer <= 0.0:
			_is_falling = true
			if hitbox:
				hitbox.monitorable = true
			if reticle_sprite:
				reticle_sprite.queue_free()
		return
	
	velocity.y = fall_speed
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision or global_position.y >= _target_ground_y:
		_shatter()

func _shatter() -> void:
	set_physics_process(false)
	if hitbox:
		hitbox.set_deferred("monitorable", false)
	# Shatter dust fade
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.2), 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
	await tween.finished
	queue_free()
