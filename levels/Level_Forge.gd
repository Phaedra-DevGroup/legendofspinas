class_name LevelForge
extends LevelBase

## Act I Metroidvania level: "The Legend of Espinas"
## Features 5 interconnected zones:
## 1. Ruined Terraces (Platforming, Bats, Wolves, Lore Stele, Keystone 1)
## 2. Underground Forge (Master Poolad Sanctuary, Upgrades, Checkpoint)
## 3. Corrupted Mine & Depths (Hollow Villagers, Thorn Spitters, Golden Pomegranate, Keystone 2)
## 4. Colosseum of the Colossus (Cinematic 2-Phase Crusher Boss, Stalactites, Spikes)
## 5. Summit Overlook (Ancient Beacon Victory Climax)

@onready var master_poolad: MasterPoolad = $MasterPoolad
@onready var crusher_boss: CrusherOfTheRuins = $BossArena/CrusherOfTheRuins
@onready var hollow_lurker: HollowLurker = $Enemies/HollowLurker
@onready var keystone_gate: StaticBody2D = $Environment/KeystoneGate
@onready var ancient_beacon: Node2D = $Environment/AncientBeacon
@onready var nasim_merchant: Node2D = $NasimMerchant

var _active_speaker: String = "poolad"
var _nasim_pomegranate_bought: bool = false

const KEYSTONE_ICON_TEX = preload("res://assets/ui/theme/icon_keystone.png")
const KEYSTONE_EMPTY_TEX = preload("res://assets/ui/theme/icon_keystone_empty.png")
const FOREST_LEVEL: String = "res://levels/Level_Forest.tscn"

const POOLAD_GREETING_BARDIA: String = """برخاستی شاگرد من! دستت هنوز از حرارت ضربات سندان گرم است.
ظلمات این دیار را در زیر آوار مرگ‌مایه مدفون کرد، اما آتش این کوره هنوز زنده است.
مچ‌بند سنگی فیروزه‌ای‌ات را محکم ببند. دروازه شرقی قفل است و آن سنگ‌شکن بی‌مغز در صحن باستانی کشیک می‌دهد.
دو کلیدسنگ را از خرابه‌های بیرونی و اعماق تاریک معدن پیدا کن تا دروازه را بگشاییم.
هر تکه مس و آهن قراضه‌ای که یافتی برای من بیاور؛ استخوان‌هایت برای کوبیدن آن غول سنگی باید از فولاد آب‌دیده باشد!"""

const POOLAD_GREETING_ROJAN: String = """درود بر تیزبین‌ترین دیده‌بان اسپیناس!
بادهای سیاه مرگ‌مایه بوی فساد و ناامیدی می‌دهند، اما در چشمان تو هنوز فروغ جنگل‌های کهن زنده است.
دخترم، آن هیولای سنگی در صحن شرقی پوسته‌ای از خارا دارد و تیرهای عادی به آسانی در تنش نمی‌نشینند.
باید از چابکی باد بهره ببری؛ از لبه‌ها و دیواره‌ها بجه و مفاصل پشت گردنش را با تیر هدف بگیر.
کلیدسنگ‌های دروازه را از دخمه‌ها بیاب، و هر قطعه فلزی یافتی بیاور تا نوک پیکان‌هایت را با آلیاژ آتشین کوره جلا دهم."""

const NASIM_GREETING: String = """هووی قهرمان! پای برهنه روی تیغ‌های مرگ‌مایه قدم می‌زنی و خم به ابرو نمی‌آوری؟!
من نسیمم؛ هر سوراخ‌سنبه‌ای در این کوهستان خراب‌شده را مثل کف دستم می‌شناسم.
اگر چند قطعه باستانی دندان‌گیر در کوله‌ات داری، انارهای طلایی برایت دارم که جانت را دوبله می‌کند!
راستی... اگر سر و کارت با آن سنگ‌شکن غول‌پیکر افتاد، وادارش کن به سمتت یورش بیاورد و جاخالی بده؛
وقتی با سر به دیوار صحن بکوبد گیج می‌شود و هسته فیروزه‌ای‌اش پیدا می‌شود؛ همان وقت ضربه‌هایت دوچندان کارگر است. این نصیحت هم تحفه رایگان از طرف نسیم!"""

