class_name HollowLurker
extends EnemyBase

## Mini-Boss: The Hollow Lurker (خزنده ژرفا) - guardian of Keystone #2 in the deep mines.
## A thorned serpent that picks attacks by range: a fast lunge bite up close, ceiling crawl into a
## telegraphed thorn rain, aimed spike volleys, and a burrow strike that tunnels under the hero
## (its dirt trail and reticle give the dodge window). Phase 2 chains attacks and speeds everything up.
## Animation is procedural: slithering sway, coil squash, flipping onto the ceiling, dirt trails.

signal boss_health_changed(current: int, max_hp: int)
signal boss_phase_changed(phase: int)
signal boss_defeated()

enum State {
	DORMANT,
	IDLE,
	CEILING_CRAWL,
	THORN_RAIN,
	SPIKE_VOLLEY,
	BURROW_SINK,
	BURROW_APPROACH,
	BURROW_STRIKE,
	DYING,
	LUNGE_WINDUP,
	LUNGE,
	RECOVER,
}

const THORN_SCENE = preload("res://characters/enemies/thorn_spitter/ThornProjectile.tscn")
const STALACTITE_SCENE = preload("res://characters/bosses/crusher/FallingStalactite.tscn")

@export var floor_y: float = 320.0
@export var ceiling_y: float = 110.0
@export var wake_range: float = 240.0
@export var crawl_speed: float = 130.0
@export var burrow_speed: float = 190.0
@export var lunge_speed: float = 380.0
@export var gravity: float = 900.0

@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var eruption_hitbox: HitboxComponent = $Visuals/EruptionHitbox
@onready var reticle: Sprite2D = $ReticleSprite

const TEX_IDLE = preload("res://assets/sprites/bosses/lurker/lurker_idle.png")
const TEX_STRIKE = preload("res://assets/sprites/bosses/lurker/lurker_strike.png")
const TEX_BURROW = preload("res://assets/sprites/bosses/lurker/lurker_burrow.png")
const OUTLINE_SHADER = preload("res://components/fx/PixelOutline.gdshader")

var current_state: State = State.DORMANT
var current_phase: int = 1
var _facing_direction: float = -1.0
var _state_timer: float = 0.0
var _attack_step: int = 0
var _target_player: PlayerController = null
var _burrow_target_x: float = 0.0
var _phase_2_triggered: bool = false
var _spawn_position: Vector2 = Vector2.ZERO
var _anim_time: float = 0.0
var _trail_timer: float = 0.0
var _sprite_base_pos: Vector2 = Vector2.ZERO
var _last_attack: int = -1

func _ready() -> void:
	_spawn_position = global_position
	max_health = 42
	scrap_drop_count = 8
	touch_damage = 1
	knockback_resistance = 3.0
	super._ready()
	_sprite_base_pos = sprite.position
	_set_texture(TEX_IDLE)
	# A glowing rim keeps the dark serpent readable against the mine walls
	var outline: ShaderMaterial = ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("outline_color", Color(0.9, 0.45, 1.0, 0.95))
	outline.set_shader_parameter("pulse_speed", 4.0)
	sprite.material = outline
	if eruption_hitbox:
		eruption_hitbox.faction = HitboxComponent.Faction.ENEMY
		eruption_hitbox.damage = 2
		eruption_hitbox.knockback_force = 280.0
		eruption_hitbox.monitorable = false
	if reticle:
		reticle.top_level = true
		reticle.visible = false
		reticle.scale = Vector2(2.0, 2.0)

func get_spawn_position() -> Vector2:
	return _spawn_position

