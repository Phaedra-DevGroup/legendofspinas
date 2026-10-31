class_name PlayerIdleState
extends PlayerState

## Handles idle behavior when player is resting on solid ground.

func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"idle")
	player.reset_air_abilities()

func physics_update(delta: float) -> void:
	# If player falls off a ledge without jumping
	if not player.is_on_floor():
		state_machine.transition_to("Fall", {"coyote_eligible": true})
		return
	
	# Gale Slide (Rojan: Down + Jump on the ground)
	if (Input.is_action_just_pressed(&"move_down") or (Input.is_action_just_pressed(&"jump") and Input.is_action_pressed(&"move_down"))) and player.can_slide():
		state_machine.transition_to("Slide")
		return
	
	# Jump input check
	if Input.is_action_just_pressed(&"jump"):
		state_machine.transition_to("Jump")
		return
	
	# Attack input check
	if Input.is_action_just_pressed(&"attack"):
		state_machine.transition_to("Attack")
		return
	
	# Interact input check
	if Input.is_action_just_pressed(&"interact") and player.can_interact():
		state_machine.transition_to("Interact")
		return
	
	# Directional movement check
	var direction: float = player.get_input_direction()
	if not is_zero_approx(direction):
		state_machine.transition_to("Run")
		return
	
	# Apply ground friction and move
	player.apply_friction(delta)
	player.move_and_slide()
