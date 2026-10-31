class_name CorruptedArboris
extends CharacterBody2D

## Act II Boss: Corrupted Arboris (آربوریس مسخ‌شده)
## The forest's ancient guardian tree, its mind poisoned by a pulsing Marg-mayeh crystal in its back.
## Its bark shrugs off blows from the front: the hero has to get behind it (slide past, grapple over,
## or wait for a slam to bury its arms in the ground) to strike the crystal.
##
## Phase 1: root eruptions that chase the hero, low thorn-branch sweeps (jump them), arm slams that
##          leave it stuck and exposed, and spinning thorn bursts.
## Phase 2: faster everything, acid-glob volleys that leave burning puddles, and a toxic fog that
##          floods the arena floor and drives the hero up onto the branches.
## Turning around is slow and telegraphed (creaking, shaking) so getting behind it is a fair play.

signal boss_health_changed(current: int, max_hp: int)
signal boss_phase_changed(phase: int)
signal boss_defeated()

enum State {
	DORMANT,
	INTRO,
	IDLE,
	WALK,
	TURN,
	ROOT_WINDUP,
	SWEEP_WINDUP,
	SWEEP,
	SLAM_WINDUP,
	SLAM_STUCK,
	SPIN_WINDUP,
	ACID_WINDUP,
	FOG_CALL,
	RECOVER,
	PHASE_TRANSITION,
	DYING,
}

enum Attack { NONE, ROOTS, SWEEP, SLAM, SPIN, ACID, FOG }

const ROOT_SPIKE_SCENE = preload("res://characters/bosses/arboris/RootSpike.tscn")
const ACID_GLOB_SCENE = preload("res://characters/bosses/arboris/AcidGlob.tscn")
const THORN_SCENE = preload("res://characters/enemies/thorn_spitter/ThornProjectile.tscn")
const BARK_DROP_SCENE = preload("res://components/collectibles/ArborisBark.tscn")
const OUTLINE_SHADER = preload("res://components/fx/PixelOutline.gdshader")

const TEX_IDLE = preload("res://assets/sprites/bosses/arboris/arboris_idle.png")
const TEX_WINDUP = preload("res://assets/sprites/bosses/arboris/arboris_windup.png")
const TEX_SLAM = preload("res://assets/sprites/bosses/arboris/arboris_slam.png")
const TEX_SPREAD = preload("res://assets/sprites/bosses/arboris/arboris_spread.png")

@export var max_health: int = 108
@export var walk_speed: float = 26.0
@export var gravity: float = 900.0
@export var arena_left: float = 3820.0
@export var arena_right: float = 4580.0
@export var floor_y: float = 320.0
## Seconds the hero may stand behind it before it turns around.
@export var turn_delay: float = 1.3

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: ArborisBarkHurtbox = $HurtboxComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var crystal_marker: Marker2D = $Visuals/CrystalMarker
@onready var crystal_glow: CPUParticles2D = $Visuals/CrystalMarker/CrystalGlow

var current_state: State = State.DORMANT
var current_phase: int = 1
var is_dying: bool = false
var _target_player: PlayerController = null
## -1 faces left (the way the art is drawn), +1 faces right.
var _facing: float = -1.0
var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _behind_timer: float = 0.0
var _attacks_since_fog: int = 0
var _last_attack: Attack = Attack.NONE
var _spawn_position: Vector2 = Vector2.ZERO
var _sprite_base_pos: Vector2 = Vector2.ZERO
var _material: ShaderMaterial = null
var _sweep_hitbox: HitboxComponent = null
var _slam_hitbox: HitboxComponent = null
var _fog: Node2D = null
var _fog_hitbox: HitboxComponent = null
var _fog_timer: float = 0.0
var _fog_tween: Tween = null
var _root_queue: Array[float] = []
var _root_timer: float = 0.0
var _shot_fired: bool = false

