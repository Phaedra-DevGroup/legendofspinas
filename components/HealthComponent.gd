class_name HealthComponent
extends Node2D

## Modular Health & Invulnerability Component for "The Legend of Espinas".
## Handles current/max health, damage taking with i-frames, healing, and death signals.

signal health_changed(current: int, max_health: int)
signal damaged(amount: int, knockback: Vector2)
signal healed(amount: int)
signal died()

@export var max_health: int = 5:
	set(value):
		max_health = maxi(1, value)
		if current_health > max_health:
			current_health = max_health
		health_changed.emit(current_health, max_health)

@export var i_frame_duration: float = 0.8
@export var can_be_invulnerable: bool = true

var current_health: int = 5
var is_invulnerable: bool = false
var _invulnerability_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta: float) -> void:
	if is_invulnerable:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0.0:
			is_invulnerable = false

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> bool:
	if is_invulnerable and can_be_invulnerable:
		return false
	if current_health <= 0:
		return false
	
	var actual_damage: int = maxi(1, amount)
	current_health = maxi(0, current_health - actual_damage)
	
	if can_be_invulnerable and i_frame_duration > 0.0:
		is_invulnerable = true
		_invulnerability_timer = i_frame_duration
	
	damaged.emit(actual_damage, knockback)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()
	
	return true

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	var old_health: int = current_health
	current_health = mini(max_health, current_health + maxi(1, amount))
	var gained: int = current_health - old_health
	if gained > 0:
		healed.emit(gained)
		health_changed.emit(current_health, max_health)

func reset_health() -> void:
	current_health = max_health
	is_invulnerable = false
	_invulnerability_timer = 0.0
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0
