class_name SeismicSunder
extends Node2D

## Bardia's charged Turquoise Resonance: a ground shockwave that shatters
## Marg-Mayeh root barriers and breaks the guard of shielded enemies.
## Travels all the way across the screen (600+ px range).

@export var travel_speed: float = 420.0
@export var lifetime: float = 1.65
@export var barrier_clear_radius: float = 80.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $HitboxComponent

var _direction: float = 1.0
var _timer: float = 0.0

func _ready() -> void:
	if hitbox:
		hitbox.faction = HitboxComponent.Faction.PLAYER
		hitbox.bypass_guard = true
		hitbox.knockback_force = 260.0
	if sprite:
		sprite.flip_h = _direction < 0.0

func launch(direction: float, damage: int) -> void:
	_direction = signf(direction) if not is_zero_approx(direction) else 1.0
	if hitbox:
		hitbox.damage = damage
	if sprite:
		sprite.flip_h = _direction < 0.0
	position.x += _direction * 10.0

func _process(delta: float) -> void:
	_timer += delta
	position.x += _direction * travel_speed * delta
	_clear_marg_mayeh_barriers()
	
	if _timer >= lifetime:
		set_process(false)
		if hitbox:
			hitbox.set_deferred("monitorable", false)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(self, "modulate:a", 0.0, 0.12)
		tween.tween_property(self, "scale", Vector2(1.4, 0.4), 0.12)
		tween.chain().tween_callback(queue_free)

func _clear_marg_mayeh_barriers() -> void:
	for barrier in get_tree().get_nodes_in_group(&"marg_mayeh"):
		if barrier is Node2D:
			var node: Node2D = barrier as Node2D
			if absf(node.global_position.x - global_position.x) < barrier_clear_radius:
				node.queue_free()
