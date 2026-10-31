class_name AncientBeacon
extends Node2D

## Sacred Beacon at the Summit Overlook.
## Lighting it purifies the terraces and completes the Act 1 demo.

signal beacon_lit()

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var sprite: Sprite2D = $Sprite2D

var _is_lit: bool = false
## The beacon stays dark until the Crusher guarding the summit has fallen.
var _is_locked: bool = false

const PROMPT_READY: String = "روشن کردن مشعل باستانی"
const PROMPT_LOCKED: String = "مشعل خاموش است؛ نخست سنگ‌شکن را شکست دهید"

func _ready() -> void:
	if interactable:
		interactable.prompt_message = PROMPT_LOCKED if _is_locked else PROMPT_READY
		interactable.interacted.connect(_on_interacted)

func _on_interacted(_actor: Node2D) -> void:
	if _is_lit or _is_locked:
		if _is_locked:
			var shake: Tween = create_tween()
			shake.tween_property(sprite, "position:x", sprite.position.x + 2.0, 0.05)
			shake.tween_property(sprite, "position:x", sprite.position.x, 0.05)
		return
	_is_lit = true
	interactable.set_interactable(false)
	
	# Flare flare up
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate", Color(2.5, 2.5, 3.2), 0.5)
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.5)
	
	beacon_lit.emit()

func lock() -> void:
	_is_locked = true
	if interactable:
		interactable.prompt_message = PROMPT_LOCKED
	if sprite:
		sprite.modulate = Color(0.55, 0.55, 0.7)

func unlock() -> void:
	_is_locked = false
	if interactable:
		interactable.prompt_message = PROMPT_READY
	if sprite:
		var tween: Tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.6)
