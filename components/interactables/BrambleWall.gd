class_name BrambleWall
extends StaticBody2D

## Dense wall of thorny Marg-mayeh vines (دیواره پیچک‌های تیغ‌دار) blocking a path.
## Solid and painful to touch until something withers it (Atousa's light, the Arboris' fall).

signal withered()

@export var wall_height: float = 120.0

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var vines: Node2D = $Vines

var is_open: bool = false
var _time: float = 0.0

func _ready() -> void:
	_time = randf() * TAU

func _process(delta: float) -> void:
	if is_open:
		return
	# The vines writhe slowly
	_time += delta
	for i in vines.get_child_count():
		var vine: Node2D = vines.get_child(i) as Node2D
		vine.rotation = sin(_time * 1.6 + i * 1.3) * 0.04

func wither() -> void:
	if is_open:
		return
	is_open = true
	collision.set_deferred("disabled", true)
	hitbox.set_deferred("monitorable", false)
	ScreenShake.add_trauma(0.3)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "beacon_ignite", 0.05, -4.0)
	for i in 4:
		FX.burst(get_parent(), global_position + Vector2(randf_range(-10, 10), -wall_height * randf()), Color(0.75, 0.4, 1.0, 0.9), 8, 80.0, false, 2.5, 0.6)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(vines, "modulate", Color(0.35, 0.25, 0.2, 0.0), 1.1)
	tween.tween_property(vines, "scale:y", 0.15, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func(): visible = false)
	withered.emit()
