class_name PlayerRunState
extends PlayerState

## Handles ground locomotion, acceleration, turning, and state exits.

func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"run")
	player.reset_air_abilities()

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Fall", {"coyote_eligible": true})
		return
	
	# Gale Slide (Rojan: Down + Jump on the ground, or pressing Down while running)
	if (Input.is_action_just_pressed(&"move_down") or (Input.is_action_just_pressed(&"jump") and Input.is_action_pressed(&"move_down"))) and player.can_slide():
		state_machine.transition_to("Slide")
		return
	
	if Input.is_action_just_pressed(&"jump"):
		state_machine.transition_to("Jump")
		return
	
	if Input.is_action_just_pressed(&"attack"):
		state_machine.transition_to("Attack")
		return
	
	if Input.is_action_just_pressed(&"interact") and player.can_interact():
		state_machine.transition_to("Interact")
		return
	
	var direction: float = player.get_input_direction()
	if is_zero_approx(direction):
		state_machine.transition_to("Idle")
		return
	
	player.update_facing_direction(direction)
	player.apply_horizontal_acceleration(direction, delta)
	player.move_and_slide()
