class_name GrappleRing
extends Node2D

## Bronze ring bolted to the ruined ceilings of Espinas.
## Bardia's grappling hook (Interact while airborne) latches onto the nearest ring.

func _ready() -> void:
	var sway: Tween = create_tween().set_loops()
	sway.tween_property(self, "rotation", 0.06, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(self, "rotation", -0.06, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