func _ready() -> void:
	_spawn_position = global_position
	_sprite_base_pos = sprite.position
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)
	if hurtbox_component:
		hurtbox_component.faction = HitboxComponent.Faction.ENEMY
		hurtbox_component.boss = self
		hurtbox_component.deflected.connect(_on_deflected)
	_material = ShaderMaterial.new()
	_material.shader = OUTLINE_SHADER
	_material.set_shader_parameter("outline_color", Color(0.05, 0.03, 0.08, 1.0))
	sprite.material = _material
	_sweep_hitbox = _make_hitbox(Vector2(170, 22), Vector2(-105, -11), 1, 260.0)
	_slam_hitbox = _make_hitbox(Vector2(86, 54), Vector2(-74, -27), 2, 300.0)
	_build_fog()
	_apply_facing()
	_set_texture(TEX_IDLE)
	_set_crystal_exposed(false)

# ---------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------
## Attack hitboxes live under Visuals so they mirror with the facing direction (art faces left).
func _make_hitbox(size: Vector2, pos: Vector2, damage: int, knockback: float) -> HitboxComponent:
	var hitbox: HitboxComponent = HitboxComponent.new()
	hitbox.collision_layer = 2
	hitbox.collision_mask = 4
	hitbox.faction = HitboxComponent.Faction.ENEMY
	hitbox.damage = damage
	hitbox.knockback_force = knockback
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	hitbox.add_child(shape)
	hitbox.position = pos
	visuals.add_child(hitbox)
	hitbox.set_deferred("monitorable", false)
	return hitbox

## Toxic fog band hugging the arena floor (Phase 2). Lives in level space, not on the boss.
func _build_fog() -> void:
	_fog = Node2D.new()
	_fog.name = "ToxicFog"
	_fog.top_level = true
	_fog.z_index = 3
	_fog.visible = false
	var width: float = arena_right - arena_left
	var band: Polygon2D = Polygon2D.new()
	# Dense toxic green at the floor fading to violet haze; the band is taller than the
	# damaging layer so the danger zone reads clearly from the branches above
	band.polygon = PackedVector2Array([Vector2(0, 0), Vector2(width, 0), Vector2(width, -36), Vector2(width, -76),
		Vector2(0, -76), Vector2(0, -36)])
	band.vertex_colors = PackedColorArray([
		Color(0.5, 0.9, 0.25, 0.85), Color(0.5, 0.9, 0.25, 0.85),
		Color(0.55, 0.75, 0.35, 0.6), Color(0.6, 0.35, 0.85, 0.0),
		Color(0.6, 0.35, 0.85, 0.0), Color(0.55, 0.75, 0.35, 0.6)])
	_fog.add_child(band)
	var puffs: CPUParticles2D = CPUParticles2D.new()
	puffs.amount = 40
	puffs.lifetime = 2.4
	puffs.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	puffs.emission_rect_extents = Vector2(width * 0.5, 8.0)
	puffs.position = Vector2(width * 0.5, -14)
	puffs.direction = Vector2.UP
	puffs.spread = 40.0
	puffs.gravity = Vector2(0, -6)
	puffs.initial_velocity_min = 4.0
	puffs.initial_velocity_max = 14.0
	puffs.scale_amount_min = 8.0
	puffs.scale_amount_max = 16.0
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(0.65, 1.0, 0.4, 0.6))
	ramp.set_color(1, Color(0.6, 0.35, 0.85, 0.0))
	puffs.color_ramp = ramp
	_fog.add_child(puffs)
	_fog_hitbox = HitboxComponent.new()
	_fog_hitbox.collision_layer = 2
	_fog_hitbox.collision_mask = 4
	_fog_hitbox.faction = HitboxComponent.Faction.ENEMY
	_fog_hitbox.damage = 1
	_fog_hitbox.knockback_force = 120.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(width, 30)
	shape.shape = rect
	shape.position = Vector2(width * 0.5, -15)
	_fog_hitbox.add_child(shape)
	_fog.add_child(_fog_hitbox)
	add_child(_fog)
	_fog.global_position = Vector2(arena_left, floor_y)
	_fog_hitbox.set_deferred("monitorable", false)

