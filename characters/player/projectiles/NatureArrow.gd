class_name NatureArrow
extends CharacterBody2D

## Projectile for Rojan's Nature Bow attack.
## Travels forward with green/turquoise nature magic trail and damages enemies on impact.
## The charged Gale Piercer flies turquoise and punches through up to 3 enemies.

@export var speed: float = 380.0
@export var lifetime: float = 2.0
@export var damage: int = 1
@export var pierce: int = 0

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var sprite: Sprite2D = $Sprite2D

var direction: float = 1.0
var _timer: float = 0.0
var _hits: int = 0

func _ready() -> void:
	if hitbox:
		hitbox.damage = damage
		hitbox.faction = HitboxComponent.Faction.PLAYER
		hitbox.knockback_force = 140.0
		hitbox.hit_landed.connect(_on_hit_landed)
		hitbox.hit_blocked.connect(_on_hit_blocked)
	
	# Rotate or flip sprite based on travel direction
	if sprite:
		sprite.flip_h = direction < 0.0
		if pierce > 0:
			sprite.modulate = Color(0.4, 1.6, 1.5, 1.0)

func set_direction(dir: float) -> void:
	direction = signf(dir)
	if is_zero_approx(direction):
		direction = 1.0
	velocity = Vector2(direction * speed, 0.0)
	if sprite:
		sprite.flip_h = direction < 0.0

func set_damage(amount: int) -> void:
	damage = amount
	if hitbox:
		hitbox.damage = amount

func set_pierce(count: int) -> void:
	pierce = count
	if sprite and count > 0:
		sprite.modulate = Color(0.4, 1.6, 1.5, 1.0)

func set_guard_breaker(enabled: bool) -> void:
	if hitbox:
		hitbox.bypass_guard = enabled

func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()
		return
	
	velocity = Vector2(direction * speed, 0.0)
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		_impact_and_destroy()

func _on_hit_landed(_hurtbox: HurtboxComponent) -> void:
	_hits += 1
	if _hits > pierce:
		_impact_and_destroy()

func _on_hit_blocked(_hurtbox: HurtboxComponent) -> void:
	# Deflected by a raised shield
	_impact_and_destroy()

func _impact_and_destroy() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "arrow_hit")
	# Quick scale pop and delete
	set_physics_process(false)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 0.1), 0.06)
	tween.tween_callback(queue_free)
