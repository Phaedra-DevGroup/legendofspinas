class_name ThrownRockProjectile
extends CharacterBody2D

## Arcing boulder projectile thrown by Crusher of the Ruins.

@export var gravity: float = 650.0
@export var damage: int = 1

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var _rotation_speed: float = 6.0

func _ready() -> void:
	add_to_group(&"boss_projectiles")
	if hitbox:
		hitbox.damage = damage
		hitbox.faction = HitboxComponent.Faction.ENEMY
		hitbox.knockback_force = 180.0

func launch(initial_velocity: Vector2) -> void:
	velocity = initial_velocity

func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	if sprite:
		sprite.rotation += _rotation_speed * delta
	
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		queue_free()
