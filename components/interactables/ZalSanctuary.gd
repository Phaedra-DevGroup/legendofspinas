class_name ZalSanctuary
extends Node2D

## Sanctuary of Old Zal (استراحتگاه زال کهنسال): a campfire where the old bard plays
## ancient melodies. Resting saves progress, refills the flask and hints at coming dangers.

signal rested(title: String, text: String)

@export var lore_title: String = "زال کهنسال (آواز کوهستان)"
@export_multiline var lore_hint: String = "«آتش را که گرم کردی، چشم بر پشتگردنه‌ها داشته باش...»"

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "استراحتگاه زال کهنسال"
		interactable.interacted.connect(_on_interacted)
	if sprite:
		var flicker: Tween = create_tween().set_loops()
		flicker.tween_property(sprite, "modulate", Color(1.25, 1.1, 0.95, 1.0), 0.35)
		flicker.tween_property(sprite, "modulate", Color.WHITE, 0.45)

func _on_interacted(actor: Node2D) -> void:
	var hero: PlayerController = actor as PlayerController
	if hero:
		hero.set_checkpoint(global_position + Vector2(0, -18))
		if hero.health_component:
			hero.health_component.heal(hero.health_component.max_health)
			hero.health_updated.emit(hero.health_component.current_health, hero.health_component.max_health)
	ScreenShake.add_trauma(0.05)
	rested.emit(lore_title, lore_hint)
