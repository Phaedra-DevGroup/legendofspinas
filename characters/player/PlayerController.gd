class_name PlayerController
extends CharacterBody2D

## Main player character controller for "The Legend of Espinas".
## Manages Bardia / Rojan movement physics, FSM execution, combat, and interaction targeting.

enum CharacterType {
	BARDIA, ## Melee, grappling hook, wristband
	ROJAN   ## Ranged, agile, double jump, nature arrows
}

signal character_configured(type: CharacterType)
signal interaction_target_changed(target: InteractableComponent)
signal attack_performed(type: CharacterType)
signal health_updated(current: int, max_health: int)
signal scraps_updated(total_scraps: int)
signal player_died()

const NATURE_ARROW_SCENE = preload("res://characters/player/projectiles/NatureArrow.tscn")
const SEISMIC_SUNDER_SCENE = preload("res://characters/player/projectiles/SeismicSunder.tscn")
const SPRITE_FRAMES_BARDIA = preload("res://characters/player/SpriteFrames_Bardia.tres")
const SPRITE_FRAMES_ROJAN = preload("res://characters/player/SpriteFrames_Rojan.tres")

## Hold-to-charge (Turquoise Resonance) tuning.
const CHARGE_THRESHOLD: float = 0.65
const MAX_CHARGE_TIME: float = 1.2
const GRAPPLE_RANGE: float = 150.0
const KILL_PLANE_Y: float = 420.0

@export_group("Character Configuration")
@export var character_type: CharacterType = CharacterType.BARDIA:
	set(value):
		character_type = value
		_apply_character_archetype()

@export_group("Movement Dynamics")
@export var speed: float = 145.0
@export var acceleration: float = 1300.0
@export var friction: float = 1500.0
@export var air_acceleration: float = 850.0
@export var air_friction: float = 450.0

@export_group("Jump & Gravity")
@export var jump_velocity: float = -385.0
@export var gravity: float = 900.0
@export var fall_gravity_multiplier: float = 1.35
@export var coyote_time: float = 0.16
@export var jump_buffer_time: float = 0.16

@export_group("Combat")
## Permanent weapon upgrade level bought at Master Poolad's forge.
@export var attack_damage_bonus: int = 0
@export var slide_cooldown: float = 0.18

@onready var state_machine: StateMachine = $StateMachine
@onready var visuals: Node2D = $Visuals
@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var interaction_detector: Area2D = $InteractionDetector

# Combat & Components
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hurtbox_shape: CollisionShape2D = $HurtboxComponent/CollisionShape2D
@onready var melee_hitbox: HitboxComponent = $Visuals/MeleeHitbox
@onready var slash_sprite: Sprite2D = $Visuals/SlashSprite
@onready var charge_glow: ColorRect = $Visuals/ChargeGlow
@onready var grapple_rope: Line2D = $GrappleRope

const MAX_AIR_JUMPS: int = 1
var air_jumps_left: int = 1
var has_wall_jumped: bool = false
var facing_direction: float = 1.0
var can_double_jump: bool = true
var ancient_scraps: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var attack_charge: float = 0.0
var _slide_cooldown_timer: float = 0.0
var _nearby_interactables: Array[InteractableComponent] = []
var _current_interactable: InteractableComponent = null
## Contextual control hint shown by the level HUD ("[E] ..."); kept empty when there is nothing to do.
var action_prompt: String = ""

func _ready() -> void:
	# Read character archetype chosen in Main Menu
	if is_instance_valid(SceneManager):
		character_type = SceneManager.selected_character
	_apply_character_archetype()
	add_to_group(&"player")
	
	checkpoint_position = global_position
	
	if state_machine:
		state_machine.init(self)
	
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_interaction_area_entered)
		interaction_detector.area_exited.connect(_on_interaction_area_exited)
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.damaged.connect(_on_player_damaged)
		health_component.died.connect(_on_player_died)
		health_updated.emit(health_component.current_health, health_component.max_health)
	
	if melee_hitbox:
		melee_hitbox.monitoring = false
		melee_hitbox.monitorable = false
		melee_hitbox.damage = get_attack_damage()
	if slash_sprite:
		slash_sprite.visible = false
	if charge_glow:
		charge_glow.visible = false
	if grapple_rope:
		grapple_rope.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if state_machine:
		state_machine.handle_input(event)

