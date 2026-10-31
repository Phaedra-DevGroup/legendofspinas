class_name AncientGearBossDrop
extends Area2D

## Grand Ancient Gear Piece (چرخ‌دنده باستانی معبد).
## Dropped upon defeating the Crusher of the Ruins boss. Collecting this completes the Act 1 Demo!

signal gear_collected()

@onready var sprite: Sprite2D = $Sprite2D

var _time_alive: float = 0.0

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time_alive += delta
	if sprite:
		sprite.position.y = sin(_time_alive * 4.0) * 4.0
		var pulse: float = 1.0 + sin(_time_alive * 6.0) * 0.2
		sprite.modulate = Color(pulse, pulse, 1.2, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		set_deferred("monitoring", false)
		gear_collected.emit()
		
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.25)
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		await tween.finished
		queue_free()
