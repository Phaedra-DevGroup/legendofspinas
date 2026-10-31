class_name PlayerFallState
extends PlayerState

## Handles downward falling physics, coyote-time forgiveness, and jump buffering.

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

func enter(msg: Dictionary = {}) -> void:
	player.play_animation(&"fall")
	_jump_buffer_timer = 0.0
	
	if msg.get("coyote_eligible", false):
		_coyote_timer = player.coyote_time
	else:
		_coyote_timer = 0.0

func physics_update(delta: float) -> void:
	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	
	if _jump_buffer_timer > 0.0:
		_jump_buffer_timer -= delta
	
	# Jump input check
	if Input.is_action_just_pressed(&"jump"):
		if player.can_wall_jump():
			var wall_norm: Vector2 = player.get_wall_normal()
			player.velocity.x = wall_norm.x * player.speed * 1.3
			player.velocity.y = player.jump_velocity * 0.95
			player.update_facing_direction(wall_norm.x)
			player.has_wall_jumped = true
			player.consume_double_jump()
			state_machine.transition_to("Jump")
			return
		elif _coyote_timer > 0.0:
			state_machine.transition_to("Jump")
			return
		elif player.can_perform_double_jump():
			player.consume_double_jump()
			state_machine.transition_to("Jump")
			return
		else:
			# Buffer jump for responsive landing
			_jump_buffer_timer = player.jump_buffer_time
	
	if Input.is_action_just_pressed(&"attack"):
		state_machine.transition_to("Attack")
		return
	
	# Grappling Hook (Bardia / Rojan: Grapple or Interact while airborne near a bronze ring)
	if (Input.is_action_just_pressed(&"grapple") or Input.is_action_just_pressed(&"interact")) and player.can_grapple():
		state_machine.transition_to("Grapple")
		return
	
	# Horizontal air control
	var direction: float = player.get_input_direction()
	if not is_zero_approx(direction):
		player.update_facing_direction(direction)
		player.apply_air_acceleration(direction, delta)
	else:
		player.apply_air_friction(delta)
	
	# Apply downward gravity with fall multiplier for snappy feel
	player.apply_fall_gravity(delta)
	player.move_and_slide()
	
	# Landed on floor
	if player.is_on_floor():
		player.floor_snap_length = 4.0
		player.reset_air_abilities()
		if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "land")
		
		if _jump_buffer_timer > 0.0:
			state_machine.transition_to("Jump")
		elif (Input.is_action_pressed(&"move_down") or Input.is_action_just_pressed(&"move_down")) and player.can_slide():
			state_machine.transition_to("Slide")
		elif not is_zero_approx(player.get_input_direction()):
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
