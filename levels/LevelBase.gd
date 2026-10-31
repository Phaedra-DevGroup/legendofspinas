class_name LevelBase
extends Node2D

## Shared runtime for every playable arc: HUD (hearts, scraps, quest banner, action prompt),
## boss health bar, NPC dialogue panel, sealed boss arenas, respawn fade, victory modal,
## safe-area handling and the fallback hero picker.
## Each level scene keeps the same TopHUD / DialogueUI / VictoryUI node layout and overrides
## the virtual hooks (_setup_level, _connect_level_signals, dialogue choices, victory buttons).

@export var music_track: String = "forge"
## Later arcs restore the scraps, hearts and upgrades the hero earned in earlier ones.
@export var carry_progress: bool = false

@onready var player: PlayerController = $Player
@onready var touch_controls: TouchControls = $TouchControls

# HUD Elements
@onready var top_hud: CanvasLayer = $TopHUD
@onready var safe_area: MarginContainer = $TopHUD/SafeArea
@onready var hero_status_label: Label = $TopHUD/SafeArea/TopRow/StatusPanel/StatusVBox/CountersHBox/HeroStatus
@onready var scraps_label: Label = $TopHUD/SafeArea/TopRow/StatusPanel/StatusVBox/CountersHBox/ScrapsLabel
@onready var keystone_icons: HBoxContainer = $TopHUD/SafeArea/TopRow/StatusPanel/StatusVBox/CountersHBox/KeystoneIcons
@onready var hearts_container: HBoxContainer = $TopHUD/SafeArea/TopRow/StatusPanel/StatusVBox/HeartsHBox
@onready var quest_banner: Label = $TopHUD/TopCenter/QuestPanel/QuestBanner
@onready var action_prompt_panel: PanelContainer = $TopHUD/ActionPromptPanel
@onready var action_prompt_label: Label = $TopHUD/ActionPromptPanel/ActionPrompt

# Boss Bar Elements
@onready var boss_hud: Control = $TopHUD/TopCenter/BossHUD
@onready var boss_health_bar: ProgressBar = $TopHUD/TopCenter/BossHUD/BossProgressBar
@onready var boss_title_label: Label = $TopHUD/TopCenter/BossHUD/BossTitle

# Dialogue Elements
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var pause_btn: BaseButton = $TopHUD/SafeArea/TopRow/PauseBtn
@onready var dialogue_layer: CanvasLayer = $DialogueUI
@onready var dialogue_panel: PanelContainer = $DialogueUI/DialogueContainer
@onready var speaker_name_label: Label = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/SpeakerName
@onready var dialogue_text_label: Label = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/DialogueText
@onready var prompt_hint_label: Label = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/PromptHint
@onready var choice_vbox: GridContainer = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/ChoiceVBox
@onready var btn_quest: Button = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/ChoiceVBox/QuestBtn
@onready var btn_upgrade: Button = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/ChoiceVBox/UpgradeBtn
@onready var btn_heal: Button = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/ChoiceVBox/HealBtn
@onready var btn_close: Button = $DialogueUI/DialogueContainer/MarginContainer/VBoxContainer/ChoiceVBox/CloseBtn

# Victory Modal
@onready var victory_layer: CanvasLayer = $VictoryUI
@onready var victory_title: Label = $VictoryUI/VictoryPanel/MarginContainer/VBoxContainer/VictoryTitle
@onready var victory_desc: Label = $VictoryUI/VictoryPanel/MarginContainer/VBoxContainer/VictoryDesc
@onready var restart_demo_btn: Button = $VictoryUI/VictoryPanel/MarginContainer/VBoxContainer/ButtonsHBox/RestartBtn
@onready var menu_demo_btn: Button = $VictoryUI/VictoryPanel/MarginContainer/VBoxContainer/ButtonsHBox/MenuBtn

const HEART_FULL_TEX = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY_TEX = preload("res://assets/ui/heart_empty.png")
const ARENA_WALL_TEX = preload("res://assets/sprites/environment/keystone_gate.png")

var _player_signals_connected: bool = false
var _char_select_layer: CanvasLayer = null
var _last_hp_shown: int = 0
var _last_prompt: String = ""
var _arena_walls: Array[StaticBody2D] = []

