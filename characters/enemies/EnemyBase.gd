class_name EnemyBase
extends CharacterBody2D

## Base class for enemies in "The Legend of Espinas".
## Handles Health, Hurtbox, Hitbox, hurt flashes, knockback, and scrap drops.

signal enemy_defeated(enemy: EnemyBase)

@export var max_health: int = 2
@export var scrap_drop_count: int = 2
@export var touch_damage: int = 1
@export var knockback_resistance: float = 1.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var visuals: Node2D = $Visuals

var is_dying: bool = false
const SCRAP_SCENE = preload("res://components/collectibles/AncientScrapCollectible.tscn")

func _ready() -> void:
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
	
	if hitbox_component:
		hitbox_component.faction = HitboxComponent.Faction.ENEMY
		hitbox_component.damage = touch_damage
	
	if hurtbox_component:
		hurtbox_component.faction = HitboxComponent.Faction.ENEMY

func _on_damaged(_amount: int, knockback: Vector2) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "enemy_hit")
	if visuals:
		visuals.modulate = Color(1.5, 0.3, 0.3, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)
	
	if knockback_resistance > 0.0:
		velocity += knockback * (1.0 / knockback_resistance)

func _on_died() -> void:
	if is_dying:
		return
	is_dying = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "enemy_die")
	enemy_defeated.emit(self)
	ScreenShake.add_trauma(0.15)
	
	# Spawn ancient scrap drops
	_spawn_scrap_drops()
	
	# Death puff animation
	set_physics_process(false)
	if hitbox_component:
		hitbox_component.set_deferred("monitorable", false)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "scale", Vector2(1.4, 0.1), 0.15)
	tween.tween_property(visuals, "modulate:a", 0.0, 0.15)
	await tween.finished
	queue_free()

func _spawn_scrap_drops() -> void:
	if not SCRAP_SCENE:
		return
	var parent_node: Node = get_parent()
	if not parent_node:
		return
	
	for i in range(scrap_drop_count):
		var scrap: Node2D = SCRAP_SCENE.instantiate() as Node2D
		if scrap:
			scrap.global_position = global_position + Vector2(randf_range(-12, 12), randf_range(-16, -6))
			parent_node.call_deferred("add_child", scrap)
