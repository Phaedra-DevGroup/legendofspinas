class_name PlayerInteractState
extends PlayerState

## Handles interaction with nearby NPCs (Master Poolad, Zal, Nasim, Atousa) or objects.

func enter(_msg: Dictionary = {}) -> void:
	player.play_animation(&"idle")
	player.velocity = Vector2.ZERO
	
	# Face the interaction target if available
	var target: InteractableComponent = player.get_current_interactable()
	if target:
		var target_dir: float = signf(target.global_position.x - player.global_position.x)
		if not is_zero_approx(target_dir):
			player.update_facing_direction(target_dir)
		
		# Execute the interaction on the component
		target.interact(player)
	
	# Transition back to Idle once interaction trigger is submitted
	state_machine.transition_to("Idle")