func _ready() -> void:
	# Force landscape orientation on mobile/Android devices
	if OS.has_feature("mobile") or OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", music_track)

	if dialogue_layer:
		dialogue_layer.hide()
	if boss_hud:
		boss_hud.hide()
	if victory_layer:
		victory_layer.hide()

	_setup_player()
	_setup_dialogue_buttons()
	_setup_victory_buttons()

	if pause_btn and pause_menu:
		pause_btn.pressed.connect(pause_menu.toggle_pause)
	if pause_menu:
		pause_menu.back_requested.connect(_on_back_requested)
	if dialogue_layer:
		# Dialogue freezes the world, so its buttons must keep processing
		dialogue_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	_setup_level()
	_apply_safe_area()
	_check_character_selection_needed()

func _process(_delta: float) -> void:
	# Contextual controls hint (grapple rings, interactables)
	if action_prompt_label and player:
		if _last_prompt != player.action_prompt:
			_last_prompt = player.action_prompt
			action_prompt_label.text = _touch_friendly_prompt(player.action_prompt)
		action_prompt_panel.visible = not player.action_prompt.is_empty()

# ---------------------------------------------------------
# Virtual hooks
# ---------------------------------------------------------
## Level-specific wiring (bosses, collectibles, NPCs). Runs after the shared HUD is ready.
func _setup_level() -> void:
	pass

## Connect level NPC signals once; called the first time the player is set up.
func _connect_level_signals() -> void:
	pass

func _on_quest_dialogue_chosen() -> void:
	_close_dialogue()

func _on_upgrade_chosen() -> void:
	pass

func _on_heal_chosen() -> void:
	pass

# ---------------------------------------------------------
# Player & HUD Subsystem
# ---------------------------------------------------------
func _setup_player() -> void:
	if not player:
		return

	if touch_controls:
		touch_controls.setup_player(player)

	# _setup_player runs again after the in-level hero picker; never double-connect
	if not _player_signals_connected:
		_player_signals_connected = true
		player.health_updated.connect(_on_player_health_updated)
		player.scraps_updated.connect(_on_player_scraps_updated)
		player.player_died.connect(_on_player_died)
		_connect_level_signals()
		if carry_progress:
			SceneManager.apply_player_state(player)

	if player.character_type == PlayerController.CharacterType.ROJAN:
		hero_status_label.text = "روژان"
	else:
		hero_status_label.text = "بردیا"

	_on_player_health_updated(player.health_component.current_health, player.health_component.max_health)
	_on_player_scraps_updated(player.ancient_scraps)

## On a phone there is no [E] key: point at the glowing touch button instead.
func _touch_friendly_prompt(prompt: String) -> String:
	if touch_controls and touch_controls.visible and (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()):
		# A leading key hint just goes; mid-sentence ("jump and press [E]...") it names the button
		if prompt.begins_with("[E] "):
			prompt = prompt.substr(4)
		return prompt.replace("[E]", "دکمه تعامل")
	return prompt

## Keeps the HUD clear of notches and rounded corners on phones.
func _apply_safe_area() -> void:
	if not safe_area or not OS.has_feature("mobile"):
		return
	var screen: Vector2 = Vector2(DisplayServer.screen_get_size())
	if screen.x <= 0.0:
		return
	var safe: Rect2 = Rect2(DisplayServer.get_display_safe_area())
	var scale: float = get_viewport().get_visible_rect().size.x / screen.x
	safe_area.add_theme_constant_override("margin_left", 10 + int(safe.position.x * scale))
	safe_area.add_theme_constant_override("margin_right", 10 + int((screen.x - safe.end.x) * scale))

func _on_lore_stele_read(title: String, text: String) -> void:
	if not dialogue_layer:
		return
	speaker_name_label.text = title
	dialogue_text_label.text = text
	prompt_hint_label.text = "[برای بستن، دکمه بازگشت را لمس کنید]"

	# Hide action choices, show only close button
	btn_quest.hide()
	btn_upgrade.hide()
	btn_heal.hide()
	btn_close.show()

	_open_dialogue_panel()

func _on_player_health_updated(current: int, max_hp: int) -> void:
	if not hearts_container:
		return

	for child in hearts_container.get_children():
		child.queue_free()

	for i in range(max_hp):
		var heart: TextureRect = TextureRect.new()
		heart.texture = HEART_FULL_TEX if i < current else HEART_EMPTY_TEX
		heart.stretch_mode = TextureRect.STRETCH_KEEP
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_container.add_child(heart)
	# Pulse the panel on damage so a lost heart is noticed mid-fight
	if current < _last_hp_shown and hearts_container.get_parent():
		var plate: Control = hearts_container.get_parent().get_parent() as Control
		plate.modulate = Color(1.8, 0.6, 0.6)
		plate.create_tween().tween_property(plate, "modulate", Color.WHITE, 0.3)
	_last_hp_shown = current

