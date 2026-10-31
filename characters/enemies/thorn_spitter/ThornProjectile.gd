class_name ThornProjectile
extends CharacterBody2D

## Linear violet thorn projectile fired by Corrupted Thorn Spitter.

@export var speed: float = 140.0
@export var lifetime: float = 2.4
@export var damage: int = 1

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var _direction: Vector2 = Vector2.LEFT
var _timer: float = 0.0

func _ready() -> void:
	if hitbox:
		hitbox.damage = damage
		hitbox.faction = HitboxComponent.Faction.ENEMY
		hitbox.knockback_force = 120.0
		# Thorns shatter on the hero instead of flying through them
		hitbox.hit_landed.connect(func(_hurtbox: HurtboxComponent): queue_free())

func launch(target_dir: Vector2) -> void:
	_direction = target_dir.normalized()
	rotation = _direction.angle()
	velocity = _direction * speed

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()
		return
	
	velocity = _direction * speed
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		queue_free()
