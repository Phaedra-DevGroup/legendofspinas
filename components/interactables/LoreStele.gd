class_name LoreStele
extends Node2D

## Ancient Persian inscribed stone tablet revealing lore about Anahita and Espinas.

signal stele_read(title: String, text: String)

@export var lore_title: String = "کتیبه باستانی اشک آناهیتا"
@export_multiline var lore_text: String = "«در بالاترین چکاد اسپیناس، گوهری از زلال‌ترین آب‌های جهان می‌تپید. تا آن دم که سایه ظلمات بر محراب افتاد و خارهای مرگ‌مایه ریشه دواندند...»"

@onready var interactable: InteractableComponent = $InteractableComponent
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	if interactable:
		interactable.prompt_message = "خواندن کتیبه باستان"
		interactable.interacted.connect(_on_interacted)

func _on_interacted(_actor: Node2D) -> void:
	stele_read.emit(lore_title, lore_text)
