class_name FX
extends RefCounted

## Small library of procedural pixel-art effects shared by bosses and hazards:
## square-particle bursts (dust, debris, sparks), afterimages and flashes.
## Everything is CPU based so it runs on the GL Compatibility renderer used on Android.

## One-shot burst of square pixels. `upward` bursts fan up (dust/debris), otherwise radial (sparks).
static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 14, speed: float = 90.0,
		upward: bool = true, size: float = 3.0, lifetime: float = 0.5) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p: CPUParticles2D = CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.92
	p.amount = amount
	p.lifetime = lifetime
	p.direction = Vector2.UP if upward else Vector2.RIGHT
	p.spread = 70.0 if upward else 180.0
	p.initial_velocity_min = speed * 0.45
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 320.0 if upward else 60.0)
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	p.z_index = 5
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(lifetime + 0.3, false).timeout.connect(p.queue_free)

## Floor dust kicked up by heavy feet or impacts.
static func dust(parent: Node, pos: Vector2, amount: int = 12, speed: float = 80.0) -> void:
	burst(parent, pos, Color(0.62, 0.55, 0.46, 0.9), amount, speed, true, 3.0, 0.55)

## Rock chunks for slams, crashes and death crumbles.
static func debris(parent: Node, pos: Vector2, amount: int = 10, speed: float = 160.0) -> void:
	burst(parent, pos, Color(0.42, 0.44, 0.38, 1.0), amount, speed, true, 4.0, 0.8)

## Bright radial sparks where a hit lands.
static func sparks(parent: Node, pos: Vector2, color: Color = Color(1.0, 0.95, 0.7, 1.0), amount: int = 8) -> void:
	burst(parent, pos, color, amount, 130.0, false, 2.0, 0.28)

## Fading ghost copy of a sprite (charge trails, dashes).
static func afterimage(parent: Node, source: Sprite2D, tint: Color = Color(1.0, 0.35, 0.55, 0.55), fade: float = 0.25) -> void:
	if parent == null or source == null or source.texture == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = source.texture
	ghost.centered = source.centered
	ghost.offset = source.offset
	ghost.flip_h = source.flip_h
	ghost.modulate = tint
	ghost.z_index = -1
	parent.add_child(ghost)
	ghost.global_transform = source.global_transform
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, fade)
	tween.tween_callback(ghost.queue_free)

## Quick overbright flash on any CanvasItem (hit feedback).
static func flash(item: CanvasItem, color: Color = Color(2.2, 2.2, 2.2), duration: float = 0.12) -> void:
	if item == null:
		return
	item.modulate = color
	var tween: Tween = item.create_tween()
	tween.tween_property(item, "modulate", Color.WHITE, duration)
