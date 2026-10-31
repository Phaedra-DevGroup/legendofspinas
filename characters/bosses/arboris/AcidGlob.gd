class_name AcidGlob
extends Node2D

## Lobbed blob of Marg-mayeh acid (گلوله اسیدی) from the Corrupted Arboris.
## Flies on a ballistic arc, hurts on contact and splashes into a short-lived acid puddle.

const PUDDLE_SCENE = preload("res://characters/hazards/AcidPool.tscn")
const GRAVITY: float = 620.0

@export var floor_y: float = 320.0
@export var puddle_width: float = 44.0
@export var puddle_lifetime: float = 2.6

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: HitboxComponent = $HitboxComponent

var velocity: Vector2 = Vector2.ZERO
var _trail_timer: float = 0.0

func _ready() -> void:
	hitbox.faction = HitboxComponent.Faction.ENEMY
	hitbox.hit_landed.connect(func(_hurtbox: HurtboxComponent): _splash(false))

## Fire so the glob lands at `target_x` after `flight_time` seconds.
func launch_to(target_x: float, flight_time: float) -> void:
	var dx: float = target_x - global_position.x
	var dy: float = floor_y - global_position.y
	velocity.x = dx / flight_time
	velocity.y = (dy - 0.5 * GRAVITY * flight_time * flight_time) / flight_time

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	global_position += velocity * delta
	sprite.rotation += delta * 9.0
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.05
		FX.burst(get_parent(), global_position, Color(0.55, 0.9, 0.3, 0.7), 2, 20.0, false, 2.0, 0.3)
	if global_position.y >= floor_y:
		global_position.y = floor_y
		_splash(true)

func _splash(leave_puddle: bool) -> void:
	set_physics_process(false)
	FX.burst(get_parent(), global_position, Color(0.6, 1.0, 0.35, 0.95), 10, 90.0, true, 2.5, 0.45)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "enemy_hit", 0.25, -6.0)
	if leave_puddle and PUDDLE_SCENE:
		var puddle: AcidPool = PUDDLE_SCENE.instantiate() as AcidPool
		puddle.width = puddle_width
		puddle.lifetime = puddle_lifetime
		get_parent().call_deferred("add_child", puddle)
		puddle.set_deferred("global_position", Vector2(global_position.x, floor_y))
	queue_free()
