class_name GoldenPomegranate
extends Area2D

## Permanent Health Container in "The Legend of Espinas".
## Increases maximum player HP by +1 heart and restores health.

signal pomegranate_collected()

@onready var sprite: Sprite2D = $Sprite2D
var _collected: bool = false
var _initial_y: float = 0.0

func _ready() -> void:
	_initial_y = position.y
	body_entered.connect(_on_body_entered)
	
	# Gentle floating animation
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -4.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is PlayerController:
		_collected = true
		pomegranate_collected.emit()
		
		# Increase player max health and heal
		if body.health_component:
			body.health_component.max_health += 1
			body.health_component.heal(1)
			body.health_updated.emit(body.health_component.current_health, body.health_component.max_health)
		
		# Collection fanfare flash & scale up
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.3)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
		queue_free()