func _process(delta: float) -> void:
	if state_machine:
		state_machine.update(delta)

func _physics_process(delta: float) -> void:
	if _slide_cooldown_timer > 0.0:
		_slide_cooldown_timer -= delta
	# Fell out of the world (spike pits / open gaps)
	if global_position.y > KILL_PLANE_Y:
		_on_player_died()
		return
	if state_machine:
		state_machine.physics_update(delta)
	_update_action_prompt()

## One contextual hint for whatever the hero can do right here, right now.
func _update_action_prompt() -> void:
	if _current_interactable and _current_interactable.is_interactable:
		action_prompt = "[E] " + _current_interactable.prompt_message
		return
	
	action_prompt = ""
	# Wider reach while grounded so the jump-first hint shows up at the pit's edge
	var reach: float = GRAPPLE_RANGE if not is_on_floor() else GRAPPLE_RANGE + 80.0
	if find_grapple_anchor(reach) == Vector2.ZERO:
		return
	if is_on_floor():
		action_prompt = "بپر و [E] را برای قلاب برنزی بزن"
	else:
		action_prompt = "[E] قلاب برنزی: بگیر و بچرخ"

# ---------------------------------------------------------
# Movement & Physics Utilities
# ---------------------------------------------------------

func get_input_direction() -> float:
	return Input.get_axis(&"move_left", &"move_right")

func apply_horizontal_acceleration(direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)

func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func apply_air_acceleration(direction: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, direction * speed, air_acceleration * delta)

func apply_air_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, air_friction * delta)

func apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func apply_fall_gravity(delta: float) -> void:
	velocity.y += (gravity * fall_gravity_multiplier) * delta

func update_facing_direction(direction: float) -> void:
	if is_zero_approx(direction):
		return
	facing_direction = signf(direction)
	if visuals:
		visuals.scale.x = facing_direction

func reset_air_abilities() -> void:
	air_jumps_left = MAX_AIR_JUMPS
	has_wall_jumped = false
	can_double_jump = true

func can_perform_double_jump() -> bool:
	return air_jumps_left > 0 and not is_on_floor()

func consume_double_jump() -> void:
	air_jumps_left = maxi(air_jumps_left - 1, 0)
	can_double_jump = (air_jumps_left > 0)

# ---------------------------------------------------------
# Animation & Combat Actions
# ---------------------------------------------------------

func play_animation(anim_name: StringName) -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
			animated_sprite.play(anim_name)
	elif animation_player:
		var prefix: String = "bardia_" if character_type == CharacterType.BARDIA else "rojan_"
		var specific_anim: StringName = StringName(prefix + String(anim_name))
		if animation_player.has_animation(specific_anim):
			animation_player.play(specific_anim)
		elif animation_player.has_animation(anim_name):
			animation_player.play(anim_name)

func execute_attack(charged: bool = false) -> void:
	attack_performed.emit(character_type)
	
	if character_type == CharacterType.ROJAN:
		_spawn_nature_arrow(charged)
	else:
		if charged:
			_spawn_seismic_sunder()
		else:
			_bardia_light_strike()

## Base weapon damage: 1 + forge upgrades (base 1 -> 3 after one upgrade).
func get_attack_damage() -> int:
	return 1 + attack_damage_bonus

## Charged (Turquoise Resonance) hits deal double damage and break guards.
func get_charged_damage() -> int:
	return get_attack_damage() * 2

func is_attack_fully_charged() -> bool:
	return attack_charge >= CHARGE_THRESHOLD

func set_charge_glow(enabled: bool) -> void:
	if charge_glow:
		charge_glow.visible = enabled

