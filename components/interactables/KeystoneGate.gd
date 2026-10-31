class_name KeystoneGate
extends StaticBody2D

## Heavy mechanical stone gate blocking the entrance to the Crusher's Colosseum.
## Opens when the player collects the 2 Ancient Keystones.

signal gate_opened()

@export var required_keystones: int = 2

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var is_open: bool = false

func open_gate() -> void:
	if is_open:
		return
	is_open = true
	gate_opened.emit()
	ScreenShake.add_trauma(0.6)
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Slide down into floor with tremor
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y + 96.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
