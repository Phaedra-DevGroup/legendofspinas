class_name CrusherOfTheRuins
extends CharacterBody2D

## Act 1 Boss: Crusher of the Ruins (سنگ‌شکن ویرانه‌ها)
## A stone colossus that stalks the hero across a sealed arena and picks attacks by range:
## close-range swipe, seismic slam (shockwaves + crystal spikes), aimed boulder volleys,
## a telegraphed bull charge that leaves it stunned and exposed when it smashes into the arena wall,
## and in Phase 2 a ground-breaker leap plus attack combos.
## All motion is animated procedurally (breathing, footsteps, squash & stretch, afterimages, dust).

signal boss_health_changed(current: int, max_hp: int)
signal boss_phase_changed(phase: int)
signal boss_defeated()

enum State {
	SLEEPING,
	IDLE,
	WINDUP_SLAM,
	WINDUP_BOULDER,
	CHARGING,
	LEAP_ANTICIPATION,
	LEAPING,
	STUNNED,
	PHASE_TRANSITION,
	DYING,
	INTRO,
	WALK,
	WINDUP_SWIPE,
	CHARGE_WINDUP,
	RECOVER,
}

enum Attack { NONE, SWIPE, SLAM, BOULDER, CHARGE, LEAP }

const SHOCKWAVE_SCENE = preload("res://characters/bosses/crusher/ShockwaveProjectile.tscn")
const ROCK_SCENE = preload("res://characters/bosses/crusher/ThrownRockProjectile.tscn")
const STALACTITE_SCENE = preload("res://characters/bosses/crusher/FallingStalactite.tscn")
const CRYSTAL_SPIKE_SCENE = preload("res://characters/bosses/crusher/CrystalSpikeHazard.tscn")
const GEAR_DROP_SCENE = preload("res://components/collectibles/AncientGearBossDrop.tscn")
const RETICLE_TEX = preload("res://assets/sprites/bosses/crusher/fx/warning_reticle.png")
const OUTLINE_SHADER = preload("res://components/fx/PixelOutline.gdshader")

const TEX_IDLE_0 = preload("res://assets/sprites/bosses/crusher/crusher_idle_0.png")
const TEX_IDLE_1 = preload("res://assets/sprites/bosses/crusher/crusher_idle_1.png")
const TEX_SLAM = preload("res://assets/sprites/bosses/crusher/crusher_slam_0.png")
const TEX_CHARGE = preload("res://assets/sprites/bosses/crusher/crusher_charge_0.png")
const TEX_STUN = preload("res://assets/sprites/bosses/crusher/crusher_stun_0.png")

const ROCK_GRAVITY: float = 650.0

@export var max_health: int = 96
@export var base_charge_speed: float = 168.0
@export var walk_speed: float = 46.0
@export var gravity: float = 900.0
## Sealed arena span (the level raises walls here when the fight starts).
@export var arena_left: float = 4470.0
@export var arena_right: float = 5300.0
@export var floor_y: float = 320.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D

var current_state: State = State.SLEEPING
var current_phase: int = 1
var _target_player: PlayerController = null
var _facing_direction: float = -1.0
var _state_timer: float = 0.0
var _anim_time: float = 0.0
var _step_timer: float = 0.0
var _afterimage_timer: float = 0.0
var _phase_2_triggered: bool = false
var _leap_target_x: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _last_attack: Attack = Attack.NONE
var _repeat_count: int = 0
var _combo_queue: Array[Attack] = []
var _swipe_hitbox: HitboxComponent = null
var _shadow: Polygon2D = null
var _reticle: Sprite2D = null
var _sprite_base_pos: Vector2 = Vector2.ZERO
var _tint: Color = Color.WHITE
var _leap_tween: Tween = null