func _physics_process(delta: float) -> void:
	if is_dying:
		return

	_locate_player()

	match current_state:
		State.DORMANT:
			velocity = Vector2.ZERO
			if _target_player and global_position.distance_to(_target_player.global_position) < wake_range:
				_wake_up()
		State.IDLE:
			velocity.x = 0.0
			_apply_gravity(delta)
			_face_player()
			_state_timer -= delta
			if _state_timer <= 0.0:
				_choose_next_attack()
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
			_apply_gravity(delta)
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.IDLE
				_state_timer = 0.25 if current_phase == 1 else 0.1
		State.LUNGE_WINDUP:
			velocity.x = 0.0
			_apply_gravity(delta)
			sprite.position.x = _sprite_base_pos.x + randf_range(-1.5, 1.5)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_execute_lunge()
		State.LUNGE:
			_apply_gravity(delta)
			_trail_timer -= delta
			if _trail_timer <= 0.0:
				_trail_timer = 0.04
				FX.afterimage(get_parent(), sprite, Color(0.8, 0.3, 1.0, 0.5), 0.2)
			_state_timer -= delta
			if _state_timer <= 0.0 or is_on_wall():
				_recover(0.6)
		State.CEILING_CRAWL:
			_process_ceiling_crawl(delta)
		State.THORN_RAIN:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				_end_thorn_rain()
		State.SPIKE_VOLLEY:
			velocity.x = 0.0
			sprite.position.x = _sprite_base_pos.x + randf_range(-1.0, 1.0)
			_state_timer -= delta
			if _state_timer <= 0.0:
				_fire_spike_volley()
		State.BURROW_SINK:
			velocity = Vector2.ZERO
			_state_timer -= delta
			if _state_timer <= 0.0:
				current_state = State.BURROW_APPROACH
				_state_timer = 1.1 if current_phase == 1 else 0.75
				visuals.visible = false
		State.BURROW_APPROACH:
			_process_burrow_approach(delta)
		State.BURROW_STRIKE:
			velocity = Vector2.ZERO

	# Burrowing / ceiling states move the boss manually (no body physics)
	if current_state not in [State.BURROW_SINK, State.BURROW_APPROACH, State.CEILING_CRAWL, State.THORN_RAIN]:
		move_and_slide()

func _process(delta: float) -> void:
	if is_dying or current_state == State.DORMANT:
		return
	_anim_time += delta
	# Slithering sway: the serpent never sits perfectly still
	var sway: float = sin(_anim_time * 5.0)
	match current_state:
		State.IDLE, State.RECOVER:
			sprite.skew = sway * 0.12
			sprite.position.y = _sprite_base_pos.y + sin(_anim_time * 2.5) * 2.0
		State.CEILING_CRAWL, State.THORN_RAIN:
			sprite.skew = sway * 0.2
		_:
			sprite.skew = 0.0

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

# ---------------------------------------------------------
# Phase / attack selection
# ---------------------------------------------------------
func _wake_up() -> void:
	current_state = State.IDLE
	_state_timer = 1.2
	boss_health_changed.emit(health_component.current_health, max_health)
	_face_player()
	ScreenShake.add_trauma(0.4)
	FX.debris(get_parent(), global_position, 14, 150.0)
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(0.75, 0.3, 1.0, 1.0), 20, 160.0, false, 3.0, 0.6)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "wolf_bite", 0.1, 2.0)
	var roar: Tween = create_tween()
	roar.tween_property(visuals, "scale", Vector2(_facing_direction * 1.3, 1.3), 0.25)
	roar.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)

func _choose_next_attack() -> void:
	_attack_step += 1
	_face_player()
	var dist: float = _distance_to_player()
	var choice: int
	if dist < 100.0 and _last_attack != 0:
		choice = 0 # lunge
	else:
		var pool: Array = [1, 2, 3] # ceiling rain, volley, burrow
		pool.erase(_last_attack)
		choice = pool[randi() % pool.size()]
	_last_attack = choice
	match choice:
		0:
			_start_lunge()
		1:
			_start_ceiling_crawl()
		2:
			_start_spike_volley()
		_:
			_start_burrow()

func _recover(duration: float) -> void:
	current_state = State.RECOVER
	_state_timer = duration * (0.65 if current_phase == 2 else 1.0)
	_set_texture(TEX_IDLE)
	visuals.scale = Vector2(_facing_direction, 1.0)

