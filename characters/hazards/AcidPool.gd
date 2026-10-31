class_name AcidPool
extends Node2D

## Pool of bubbling Marg-mayeh acid (چشمه اسیدی). Burns the hero and pops them back up
## so a misjudged mushroom bounce costs a heart instead of a long walk back.
## `width` stretches the tiled surface, the damage area and the bubbles together.

@export var width: float = 96.0
## Temporary puddles (left by the Arboris' acid globs) shrink away after this many seconds; 0 = permanent.
@export var lifetime: float = 0.0

@onready var surface: Sprite2D = $Surface
@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var shape: CollisionShape2D = $HitboxComponent/CollisionShape2D
@onready var bubbles: CPUParticles2D = $Bubbles

var _time: float = 0.0

func _ready() -> void:
	_apply_width()
	if lifetime > 0.0:
		var fade: Tween = create_tween()
		fade.tween_interval(lifetime)
		fade.tween_property(self, "scale:x", 0.0, 0.5)
		fade.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
		fade.tween_callback(queue_free)

func _apply_width() -> void:
	if surface and surface.texture:
		surface.region_enabled = true
		surface.region_rect = Rect2(0, 0, width, surface.texture.get_height())
	if shape:
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(width - 6.0, 12.0)
		shape.shape = rect
	if bubbles:
		bubbles.emission_rect_extents = Vector2(width * 0.45, 2.0)
		bubbles.amount = maxi(3, int(width / 14.0))

func _process(delta: float) -> void:
	# Slow churn of the acid surface
	_time += delta
	if surface:
		surface.region_rect.position.x = fmod(_time * 6.0, 32.0)
		var glow: float = 1.0 + sin(_time * 3.0) * 0.12
		surface.modulate = Color(glow, glow, glow, 1.0)
