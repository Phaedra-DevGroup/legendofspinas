class_name StateMachine
extends Node

## Generic Finite State Machine (FSM) manager node.
## Orchestrates state transitions, lifecycle hooks, and passes physics/input ticks to active state.

signal state_transitioned(old_state: PlayerState, new_state: PlayerState)

@export var initial_state: PlayerState

var current_state: PlayerState
var states: Dictionary = {}

func init(actor: PlayerController) -> void:
	for child in get_children():
		if child is PlayerState:
			states[child.name.to_lower()] = child
			child.player = actor
			child.state_machine = self
	
	if initial_state:
		current_state = initial_state
		current_state.enter({})
	elif get_child_count() > 0 and get_child(0) is PlayerState:
		current_state = get_child(0) as PlayerState
		current_state.enter({})

func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String, msg: Dictionary = {}) -> void:
	var key: String = target_state_name.to_lower()
	if not states.has(key):
		push_error("StateMachine: State '%s' not registered under %s" % [target_state_name, get_path()])
		return
	
	var new_state: PlayerState = states[key]
	if new_state == current_state:
		return
	
	var old_state: PlayerState = current_state
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter(msg)
	state_transitioned.emit(old_state, new_state)

func get_current_state_name() -> String:
	return current_state.name if current_state else ""