func _ready() -> void:
	_spawn_position = global_position
	_sprite_base_pos = sprite.position
	if health_component:
		health_component.max_health = max_health
		health_component.current_health = max_health
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)

	if hitbox_component:
		hitbox_component.faction = HitboxComponent.Faction.ENEMY
		hitbox_component.damage = 2
		hitbox_component.knockback_force = 240.0

	if hurtbox_component:
		hurtbox_component.faction = HitboxComponent.Faction.ENEMY

	_build_swipe_hitbox()
	_build_shadow()
	var outline: ShaderMaterial = ShaderMaterial.new()
	outline.shader = OUTLINE_SHADER
	outline.set_shader_parameter("outline_color", Color(0.08, 0.05, 0.12, 1.0))
	sprite.material = outline
	_set_texture(TEX_IDLE_0)

# ---------------------------------------------------------
# Setup helpers
# ---------------------------------------------------------
func _build_swipe_hitbox() -> void:
	_swipe_hitbox = HitboxComponent.new()
	_swipe_hitbox.collision_layer = 2
	_swipe_hitbox.collision_mask = 4
	_swipe_hitbox.faction = HitboxComponent.Faction.ENEMY
	_swipe_hitbox.damage = 2
	_swipe_hitbox.knockback_force = 300.0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(64, 60)
	shape.shape = rect
	_swipe_hitbox.add_child(shape)
	_swipe_hitbox.position = Vector2(52, -40)
	visuals.add_child(_swipe_hitbox)
	_swipe_hitbox.set_deferred("monitorable", false)

func _build_shadow() -> void:
	_shadow = Polygon2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	for i in 16:
		var a: float = TAU * i / 16.0
		pts.append(Vector2(cos(a) * 34.0, sin(a) * 6.0))
	_shadow.polygon = pts
	_shadow.color = Color(0.0, 0.0, 0.05, 0.35)
	_shadow.top_level = true
	_shadow.z_index = -1
	add_child(_shadow)
	_shadow.global_position = Vector2(global_position.x, floor_y)

# ---------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------
func wake_up() -> void:
	if current_state != State.SLEEPING:
		return
	_face_player()
	current_state = State.INTRO
	_state_timer = 1.5
	boss_health_changed.emit(health_component.current_health, max_health)
	# Awakening roar: rise, shudder, slam a foot down
	_set_texture(TEX_SLAM)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 0.9, 1.2), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		ScreenShake.add_trauma(0.6)
		FX.debris(get_parent(), global_position + Vector2(0, -4), 14)
		FX.dust(get_parent(), global_position, 18, 120.0)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.05, 2.0)
	)
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 1.2, 0.85), 0.08)
	tween.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.3).set_trans(Tween.TRANS_BACK)

func _physics_process(delta: float) -> void:
	if current_state == State.DYING:
		return
	_locate_player()

	if current_state != State.LEAPING:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0.0

	match current_state:
		State.SLEEPING:
			velocity.x = 0.0
			if _target_player and global_position.distance_to(_target_player.global_position) < 260.0:
				wake_up()
		State.INTRO:
			velocity.x = 0.0
			_tick_then(delta, _begin_walk)
		State.IDLE:
			velocity.x = 0.0
			_face_player()
			_tick_then(delta, _choose_next_attack)
		State.WALK:
			_process_walk(delta)
		State.WINDUP_SWIPE:
			velocity.x = 0.0
			_tick_then(delta, _execute_swipe)
		State.WINDUP_SLAM:
			velocity.x = 0.0
			_shudder(1.5)
			_tick_then(delta, _execute_ground_slam)
		State.WINDUP_BOULDER:
			velocity.x = 0.0
			_tick_then(delta, _execute_rock_throw)
		State.CHARGE_WINDUP:
			velocity.x = 0.0
			_shudder(2.0)
			_step_timer -= delta
			if _step_timer <= 0.0:
				# Bull-like hoof scrapes telegraph the charge
				_step_timer = 0.18
				FX.dust(get_parent(), global_position + Vector2(-_facing_direction * 18.0, 0), 5, 60.0)
			_tick_then(delta, _launch_charge)
		State.CHARGING:
			_process_charge(delta)
		State.LEAP_ANTICIPATION:
			velocity.x = 0.0
			_shudder(1.5)
			_tick_then(delta, _execute_leap_airborne)
		State.LEAPING:
			pass # driven by a tween
		State.STUNNED:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_tick_then(delta, _recover_from_stun)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			_tick_then(delta, _end_recover)
		State.PHASE_TRANSITION:
			velocity.x = 0.0
			_shudder(2.5)
			_tick_then(delta, func():
				current_state = State.IDLE
				_state_timer = 0.3
			)

	if current_state != State.LEAPING:
		move_and_slide()
		global_position.x = clampf(global_position.x, arena_left, arena_right)

func _process(delta: float) -> void:
	if current_state == State.DYING:
		return
	_anim_time += delta
	_animate(delta)
	if _shadow:
		_shadow.global_position = Vector2(global_position.x, floor_y)
		var height: float = maxf(0.0, floor_y - global_position.y)
		var s: float = clampf(1.0 - height / 260.0, 0.35, 1.0)
		_shadow.scale = Vector2(s, s)

## Counts down the state timer and runs `next` once it expires.
func _tick_then(delta: float, next: Callable) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		next.call()

# ---------------------------------------------------------
# Procedural animation
# ---------------------------------------------------------
func _animate(delta: float) -> void:
	var bob: float = 0.0
	match current_state:
		State.SLEEPING:
			bob = sin(_anim_time * 1.4) * 1.0
		State.IDLE, State.INTRO, State.RECOVER:
			# Heavy breathing
			bob = sin(_anim_time * 3.2) * 1.5
			_set_texture(TEX_IDLE_1 if fmod(_anim_time, 0.8) < 0.4 else TEX_IDLE_0)
		State.WALK:
			# Lumbering footsteps: bounce, alternate frames
			var cycle: float = fmod(_anim_time, 0.5) / 0.5
			bob = -absf(sin(cycle * PI)) * 4.0
			_set_texture(TEX_IDLE_1 if cycle < 0.5 else TEX_IDLE_0)
		State.STUNNED:
			# Dazed sway with the exposed core pulsing
			bob = sin(_anim_time * 2.0) * 1.0
			visuals.rotation = sin(_anim_time * 5.0) * 0.05
			sprite.self_modulate = Color(0.85, 0.85, 0.9).lerp(Color(1.25, 1.7, 1.7), 0.5 + 0.5 * sin(_anim_time * 10.0))
		State.CHARGING:
			_afterimage_timer -= delta
			if _afterimage_timer <= 0.0:
				_afterimage_timer = 0.05
				FX.afterimage(get_parent(), sprite, Color(1.0, 0.35, 0.45, 0.5))
	if current_state != State.STUNNED:
		visuals.rotation = 0.0
		sprite.self_modulate = _tint
	sprite.position = _sprite_base_pos + Vector2(0, bob)

## Small tremble used during windups to sell the effort.
func _shudder(strength: float) -> void:
	sprite.position.x = _sprite_base_pos.x + randf_range(-strength, strength)

# ---------------------------------------------------------
# Movement
# ---------------------------------------------------------
func _begin_walk() -> void:
	current_state = State.WALK
	_state_timer = randf_range(0.6, 1.1) if current_phase == 1 else randf_range(0.35, 0.7)
	_step_timer = 0.25

func _process_walk(delta: float) -> void:
	_face_player()
	var dist: float = _distance_to_player()
	if dist < 56.0:
		velocity.x = 0.0
		_choose_next_attack()
		return
	var spd: float = walk_speed * (1.45 if current_phase == 2 else 1.0)
	velocity.x = _facing_direction * spd
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.5
		ScreenShake.add_trauma(0.08)
		FX.dust(get_parent(), global_position + Vector2(_facing_direction * 14.0, 0), 5, 50.0)
	_tick_then(delta, _choose_next_attack)

# ---------------------------------------------------------
# Attack selection: by range, never the same move three times in a row
# ---------------------------------------------------------
func _choose_next_attack() -> void:
	_face_player()
	var next: Attack = Attack.NONE
	if not _combo_queue.is_empty():
		next = _combo_queue.pop_front()
	else:
		var dist: float = _distance_to_player()
		var options: Array[Attack] = []
		if dist < 80.0:
			options = [Attack.SWIPE, Attack.SWIPE, Attack.SLAM]
		elif dist < 220.0:
			options = [Attack.SLAM, Attack.CHARGE, Attack.BOULDER]
		else:
			options = [Attack.BOULDER, Attack.CHARGE, Attack.CHARGE]
		if current_phase == 2:
			options.append(Attack.LEAP)
			if dist >= 80.0:
				options.append(Attack.LEAP)
		for _try in 4:
			next = options[randi() % options.size()]
			if next != _last_attack or _repeat_count < 1:
				break

	_repeat_count = _repeat_count + 1 if next == _last_attack else 0
	_last_attack = next
	match next:
		Attack.SWIPE:
			_start_swipe()
		Attack.SLAM:
			_start_ground_slam()
			if current_phase == 2 and _combo_queue.is_empty() and randf() < 0.5:
				_combo_queue.append(Attack.CHARGE)
		Attack.BOULDER:
			_start_boulder_throw()
		Attack.CHARGE:
			_start_charge()
		Attack.LEAP:
			_start_ground_breaker_leap()
			if randf() < 0.4:
				_combo_queue.append(Attack.SLAM)

func _recover(duration: float) -> void:
	current_state = State.RECOVER
	_state_timer = duration * (0.7 if current_phase == 2 else 1.0)
	_set_texture(TEX_IDLE_0)

func _end_recover() -> void:
	if not _combo_queue.is_empty():
		_choose_next_attack()
	else:
		_begin_walk()

# ---------------------------------------------------------
# Attack: Close swipe
# ---------------------------------------------------------
func _start_swipe() -> void:
	current_state = State.WINDUP_SWIPE
	_state_timer = 0.42 if current_phase == 1 else 0.3
	_set_texture(TEX_SLAM)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 0.85, 1.12), _state_timer).set_trans(Tween.TRANS_SINE)
	FX.flash(sprite, Color(1.8, 1.5, 1.0), _state_timer)

func _execute_swipe() -> void:
	_set_texture(TEX_CHARGE)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "heavy_slash", 0.08, 1.0)
	# Lunge forward with an arcing backhand
	velocity.x = _facing_direction * 260.0
	visuals.scale = Vector2(_facing_direction * 1.3, 0.9)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
	_swipe_hitbox.set_deferred("monitorable", true)
	FX.dust(get_parent(), global_position, 8, 90.0)
	get_tree().create_timer(0.18, false).timeout.connect(func():
		if is_instance_valid(_swipe_hitbox):
			_swipe_hitbox.set_deferred("monitorable", false)
	)
	_recover(0.75)

# ---------------------------------------------------------
# Attack: Seismic Fissure (Ground Slam + Crystal Spikes)
# ---------------------------------------------------------
func _start_ground_slam() -> void:
	current_state = State.WINDUP_SLAM
	_state_timer = 0.68 if current_phase == 1 else 0.48
	_set_texture(TEX_SLAM)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 0.85, 1.25), _state_timer * 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "_tint", Color(2.0, 0.8, 2.3), _state_timer * 0.8)

func _execute_ground_slam() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam")
	_tint = Color.WHITE
	visuals.scale = Vector2(_facing_direction * 1.45, 0.65)
	var settle: Tween = create_tween()
	settle.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.3).set_trans(Tween.TRANS_ELASTIC)
	ScreenShake.add_trauma(0.5)
	FX.debris(get_parent(), global_position + Vector2(_facing_direction * 30.0, 0), 12)
	FX.dust(get_parent(), global_position, 20, 140.0)

	_spawn_shockwave(1.0)
	_spawn_shockwave(-1.0)
	var spike_offsets: Array = [40.0, 80.0] if current_phase == 1 else [40.0, 80.0, 120.0]
	for i in spike_offsets.size():
		var off: float = spike_offsets[i]
		# Spikes ripple outward one after another
		get_tree().create_timer(0.08 * i, false).timeout.connect(func():
			_spawn_crystal_spike(Vector2(global_position.x + off, floor_y))
			_spawn_crystal_spike(Vector2(global_position.x - off, floor_y))
		)
	_set_texture(TEX_SLAM)
	_recover(1.1)

func _spawn_shockwave(dir: float) -> void:
	var wave: CharacterBody2D = SHOCKWAVE_SCENE.instantiate() as CharacterBody2D
	if wave:
		# Spawn resting on the floor surface: spawning inside the floor made move_and_collide
		# report a hit on the first frame and the wave vanished before it ever travelled
		wave.global_position = Vector2(global_position.x + dir * 34.0, floor_y - 1.0)
		if wave.has_method("set_direction"):
			wave.call("set_direction", dir)
		if current_phase == 2:
			wave.set("speed", 220.0)
		get_parent().add_child(wave)

func _spawn_crystal_spike(pos: Vector2) -> void:
	if pos.x < arena_left - 20.0 or pos.x > arena_right + 20.0:
		return
	var spike: Node2D = CRYSTAL_SPIKE_SCENE.instantiate() as Node2D
	if spike:
		spike.global_position = pos + Vector2(0, 16.0)
		get_parent().add_child(spike)
		FX.burst(get_parent(), pos, Color(0.4, 1.0, 0.95, 1.0), 6, 70.0, true, 2.0, 0.35)

# ---------------------------------------------------------
# Attack: Catapult Boulder Toss (aimed; a spread volley in Phase 2)
# ---------------------------------------------------------
func _start_boulder_throw() -> void:
	current_state = State.WINDUP_BOULDER
	_state_timer = 0.75 if current_phase == 1 else 0.55
	_set_texture(TEX_SLAM)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 0.9, 1.25), _state_timer).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "_tint", Color(2.3, 1.3, 0.5), _state_timer)

func _execute_rock_throw() -> void:
	_tint = Color.WHITE
	visuals.scale = Vector2(_facing_direction * 1.2, 0.9)
	create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.25)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "heavy_slash", 0.1, -2.0)
	if _target_player:
		var aim_x: float = _target_player.global_position.x
		# Lead the hero's movement a little
		aim_x += _target_player.velocity.x * 0.35
		var shots: Array = [[0.0, 0.85]] if current_phase == 1 else [[-60.0, 0.7], [0.0, 0.9], [60.0, 1.1]]
		for s in shots:
			_throw_rock_at(Vector2(aim_x + float(s[0]), floor_y - 8.0), float(s[1]))
	_set_texture(TEX_IDLE_0)
	_recover(0.9)

func _throw_rock_at(target: Vector2, flight_time: float) -> void:
	var rock: CharacterBody2D = ROCK_SCENE.instantiate() as CharacterBody2D
	if not rock:
		return
	var start: Vector2 = global_position + Vector2(_facing_direction * 20.0, -110.0)
	rock.global_position = start
	# Solve the ballistic arc that lands on `target` after `flight_time`
	var v: Vector2 = Vector2(
		(target.x - start.x) / flight_time,
		(target.y - start.y - 0.5 * ROCK_GRAVITY * flight_time * flight_time) / flight_time)
	rock.set("gravity", ROCK_GRAVITY)
	if rock.has_method("launch"):
		rock.call("launch", v)
	get_parent().add_child(rock)

# ---------------------------------------------------------
# Attack: Bull Charge -> crashes into the arena wall and is left stunned (weak point exposed)
# ---------------------------------------------------------
func _start_charge() -> void:
	current_state = State.CHARGE_WINDUP
	_state_timer = 0.75 if current_phase == 1 else 0.55
	_step_timer = 0.0
	_set_texture(TEX_CHARGE)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 1.2, 0.85), _state_timer).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "_tint", Color(1.9, 0.7, 0.75), _state_timer)

func _launch_charge() -> void:
	current_state = State.CHARGING
	_state_timer = 2.6
	_afterimage_timer = 0.0
	_tint = Color(1.3, 0.85, 0.85)
	visuals.scale = Vector2(_facing_direction * 1.1, 0.95)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "wolf_bite", 0.05, -2.0)

func _process_charge(delta: float) -> void:
	var spd: float = base_charge_speed * (1.55 if current_phase == 2 else 1.3)
	velocity.x = _facing_direction * spd
	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_timer = 0.12
		FX.dust(get_parent(), global_position + Vector2(-_facing_direction * 16.0, 0), 4, 60.0)
		ScreenShake.add_trauma(0.05)
	var at_edge: bool = (global_position.x <= arena_left + 1.0 and _facing_direction < 0.0) \
		or (global_position.x >= arena_right - 1.0 and _facing_direction > 0.0)
	if is_on_wall() or at_edge:
		_crash_into_wall()
		return
	_state_timer -= delta
	if _state_timer <= 0.0:
		# Ran out of steam: skid to a halt
		_tint = Color.WHITE
		velocity.x = _facing_direction * spd * 0.5
		FX.dust(get_parent(), global_position, 10, 90.0)
		_recover(0.8)

func _crash_into_wall() -> void:
	current_state = State.STUNNED
	_state_timer = 2.6 if current_phase == 1 else 2.0
	_tint = Color.WHITE
	_set_texture(TEX_STUN)
	velocity.x = -_facing_direction * 120.0
	ScreenShake.add_trauma(0.7)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.05, 3.0)
	FX.debris(get_parent(), global_position + Vector2(_facing_direction * 30.0, -60.0), 16, 200.0)
	_spawn_ceiling_stalactites()
	visuals.scale = Vector2(_facing_direction * 0.7, 1.3)
	create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC)

func _spawn_ceiling_stalactites() -> void:
	var parent_node: Node = get_parent()
	var target_x: float = _target_player.global_position.x if _target_player else global_position.x
	var drops: int = 3 if current_phase == 1 else 5
	for i in drops:
		var drop_x: float = clampf(target_x + (i - (drops - 1) * 0.5) * 90.0, arena_left, arena_right)
		var stala: CharacterBody2D = STALACTITE_SCENE.instantiate() as CharacterBody2D
		if stala:
			stala.global_position = Vector2(drop_x, 70.0)
			if stala.has_method("setup"):
				stala.call("setup", floor_y + 16.0)
			parent_node.call_deferred("add_child", stala)

func _recover_from_stun() -> void:
	sprite.self_modulate = Color.WHITE
	visuals.rotation = 0.0
	_set_texture(TEX_IDLE_0)
	# Shake off the rubble
	visuals.scale = Vector2(_facing_direction * 1.15, 0.9)
	create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.25)
	FX.dust(get_parent(), global_position, 10, 80.0)
	_recover(0.4)

# ---------------------------------------------------------
# Phase 2 Attack: Ground Breaker Leap
# ---------------------------------------------------------
func _start_ground_breaker_leap() -> void:
	current_state = State.LEAP_ANTICIPATION
	_state_timer = 0.6
	_set_texture(TEX_SLAM)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 1.4, 0.6), 0.5).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(self, "_tint", Color(2.3, 0.5, 2.3), 0.5)

func _execute_leap_airborne() -> void:
	current_state = State.LEAPING
	_tint = Color.WHITE
	var target_x: float = _target_player.global_position.x if _target_player else global_position.x
	_leap_target_x = clampf(target_x, arena_left + 20.0, arena_right - 20.0)
	visuals.scale = Vector2(_facing_direction * 0.75, 1.4)
	FX.dust(get_parent(), global_position, 16, 130.0)
	ScreenShake.add_trauma(0.25)
	_show_reticle(_leap_target_x)

	var start: Vector2 = global_position
	var duration: float = 0.85
	var arc: Tween = create_tween()
	_leap_tween = arc
	arc.tween_method(func(t: float):
		global_position = Vector2(lerpf(start.x, _leap_target_x, t), floor_y - sin(t * PI) * 170.0)
		if t > 0.5:
			visuals.scale = Vector2(_facing_direction * 0.85, 1.25)
	, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE)
	arc.tween_callback(_execute_leap_impact)

func _execute_leap_impact() -> void:
	if current_state != State.LEAPING:
		return
	global_position.y = floor_y
	velocity = Vector2.ZERO
	_hide_reticle()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam")
	visuals.scale = Vector2(_facing_direction * 1.5, 0.6)
	create_tween().tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.35).set_trans(Tween.TRANS_ELASTIC)
	ScreenShake.add_trauma(0.65)
	FX.debris(get_parent(), global_position, 16, 180.0)
	FX.dust(get_parent(), global_position, 24, 160.0)
	_spawn_shockwave(1.0)
	_spawn_shockwave(-1.0)
	_spawn_crystal_spike(Vector2(global_position.x - 44, floor_y))
	_spawn_crystal_spike(Vector2(global_position.x + 44, floor_y))
	_set_texture(TEX_IDLE_0)
	_recover(0.9)

func _show_reticle(x: float) -> void:
	if not _reticle:
		_reticle = Sprite2D.new()
		_reticle.texture = RETICLE_TEX
		_reticle.top_level = true
		_reticle.scale = Vector2(2.5, 2.0)
		add_child(_reticle)
	_reticle.visible = true
	_reticle.global_position = Vector2(x, floor_y - 4.0)
	var blink: Tween = _reticle.create_tween().set_loops(4)
	blink.tween_property(_reticle, "modulate:a", 0.3, 0.1)
	blink.tween_property(_reticle, "modulate:a", 1.0, 0.1)

func _hide_reticle() -> void:
	if _reticle:
		_reticle.visible = false

# ---------------------------------------------------------
# Health, Damage & Phase 2 Transition
# ---------------------------------------------------------
func _on_damaged(amount: int, _knockback: Vector2) -> void:
	# The stunned colossus exposes its turquoise core: hits land twice as hard
	if current_state == State.STUNNED and health_component.current_health > 0:
		health_component.current_health = maxi(0, health_component.current_health - amount)
		FX.sparks(get_parent(), global_position + Vector2(0, -60), Color(0.5, 1.0, 0.95, 1.0), 12)
		if health_component.current_health <= 0:
			health_component.died.emit()
			return
	boss_health_changed.emit(health_component.current_health, max_health)
	FX.flash(visuals, Color(2.4, 2.4, 2.4), 0.12)
	FX.sparks(get_parent(), global_position + Vector2(randf_range(-14, 14), randf_range(-80, -30)))
	if current_state in [State.IDLE, State.WALK, State.RECOVER]:
		# Flinch
		sprite.position.x += -_facing_direction * 3.0

	if not _phase_2_triggered and health_component.current_health <= (max_health / 2):
		_trigger_phase_2()

func _trigger_phase_2() -> void:
	_phase_2_triggered = true
	current_phase = 2
	_combo_queue.clear()
	_hide_reticle()
	boss_phase_changed.emit(2)
	current_state = State.PHASE_TRANSITION
	_state_timer = 1.5
	_set_texture(TEX_SLAM)
	velocity = Vector2.ZERO
	# Brief invulnerability while it roars so the transition always plays out
	health_component.is_invulnerable = true
	health_component._invulnerability_timer = 1.5
	ScreenShake.add_trauma(0.8)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.0, 4.0)

	var tween: Tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(_facing_direction * 1.35, 1.35), 0.5).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "_tint", Color(1.7, 0.7, 2.2), 0.5)
	tween.tween_property(visuals, "scale", Vector2(_facing_direction, 1.0), 0.4)
	# From now on it glows with corrupted rage
	tween.tween_property(self, "_tint", Color(1.25, 0.85, 1.35), 0.5)
	tween.tween_callback(func(): _tint = Color(1.25, 0.85, 1.35))

	for off in [-120.0, -70.0, -30.0, 30.0, 70.0, 120.0]:
		_spawn_crystal_spike(Vector2(global_position.x + off, floor_y))
	FX.burst(get_parent(), global_position + Vector2(0, -60), Color(0.8, 0.3, 1.0, 1.0), 30, 200.0, false, 3.0, 0.8)

func _on_died() -> void:
	if current_state == State.DYING:
		return
	current_state = State.DYING
	set_physics_process(false)
	_hide_reticle()
	_combo_queue.clear()
	velocity = Vector2.ZERO
	boss_defeated.emit()

	if hitbox_component:
		hitbox_component.set_deferred("monitorable", false)
	if _swipe_hitbox:
		_swipe_hitbox.set_deferred("monitorable", false)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", false)
	for node in get_tree().get_nodes_in_group(&"boss_projectiles"):
		if is_instance_valid(node):
			node.queue_free()

	# Death throes: tremble, flash and burst apart before crumbling into rubble
	_set_texture(TEX_STUN)
	_tint = Color.WHITE
	sprite.self_modulate = Color.WHITE
	visuals.rotation = 0.0
	ScreenShake.add_trauma(0.8)
	ScreenShake.hitstop(0.12)
	for i in 6:
		await get_tree().create_timer(0.22, false).timeout
		if not is_inside_tree():
			return
		sprite.position = _sprite_base_pos + Vector2(randf_range(-4, 4), randf_range(-2, 2))
		FX.flash(visuals, Color(3.0, 3.0, 3.0), 0.12)
		FX.debris(get_parent(), global_position + Vector2(randf_range(-30, 30), randf_range(-110, -20)), 8, 170.0)
		FX.burst(get_parent(), global_position + Vector2(randf_range(-24, 24), randf_range(-90, -30)), Color(0.45, 1.0, 0.95, 1.0), 10, 160.0, false, 3.0, 0.5)
		ScreenShake.add_trauma(0.35)
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "enemy_die", 0.15, 0.0)

	var gear: Node2D = GEAR_DROP_SCENE.instantiate() as Node2D
	if gear:
		gear.global_position = global_position + Vector2(0, -20)
		get_parent().call_deferred("add_child", gear)
	FX.debris(get_parent(), global_position, 30, 220.0)
	FX.dust(get_parent(), global_position, 30, 180.0)
	ScreenShake.add_trauma(0.9)
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "boss_slam", 0.0, 3.0)

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(visuals, "scale", Vector2(1.6, 0.05), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(visuals, "modulate:a", 0.0, 0.5)
	if _shadow:
		tween.tween_property(_shadow, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

# ---------------------------------------------------------
# Utilities
# ---------------------------------------------------------
func _face_player() -> void:
	if _target_player and is_instance_valid(_target_player):
		var dir: float = signf(_target_player.global_position.x - global_position.x)
		if not is_zero_approx(dir):
			_facing_direction = dir
			if visuals:
				visuals.scale.x = absf(visuals.scale.x) * _facing_direction

func _distance_to_player() -> float:
	if _target_player and is_instance_valid(_target_player):
		return absf(_target_player.global_position.x - global_position.x)
	return 9999.0

func _set_texture(tex: Texture2D) -> void:
	if sprite and tex and sprite.texture != tex:
		sprite.texture = tex

func _locate_player() -> void:
	if not _target_player or not is_instance_valid(_target_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			_target_player = players[0] as PlayerController

func reset_boss() -> void:
	if current_state == State.DYING:
		return
	current_state = State.SLEEPING
	current_phase = 1
	_phase_2_triggered = false
	_last_attack = Attack.NONE
	_repeat_count = 0
	_combo_queue.clear()
	velocity = Vector2.ZERO
	if _leap_tween and _leap_tween.is_valid():
		_leap_tween.kill()
	global_position = _spawn_position
	_tint = Color.WHITE
	_hide_reticle()
	if health_component:
		health_component.current_health = max_health
		health_component.is_invulnerable = false
	boss_health_changed.emit(max_health, max_health)
	_set_texture(TEX_IDLE_0)
	if visuals:
		visuals.scale = Vector2(_facing_direction, 1.0)
		visuals.modulate = Color.WHITE
		visuals.rotation = 0.0
	if hitbox_component:
		hitbox_component.set_deferred("monitorable", true)
	if _swipe_hitbox:
		_swipe_hitbox.set_deferred("monitorable", false)
	if hurtbox_component:
		hurtbox_component.set_deferred("monitoring", true)

	# Clear active projectiles dislodged during the fight
	for node in get_tree().get_nodes_in_group(&"boss_projectiles"):
		if is_instance_valid(node):
			node.queue_free()
