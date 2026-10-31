class_name NasimMerchant
extends CharacterBody2D

## Nasim the Wandering Merchant (نسیم، دختر دوره‌گرد و تاجر پرتگاه‌ها)
## Sells rare goods (Golden Pomegranate, Attack Charm) in exchange for Ancient Scraps.

signal item_purchased(item_name: String)

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var anim_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D if has_node("Visuals/AnimatedSprite2D") else null
@onready var sprite: Node2D = anim_sprite if anim_sprite != null else ($Sprite2D if has_node("Sprite2D") else null)

var pomegranate_sold: bool = false
var charm_sold: bool = false

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "گفتگو و معامله با نسیم"
	play_animation(&"idle")

func play_animation(anim_name: StringName) -> void:
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)

func on_interacted() -> void:
	play_animation(&"talk")
	var t: SceneTreeTimer = get_tree().create_timer(3.0)
	t.timeout.connect(func():
		if is_instance_valid(self):
			play_animation(&"idle")
	)

func on_traded() -> void:
	play_animation(&"trade")
	var t: SceneTreeTimer = get_tree().create_timer(2.5)
	t.timeout.connect(func():
		if is_instance_valid(self):
			play_animation(&"idle")
	)