const NASIM_OUT_OF_STOCK: String = """انار طلایی کوهستان تمام شد رفیق! نوش جانت، همین یکی را در شکاف صخره‌های قله پیدا کرده بودم.
اگر دوام آوردی و به قله رسیدی، باز هم به خیمه‌ام سر بزن!"""

var _boss_fight_started: bool = false
var _crusher_defeated: bool = false
var _weapon_upgraded: bool = false
var _keystones_collected: int = 0
const TOTAL_KEYSTONES: int = 2

func _setup_level() -> void:
	_setup_boss()
	_setup_interactables_and_collectibles()
	if ancient_beacon and ancient_beacon.has_method("lock"):
		ancient_beacon.call("lock")
	if victory_title:
		victory_title.text = "آرک اول کامل شد!"
	if victory_desc:
		victory_desc.text = "مشعل باستانی اسپیناس شعله‌ور شد و خرابه‌ها از خارهای مرگ‌مایه پاک گشتند.\nاما ریشه‌های ظلمات در جنگل مه‌آلود بالادست هنوز می‌تپند..."
	if restart_demo_btn:
		restart_demo_btn.text = "ادامه: آرک دوم"
	_update_quest_banner("ماموریت: در خرابه‌ها کاوش کنید و به کوره استاد پولاد برسید.")
	_update_keystones_label()

func _connect_level_signals() -> void:
	if master_poolad and master_poolad.interactable_component:
		master_poolad.interactable_component.interacted.connect(_on_poolad_interacted)

func _process(delta: float) -> void:
	super._process(delta)
	# Trigger boss arena when player advances past x = 4550 into Colosseum
	if not _boss_fight_started and not _crusher_defeated and player and player.global_position.x > 4550.0:
		_start_boss_battle()

	# The deep-mine guardian gives up the hunt (and its health bar) once the hero leaves its lair
	if not _boss_fight_started and player and is_instance_valid(hollow_lurker) \
			and hollow_lurker.current_state != HollowLurker.State.DORMANT \
			and not hollow_lurker.is_dying \
			and absf(player.global_position.x - hollow_lurker.get_spawn_position().x) > 520.0:
		hollow_lurker.reset_boss()
		if boss_hud:
			boss_hud.hide()

# ---------------------------------------------------------
# Collectibles & Interactables
# ---------------------------------------------------------
func _setup_interactables_and_collectibles() -> void:
	# Connect Keystones
	for keystone in get_tree().get_nodes_in_group(&"keystones"):
		if keystone.has_signal("keystone_collected"):
			keystone.connect("keystone_collected", _on_keystone_found)

	# Connect Golden Pomegranates
	for pom in get_tree().get_nodes_in_group(&"pomegranates"):
		if pom.has_signal("pomegranate_collected"):
			pom.connect("pomegranate_collected", _on_pomegranate_found)

	# Connect Lore Steles
	for stele in get_tree().get_nodes_in_group(&"lore_steles"):
		if stele.has_signal("stele_read"):
			stele.connect("stele_read", _on_lore_stele_read)

	# Connect Sanctuaries of Old Zal
	for sanctuary in get_tree().get_nodes_in_group(&"sanctuaries"):
		if sanctuary.has_signal("rested"):
			sanctuary.connect("rested", _on_lore_stele_read)

	# Connect Ancient Beacon
	if ancient_beacon and ancient_beacon.has_signal("beacon_lit"):
		ancient_beacon.connect("beacon_lit", _on_beacon_lit)

	# Connect Nasim Merchant
	if nasim_merchant:
		var interact: Area2D = nasim_merchant.get_node_or_null("InteractableComponent")
		if interact and interact.has_signal("interacted"):
			interact.connect("interacted", _on_nasim_interacted)

