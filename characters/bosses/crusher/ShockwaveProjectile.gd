class_name ShockwaveProjectile
extends CharacterBody2D

## Ground Shockwave emitted by Crusher's ground slam.
## Travels across floor dealing damage to player.

@export var speed: float = 160.0
@export var lifetime: float = 1.8
@export var damage: int = 1

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var direction: float = 1.0
var _timer: float = 0.0

func _ready() -> void:
	add_to_group(&"boss_projectiles")
	if hitbox:
		hitbox.damage = damage
		hitbox.faction = HitboxComponent.Faction.ENEMY
		hitbox.knockback_force = 190.0
	if sprite:
		sprite.flip_h = direction < 0.0

func set_direction(dir: float) -> void:
	direction = signf(dir)
	if is_zero_approx(direction):
		direction = 1.0
	velocity = Vector2(direction * speed, 0.0)
	if sprite:
		sprite.flip_h = direction < 0.0

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()
		return
	
	velocity = Vector2(direction * speed, 0.0)
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		queue_free()