func _on_player_scraps_updated(total: int) -> void:
	if scraps_label:
		scraps_label.text = PersianUtils.to_persian_number(total)

func _on_player_died() -> void:
	_update_quest_banner("تجدید قوا در آخرین استراحتگاه...")
	_play_respawn_fade()

func _update_quest_banner(text: String) -> void:
	if quest_banner:
		quest_banner.text = text

## Brief black dip so respawning at a checkpoint never reads as a teleport glitch.
func _play_respawn_fade() -> void:
	if not top_hud:
		return
	var fade: ColorRect = ColorRect.new()
	fade.color = Color(0.02, 0.0, 0.04, 1.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_hud.add_child(fade)
	var tween: Tween = fade.create_tween()
	tween.tween_interval(0.15)
	tween.tween_property(fade, "modulate:a", 0.0, 0.45)
	tween.tween_callback(fade.queue_free)

## Android back / Escape while something else froze the game (dialogue, hero picker).
func _on_back_requested() -> void:
	if dialogue_layer and dialogue_layer.visible:
		_close_dialogue()

# ---------------------------------------------------------
# Dialogue Panel
# ---------------------------------------------------------
func _setup_dialogue_buttons() -> void:
	if dialogue_text_label:
		# Under an RTL layout direction Godot mirrors alignment, so LEFT means "start" (the right edge)
		dialogue_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		dialogue_text_label.text_direction = Control.TEXT_DIRECTION_RTL
		dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dialogue_text_label.language = "fa"
	if speaker_name_label:
		speaker_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		speaker_name_label.text_direction = Control.TEXT_DIRECTION_RTL
		speaker_name_label.language = "fa"
	if prompt_hint_label:
		prompt_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		prompt_hint_label.text_direction = Control.TEXT_DIRECTION_RTL
		prompt_hint_label.language = "fa"
	if dialogue_panel:
		dialogue_panel.layout_direction = Control.LAYOUT_DIRECTION_RTL

	if btn_quest:
		btn_quest.pressed.connect(_on_quest_dialogue_chosen)
	if btn_upgrade:
		btn_upgrade.pressed.connect(_on_upgrade_chosen)
	if btn_heal:
		btn_heal.pressed.connect(_on_heal_chosen)
	if btn_close:
		btn_close.pressed.connect(_close_dialogue)

func _open_dialogue_panel() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	dialogue_layer.show()
	get_tree().paused = true
	if touch_controls:
		touch_controls.release_all()
	dialogue_panel.pivot_offset = dialogue_panel.size * 0.5
	dialogue_panel.scale = Vector2(0.85, 0.85)
	var tween: Tween = dialogue_panel.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialogue_panel, "scale", Vector2.ONE, 0.15)

func _close_dialogue() -> void:
	if not dialogue_layer or not dialogue_layer.visible:
		return
	get_tree().paused = false
	var tween: Tween = dialogue_panel.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(dialogue_panel, "scale", Vector2(0.85, 0.85), 0.1)
	tween.finished.connect(func(): dialogue_layer.hide())

# ---------------------------------------------------------
# Boss Bar & Sealed Arena
# ---------------------------------------------------------
func _show_boss_bar(title: String, current: int, max_hp: int) -> void:
	if boss_title_label:
		boss_title_label.text = title
	if boss_hud and boss_health_bar:
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = current
		boss_hud.show()

func _on_boss_health_changed(current: int, max_hp: int) -> void:
	if not boss_health_bar:
		return
	if is_equal_approx(boss_health_bar.max_value, max_hp) and current < boss_health_bar.value:
		_flash_boss_bar()
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = current

func _flash_boss_bar() -> void:
	boss_health_bar.modulate = Color(2.0, 2.0, 2.0)
	var tween: Tween = boss_health_bar.create_tween()
	tween.tween_property(boss_health_bar, "modulate", Color.WHITE, 0.2)