# ---------------------------------------------------------
# Public API (driven by the level)
# ---------------------------------------------------------
func wake_up() -> void:
	if current_state != State.DORMANT or is_dying:
		return
	_locate_player()
	_face_player()
	current_state = State.INTRO
	_state_timer = 0.0
	boss_health_changed.emit(health_component.current_health, max_health)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.05, -2.0)
	# Uproots itself: rises, shakes the canopy and roars leaves everywhere
	_set_texture(TEX_WINDUP)
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "position:y", _sprite_base_pos.y - 10.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		ScreenShake.add_trauma(0.6)
		FX.burst(get_parent(), global_position + Vector2(0, -130), Color(0.45, 0.62, 0.3, 1.0), 26, 160.0, false, 3.0, 1.0)
		FX.dust(get_parent(), global_position, 20, 140.0)
	)
	tween.tween_property(sprite, "position:y", _sprite_base_pos.y, 0.25).set_trans(Tween.TRANS_BACK)

func reset_boss() -> void:
	if is_dying:
		return
	current_state = State.DORMANT
	current_phase = 1
	_state_timer = 0.0
	_behind_timer = 0.0
	_attacks_since_fog = 0
	_last_attack = Attack.NONE
	_root_queue.clear()
	velocity = Vector2.ZERO
	global_position = _spawn_position
	_facing = -1.0
	_apply_facing()
	_end_fog()
	_disable_attack_hitboxes()
	_set_crystal_exposed(false)
	_clear_projectiles()
	if health_component:
		health_component.current_health = max_health
		health_component.is_invulnerable = false
	boss_health_changed.emit(max_health, max_health)
	_set_texture(TEX_IDLE)
	sprite.position = _sprite_base_pos
	sprite.rotation = 0.0
	visuals.modulate = Color.WHITE
	visuals.rotation = 0.0

func is_crystal_exposed() -> bool:
	return current_state == State.SLAM_STUCK

## World-space x of the weak-point crystal (on the tree's back).
func get_crystal_position() -> Vector2:
	return crystal_marker.global_position

func get_facing() -> float:
	return _facing

# ---------------------------------------------------------
# Main loop
# ---------------------------------------------------------
func _physics_process(delta: float) -> void:
	if is_dying:
		return
	_locate_player()
	_anim_time += delta
	_state_timer += delta
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0
	velocity.x = 0.0

	_update_roots(delta)
	_update_fog(delta)

	match current_state:
		State.DORMANT:
			_idle_sway()
		State.INTRO:
			if _state_timer >= 1.3:
				_enter_idle()
		State.IDLE:
			_idle_sway()
			_track_behind(delta)
			if current_state == State.IDLE and _state_timer >= _idle_time():
				_choose_attack()
		State.WALK:
			_process_walk(delta)
		State.TURN:
			_process_turn()
		State.ROOT_WINDUP:
			_process_root_windup()
		State.SWEEP_WINDUP:
			_process_sweep_windup()
		State.SWEEP:
			_process_sweep()
		State.SLAM_WINDUP:
			_process_slam_windup()
		State.SLAM_STUCK:
			_process_slam_stuck()
		State.SPIN_WINDUP:
			_process_spin()
		State.ACID_WINDUP:
			_process_acid()
		State.FOG_CALL:
			_process_fog_call()
		State.RECOVER:
			sprite.position = sprite.position.lerp(_sprite_base_pos, 0.2)
			sprite.rotation = lerpf(sprite.rotation, 0.0, 0.2)
			if _state_timer >= _recover_time():
				_enter_idle()
		State.PHASE_TRANSITION:
			_process_phase_transition()

	move_and_slide()

func _idle_time() -> float:
	return 0.75 if current_phase == 1 else 0.45

func _recover_time() -> float:
	return 0.55 if current_phase == 1 else 0.35

func _idle_sway() -> void:
	# Slow breathing of the canopy
	sprite.position.y = _sprite_base_pos.y + sin(_anim_time * 1.8) * 1.5
	sprite.rotation = sin(_anim_time * 1.1) * 0.015

func _enter_idle() -> void:
	current_state = State.IDLE
	_state_timer = 0.0
	_set_texture(TEX_IDLE)
	sprite.position = _sprite_base_pos
	sprite.rotation = 0.0

