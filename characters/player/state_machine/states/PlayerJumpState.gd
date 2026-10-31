class_name PlayerJumpState
extends PlayerState

## Handles upward jump impulse, variable jump cut-off, and air control.

## A quick tap still clears this many pixels (the highest ground ledges sit ~76px up), so short
## mobile taps are never punished; holding the button gives the full ~82px leap.
@export var min_jump_height: float = 78.0

var _jump_cut_done: bool = false
var _takeoff_y: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"jump")
	player.floor_snap_length = 0.0
	player.velocity.y = player.jump_velocity
	_jump_cut_done = false
	_takeoff_y = player.global_position.y
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "jump")

func physics_update(delta: float) -> void:
	# Variable jump height: releasing early trims the rise down to the guaranteed minimum (once per
	# jump). The cut may only ever slow the hero - the old minf() here *raised* upward speed on every
	# release, which let players climb forever by tapping jump.
	if not _jump_cut_done and Input.is_action_just_released(&"jump") and player.velocity.y < 0.0:
		_jump_cut_done = true
		var risen: float = _takeoff_y - player.global_position.y
		var remaining: float = maxf(0.0, min_jump_height - risen)
		var needed_speed: float = -sqrt(2.0 * player.gravity * remaining)
		player.velocity.y = maxf(player.velocity.y, needed_speed)
	
	# Attack in mid-air
	if Input.is_action_just_pressed(&"attack"):
		state_machine.transition_to("Attack")
		return
	
	# Grappling Hook (Bardia / Rojan: Grapple or Interact while airborne near a bronze ring)
	if (Input.is_action_just_pressed(&"grapple") or Input.is_action_just_pressed(&"interact")) and player.can_grapple():
		state_machine.transition_to("Grapple")
		return
	
	# Check for wall-jump or double-jump
	if Input.is_action_just_pressed(&"jump"):
		if player.can_wall_jump():
			var wall_norm: Vector2 = player.get_wall_normal()
			player.velocity.x = wall_norm.x * player.speed * 1.3
			player.velocity.y = player.jump_velocity * 0.95
			player.update_facing_direction(wall_norm.x)
			player.has_wall_jumped = true
			player.consume_double_jump()
			player.floor_snap_length = 0.0
			player.play_animation(&"jump")
			if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
				get_node("/root/AudioManager").call("play_sfx", "jump")
			return
		elif player.can_perform_double_jump():
			player.consume_double_jump()
			player.floor_snap_length = 0.0
			player.velocity.y = player.jump_velocity
			_jump_cut_done = false
			_takeoff_y = player.global_position.y
			player.play_animation(&"jump")
			if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
				get_node("/root/AudioManager").call("play_sfx", "double_jump")
			return
	
	# Air horizontal steering
	var direction: float = player.get_input_direction()
	if not is_zero_approx(direction):
		player.update_facing_direction(direction)
		player.apply_air_acceleration(direction, delta)
	else:
		player.apply_air_friction(delta)
	
	# Apply gravity
	player.apply_gravity(delta)
	player.move_and_slide()
	
	# Landed on floor directly
	if player.is_on_floor() and player.velocity.y >= 0.0:
		player.floor_snap_length = 4.0
		player.reset_air_abilities()
		if not is_zero_approx(player.get_input_direction()):
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
		return
	
	# Transition to fall once vertical velocity turns downward
	if player.velocity.y >= 0.0:
		state_machine.transition_to("Fall")
