class_name ArborisBark
extends Area2D

## Shard of purified Arboris bark (پوسته آربوریس), dropped when the guardian is healed.
## Woven into the hero's armour it grants one extra heart and fully restores health.

signal bark_collected()

@onready var sprite: Sprite2D = $Sprite2D

var _time_alive: float = 0.0

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	# Pop out of the tree, then hover
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_time_alive += delta
	if sprite:
		sprite.position.y = sin(_time_alive * 4.0) * 4.0
		var pulse: float = 1.0 + sin(_time_alive * 6.0) * 0.2
		sprite.modulate = Color(pulse, 1.15, pulse, 1.0)

func _on_body_entered(body: Node2D) -> void:
	var hero: PlayerController = body as PlayerController
	if not hero:
		return
	set_deferred("monitoring", false)
	if hero.health_component:
		hero.health_component.max_health += 1
		hero.health_component.heal(hero.health_component.max_health)
		hero.health_updated.emit(hero.health_component.current_health, hero.health_component.max_health)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "pomegranate_pickup")
	FX.burst(get_parent(), global_position, Color(0.55, 1.0, 0.85, 1.0), 16, 110.0, false, 2.5, 0.6)
	bark_collected.emit()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()