func _on_keystone_found() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "keystone_unlock")
	_keystones_collected += 1
	_update_keystones_label()

	if _keystones_collected >= TOTAL_KEYSTONES:
		_update_quest_banner("هر ۲ کلیدسنگ یافت شد! دروازه باستانی صحن نبرد اکنون گشوده می‌شود.")
		if keystone_gate and keystone_gate.has_method("open_gate"):
			keystone_gate.call("open_gate")
	else:
		_update_quest_banner("کلیدسنگ باستانی ۱ از ۲ یافت شد! به اعماق معدن فاسد برای کلید دوم بروید.")

func _update_keystones_label() -> void:
	if not keystone_icons:
		return
	for child in keystone_icons.get_children():
		child.queue_free()
	for i in range(TOTAL_KEYSTONES):
		var icon: TextureRect = TextureRect.new()
		icon.texture = KEYSTONE_ICON_TEX if i < _keystones_collected else KEYSTONE_EMPTY_TEX
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		keystone_icons.add_child(icon)

func _on_pomegranate_found() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "pomegranate_pickup")
	_update_quest_banner("انار طلایی باستانی نوش جان شد! حداکثر جان قهرمان افزایش یافت.")

func _on_beacon_lit() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "beacon_ignite")
		get_node("/root/AudioManager").call("stop_music", 1.5)
	_update_quest_banner("مشعل باستانی اسپیناس شعله‌ور شد! نور فیروزه‌ای خارهای مرگ‌مایه را سوزاند.")
	# Act I is done: bank the hero's progress so Act II (and "Continue") picks it up
	if player:
		SceneManager.store_player_state(player)
	SceneManager.unlock_arc(2)
	await get_tree().create_timer(1.2).timeout
	_show_victory_modal()

func _on_player_died() -> void:
	super._on_player_died()
	if _boss_fight_started and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", "forge")
	_boss_fight_started = false
	_lower_arena_walls()
	if boss_hud:
		boss_hud.hide()
	if crusher_boss and is_instance_valid(crusher_boss) and crusher_boss.has_method("reset_boss"):
		crusher_boss.reset_boss()
	if hollow_lurker and is_instance_valid(hollow_lurker) and hollow_lurker.has_method("reset_boss"):
		hollow_lurker.reset_boss()

# ---------------------------------------------------------
# Master Poolad & Nasim Dialogue
# ---------------------------------------------------------
func _on_poolad_interacted(_actor: Node2D) -> void:
	if not dialogue_layer or not dialogue_panel:
		return

	_active_speaker = "poolad"
	if master_poolad:
		master_poolad.play_talk()
	if player:
		player.set_checkpoint(Vector2(1250, 320))

	speaker_name_label.text = "استاد پولاد (آهنگر باستانی)"
	if player and player.character_type == PlayerController.CharacterType.ROJAN:
		dialogue_text_label.text = POOLAD_GREETING_ROJAN
	else:
		dialogue_text_label.text = POOLAD_GREETING_BARDIA
	prompt_hint_label.text = "[یک گزینه را برای گفتگو یا خدمات کوره انتخاب کنید]"

	btn_quest.show()
	btn_upgrade.show()
	btn_upgrade.text = "ارتقای سلاح (۵ قطعه)"
	btn_heal.show()
	btn_heal.text = "استراحت و درمان"
	btn_close.show()

	_open_dialogue_panel()

func _on_nasim_interacted(_actor: Node2D) -> void:
	if not dialogue_layer or not dialogue_panel:
		return

	_active_speaker = "nasim"
	if nasim_merchant and nasim_merchant.has_method("on_interacted"):
		nasim_merchant.call("on_interacted")
	speaker_name_label.text = "نسیم (دختر دوره‌گرد و تاجر پرتگاه‌ها)"
	dialogue_text_label.text = NASIM_GREETING
	prompt_hint_label.text = "[یک کالا را برای خرید انتخاب کنید]"

	btn_quest.hide()
	btn_upgrade.show()
	btn_upgrade.text = "خرید انار طلایی (۶ قطعه)"
	btn_heal.show()
	btn_heal.text = "معجون گیاهی شفا (۳ قطعه)"
	btn_close.show()

	_open_dialogue_panel()