func _spawn_nature_arrow(charged: bool) -> void:
	if not NATURE_ARROW_SCENE:
		return
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "bow_shoot")
	var arrow: CharacterBody2D = NATURE_ARROW_SCENE.instantiate() as CharacterBody2D
	if not is_instance_valid(arrow):
		return
	arrow.global_position = global_position + Vector2(facing_direction * 2.0, -18.0)
	if arrow.has_method("set_direction"):
		arrow.call("set_direction", facing_direction)
	if arrow.has_method("set_damage"):
		arrow.call("set_damage", get_charged_damage() if charged else get_attack_damage())
	if arrow.has_method("set_pierce"):
		arrow.call("set_pierce", 3 if charged else 0)
	if arrow.has_method("set_guard_breaker"):
		arrow.call("set_guard_breaker", charged)
	get_parent().add_child(arrow)
	
	if charged:
		ScreenShake.shake(0.2, 2.0)
	if not is_on_floor():
		velocity.y = minf(velocity.y, -30.0)
		velocity.x = -facing_direction * 35.0

func _spawn_seismic_sunder() -> void:
	if not SEISMIC_SUNDER_SCENE:
		return
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "heavy_slash")
	var sunder: Node2D = SEISMIC_SUNDER_SCENE.instantiate() as Node2D
	if not is_instance_valid(sunder):
		return
	sunder.global_position = global_position + Vector2(0, -4.0)
	if sunder.has_method("launch"):
		sunder.call("launch", facing_direction, get_charged_damage())
	get_parent().add_child(sunder)

func _bardia_light_strike() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "slash")
	if melee_hitbox:
		melee_hitbox.bypass_guard = false
		melee_hitbox.damage = get_attack_damage()
		melee_hitbox.monitorable = true
		if slash_sprite:
			slash_sprite.visible = true
			slash_sprite.modulate = Color(1.2, 1.2, 1.2, 1.0)
			var tween: Tween = create_tween()
			tween.tween_property(slash_sprite, "modulate:a", 0.0, 0.16)
			tween.tween_callback(func():
				slash_sprite.visible = false
				if melee_hitbox:
					melee_hitbox.monitorable = false
			)

# ---------------------------------------------------------
# Hero Mobility Signatures (grapple hook / gale slide)
# ---------------------------------------------------------

func can_grapple() -> bool:
	return not is_on_floor() and find_grapple_anchor() != Vector2.ZERO

## Nearest bronze grapple ring within range, or Vector2.ZERO when none is reachable.
func find_grapple_anchor(max_range: float = GRAPPLE_RANGE) -> Vector2:
	var best: Vector2 = Vector2.ZERO
	var min_distance: float = max_range
	for ring in get_tree().get_nodes_in_group(&"grapple_rings"):
		if ring is Node2D:
			var ring_pos: Vector2 = (ring as Node2D).global_position
			var distance: float = global_position.distance_to(ring_pos)
			if distance < min_distance:
				min_distance = distance
				best = ring_pos
	return best

func set_grapple_rope(anchor: Vector2, enabled: bool) -> void:
	if not grapple_rope:
		return
	grapple_rope.visible = enabled
	if enabled:
		grapple_rope.points = PackedVector2Array([Vector2(0, -20), to_local(anchor)])

func can_slide() -> bool:
	if character_type != CharacterType.ROJAN or _slide_cooldown_timer > 0.0:
		return false
	return is_on_floor() or test_move(global_transform, Vector2(0, 6.0))

func start_slide_cooldown() -> void:
	_slide_cooldown_timer = slide_cooldown

## While sliding the hero ducks low and slips through enemy hitboxes.
func set_sliding(active: bool) -> void:
	if hurtbox_shape and hurtbox_shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = hurtbox_shape.shape as CapsuleShape2D
		capsule.height = 18.0 if active else 36.0
		hurtbox_shape.position.y = -9.0 if active else -18.0
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", not active)
	if visuals and not active:
		visuals.scale = Vector2(facing_direction, 1.0)

# ---------------------------------------------------------
# Health, Damage & Respawn Subsystem
# ---------------------------------------------------------

