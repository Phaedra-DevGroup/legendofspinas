class_name TouchControls
extends CanvasLayer

## Mobile touch control overlay for Android devices.
## Maps virtual touch screen buttons to Godot InputMap actions.
## Highlights the Interact button when the player enters an NPC's range.
## Highlights the Grapple button when near a bronze grapple ring or airborne.
## Automatically toggles character-specific buttons (e.g. Slide for Rojan only).
## Buttons are laid out against the screen corners at runtime so they hug the edges on any
## aspect ratio (16:9 tablets up to 21:9 phones) and stay clear of display cutouts.

@export var auto_hide_on_desktop: bool = false
## Gap between the buttons and the screen edge, in viewport pixels.
@export var edge_margin: float = 16.0
## Resting opacity: visible but never hiding the action behind it.
@export var idle_alpha: float = 0.72

const BUTTON_SIZE: float = 48.0
const BUTTON_GAP: float = 10.0

@onready var btn_left: TouchScreenButton = find_child("BtnLeft", true, false) as TouchScreenButton
@onready var btn_right: TouchScreenButton = find_child("BtnRight", true, false) as TouchScreenButton
@onready var btn_jump: TouchScreenButton = find_child("BtnJump", true, false) as TouchScreenButton
@onready var btn_attack: TouchScreenButton = find_child("BtnAttack", true, false) as TouchScreenButton
@onready var btn_interact: TouchScreenButton = find_child("BtnInteract", true, false) as TouchScreenButton
@onready var btn_grapple: TouchScreenButton = find_child("BtnGrapple", true, false) as TouchScreenButton
@onready var btn_down: TouchScreenButton = find_child("BtnDown", true, false) as TouchScreenButton

var _player: PlayerController = null

func _ready() -> void:
	# Hide on desktop if requested and not running on mobile
	if auto_hide_on_desktop and not OS.has_feature("mobile") and not OS.has_feature("touchscreen"):
		hide()
		return

	for btn in _all_buttons():
		btn.modulate.a = idle_alpha
		btn.pressed.connect(_on_button_pressed.bind(btn))
		btn.released.connect(_on_button_released.bind(btn))

	# Interact button starts dimmed until an interactable is in proximity
	if btn_interact:
		btn_interact.modulate.a = 0.3
	if btn_grapple:
		btn_grapple.modulate.a = 0.3

	get_viewport().size_changed.connect(_layout)
	_layout()

	# Check for player already present in scene tree
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		setup_player(players[0] as PlayerController)

func _all_buttons() -> Array[TouchScreenButton]:
	var result: Array[TouchScreenButton] = []
	for btn in [btn_left, btn_right, btn_jump, btn_attack, btn_interact, btn_grapple, btn_down]:
		if btn:
			result.append(btn)
	return result

## Anchors the d-pad to the bottom-left corner and the action cluster to the bottom-right.
func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var inset: Vector2 = _safe_area_insets(view)
	var bottom: float = view.y - edge_margin - BUTTON_SIZE
	var left: float = edge_margin + inset.x
	var right: float = view.x - edge_margin - inset.y - BUTTON_SIZE
	var step: float = BUTTON_SIZE + BUTTON_GAP

	if btn_left:
		btn_left.position = Vector2(left, bottom)
	if btn_right:
		btn_right.position = Vector2(left + step, bottom)
	if btn_jump:
		btn_jump.position = Vector2(right, bottom)
	if btn_attack:
		btn_attack.position = Vector2(right - step, bottom)
	if btn_down:
		btn_down.position = Vector2(right - step * 2.0, bottom)
	if btn_grapple:
		btn_grapple.position = Vector2(right, bottom - step)
	if btn_interact:
		btn_interact.position = Vector2(right - step, bottom - step)

## Horizontal space eaten by notches / punch-hole cameras, converted to viewport pixels.
func _safe_area_insets(view: Vector2) -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var screen: Vector2 = Vector2(DisplayServer.screen_get_size())
	if screen.x <= 0.0:
		return Vector2.ZERO
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var scale: float = view.x / screen.x
	return Vector2(safe.position.x * scale, (screen.x - safe.end.x) * scale)

## Press feedback is colour only: resizing/moving a TouchScreenButton under a held finger
## makes it release and re-press (pass-by), firing repeated just_pressed events.
func _on_button_pressed(btn: TouchScreenButton) -> void:
	btn.self_modulate = Color(1.4, 1.4, 1.4)

func _on_button_released(btn: TouchScreenButton) -> void:
	btn.self_modulate = Color.WHITE

## Drops every held virtual button (e.g. when a dialogue freezes the game mid-run).
func release_all() -> void:
	for btn in _all_buttons():
		if btn.action != "" and Input.is_action_pressed(btn.action):
			Input.action_release(btn.action)
		btn.self_modulate = Color.WHITE

func _process(_delta: float) -> void:
	if not _player or not is_instance_valid(_player):
		var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
		if not players.is_empty():
			setup_player(players[0] as PlayerController)
		return

	if btn_grapple:
		var has_anchor: bool = _player.find_grapple_anchor(PlayerController.GRAPPLE_RANGE + 40.0) != Vector2.ZERO
		var target_alpha: float = 1.0 if has_anchor else 0.3
		if not is_equal_approx(btn_grapple.modulate.a, target_alpha):
			btn_grapple.modulate.a = move_toward(btn_grapple.modulate.a, target_alpha, 0.1)

func setup_player(player: PlayerController) -> void:
	if not player:
		return
	_player = player
	if not player.interaction_target_changed.is_connected(on_player_interaction_target_changed):
		player.interaction_target_changed.connect(on_player_interaction_target_changed)
	if not player.character_configured.is_connected(on_character_configured):
		player.character_configured.connect(on_character_configured)
	on_character_configured(player.character_type)

func on_character_configured(type: int) -> void:
	if not btn_down:
		btn_down = find_child("BtnDown", true, false) as TouchScreenButton
	if btn_down:
		# Only Rojan has the Gale Slide ability. When Bardia is selected, hide the slide/crouch button.
		btn_down.visible = (type == PlayerController.CharacterType.ROJAN)

## Connect this method to PlayerController.interaction_target_changed
func on_player_interaction_target_changed(target: InteractableComponent) -> void:
	if not btn_interact:
		return

	var tween: Tween = create_tween()
	if target != null:
		# Highlight button when NPC/chest is near, with a little "look at me" pop
		tween.tween_property(btn_interact, "modulate:a", 1.0, 0.15)
		tween.parallel().tween_property(btn_interact, "self_modulate", Color(1.4, 1.4, 1.4), 0.15)
		tween.tween_property(btn_interact, "self_modulate", Color.WHITE, 0.25)
	else:
		# Dim down when out of range
		tween.tween_property(btn_interact, "modulate:a", 0.3, 0.15)