func _on_quest_dialogue_chosen() -> void:
	_update_quest_banner("ماموریت: یافتن ۲ کلیدسنگ و باز کردن دروازه صحن شرقی.")
	_close_dialogue()

func _on_upgrade_chosen() -> void:
	if not player:
		return

	if _active_speaker == "nasim":
		if _nasim_pomegranate_bought:
			dialogue_text_label.text = NASIM_OUT_OF_STOCK
			return
		if player.spend_scraps(6):
			_nasim_pomegranate_bought = true
			if nasim_merchant and nasim_merchant.has_method("on_traded"):
				nasim_merchant.call("on_traded")
			if player.health_component:
				player.health_component.max_health += 1
				player.health_component.heal(1)
				player.health_updated.emit(player.health_component.current_health, player.health_component.max_health)
			dialogue_text_label.text = "انار طلایی گوارای وجودت! یک قلب دیگر به سرسختی‌ات افزوده شد."
			_update_quest_banner("انار طلایی از نسیم خریداری شد! حداکثر جان افزایش یافت.")
		else:
			dialogue_text_label.text = "جیب‌هایت خالی است قهرمان! ۶ قطعه باستانی برای این انار طلایی نیاز داری."
		return

	if _weapon_upgraded:
		dialogue_text_label.text = "سلاحت هم‌اکنون با بالاترین کیفیت ممکن تقویت شده است و ضرباتت بر سنگ خارا هم کارگر است!"
		return

	if player.spend_scraps(5):
		_weapon_upgraded = true
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").call("play_sfx", "anvil_hammer")
		if master_poolad:
			master_poolad.play_forge()
		# Symmetrical upgrade: both Bardia's melee and Rojan's arrows scale with the bonus
		player.attack_damage_bonus += 2
		if player.melee_hitbox:
			player.melee_hitbox.damage = player.get_attack_damage()
		if player.character_type == PlayerController.CharacterType.ROJAN:
			dialogue_text_label.text = "آفرین دخترم! پیکان‌هایت را با آلیاژ آتشین کوره آب‌دیده کردم. اکنون تیرهایت در تن سخت‌ترین هیولاها هم نفوذ می‌کنند!"
		else:
			dialogue_text_label.text = "آفرین! سلاحت رو با فولاد گداخته و سنگ محک ارتقا دادم. قدرت ضرباتت به طرز چشمگیری افزایش یافت!"
		_update_quest_banner("قدرت سلاح ارتقا یافت! اکنون برای نبرد سنگین آماده‌اید.")
	else:
		dialogue_text_label.text = "برای ارتقای سلاح دست‌کم به ۵ قطعه باستانی نیاز داری. در خرابه‌ها و میان دشمنان جستجو کن!"

func _on_heal_chosen() -> void:
	if not player or not player.health_component:
		return

	if _active_speaker == "nasim":
		if player.spend_scraps(3):
			if nasim_merchant and nasim_merchant.has_method("on_traded"):
				nasim_merchant.call("on_traded")
			player.health_component.heal(player.health_component.max_health)
			dialogue_text_label.text = "معجون گیاهی تازه چیده از دامنه‌های اسپیناس تقدیم تو! تمام جراحاتت التیام یافت."
		else:
			dialogue_text_label.text = "دست‌کم به ۳ قطعه باستانی برای خرید معجون شفا نیاز داری!"
		return

	player.health_component.heal(player.health_component.max_health)
	dialogue_text_label.text = "در کنار آتش کوره استراحت کردی. جان و توان از دست‌رفته‌ات کاملاً بازیابی شد!"

func _close_dialogue() -> void:
	if master_poolad:
		master_poolad.play_idle()
	if nasim_merchant and nasim_merchant.has_method("play_animation"):
		nasim_merchant.call("play_animation", &"idle")
	super._close_dialogue()