## While the hero lingers behind it, count up; when patience runs out it turns around.
func _track_behind(delta: float) -> void:
	if not _target_player:
		return
	if _player_side() != _facing:
		_behind_timer += delta
		var delay: float = turn_delay if current_phase == 1 else turn_delay * 0.65
		if _behind_timer >= delay:
			_enter_turn()
	else:
		_behind_timer = 0.0

func _player_side() -> float:
	if not _target_player:
		return _facing
	var side: float = signf(_target_player.global_position.x - global_position.x)
	return _facing if is_zero_approx(side) else side

func _player_distance() -> float:
	if not _target_player:
		return 9999.0
	return absf(_target_player.global_position.x - global_position.x)

# ---------------------------------------------------------
# Attack selection
# ---------------------------------------------------------
func _choose_attack() -> void:
	if not _target_player:
		return
	# Never attack the wrong way: turn first
	if _player_side() != _facing:
		_enter_turn()
		return
	var dist: float = _player_distance()
	var options: Array[Attack] = []
	if dist < 130.0:
		options.append_array([Attack.SLAM, Attack.SLAM, Attack.SWEEP])
	elif dist < 220.0:
		options.append_array([Attack.SWEEP, Attack.SWEEP, Attack.ROOTS])
	else:
		options.append_array([Attack.ROOTS, Attack.SPIN])
		# Too far to bother with branches: lumber closer sometimes
		if dist > 300.0 and randf() < 0.35:
			_enter_walk()
			return
	options.append(Attack.SPIN)
	if current_phase == 2:
		options.append_array([Attack.ACID, Attack.ACID])
		if _attacks_since_fog >= 5 and _fog_timer <= 0.0:
			options = [Attack.FOG]
	# Avoid repeating the same move back to back
	if options.size() > 1:
		options.erase(_last_attack)
	var attack: Attack = options[randi() % options.size()]
	_last_attack = attack
	_attacks_since_fog += 1
	match attack:
		Attack.ROOTS:
			_enter_root_windup()
		Attack.SWEEP:
			_enter_sweep_windup()
		Attack.SLAM:
			_enter_slam_windup()
		Attack.SPIN:
			_enter_spin()
		Attack.ACID:
			_enter_acid()
		Attack.FOG:
			_enter_fog_call()

# ---------------------------------------------------------
# Walk & turn
# ---------------------------------------------------------
func _enter_walk() -> void:
	current_state = State.WALK
	_state_timer = 0.0

func _process_walk(_delta: float) -> void:
	var dir: float = _player_side()
	if dir != _facing:
		_enter_turn()
		return
	var next_x: float = global_position.x + dir * walk_speed * get_physics_process_delta_time()
	if next_x > arena_left + 70.0 and next_x < arena_right - 70.0:
		velocity.x = dir * walk_speed
	# Lumbering root-steps
	sprite.rotation = sin(_state_timer * 5.0) * 0.04
	sprite.position.y = _sprite_base_pos.y - absf(sin(_state_timer * 5.0)) * 3.0
	if fmod(_state_timer, 0.63) < get_physics_process_delta_time():
		FX.dust(get_parent(), global_position + Vector2(-_facing * 10.0, 0), 4, 40.0)
		ScreenShake.add_trauma(0.05)
	if _state_timer >= 1.4 or _player_distance() < 200.0:
		_enter_idle()

func _enter_turn() -> void:
	current_state = State.TURN
	_state_timer = 0.0
	_behind_timer = 0.0
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "shield_block", 0.1, -10.0)

func _process_turn() -> void:
	# Creaking shudder telegraphs the turn, then it swings around
	var turn_time: float = 0.5 if current_phase == 1 else 0.32
	sprite.position.x = _sprite_base_pos.x + sin(_state_timer * 60.0) * 1.5
	if _state_timer >= turn_time:
		_facing = -_facing
		_apply_facing()
		sprite.position = _sprite_base_pos
		FX.dust(get_parent(), global_position, 8, 70.0)
		_enter_recover()

# ---------------------------------------------------------
# Root eruption
# ---------------------------------------------------------
func _enter_root_windup() -> void:
	current_state = State.ROOT_WINDUP
	_state_timer = 0.0
	_set_texture(TEX_WINDUP)

