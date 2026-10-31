class_name SporeCrawler
extends EnemyBase

## Spore Crawler (خزنده اسپور انفجاری) - Act 1 tactical hazard.
## Scuttles fast across mine floors; upon closing in it swells, flashes violet
## and detonates in a purple AoE blast.

enum State { SCUTTLE, SWELL }

@export var speed: float = 90.0
@export var detonation_range: float = 30.0
@export var swell_duration: float = 0.8
@export var gravity: float = 900.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var blast_hitbox: HitboxComponent = $Visuals/BlastHitbox

const TEX_IDLE = preload("res://assets/sprites/enemies/spore_crawler/crawler_idle.png")
const TEX_SWELL = preload("res://assets/sprites/enemies/spore_crawler/crawler_swell.png")

var current_state: State = State.SCUTTLE
var _facing_direction: float = -1.0
var _state_timer: float = 0.0
var _target_player: PlayerController = null

func _ready() -> void:
	max_health = 1
	scrap_drop_count = 1
	touch_damage = 1
	knockback_resistance = 0.0
	super._ready()
	sprite.texture = TEX_IDLE
	if blast_hitbox:
		blast_hitbox.faction = HitboxComponent.Faction.ENEMY
		blast_hitbox.damage = 1
		blast_hitbox.knockback_force = 240.0
		blast_hitbox.monitorable = false

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	
	_locate_player()
	
	match current_state:
		State.SCUTTLE:
			velocity.x = _facing_direction * speed
			if is_on_wall():
				_facing_direction *= -1.0
				visuals.scale.x = _facing_direction
			if _target_player and is_instance_valid(_target_player):
				var diff: Vector2 = _target_player.global_position - global_position
				if absf(diff.y) < 40.0:
					_facing_direction = signf(diff.x) if not is_zero_approx(diff.x) else _facing_direction
					visuals.scale.x = _facing_direction
					if diff.length() <= detonation_range:
						_start_swell()
		State.SWELL:
			velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_detonate()
	
	move_and_slide()

func _start_swell() -> void:
	current_state = State.SWELL
	_state_timer = swell_duration
	sprite.texture = TEX_SWELL
	
	# Bright violet warning flash before the blast
	var flash: Tween = create_tween().set_loops(4)
	flash.tween_property(self, "modulate", Color(2.4, 1.2, 2.6), 0.1)
	flash.tween_property(self, "modulate", Color.WHITE, 0.1)
	var swell: Tween = create_tween()
	swell.tween_property(visuals, "scale", Vector2(_facing_direction * 1.35, 1.35), swell_duration)

func _detonate() -> void:
	ScreenShake.add_trauma(0.2)
	visuals.scale = Vector2(_facing_direction * 1.8, 0.6)
	if blast_hitbox:
		blast_hitbox.monitorable = true
	# Blast core: the crawler is spent after detonating
	if health_component:
		# Bypass hit i-frames so a crawler struck mid-swell still pops exactly once
		health_component.is_invulnerable = false
		health_component.take_damage(999, Vector2.ZERO)

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if players.size() > 0:
			_target_player = players[0] as PlayerController