# ---------------------------------------------------------
# Attack 0: Lunge bite (close range)
# ---------------------------------------------------------
func _start_lunge() -> void:
	current_state = State.LUNGE_WINDUP
	_state_timer = 0.4 if current_phase == 1 else 0.28
	_set_texture(TEX_STRIKE)
	# Coil back before striking
	var coil: Tween = create_tween()
	coil.tween_property(visuals, "scale", Vector2(_facing_direction * 0.75, 1.2), _state_timer).set_trans(Tween.TRANS_SINE)
	FX.flash(sprite, Color(2.0, 0.9, 2.2), _state_timer)

func _execute_lunge() -> void:
	current_state = State.LUNGE
	_state_timer = 0.32
	_trail_timer = 0.0
	velocity.x = _facing_direction * lunge_speed
	visuals.scale = Vector2(_facing_direction * 1.35, 0.85)
	create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.3)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "wolf_bite", 0.1, 0.0)
	FX.dust(get_parent(), global_position, 8, 80.0)

# ---------------------------------------------------------
# Attack 1: Ceiling Crawl -> Thorn Rain
# ---------------------------------------------------------
func _start_ceiling_crawl() -> void:
	current_state = State.CEILING_CRAWL
	_state_timer = 1.3 if current_phase == 1 else 0.95
	_set_texture(TEX_IDLE)
	FX.dust(get_parent(), global_position, 10, 120.0)
	# Leap up and cling to the mine ceiling upside down
	sprite.flip_v = true
	sprite.position.y = -_sprite_base_pos.y * 0.2
	if hitbox_component:
		hitbox_component.monitorable = false

func _process_ceiling_crawl(delta: float) -> void:
	var target_x: float = global_position.x
	if _target_player and is_instance_valid(_target_player):
		target_x = _target_player.global_position.x
	global_position.x = move_toward(global_position.x, target_x, crawl_speed * delta)
	global_position.y = move_toward(global_position.y, ceiling_y, 360.0 * delta)
	_face_player()
	_state_timer -= delta
	if _state_timer <= 0.0:
		_start_thorn_rain()

func _start_thorn_rain() -> void:
	current_state = State.THORN_RAIN
	_state_timer = 0.55
	_set_texture(TEX_STRIKE)
	FX.burst(get_parent(), global_position, Color(0.75, 0.3, 1.0, 1.0), 14, 120.0, false, 3.0, 0.5)

	var drop_count: int = 5 if current_phase == 2 else 3
	var center_x: float = _target_player.global_position.x if _target_player else global_position.x
	var parent_node: Node = get_parent()
	for i in range(drop_count):
		var offset: float = (i - (drop_count - 1) * 0.5) * 64.0
		var stala: CharacterBody2D = STALACTITE_SCENE.instantiate() as CharacterBody2D
		if stala:
			stala.global_position = Vector2(center_x + offset, ceiling_y - 20.0)
			if stala.has_method("setup"):
				stala.call("setup", floor_y + 16.0)
			parent_node.call_deferred("add_child", stala)
	ScreenShake.add_trauma(0.4)

