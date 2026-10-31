class_name MainMenu
extends Control

## Main Menu controller for "The Legend of Espinas" (افسانه اسپیناس).
## Manages game start, character selection (Bardia vs Rojan), settings, and exit.

@onready var character_select_modal: PanelContainer = $Modals/CharacterSelectModal
@onready var settings_modal: PanelContainer = $Modals/SettingsModal
@onready var lore_modal: PanelContainer = $Modals/LoreModal

@onready var start_btn: Button = $MenuCenter/MainButtons/StartBtn
@onready var character_btn: Button = $MenuCenter/MainButtons/CharacterBtn
@onready var settings_btn: Button = $MenuCenter/MainButtons/SettingsBtn
@onready var lore_btn: Button = $MenuCenter/MainButtons/LoreBtn
@onready var exit_btn: Button = $MenuCenter/MainButtons/ExitBtn

# Modal buttons (using find_child for robust discovery)
var btn_bardia: Button
var btn_rojan: Button
var close_char_btn: Button
var close_settings_btn: Button
var close_lore_btn: Button

# Settings sliders
var sound_slider: HSlider
var music_slider: HSlider

# Lore Chapter elements
var lore_rich_text: RichTextLabel
var chapter_btn_1: Button
var chapter_btn_2: Button
var chapter_btn_3: Button
var chapter_btn_4: Button

var _modal_dim: ColorRect

func _ready() -> void:
	_build_modal_dim()
	_resolve_modal_buttons()
	_add_hero_preview("BardiaCard", preload("res://characters/player/SpriteFrames_Bardia.tres"))
	_add_hero_preview("RojanCard", preload("res://characters/player/SpriteFrames_Rojan.tres"))
	_close_all_modals()
	_setup_lore_chapters()
	_setup_settings_sliders()
	
	# Start Main Menu BGM
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", "menu")
	
	# Connect main navigation buttons safely
	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)
	if character_btn:
		character_btn.pressed.connect(_on_character_select_pressed)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings_pressed)
	if lore_btn:
		lore_btn.pressed.connect(_on_lore_pressed)
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)
	
	# Connect character selection buttons
	if btn_bardia:
		btn_bardia.pressed.connect(func(): _choose_character_and_start(PlayerController.CharacterType.BARDIA))
	if btn_rojan:
		btn_rojan.pressed.connect(func(): _choose_character_and_start(PlayerController.CharacterType.ROJAN))
	
	# Connect modal back/close buttons
	if close_char_btn:
		close_char_btn.pressed.connect(_close_all_modals)
	if close_settings_btn:
		close_settings_btn.pressed.connect(_close_all_modals)
	if close_lore_btn:
		close_lore_btn.pressed.connect(_close_all_modals)
	
	_add_continue_button()
	print("[MainMenu] All navigation and modal buttons successfully connected.")

## Shown once an arc beyond the first is unlocked: resumes it with the saved hero and items.
func _add_continue_button() -> void:
	if not start_btn or not SceneManager.can_continue():
		return
	var arc_names: Array[String] = ["", "آرک اول", "آرک دوم: جنگل مه‌آلود"]
	var btn: Button = Button.new()
	btn.name = "ContinueBtn"
	btn.text = "ادامه — " + arc_names[clampi(SceneManager.unlocked_arc, 1, arc_names.size() - 1)]
	btn.custom_minimum_size = start_btn.custom_minimum_size
	btn.add_theme_font_override("font", start_btn.get_theme_font("font"))
	btn.add_theme_font_size_override("font_size", start_btn.get_theme_font_size("font_size"))
	var column: Node = start_btn.get_parent()
	column.add_child(btn)
	column.move_child(btn, start_btn.get_index())
	start_btn.text = "ماجراجویی تازه"
	# Start and hero-select open the same picker; drop the duplicate to keep the column short
	if character_btn:
		character_btn.hide()
	btn.pressed.connect(func():
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "ui_select")
		SceneManager.continue_game()
	)

func _setup_settings_sliders() -> void:
	sound_slider = find_child("SoundSlider", true, false) as HSlider
	music_slider = find_child("MusicSlider", true, false) as HSlider
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio:
		# Reflect the saved volumes before wiring change handlers
		if sound_slider:
			sound_slider.set_value_no_signal(audio.get("sfx_volume") * 100.0)
			sound_slider.drag_ended.connect(func(_changed: bool): audio.call("save_settings"))
		if music_slider:
			music_slider.set_value_no_signal(audio.get("music_volume") * 100.0)
			music_slider.drag_ended.connect(func(_changed: bool): audio.call("save_settings"))
	if sound_slider:
		sound_slider.value_changed.connect(func(val: float):
			if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
				get_node("/root/AudioManager").call("set_sfx_volume", val / 100.0)
		)
	if music_slider:
		music_slider.value_changed.connect(func(val: float):
			if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
				get_node("/root/AudioManager").call("set_music_volume", val / 100.0)
		)