## Seals a boss arena with rising stone pillars so the fight can't be skipped or kited forever.
func _raise_arena_walls(left_x: float, right_x: float, floor_y: float = 320.0, tint: Color = Color(0.85, 0.75, 1.0)) -> void:
	_lower_arena_walls()
	var arena: Node = get_node_or_null("BossArena")
	if arena == null:
		arena = self
	for x in [left_x, right_x]:
		var wall: StaticBody2D = StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 0
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = Vector2(24, 420)
		shape.shape = rect
		shape.position = Vector2(0, -210)
		wall.add_child(shape)
		var pillar: Node2D = Node2D.new()
		pillar.name = "Pillar"
		for i in 4:
			var block: Sprite2D = Sprite2D.new()
			block.texture = ARENA_WALL_TEX
			block.position = Vector2(0, -48 - i * 92)
			block.modulate = tint
			pillar.add_child(block)
		pillar.position = Vector2(0, 360)
		wall.add_child(pillar)
		arena.add_child(wall)
		wall.global_position = Vector2(x, floor_y)
		var rise: Tween = pillar.create_tween()
		rise.tween_property(pillar, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		FX.dust(self, Vector2(x, floor_y), 14, 120.0)
		_arena_walls.append(wall)
	ScreenShake.add_trauma(0.4)

func _lower_arena_walls() -> void:
	for wall in _arena_walls:
		if not is_instance_valid(wall):
			continue
		var pillar: Node2D = wall.get_node_or_null("Pillar") as Node2D
		for child in wall.get_children():
			if child is CollisionShape2D:
				(child as CollisionShape2D).set_deferred("disabled", true)
		if pillar:
			var sink: Tween = pillar.create_tween()
			sink.tween_property(pillar, "position:y", 380.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			sink.tween_callback(wall.queue_free)
		else:
			wall.queue_free()
	_arena_walls.clear()

# ---------------------------------------------------------
# Victory Screen Subsystem
# ---------------------------------------------------------
func _setup_victory_buttons() -> void:
	if restart_demo_btn:
		restart_demo_btn.pressed.connect(_on_victory_primary_pressed)
	if menu_demo_btn:
		menu_demo_btn.pressed.connect(func():
			SceneManager.change_scene("res://ui/main_menu/MainMenu.tscn", true)
		)

## Primary victory button; replays this level unless a level overrides it.
func _on_victory_primary_pressed() -> void:
	SceneManager.change_scene(scene_file_path, true)

func _show_victory_modal() -> void:
	if victory_layer:
		victory_layer.show()
		if touch_controls:
			touch_controls.release_all()
		var panel: Control = victory_layer.get_node_or_null("VictoryPanel") as Control
		if panel:
			panel.scale = Vector2(0.8, 0.8)
			var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_property(panel, "scale", Vector2.ONE, 0.25)

# ---------------------------------------------------------
# Standalone Character Selection Overlay
# ---------------------------------------------------------
func _check_character_selection_needed() -> void:
	if not SceneManager.has_chosen_character:
		_show_character_select_overlay()

func _show_character_select_overlay() -> void:
	if _char_select_layer:
		return
	_char_select_layer = CanvasLayer.new()
	_char_select_layer.layer = 30
	_char_select_layer.process_mode = Node.PROCESS_MODE_ALWAYS

	var overlay: ColorRect = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.8)
	_char_select_layer.add_child(overlay)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_char_select_layer.add_child(center)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 220)
	center.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "قهرمان خود را برگزینید"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text_direction = Control.TEXT_DIRECTION_RTL
	title.add_theme_color_override("font_color", Color(0.96, 0.8, 0.35))
	vbox.add_child(title)

	var desc: Label = Label.new()
	desc.text = "برای شروع ماجراجویی در کوهستان اسپیناس، قهرمان خود را انتخاب کنید:"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.text_direction = Control.TEXT_DIRECTION_RTL
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	var btn_b: Button = Button.new()
	btn_b.text = "بردیا (شاگرد آهنگر)\n• نبرد سنگین، شلیک زلزله و قلاب برنزی"
	btn_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_b.custom_minimum_size = Vector2(170, 56)
	btn_b.pressed.connect(func():
		_select_hero_and_resume(PlayerController.CharacterType.BARDIA)
	)
	hbox.add_child(btn_b)

	var btn_r: Button = Button.new()
	btn_r.text = "روژان (کماندار باد)\n• تیرهای طبیعت، پرش جفت و سر خوردن"
	btn_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_r.custom_minimum_size = Vector2(170, 56)
	btn_r.pressed.connect(func():
		_select_hero_and_resume(PlayerController.CharacterType.ROJAN)
	)
	hbox.add_child(btn_r)

	add_child(_char_select_layer)
	get_tree().paused = true

func _select_hero_and_resume(type: PlayerController.CharacterType) -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_select")
	SceneManager.set_character(type)
	if player:
		player.character_type = type
	_setup_player()
	if _char_select_layer:
		_char_select_layer.queue_free()
		_char_select_layer = null
	get_tree().paused = false
