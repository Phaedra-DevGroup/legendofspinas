class_name MasterPoolad
extends CharacterBody2D

## Master Poolad: The underground blacksmith of Espinas (استاد پولاد).
## Listens to his InteractableComponent to trigger dialogue and weapon upgrades in Persian.

@export_group("دیالوگ و پیش‌زمینه داستانی")
@export_multiline var initial_greeting: String = "حرارت این کوره تنها چیزیه که جلوی مرگ‌مایه رو می‌گیره تا خونمون منجمد نشه. سلاحت رو نشونم بده شاگرد؛ صعود به قله شوخی‌بردار نیست."

@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var dialogue_indicator: Sprite2D = $Visuals/DialogueIndicator
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D

var _ambient_timer: float = 0.0

func _ready() -> void:
	_ensure_nodes()
	if interactable_component:
		interactable_component.prompt_message = "گفتگو و ارتقا"
		interactable_component.focused.connect(_on_focused)
		interactable_component.unfocused.connect(_on_unfocused)
		interactable_component.interacted.connect(_on_interacted)
	
	if dialogue_indicator:
		dialogue_indicator.visible = false
	
	play_idle()

func _ensure_nodes() -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("Visuals/AnimatedSprite2D")
	if not dialogue_indicator:
		dialogue_indicator = get_node_or_null("Visuals/DialogueIndicator")
	if not interactable_component:
		interactable_component = get_node_or_null("InteractableComponent")

func _physics_process(delta: float) -> void:
	# Subtle ambient forge activity: occasionally strike anvil if idle
	_ambient_timer += delta
	if _ambient_timer >= 7.0:
		_ambient_timer = 0.0
		_ensure_nodes()
		if animated_sprite and animated_sprite.animation == &"idle":
			play_forge()
			var t := get_tree().create_timer(2.4)
			t.timeout.connect(func():
				if is_instance_valid(self) and animated_sprite and animated_sprite.animation == &"forge":
					play_idle()
			)

func play_idle() -> void:
	_ensure_nodes()
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(&"idle"):
		animated_sprite.play(&"idle")

func play_forge() -> void:
	_ensure_nodes()
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(&"forge"):
		animated_sprite.play(&"forge")

func play_talk() -> void:
	_ensure_nodes()
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(&"talk"):
		animated_sprite.play(&"talk")

func _on_focused(_component: InteractableComponent) -> void:
	_ensure_nodes()
	if dialogue_indicator:
		dialogue_indicator.visible = true
	play_talk()

func _on_unfocused(_component: InteractableComponent) -> void:
	_ensure_nodes()
	if dialogue_indicator:
		dialogue_indicator.visible = false
	play_idle()

func _on_interacted(actor: Node2D) -> void:
	print("[استاد پولاد] تعامل با قهرمان آغاز شد: ", actor.name)
	play_talk()