func _resolve_modal_buttons() -> void:
	# Use find_child to avoid any hierarchy-related path mismatches
	btn_bardia = find_child("SelectBardiaBtn", true, false) as Button
	btn_rojan = find_child("SelectRojanBtn", true, false) as Button
	close_char_btn = find_child("CloseCharBtn", true, false) as Button
	close_settings_btn = find_child("CloseSettingsBtn", true, false) as Button
	close_lore_btn = find_child("CloseLoreBtn", true, false) as Button
	
	lore_rich_text = find_child("StoryRichText", true, false) as RichTextLabel
	chapter_btn_1 = find_child("Chapter1Btn", true, false) as Button
	chapter_btn_2 = find_child("Chapter2Btn", true, false) as Button
	chapter_btn_3 = find_child("Chapter3Btn", true, false) as Button
	chapter_btn_4 = find_child("Chapter4Btn", true, false) as Button

func _setup_lore_chapters() -> void:
	if chapter_btn_1:
		chapter_btn_1.pressed.connect(func(): _display_lore_chapter(1))
	if chapter_btn_2:
		chapter_btn_2.pressed.connect(func(): _display_lore_chapter(2))
	if chapter_btn_3:
		chapter_btn_3.pressed.connect(func(): _display_lore_chapter(3))
	if chapter_btn_4:
		chapter_btn_4.pressed.connect(func(): _display_lore_chapter(4))
	_display_lore_chapter(1)

func _display_lore_chapter(chapter_num: int) -> void:
	if not lore_rich_text:
		return
	
	match chapter_num:
		1:
			lore_rich_text.text = "[b][color=#f5cd59]بخش ۱: برکت باستانی اسپیناس و اشک آناهیتا[/color][/b]\n\nدر دامنه‌های مه‌گرفته و سرسبز کوهستان اسپیناس، روستایی پلکانی و سنگی با بام‌های کاه‌گلی قرار دارد. این دیار قرن‌ها در پناه گوهر مقدس [color=#64e0e0]«اشک آناهیتا»[/color] در صلح و باروری می‌زیست.\n\nاین سنگ فیروزه‌ای درخشان در بلندترین محراب معبد قله جای داشت و سرچشمه جویبارهای زلال، سرسبزی جنگل‌های انبوه، و دمنده‌ی حیات پاک به خاک، چشمه‌ها و ساکنان کوهستان بود."
		2:
			lore_rich_text.text = "[b][color=#f5cd59]بخش ۲: یورش ظلمات و طاعون مرگ‌مایه[/color][/b]\n\nآرامش کوهستان با بیداری [color=#d175ff]«ظلمات»[/color]، ساحر کینه‌توز اعماق تاریکی، در هم شکست. او با ارتشی از سایه‌ها به معبد تاخت و گوهر فیروزه‌ای را ربود.\n\nبا تسخیر و فساد سنگ، زهر سیاه و پیچنده‌ای به نام [color=#c759f5]«مرگ‌مایه» (Marg-mayeh)[/color] در رگ‌های کوهستان جاری شد؛ چشمه‌ها خشکیدند، خارهای بنفش زهرآگین بر زمین و دیوارها روییدند و جانوران معصوم به هیولاهایی مسخ‌شده بدل شدند."
		3:
			lore_rich_text.text = "[b][color=#f5cd59]بخش ۳: قهرمانان برگزیده و یاران کوهستان[/color][/b]\n\n[color=#64e0e0]• بردیا (Bardia):[/color] شاگرد تنومند آهنگر، مسلح به مچ‌بند سنگی فیروزه‌ای و قلاب برنزی برای مبارزات سنگین و تن‌به‌تن.\n[color=#8ce88c]• روژان (Rojan):[/color] کماندار چابک بادهای اسپیناس با تیرهای آمیخته به جادوی طبیعت و پرش جفت.\n[color=#f5cd59]• یاران کوهستان:[/color]\n- [b]استاد پولاد:[/b] آهنگر کوره زیرزمینی و لنگرگاه امید.\n- [b]آتوسا:[/b] روح اسیر جنگل مه‌آلود.\n- [b]زال کهنسال:[/b] پیر دانای غارها و چراغ راه.\n- [b]نسیم:[/b] تاجر جسور انار طلایی و کلیدهای باستانی."
		4:
			lore_rich_text.text = "[b][color=#f5cd59]بخش ۴: ماموریت دمو — کوره زیرزمینی و سنگ‌شکن[/color][/b]\n\nدر این دمو (آرک اول)، شما سفر خود را از میان کوچه‌های ویران آغاز می‌کنید. از خارهای بنفش مرگ‌مایه جاخالی دهید و خفاش‌های تیغ‌دار و گرگ‌های تاریکی را از سر راه بردارید.\n\nبه کوره امن [b]استاد پولاد[/b] برسید تا سلاحتان تقویت شود، سپس راهی صحن بیرونی شوید تا با [color=#ff6b6b]«سنگ‌شکن ویرانه‌ها» (Crusher of the Ruins)[/color] پنجه در افکنید و [color=#f5cd59]«چرخ‌دنده باستانی»[/color] را پس بگیرید!"