func _process_root_windup() -> void:
	var windup: float = 0.6 if current_phase == 1 else 0.42
	sprite.position.y = _sprite_base_pos.y - minf(_state_timer / windup, 1.0) * 6.0
	if _state_timer >= windup:
		_set_texture(TEX_SLAM)
		sprite.position.y = _sprite_base_pos.y + 4.0
		ScreenShake.add_trauma(0.35)
		FX.dust(get_parent(), global_position + Vector2(_facing * 50.0, 0), 12, 110.0)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "boss_slam")
		# A line of roots marches toward the hero; in phase 2 one also bursts right under them
		var count: int = 4 if current_phase == 1 else 6
		var start_x: float = global_position.x + _facing * 70.0
		_root_queue.clear()
		for i in count:
			_root_queue.append(start_x + _facing * i * 52.0)
		if current_phase == 2 and _target_player:
			_root_queue.insert(2, _target_player.global_position.x)
		_root_timer = 0.0
		_enter_recover()

func _update_roots(delta: float) -> void:
	if _root_queue.is_empty():
		return
	_root_timer -= delta
	if _root_timer > 0.0:
		return
	_root_timer = 0.17 if current_phase == 1 else 0.12
	var x: float = clampf(_root_queue.pop_front(), arena_left + 12.0, arena_right - 12.0)
	var spike: Node2D = ROOT_SPIKE_SCENE.instantiate() as Node2D
	spike.add_to_group(&"boss_projectiles")
	get_parent().add_child(spike)
	spike.global_position = Vector2(x, floor_y)

# ---------------------------------------------------------
# Thorn-branch sweep (jump it)
# ---------------------------------------------------------
func _enter_sweep_windup() -> void:
	current_state = State.SWEEP_WINDUP
	_state_timer = 0.0
	_set_texture(TEX_SPREAD)

func _process_sweep_windup() -> void:
	var windup: float = 0.6 if current_phase == 1 else 0.42
	# Pull back and coil
	sprite.rotation = lerpf(0.0, 0.12 * -_facing, minf(_state_timer / windup, 1.0))
	sprite.position.x = _sprite_base_pos.x + sin(_state_timer * 40.0) * 1.0
	if _state_timer >= windup:
		current_state = State.SWEEP
		_state_timer = 0.0
		_set_texture(TEX_SLAM)
		sprite.rotation = 0.1 * _facing
		_sweep_hitbox.monitorable = true
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "heavy_slash", 0.1, -2.0)
		# Leaves and grit fly along the swept ground
		for i in 5:
			FX.dust(get_parent(), global_position + Vector2(_facing * (30.0 + i * 34.0), 0), 4, 70.0)
		FX.burst(get_parent(), global_position + Vector2(_facing * 90.0, -10), Color(0.75, 0.45, 1.0, 0.9), 10, 120.0, false, 2.0, 0.35)

func _process_sweep() -> void:
	if _state_timer >= 0.22:
		_sweep_hitbox.set_deferred("monitorable", false)
		_enter_recover()

# ---------------------------------------------------------
# Arm slam -> stuck (crystal exposed)
# ---------------------------------------------------------
func _enter_slam_windup() -> void:
	current_state = State.SLAM_WINDUP
	_state_timer = 0.0
	_set_texture(TEX_WINDUP)

func _process_slam_windup() -> void:
	var windup: float = 0.75 if current_phase == 1 else 0.52
	sprite.position.y = _sprite_base_pos.y - minf(_state_timer / windup, 1.0) * 10.0
	sprite.position.x = _sprite_base_pos.x + sin(_state_timer * 50.0) * minf(_state_timer, 1.0)
	if _state_timer >= windup:
		current_state = State.SLAM_STUCK
		_state_timer = 0.0
		_set_texture(TEX_SLAM)
		sprite.position = _sprite_base_pos + Vector2(0, 6)
		sprite.rotation = -0.08 * _facing
		_slam_hitbox.monitorable = true
		ScreenShake.add_trauma(0.6)
		FX.debris(get_parent(), global_position + Vector2(_facing * 70.0, 0), 14, 170.0)
		FX.dust(get_parent(), global_position + Vector2(_facing * 70.0, 0), 16, 130.0)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.05, 2.0)
		_set_crystal_exposed(true)

