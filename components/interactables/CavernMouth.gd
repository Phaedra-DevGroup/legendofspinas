class_name CavernMouth
extends Node2D

## Mouth of the Sunken Crystal Caverns (دهانه غارهای بلورین), the way on to Act III.
## Sealed by brambles until the Arboris is purified; entering it completes Act II.

signal entered()

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var crystals: CPUParticles2D = $CrystalShimmer

const PROMPT_OPEN: String = "ورود به غارهای بلورین"
const PROMPT_LOCKED: String = "دهانه غار در بند ریشه‌های آربوریس است"

var _locked: bool = true
var _used: bool = false

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	lock()

func lock() -> void:
	_locked = true
	interactable.prompt_message = PROMPT_LOCKED
	crystals.emitting = false
	sprite.modulate = Color(0.6, 0.6, 0.7)

func unlock() -> void:
	_locked = false
	interactable.prompt_message = PROMPT_OPEN
	crystals.emitting = true
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.8)

func _on_interacted(_actor: Node2D) -> void:
	if _locked:
		var shake: Tween = create_tween()
		shake.tween_property(sprite, "position:x", sprite.position.x + 2.0, 0.05)
		shake.tween_property(sprite, "position:x", sprite.position.x, 0.05)
		return
	if _used:
		return
	_used = true
	interactable.set_interactable(false)
	entered.emit()