func _on_health_changed(current: int, max_hp: int) -> void:
	health_updated.emit(current, max_hp)

func _on_player_damaged(_amount: int, knockback: Vector2) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "player_hurt")
	# Flash red and apply knockback
	if visuals:
		visuals.modulate = Color(1.0, 0.3, 0.3, 1.0)
		var tween: Tween = create_tween()
		tween.tween_property(visuals, "modulate", Color.WHITE, 0.25)
	
	if not is_zero_approx(knockback.length_squared()):
		velocity = knockback
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(45)

func _on_player_died() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "player_die")
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(160)
	player_died.emit()
	respawn()

## Return to the last checkpoint at full health with a short grace period.
func respawn() -> void:
	global_position = checkpoint_position
	velocity = Vector2.ZERO
	if health_component:
		health_component.reset_health()
		# Spawn protection so a checkpoint next to an enemy is never a death loop
		health_component.is_invulnerable = true
		health_component._invulnerability_timer = 1.2
	if visuals:
		visuals.modulate = Color.WHITE
		var blink: Tween = create_tween().set_loops(6)
		blink.tween_property(visuals, "modulate:a", 0.3, 0.1)
		blink.tween_property(visuals, "modulate:a", 1.0, 0.1)
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		camera.reset_smoothing()
	if state_machine:
		state_machine.transition_to("Idle")

func set_checkpoint(pos: Vector2) -> void:
	checkpoint_position = pos

func add_scraps(amount: int) -> void:
	ancient_scraps += amount
	scraps_updated.emit(ancient_scraps)

func spend_scraps(amount: int) -> bool:
	if ancient_scraps >= amount:
		ancient_scraps -= amount
		scraps_updated.emit(ancient_scraps)
		return true
	return false

# ---------------------------------------------------------
# Interaction Subsystem
# ---------------------------------------------------------

func can_interact() -> bool:
	return _current_interactable != null and _current_interactable.is_interactable

func get_current_interactable() -> InteractableComponent:
	return _current_interactable

func perform_interaction() -> void:
	if _current_interactable:
		_current_interactable.interact(self)

func _update_active_interactable() -> void:
	if _nearby_interactables.is_empty():
		if _current_interactable:
			_current_interactable.lose_focus()
			_current_interactable = null
			interaction_target_changed.emit(null)
		return
	
	var closest: InteractableComponent = null
	var min_distance_sq: float = INF
	
	for candidate in _nearby_interactables:
		if not is_instance_valid(candidate) or not candidate.is_interactable:
			continue
		var dist_sq: float = global_position.distance_squared_to(candidate.global_position)
		if dist_sq < min_distance_sq:
			min_distance_sq = dist_sq
			closest = candidate
	
	if closest != _current_interactable:
		if _current_interactable:
			_current_interactable.lose_focus()
		_current_interactable = closest
		if _current_interactable:
			_current_interactable.gain_focus()
		interaction_target_changed.emit(_current_interactable)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area is InteractableComponent and not _nearby_interactables.has(area):
		_nearby_interactables.append(area)
		_update_active_interactable()

func _on_interaction_area_exited(area: Area2D) -> void:
	if area is InteractableComponent:
		_nearby_interactables.erase(area)
		_update_active_interactable()

func can_wall_jump() -> bool:
	return character_type == CharacterType.ROJAN and is_on_wall() and not is_on_floor() and not has_wall_jumped

func _apply_character_archetype() -> void:
	if character_type == CharacterType.ROJAN:
		speed = 160.0 # Rojan is noticeably more agile
		if animated_sprite and SPRITE_FRAMES_ROJAN:
			animated_sprite.sprite_frames = SPRITE_FRAMES_ROJAN
	else:
		speed = 145.0 # Bardia standard ground speed
		if animated_sprite and SPRITE_FRAMES_BARDIA:
			animated_sprite.sprite_frames = SPRITE_FRAMES_BARDIA
	if animated_sprite:
		animated_sprite.play(&"idle")
	reset_air_abilities()
	character_configured.emit(character_type)
