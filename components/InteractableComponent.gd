class_name InteractableComponent
extends Area2D

## Component attached to world entities (NPCs, chests, shrines) that can be interacted with.
## Works in tandem with the Player's interaction detector.

signal focused(interactable: InteractableComponent)
signal unfocused(interactable: InteractableComponent)
signal interacted(by_actor: Node2D)

@export_group("تنظیمات تعامل")
## متنی که در کادر راهنمای کاربر نمایش داده می‌شود (مثلاً "گفتگو"، "ارتقا"، "استراحت")
@export var prompt_message: String = "گفتگو"

## Enables or disables interaction dynamically (e.g. during cinematic or quest lockout)
@export var is_interactable: bool = true

## Cooldown in seconds before the player can trigger another interaction
@export var cooldown_duration: float = 0.35

var _is_on_cooldown: bool = false
var _cooldown_timer: Timer

func _ready() -> void:
	# Default to layer 4 (Interactables) and mask 0 (passively detected by player's detector)
	collision_layer = 8 # 1 << 3 = Layer 4 (Interactables)
	collision_mask = 0
	
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = cooldown_duration
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	add_child(_cooldown_timer)

## Called when the player steps into range and targets this entity
func gain_focus() -> void:
	if not is_interactable:
		return
	focused.emit(self)

## Called when the player steps out of range or switches targets
func lose_focus() -> void:
	unfocused.emit(self)

## Invoked by the PlayerController or input system when the interact key is pressed
func interact(actor: Node2D) -> void:
	if not is_interactable or _is_on_cooldown:
		return
	
	_is_on_cooldown = true
	_cooldown_timer.start()
	interacted.emit(actor)

func set_interactable(enabled: bool) -> void:
	is_interactable = enabled
	if not enabled:
		lose_focus()

func _on_cooldown_timeout() -> void:
	_is_on_cooldown = false
