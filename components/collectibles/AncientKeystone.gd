class_name AncientKeystone
extends Area2D

## Ancient Keystone required to unlock the boss gate mechanism.

signal keystone_collected()

@onready var sprite: Sprite2D = $Sprite2D
var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Glowing pulse
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(sprite, "modulate", Color(1.8, 1.8, 2.2), 0.7)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.7)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is PlayerController:
		_collected = true
		keystone_collected.emit()
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(1.6, 1.6), 0.25)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
		await tween.finished
		queue_free()
