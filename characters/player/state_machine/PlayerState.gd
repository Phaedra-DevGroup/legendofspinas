class_name PlayerState
extends Node

## Abstract base class for all player FSM states.
## Holds references to PlayerController and StateMachine.

var player: PlayerController
var state_machine: StateMachine

## Called upon entering the state. Accepts an optional data dictionary.
func enter(_msg: Dictionary = {}) -> void:
	pass

## Called upon exiting the state. Clean up timers, animations, or temporary flags here.
func exit() -> void:
	pass

## Called by the StateMachine when an unhandled input event occurs.
func handle_input(_event: InputEvent) -> void:
	pass

## Regular frame process tick.
func update(_delta: float) -> void:
	pass

## Physics frame process tick. Movement calculations and physics queries go here.
func physics_update(_delta: float) -> void:
	pass