# ---------------------------------------------------------
# Boss Battle Subsystem (Phase 1 & Phase 2)
# ---------------------------------------------------------
func _setup_boss() -> void:
	if crusher_boss:
		crusher_boss.boss_health_changed.connect(_on_boss_health_changed)
		crusher_boss.boss_phase_changed.connect(_on_boss_phase_changed)
		crusher_boss.boss_defeated.connect(_on_boss_defeated)

	if hollow_lurker:
		hollow_lurker.boss_health_changed.connect(_on_lurker_health_changed)
		hollow_lurker.boss_phase_changed.connect(_on_lurker_phase_changed)
		hollow_lurker.boss_defeated.connect(_on_lurker_defeated)

func _on_lurker_health_changed(current: int, max_hp: int) -> void:
	if hollow_lurker and hollow_lurker.current_state == HollowLurker.State.DORMANT:
		return
	if boss_hud and not boss_hud.visible:
		boss_hud.show()
	if boss_title_label:
		boss_title_label.text = "خزنده ژرفا (نگهبان کلیدسنگ دوم)"
	_on_boss_health_changed(current, max_hp)
	_update_quest_banner("خزنده ژرفا از دل سنگ‌ها بیدار شد! مراقب خارهای سقفی و ضربه‌های زیرزمینی باشید.")

func _on_lurker_phase_changed(_phase: int) -> void:
	if boss_title_label:
		boss_title_label.text = "خزنده ژرفا [فاز ۲: غضب مرگ‌مایه]"
	_update_quest_banner("هشدار: خزنده ژرفا خشمگین شد و تیغ‌هایش دوچندان گشت!")

func _on_lurker_defeated() -> void:
	if not _boss_fight_started and boss_hud:
		boss_hud.hide()
	_update_quest_banner("خزنده ژرفا نابود شد! کلیدسنگ دوم اکنون بی‌نگهبان است.")

func _start_boss_battle() -> void:
	if not is_instance_valid(crusher_boss):
		return
	_boss_fight_started = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", "boss")
	if boss_title_label:
		boss_title_label.text = "سنگ‌شکن ویرانه‌ها (خادم مسخ‌شده مرگ‌مایه)"
	if boss_hud and boss_health_bar:
		boss_health_bar.max_value = crusher_boss.max_health
		boss_health_bar.value = crusher_boss.health_component.current_health
		boss_hud.show()
	if crusher_boss:
		crusher_boss.wake_up()
		_raise_arena_walls(crusher_boss.arena_left - 40.0, crusher_boss.arena_right + 40.0)
	_update_quest_banner("نبرد باس: سنگ‌شکن را به دیوار بکوبانید و هسته‌اش را بزنید!")

func _on_boss_phase_changed(_phase: int) -> void:
	if boss_title_label:
		boss_title_label.text = "سنگ‌شکن ویرانه‌ها [فاز ۲: طغیان خشم مرگ‌مایه]"
	_update_quest_banner("هشدار: سنگ‌شکن به خشم مرگ‌مایه دچار شد! مراقب جهش‌ها و تیغ‌های بلورین زمین باشید!")

func _on_boss_defeated() -> void:
	_crusher_defeated = true
	_boss_fight_started = false
	_lower_arena_walls()
	if boss_hud:
		boss_hud.hide()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", "forge")
	if ancient_beacon and ancient_beacon.has_method("unlock"):
		ancient_beacon.call("unlock")
	_update_quest_banner("سنگ‌شکن با خاک یکسان شد! از دروازه رد شده و مشعل باستانی چکاد را شعله‌ور سازید.")

	# Connect to gear drop
	await get_tree().create_timer(0.4).timeout
	var gear: AncientGearBossDrop = find_child("AncientGearBossDrop", true, false) as AncientGearBossDrop
	if gear:
		gear.gear_collected.connect(func():
			_update_quest_banner("چرخ‌دنده بزرگ برداشته شد! اکنون به سمت مشعل قله بروید.")
		)

# ---------------------------------------------------------
# Arc Progression
# ---------------------------------------------------------
## The beacon carries the hero's scraps, hearts and forge upgrade into Act II.
func _on_victory_primary_pressed() -> void:
	SceneManager.change_scene(FOREST_LEVEL, true)