func _process_slam_stuck() -> void:
	if _state_timer >= 0.15 and _slam_hitbox.monitorable:
		_slam_hitbox.set_deferred("monitorable", false)
	var stuck: float = 1.7 if current_phase == 1 else 1.15
	# Struggling to pull its arms out of the ground
	sprite.position.x = _sprite_base_pos.x + sin(_state_timer * 18.0) * 1.2
	if _state_timer >= stuck:
		_set_crystal_exposed(false)
		FX.dust(get_parent(), global_position + Vector2(_facing * 70.0, 0), 10, 80.0)
		_enter_recover()

# ---------------------------------------------------------
# Spinning thorn burst
# ---------------------------------------------------------
func _enter_spin() -> void:
	current_state = State.SPIN_WINDUP
	_state_timer = 0.0
	_shot_fired = false
	_set_texture(TEX_SPREAD)

func _process_spin() -> void:
	var windup: float = 0.55 if current_phase == 1 else 0.4
	# The canopy trembles faster and faster, then sprays thorns in a ring
	sprite.rotation = sin(_state_timer * (20.0 + _state_timer * 30.0)) * 0.05
	if not _shot_fired and _state_timer >= windup:
		_shot_fired = true
		_fire_thorn_ring(8, 0.0)
		if current_phase == 2:
			get_tree().create_timer(0.3, false).timeout.connect(func():
				if not is_dying and current_state != State.DORMANT:
					_fire_thorn_ring(8, PI / 8.0)
			)
	if _state_timer >= windup + (0.5 if current_phase == 1 else 0.6):
		_enter_recover()

func _fire_thorn_ring(count: int, offset: float) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "bow_shoot", 0.15, -2.0)
	var origin: Vector2 = global_position + Vector2(0, -96)
	FX.burst(get_parent(), origin, Color(0.8, 0.5, 1.0, 1.0), 14, 120.0, false, 2.5, 0.4)
	for i in count:
		var angle: float = offset + TAU * i / count
		var dir: Vector2 = Vector2(cos(angle), sin(angle))
		# Skip shots aimed straight into the floor right under the trunk
		if dir.y > 0.85:
			continue
		var thorn: ThornProjectile = THORN_SCENE.instantiate() as ThornProjectile
		thorn.speed = 130.0 if current_phase == 1 else 160.0
		thorn.lifetime = 3.0
		thorn.add_to_group(&"boss_projectiles")
		get_parent().add_child(thorn)
		thorn.global_position = origin + dir * 20.0
		thorn.launch(dir)

# ---------------------------------------------------------
# Phase 2: acid volley
# ---------------------------------------------------------
func _enter_acid() -> void:
	current_state = State.ACID_WINDUP
	_state_timer = 0.0
	_shot_fired = false
	_set_texture(TEX_WINDUP)

func _process_acid() -> void:
	sprite.position.y = _sprite_base_pos.y - minf(_state_timer / 0.45, 1.0) * 5.0
	if not _shot_fired and _state_timer >= 0.45:
		_shot_fired = true
		_set_texture(TEX_SPREAD)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "grapple_shoot", 0.1, -2.0)
		var px: float = _target_player.global_position.x if _target_player else global_position.x + _facing * 150.0
		for offset in [-58.0, 0.0, 58.0]:
			var glob: AcidGlob = ACID_GLOB_SCENE.instantiate() as AcidGlob
			glob.floor_y = floor_y
			glob.add_to_group(&"boss_projectiles")
			get_parent().add_child(glob)
			glob.global_position = global_position + Vector2(_facing * 20.0, -120)
			var target_x: float = clampf(px + offset, arena_left + 20.0, arena_right - 20.0)
			glob.launch_to(target_x, 0.85 + absf(offset) * 0.002)
	if _state_timer >= 0.95:
		_enter_recover()

