class_name PlayerGrappleState
extends PlayerState

## Bardia's Grappling Hook: latch onto bronze ceiling rings and swing across gaps.
## Release with Jump (leap off) or Interact/Grapple (let go).
##
## Simulated as a true pendulum (angle + angular velocity) instead of nudging the body's velocity
## and teleporting it back onto the rope: the old hard constraint could shove the hero into
## platforms, where the swing stalled and looked frozen.

## Tangential gravity driving the pendulum.
@export var swing_gravity: float = 900.0
## Angular acceleration (rad/s²) added by holding left/right.
@export var pump_acceleration: float = 6.5
@export var max_angular_speed: float = 4.4
## Fraction of angular speed lost per second (keeps swings from building forever).
@export var damping: float = 0.12
## The rope reels toward this length so every swing has a usable arc.
@export var target_rope_length: float = 74.0
@export var reel_speed: float = 110.0
## Speed multiplier applied when letting go, so releases carry the hero across gaps.
@export var release_boost: float = 1.15

const MIN_ROPE: float = 44.0
const MAX_SWING_ANGLE: float = 1.4
const ROPE_SHOOT_TIME: float = 0.09
## Rope attaches at the hands, roughly this far above the feet.
const HAND_OFFSET: Vector2 = Vector2(0, -28)

var anchor: Vector2 = Vector2.ZERO
var rope_length: float = 0.0
var angle: float = 0.0
var angular_velocity: float = 0.0
var _rope_timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	anchor = player.find_grapple_anchor()
	if anchor == Vector2.ZERO:
		# Never transition from inside enter(); let the machine finish this switch first
		state_machine.call_deferred("transition_to", "Fall")
		return
	var offset: Vector2 = _hand_position() - anchor
	rope_length = clampf(offset.length(), MIN_ROPE, player.GRAPPLE_RANGE)
	angle = clampf(atan2(offset.x, offset.y), -MAX_SWING_ANGLE, MAX_SWING_ANGLE)
	# Carry the hero's momentum into the swing
	angular_velocity = player.velocity.dot(_tangent()) / rope_length
	# A dead-still hang reads as a freeze: always start with a swing toward where the hero faces
	if absf(angular_velocity) < 1.4:
		angular_velocity = 1.8 * player.facing_direction
	_rope_timer = 0.0
	player.reset_air_abilities()
	player.play_animation(&"jump")
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "grapple_shoot")
		get_node("/root/AudioManager").call("play_sfx", "grapple_latch", 0.05, -4.0)

func exit() -> void:
	player.set_grapple_rope(Vector2.ZERO, false)
	if player.visuals:
		player.visuals.rotation = 0.0
		player.visuals.position = Vector2.ZERO

func physics_update(delta: float) -> void:
	if anchor == Vector2.ZERO:
		return
	if Input.is_action_just_pressed(&"jump"):
		_release()
		state_machine.transition_to("Jump")
		return
	if Input.is_action_just_pressed(&"grapple") or Input.is_action_just_pressed(&"interact"):
		_release()
		state_machine.transition_to("Fall")
		return

	# Pendulum integration
	var input_direction: float = player.get_input_direction()
	var angular_accel: float = -(swing_gravity / rope_length) * sin(angle) + input_direction * pump_acceleration
	angular_velocity += angular_accel * delta
	angular_velocity *= 1.0 - damping * delta
	angular_velocity = clampf(angular_velocity, -max_angular_speed, max_angular_speed)
	angle += angular_velocity * delta
	if absf(angle) > MAX_SWING_ANGLE:
		angle = signf(angle) * MAX_SWING_ANGLE
		angular_velocity *= -0.3
	rope_length = move_toward(rope_length, target_rope_length, reel_speed * delta)

	# Drive the body toward its point on the arc; collisions resolve normally
	var target_hand: Vector2 = anchor + Vector2(sin(angle), cos(angle)) * rope_length
	var target_feet: Vector2 = target_hand - HAND_OFFSET
	player.velocity = (target_feet - player.global_position) / maxf(delta, 0.0001)
	player.move_and_slide()

	if player.get_slide_collision_count() > 0:
		# Blocked by a wall/platform: bounce back and resync the angle with where the body really is
		var actual: Vector2 = _hand_position() - anchor
		angle = clampf(atan2(actual.x, actual.y), -MAX_SWING_ANGLE, MAX_SWING_ANGLE)
		rope_length = clampf(actual.length(), MIN_ROPE, player.GRAPPLE_RANGE)
		angular_velocity *= -0.35
		if player.is_on_floor():
			player.velocity = Vector2.ZERO
			state_machine.transition_to("Idle")
			return

	if absf(angular_velocity) > 0.35:
		player.update_facing_direction(signf(angular_velocity))
	_update_visuals(delta)

## Converts the swing into regular velocity when letting go.
func _release() -> void:
	player.velocity = _tangent() * angular_velocity * rope_length * release_boost
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "jump", 0.08, -3.0)

## Direction of motion for a positive angular velocity at the current angle.
func _tangent() -> Vector2:
	return Vector2(cos(angle), -sin(angle))

func _hand_position() -> Vector2:
	return player.global_position + HAND_OFFSET

func _update_visuals(delta: float) -> void:
	# Hook flies out first, then the rope stays taut from the hands
	_rope_timer = minf(_rope_timer + delta, ROPE_SHOOT_TIME)
	var t: float = _rope_timer / ROPE_SHOOT_TIME
	var hand: Vector2 = _hand_position()
	if player.grapple_rope:
		player.grapple_rope.visible = true
		player.grapple_rope.points = PackedVector2Array([HAND_OFFSET, player.to_local(hand.lerp(anchor, t))])
	# Lean the body along the rope, pivoting around the hands rather than the feet
	if player.visuals:
		var lean: float = -angle * 0.75
		player.visuals.rotation = lean
		player.visuals.position = HAND_OFFSET - HAND_OFFSET.rotated(lean)