func _end_thorn_rain() -> void:
	# Drop back down onto the mine floor
	_set_texture(TEX_IDLE)
	current_state = State.BURROW_STRIKE # inert while the drop tween plays
	var land: Tween = create_tween()
	land.tween_property(self, "global_position:y", floor_y, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	land.tween_callback(func():
		sprite.flip_v = false
		sprite.position = _sprite_base_pos
		visuals.scale = Vector2(_facing_direction * 1.35, 0.7)
		create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
		FX.dust(get_parent(), global_position, 14, 120.0)
		ScreenShake.add_trauma(0.3)
		if hitbox_component:
			hitbox_component.monitorable = true
		_recover(0.8)
	)

# ---------------------------------------------------------
# Attack 2: Spike Volley (aimed fan of thorns)
# ---------------------------------------------------------
func _start_spike_volley() -> void:
	current_state = State.SPIKE_VOLLEY
	_state_timer = 0.5 if current_phase == 1 else 0.35
	_set_texture(TEX_STRIKE)
	var windup: Tween = create_tween()
	windup.tween_property(visuals, "scale", Vector2(_facing_direction * 1.2, 0.85), _state_timer)
	FX.flash(sprite, Color(2.2, 1.0, 2.6), _state_timer)

func _fire_spike_volley() -> void:
	sprite.position.x = _sprite_base_pos.x
	visuals.scale = Vector2(_facing_direction * 0.85, 1.2)
	create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.2)
	if _target_player and is_instance_valid(_target_player):
		var angle_count: int = 5 if current_phase == 2 else 3
		var base_dir: Vector2 = (_target_player.global_position + Vector2(0, -16) - (global_position + Vector2(0, -30))).normalized()
		for i in range(angle_count):
			var spread: float = deg_to_rad(16.0) * (i - (angle_count - 1) * 0.5)
			var thorn: CharacterBody2D = THORN_SCENE.instantiate() as CharacterBody2D
			if thorn:
				thorn.global_position = global_position + Vector2(_facing_direction * 20.0, -30)
				if thorn.has_method("launch"):
					thorn.call("launch", base_dir.rotated(spread))
				thorn.set("speed", 170.0 if current_phase == 1 else 210.0)
				get_parent().call_deferred("add_child", thorn)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "bow_shoot", 0.1, -2.0)
	_recover(0.9)

# ---------------------------------------------------------
# Attack 3: Burrow Strike (digs under the arena and erupts beneath the hero)
# ---------------------------------------------------------
func _start_burrow() -> void:
	current_state = State.BURROW_SINK
	_state_timer = 0.4
	_set_texture(TEX_BURROW)
	velocity = Vector2.ZERO
	if hitbox_component:
		hitbox_component.monitorable = false
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
	FX.dust(get_parent(), global_position, 16, 110.0)
	var sink: Tween = create_tween()
	sink.tween_property(visuals, "scale", Vector2(_facing_direction * 1.3, 0.2), 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if reticle:
		reticle.visible = true
		reticle.global_position = Vector2(global_position.x, floor_y - 4.0)

func _process_burrow_approach(delta: float) -> void:
	if _target_player and is_instance_valid(_target_player):
		_burrow_target_x = _target_player.global_position.x
	global_position.x = move_toward(global_position.x, _burrow_target_x, burrow_speed * delta)
	if reticle:
		reticle.global_position = Vector2(global_position.x, floor_y - 4.0)
	# Churning dirt shows where it travels under the floor
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.07
		FX.dust(get_parent(), Vector2(global_position.x, floor_y), 4, 70.0)
		ScreenShake.add_trauma(0.03)
	_state_timer -= delta
	if _state_timer <= 0.0:
		_erupt()

func _erupt() -> void:
	current_state = State.BURROW_STRIKE
	global_position.y = floor_y
	visuals.visible = true
	_set_texture(TEX_STRIKE)
	if reticle:
		reticle.visible = false
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", true)
	if hitbox_component:
		hitbox_component.monitorable = true
	if eruption_hitbox:
		eruption_hitbox.monitorable = true
	ScreenShake.add_trauma(0.5)
	FX.debris(get_parent(), global_position, 18, 200.0)
	FX.dust(get_parent(), global_position, 18, 150.0)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.1, -3.0)

	visuals.scale = Vector2(_facing_direction * 0.6, 1.6)
	var burst: Tween = create_tween()
	burst.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC)

	await get_tree().create_timer(0.18, false).timeout
	if eruption_hitbox:
		eruption_hitbox.monitorable = false
	if current_state == State.BURROW_STRIKE:
		_recover(0.85)

# ---------------------------------------------------------
# Health, Phase 2 & Death
# ---------------------------------------------------------
func _on_damaged(_amount: int, _knockback: Vector2) -> void:
	super._on_damaged(_amount, _knockback)
	boss_health_changed.emit(health_component.current_health, max_health)
	FX.sparks(get_parent(), global_position + Vector2(randf_range(-12, 12), randf_range(-50, -20)), Color(0.95, 0.7, 1.0, 1.0))
	if not _phase_2_triggered and health_component.current_health <= (max_health / 2):
		_trigger_phase_2()