# ---------------------------------------------------------
# Phase 2: toxic fog (forces the hero onto the branches)
# ---------------------------------------------------------
func _enter_fog_call() -> void:
	current_state = State.FOG_CALL
	_state_timer = 0.0
	_attacks_since_fog = 0
	_set_texture(TEX_WINDUP)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.1, -6.0)
	ScreenShake.add_trauma(0.3)
	# Creeping warning: the fog rolls in harmlessly first
	_fog.visible = true
	_fog.modulate.a = 0.0
	if _fog_tween:
		_fog_tween.kill()
	_fog_tween = _fog.create_tween()
	_fog_tween.tween_property(_fog, "modulate:a", 0.45, 1.0)
	_fog_timer = 5.0

func _process_fog_call() -> void:
	sprite.rotation = sin(_state_timer * 30.0) * 0.03
	if _state_timer >= 1.1:
		if _fog_tween:
			_fog_tween.kill()
		_fog.modulate.a = 1.0
		_fog_hitbox.monitorable = true
		_enter_recover()

func _update_fog(delta: float) -> void:
	if _fog_timer <= 0.0:
		return
	_fog_timer -= delta
	if _fog_timer <= 0.0:
		_end_fog()

func _end_fog() -> void:
	_fog_timer = 0.0
	if _fog_hitbox:
		_fog_hitbox.set_deferred("monitorable", false)
	if _fog and _fog.visible:
		if _fog_tween:
			_fog_tween.kill()
		_fog_tween = _fog.create_tween()
		_fog_tween.tween_property(_fog, "modulate:a", 0.0, 0.8)
		_fog_tween.tween_callback(func(): _fog.visible = false)

func is_fog_active() -> bool:
	return _fog_timer > 0.0

# ---------------------------------------------------------
# Shared states
# ---------------------------------------------------------
func _enter_recover() -> void:
	current_state = State.RECOVER
	_state_timer = 0.0
	_set_texture(TEX_IDLE)

func _process_phase_transition() -> void:
	sprite.position.x = _sprite_base_pos.x + sin(_state_timer * 70.0) * 2.0
	if fmod(_state_timer, 0.3) < get_physics_process_delta_time():
		FX.burst(get_parent(), global_position + Vector2(randf_range(-30, 30), -120), Color(0.45, 0.6, 0.3, 1.0), 10, 120.0, false, 3.0, 0.8)
	if _state_timer >= 1.6:
		sprite.position = _sprite_base_pos
		_material.set_shader_parameter("outline_color", Color(0.55, 0.15, 0.85, 1.0))
		_material.set_shader_parameter("pulse_speed", 5.0)
		_enter_recover()

func _disable_attack_hitboxes() -> void:
	for hitbox in [_sweep_hitbox, _slam_hitbox]:
		if hitbox:
			hitbox.set_deferred("monitorable", false)

func _clear_projectiles() -> void:
	for node in get_tree().get_nodes_in_group(&"boss_projectiles"):
		if is_instance_valid(node):
			node.queue_free()

# ---------------------------------------------------------
# Damage & weak point
# ---------------------------------------------------------
## Hits from the front glance off the bark (sparks + clank) unless its arms are stuck in the ground.
func _on_deflected(hit_position: Vector2) -> void:
	FX.sparks(get_parent(), hit_position, Color(0.85, 0.75, 0.55, 1.0), 6)
	FX.burst(get_parent(), hit_position, Color(0.42, 0.32, 0.24, 1.0), 4, 70.0, true, 2.0, 0.4)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "shield_block", 0.1, -3.0)
	# Flash the crystal to teach where to strike
	crystal_glow.amount = 24
	get_tree().create_timer(0.4, false).timeout.connect(func(): crystal_glow.amount = 10)

func _on_damaged(_amount: int, _knockback: Vector2) -> void:
	boss_health_changed.emit(health_component.current_health, max_health)
	FX.flash(visuals, Color(2.2, 1.6, 2.6), 0.12)
	FX.sparks(get_parent(), crystal_marker.global_position, Color(0.85, 0.5, 1.0, 1.0), 12)
	FX.burst(get_parent(), crystal_marker.global_position, Color(0.75, 0.35, 1.0, 1.0), 6, 90.0, false, 2.0, 0.35)
	if current_phase == 1 and health_component.current_health <= max_health / 2:
		_trigger_phase_2()

