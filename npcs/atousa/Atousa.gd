class_name Atousa
extends Node2D

## Atousa (آتوسا), the ancient guardian of the Misty Forest, half-bound by Marg-mayeh roots.
## She kneels in the Sacred Grove; talking to her plays her plea, heals the hero and, with the last
## of her strength, withers the bramble wall guarding the Arboris' clearing.
## Once the Arboris is purified her bonds loosen and her glow returns.

@onready var sprite: Sprite2D = $Sprite2D
@onready var interactable_component: InteractableComponent = $InteractableComponent
@onready var glow: CPUParticles2D = $Glow

const TEX_IDLE = preload("res://assets/sprites/npcs/atousa/atousa_idle.png")
const TEX_REACH = preload("res://assets/sprites/npcs/atousa/atousa_reach.png")

var _time: float = 0.0
var _talking: bool = false
var _freed: bool = false

func _ready() -> void:
	sprite.texture = TEX_IDLE
	# The corruption dims her: a sickly violet cast until the guardian tree is healed
	sprite.self_modulate = Color(0.82, 0.78, 0.95)

func _process(delta: float) -> void:
	_time += delta
	# Laboured breathing; a weak flicker of her turquoise light
	var breath: float = sin(_time * (1.4 if not _freed else 1.0))
	sprite.scale = Vector2(1.0 - breath * 0.012, 1.0 + breath * 0.02)
	if not _freed:
		glow.modulate.a = 0.55 + 0.35 * maxf(0.0, sin(_time * 2.7)) * randf_range(0.7, 1.0)

func play_talk() -> void:
	_talking = true
	sprite.texture = TEX_REACH

func play_idle() -> void:
	_talking = false
	sprite.texture = TEX_IDLE

## Called when the Arboris is purified: her bonds wither and her light grows strong again.
func set_freed() -> void:
	if _freed:
		return
	_freed = true
	glow.modulate.a = 1.0
	glow.amount = 24
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "self_modulate", Color(1.1, 1.15, 1.1), 1.5)
	FX.burst(get_parent(), global_position + Vector2(0, -24), Color(0.5, 1.0, 0.85, 1.0), 18, 90.0, false, 2.5, 0.9)
