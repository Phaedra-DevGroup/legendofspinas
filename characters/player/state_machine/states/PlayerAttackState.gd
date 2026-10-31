class_name PlayerAttackState
extends PlayerState

## Handles attack action execution (Bardia wristband melee or Rojan nature bow shot).
## The attack charges while the button is held: releasing past CHARGE_THRESHOLD
## unleashes the Turquoise Resonance variant.

@export var attack_duration: float = 0.28
@export var charged_duration: float = 0.5

var _recovery_timer: float = 0.0
var _executed: bool = false

func enter(_msg: Dictionary = {}) -> void:
	_executed = false
	_recovery_timer = 0.0
	player.attack_charge = 0.0
	player.play_animation(&"attack")

func exit() -> void:
	player.attack_charge = 0.0
	player.set_charge_glow(false)

func physics_update(delta: float) -> void:
	if not _executed:
		player.attack_charge += delta
		player.set_charge_glow(player.is_attack_fully_charged())
		
		var released: bool = Input.is_action_just_released(&"attack")
		var maxed_out: bool = player.attack_charge >= player.MAX_CHARGE_TIME
		if released or maxed_out:
			var charged: bool = player.is_attack_fully_charged()
			player.execute_attack(charged)
			player.set_charge_glow(false)
			_executed = true
			_recovery_timer = charged_duration if charged else attack_duration
	else:
		_recovery_timer -= delta
		if _recovery_timer <= 0.0:
			_finish()
			return
	
	# Apply slight movement damping while attacking on ground, or gravity in air
	if not player.is_on_floor():
		player.apply_gravity(delta)
		player.apply_air_friction(delta)
	else:
		player.apply_friction(delta)
	
	player.move_and_slide()

func _finish() -> void:
	if not player.is_on_floor():
		state_machine.transition_to("Fall")
	elif not is_zero_approx(player.get_input_direction()):
		state_machine.transition_to("Run")
	else:
		state_machine.transition_to("Idle")