func _trigger_phase_2() -> void:
	_phase_2_triggered = true
	current_phase = 2
	boss_phase_changed.emit(2)
	crawl_speed *= 1.3
	burrow_speed *= 1.25
	lunge_speed *= 1.15
	ScreenShake.add_trauma(0.6)
	FX.burst(get_parent(), global_position + Vector2(0, -40), Color(0.8, 0.3, 1.0, 1.0), 26, 200.0, false, 3.0, 0.7)
	var rage: Tween = create_tween().set_parallel(true)
	rage.tween_property(visuals, "scale", Vector2(_facing_direction * 1.3, 1.3), 0.4)
	rage.tween_property(visuals, "modulate", Color(1.8, 0.6, 2.5), 0.4)
	rage.chain().tween_property(visuals, "modulate", Color(1.2, 0.85, 1.35), 0.6)
	rage.chain().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.3)

func _on_died() -> void:
	if is_dying:
		return
	is_dying = true
	current_state = State.DYING
	set_physics_process(false)
	visuals.visible = true
	sprite.flip_v = false
	if reticle:
		reticle.visible = false
	if hitbox_component:
		hitbox_component.set_deferred("monitorable", false)
	if eruption_hitbox:
		eruption_hitbox.set_deferred("monitorable", false)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
	ScreenShake.add_trauma(0.5)
	ScreenShake.hitstop(0.1)

	_spawn_scrap_drops()
	boss_defeated.emit()

	# Thrashing death: writhe, flash and burst into thorny ash
	for i in 4:
		await get_tree().create_timer(0.18, false).timeout
		if not is_inside_tree():
			return
		visuals.rotation = randf_range(-0.25, 0.25)
		FX.flash(visuals, Color(2.6, 2.0, 2.8), 0.1)
		FX.burst(get_parent(), global_position + Vector2(randf_range(-20, 20), randf_range(-50, -10)), Color(0.75, 0.3, 1.0, 1.0), 10, 150.0, false, 3.0, 0.5)
		ScreenShake.add_trauma(0.25)
	FX.debris(get_parent(), global_position, 20, 200.0)
	var dissolve: Tween = create_tween().set_parallel(true)
	dissolve.tween_property(visuals, "scale", Vector2(1.5, 0.1), 0.5)
	dissolve.tween_property(visuals, "modulate:a", 0.0, 0.5)
	await dissolve.finished
	queue_free()

func _face_player() -> void:
	if _target_player and is_instance_valid(_target_player):
		var dir: float = signf(_target_player.global_position.x - global_position.x)
		if not is_zero_approx(dir):
			_facing_direction = dir
			visuals.scale = Vector2(_facing_direction * absf(visuals.scale.x), visuals.scale.y)

func _distance_to_player() -> float:
	if _target_player and is_instance_valid(_target_player):
		return absf(_target_player.global_position.x - global_position.x)
	return 9999.0

func _set_texture(tex: Texture2D) -> void:
	if sprite and tex:
		sprite.texture = tex

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController

func reset_boss() -> void:
	if is_dying:
		return
	current_state = State.DORMANT
	current_phase = 1
	_phase_2_triggered = false
	_attack_step = 0
	_last_attack = -1
	crawl_speed = 130.0
	burrow_speed = 190.0
	lunge_speed = 380.0
	velocity = Vector2.ZERO
	global_position = _spawn_position
	if health_component:
		health_component.current_health = max_health
	boss_health_changed.emit(max_health, max_health)
	_set_texture(TEX_IDLE)
	if visuals:
		visuals.visible = true
		visuals.scale = Vector2(_facing_direction, 1.0)
		visuals.modulate = Color.WHITE
		visuals.rotation = 0.0
	if sprite:
		sprite.flip_v = false
		sprite.skew = 0.0
		sprite.position = _sprite_base_pos
	if reticle:
		reticle.visible = false
	if eruption_hitbox:
		eruption_hitbox.monitorable = false
	if hitbox_component:
		hitbox_component.set_deferred("monitorable", true)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", true)