func _trigger_phase_2() -> void:
	current_phase = 2
	# The first fog comes a couple of attacks into phase 2, not straight away
	_attacks_since_fog = 2
	boss_phase_changed.emit(2)
	_root_queue.clear()
	_disable_attack_hitboxes()
	_set_crystal_exposed(false)
	current_state = State.PHASE_TRANSITION
	_state_timer = 0.0
	_set_texture(TEX_SPREAD)
	ScreenShake.add_trauma(0.7)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.05, 3.0)

func _on_died() -> void:
	if is_dying:
		return
	is_dying = true
	current_state = State.DYING
	velocity = Vector2.ZERO
	_root_queue.clear()
	_end_fog()
	_disable_attack_hitboxes()
	_clear_projectiles()
	hurtbox_component.set_deferred("monitoring", false)
	boss_defeated.emit()
	_play_purification()

## The crystal shatters and the corruption drains away: the guardian is healed, not destroyed.
func _play_purification() -> void:
	_set_texture(TEX_SPREAD)
	_material.set_shader_parameter("outline_color", Color(0.05, 0.03, 0.08, 1.0))
	_material.set_shader_parameter("pulse_speed", 0.0)
	ScreenShake.add_trauma(0.9)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "enemy_die", 0.0, 2.0)
		get_node("/root/AudioManager").call("play_sfx", "boss_slam")
	var crystal_at: Vector2 = crystal_marker.global_position
	var tween: Tween = create_tween()
	# Convulse while violet light bleeds out
	for i in 6:
		tween.tween_callback(func():
			FX.sparks(get_parent(), crystal_at + Vector2(randf_range(-8, 8), randf_range(-8, 8)), Color(0.85, 0.5, 1.0, 1.0), 10)
			sprite.position.x = _sprite_base_pos.x + randf_range(-3.0, 3.0)
		)
		tween.tween_property(visuals, "modulate", Color(2.0, 1.4, 2.4), 0.06)
		tween.tween_property(visuals, "modulate", Color.WHITE, 0.14)
	# Shatter
	tween.tween_callback(func():
		crystal_glow.emitting = false
		ScreenShake.add_trauma(0.8)
		FX.burst(get_parent(), crystal_at, Color(0.8, 0.45, 1.0, 1.0), 30, 220.0, false, 3.0, 0.9)
		FX.burst(get_parent(), global_position + Vector2(0, -140), Color(0.5, 0.75, 0.35, 1.0), 30, 140.0, false, 3.0, 1.4)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "beacon_ignite")
	)
	# Settle back into a calm, healed tree
	tween.tween_callback(func(): _set_texture(TEX_IDLE))
	tween.tween_property(sprite, "position", _sprite_base_pos + Vector2(0, 4), 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(visuals, "modulate", Color(0.82, 1.0, 0.86), 1.4)
	tween.tween_callback(_drop_bark)

func _drop_bark() -> void:
	if not BARK_DROP_SCENE:
		return
	var bark: Node2D = BARK_DROP_SCENE.instantiate() as Node2D
	get_parent().add_child(bark)
	bark.global_position = global_position + Vector2(-_facing * 60.0, -30)

# ---------------------------------------------------------
# Visual helpers
# ---------------------------------------------------------
func _apply_facing() -> void:
	# The art faces left
	visuals.scale.x = -_facing

func _face_player() -> void:
	if _target_player:
		_facing = _player_side()
		_apply_facing()

func _set_texture(tex: Texture2D) -> void:
	if sprite and tex and sprite.texture != tex:
		sprite.texture = tex

func _set_crystal_exposed(exposed: bool) -> void:
	if not crystal_glow:
		return
	crystal_glow.amount = 26 if exposed else 10
	crystal_glow.scale_amount_max = 4.0 if exposed else 2.5
	if _material:
		_material.set_shader_parameter("outline_color",
			Color(0.95, 0.75, 1.0, 1.0) if exposed else (Color(0.55, 0.15, 0.85, 1.0) if current_phase == 2 else Color(0.05, 0.03, 0.08, 1.0)))

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController
