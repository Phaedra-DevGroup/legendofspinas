class_name PlayerSlideState
extends PlayerState

## Rojan's Gale Slide: Down + Jump while grounded ducks low and darts forward,
## slipping under thorn arches and through enemy hitboxes unharmed.

@export var slide_speed: float = 250.0
@export var slide_duration: float = 0.42
@export var slide_friction: float = 420.0

var _slide_timer: float = 0.0
var _air_time: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "slide")
	_slide_timer = slide_duration
	_air_time = 0.0
	player.floor_snap_length = 8.0
	player.velocity.x = player.facing_direction * slide_speed
	player.set_sliding(true)
	if player.animated_sprite and player.animated_sprite.sprite_frames and player.animated_sprite.sprite_frames.has_animation(&"slide"):
		player.play_animation(&"slide")
	else:
		player.play_animation(&"run")
		if player.visuals:
			player.visuals.scale = Vector2(player.facing_direction, 0.6)

func exit() -> void:
	player.floor_snap_length = 1.0
	player.set_sliding(false)
	player.start_slide_cooldown()
	if player.visuals:
		player.visuals.scale = Vector2(player.facing_direction, 1.0)

func physics_update(delta: float) -> void:
	_slide_timer -= delta
	player.apply_gravity(delta)
	
	if not player.is_on_floor() and not player.test_move(player.global_transform, Vector2(0, 8.0)):
		_air_time += delta
		if _air_time > 0.12:
			state_machine.transition_to("Fall")
			return
	else:
		_air_time = 0.0
	
	# Preservation hop: cancel the slide into a jump
	if Input.is_action_just_pressed(&"jump"):
		state_machine.transition_to("Jump")
		return
	
	if _slide_timer <= 0.0:
		if not is_zero_approx(player.get_input_direction()):
			state_machine.transition_to("Run")
		else:
			state_machine.transition_to("Idle")
		return
	
	player.apply_friction(delta)
	player.velocity.x = maxf(absf(player.velocity.x), 60.0) * player.facing_direction
	player.move_and_slide()