func _on_start_pressed() -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	print("[MainMenu] Start pressed -> Opening character choice modal.")
	_open_modal(character_select_modal)

func _on_character_select_pressed() -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	print("[MainMenu] Character selection pressed -> Opening character modal.")
	_open_modal(character_select_modal)

func _on_settings_pressed() -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	print("[MainMenu] Settings pressed -> Opening settings modal.")
	_open_modal(settings_modal)

func _on_lore_pressed() -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	print("[MainMenu] Lore pressed -> Opening lore modal.")
	_open_modal(lore_modal)

func _on_exit_pressed() -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	get_tree().quit()

func _choose_character_and_start(character_type: PlayerController.CharacterType) -> void:
	if Engine.has_singleton("AudioManager") or has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_select")
	print("[MainMenu] Selected character: ", character_type, " -> Changing scene to Level_Forge.")
	SceneManager.set_character(character_type)
	SceneManager.start_new_game()
	SceneManager.change_scene("res://levels/Level_Forge.tscn", true)

## Puts the hero's idle animation at the top of their selection card.
func _add_hero_preview(card_name: String, frames: SpriteFrames) -> void:
	var card: Node = find_child(card_name, true, false)
	var box: Node = card.get_node_or_null("VBox") if card else null
	if not box or not frames:
		return
	var holder: Control = Control.new()
	holder.custom_minimum_size = Vector2(0, 50)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.play(&"idle")
	holder.add_child(sprite)
	holder.resized.connect(func(): sprite.position = Vector2(holder.size.x * 0.5, holder.size.y * 0.5))
	box.add_child(holder)
	box.move_child(holder, 0)

## Full-screen shade behind modals so the main menu never bleeds through them.
func _build_modal_dim() -> void:
	var modals: Control = get_node_or_null("Modals") as Control
	if not modals:
		return
	_modal_dim = ColorRect.new()
	_modal_dim.name = "ModalDim"
	_modal_dim.color = Color(0.03, 0.02, 0.06, 0.82)
	_modal_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_dim.visible = false
	_modal_dim.gui_input.connect(func(event: InputEvent):
		# Tapping outside a modal closes it
		if event is InputEventMouseButton and event.pressed:
			_close_all_modals()
	)
	modals.add_child(_modal_dim)
	modals.move_child(_modal_dim, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _modal_dim and _modal_dim.visible:
		_close_all_modals()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	# Android back closes an open modal instead of leaving the app
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _modal_dim and _modal_dim.visible:
			_close_all_modals()
		else:
			get_tree().quit()

func _open_modal(modal: PanelContainer) -> void:
	if not modal:
		return
	_close_all_modals()
	if _modal_dim:
		_modal_dim.show()
	$MenuCenter.hide()
	modal.show()
	modal.pivot_offset = modal.size * 0.5
	modal.scale = Vector2(0.9, 0.9)
	modal.modulate.a = 0.0
	var tween: Tween = modal.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "scale", Vector2.ONE, 0.18)
	tween.tween_property(modal, "modulate:a", 1.0, 0.12)

func _close_all_modals() -> void:
	if _modal_dim:
		_modal_dim.hide()
	if has_node("MenuCenter"):
		$MenuCenter.show()
	if character_select_modal:
		character_select_modal.hide()
	if settings_modal:
		settings_modal.hide()
	if lore_modal:
		lore_modal.hide()
