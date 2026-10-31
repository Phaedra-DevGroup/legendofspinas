class_name LevelForest
extends LevelBase

## Act II: The Misty Forest (جنگل مه‌آلود و ناله آتوسا)
## 1. Forest Edge   - mist, Root Stalker ambushes, first mushroom bounces
## 2. Fungal Hollow - acid pools crossed by springy mushrooms, brittle branches and a grapple ring
## 3. Sacred Grove  - Atousa, the entangled guardian; her light opens the bramble wall
## 4. Arboris Clearing - sealed boss fight with the Corrupted Arboris
## 5. Cavern Mouth  - purified bark reward, the way on to Act III

@onready var atousa: Atousa = $Atousa
@onready var arboris: CorruptedArboris = $BossArena/CorruptedArboris
@onready var grove_bramble: BrambleWall = $Environment/GroveBramble
@onready var cavern_bramble: BrambleWall = $Environment/CavernBramble
@onready var cavern_mouth: CavernMouth = $Environment/CavernMouth

## Hero crosses this x inside the clearing -> the fight starts.
const BOSS_TRIGGER_X: float = 3720.0
const ATOUSA_CHECKPOINT: Vector2 = Vector2(3080, 302)

const ATOUSA_PLEA: String = """صدای گام‌هایت را از میان ریشه‌های رنجور زمین می‌شنیدم، فرزند کوهستان... نگاه کن، مرگ‌مایه بندبند وجودم را می‌خشکاند.
آربوریس، نگهبان کهن این بیشه، با بلور ظلمات در پشتش دیوانه شده و راه غارهای بلورین را بسته است.
با آخرین تار جانم این دیوار خار را می‌گشایم... او را از بند تاریکی رها کن؛ پوسته‌اش ضربه‌های روبرو را پس می‌زند، پس از پشت سر بر همان بلور بنفش بکوب!"""

const ATOUSA_THANKS: String = """آربوریس آرام گرفت... ریشه‌هایم سبک‌تر شده‌اند و نورم بازمی‌گردد. اکنون دهانه غارهای بلورین گشوده است.
به اعماق برو؛ آنجا چشمه‌ای باستانی هست که قطراتش هنوز خنکای دست آناهیتا را دارد.
جامی از آن آب پاک برایم بیاور تا ریشه‌های این طلسم را بسوزانم... عجله کن، قهرمان."""

const ATOUSA_QUEST: String = """از میان بیشه به شرق برو، به صحن آربوریس. وقتی شاخه‌هایش را بر خاک می‌کوبد، دمی در زمین گیر می‌کند؛ آنگاه بلورش از هر سو آسیب‌پذیر است.
و هرگاه مه زهرآگین بر زمین نشست، بر شاخه‌های بالا پناه بگیر."""

var _atousa_met: bool = false
var _talking_to_atousa: bool = false
var _boss_fight_started: bool = false
var _arboris_purified: bool = false

func _setup_level() -> void:
	if arboris:
		arboris.boss_health_changed.connect(_on_boss_health_changed)
		arboris.boss_phase_changed.connect(_on_boss_phase_changed)
		arboris.boss_defeated.connect(_on_boss_defeated)
	if cavern_mouth:
		cavern_mouth.entered.connect(_on_cavern_entered)
	for pom in get_tree().get_nodes_in_group(&"pomegranates"):
		if pom.has_signal("pomegranate_collected"):
			pom.connect("pomegranate_collected", _on_pomegranate_found)
	for stele in get_tree().get_nodes_in_group(&"lore_steles"):
		if stele.has_signal("stele_read"):
			stele.connect("stele_read", _on_lore_stele_read)
	for sanctuary in get_tree().get_nodes_in_group(&"sanctuaries"):
		if sanctuary.has_signal("rested"):
			sanctuary.connect("rested", _on_lore_stele_read)
	# Act II has no keystones
	if keystone_icons:
		keystone_icons.hide()
	if victory_title:
		victory_title.text = "آرک دوم کامل شد!"
	if victory_desc:
		victory_desc.text = "آربوریس از بند مرگ‌مایه رها شد و دهانه غارهای بلورین گشوده گشت.\nآرک سوم — ژرفای غارهای بلورین — به زودی..."
	if restart_demo_btn:
		restart_demo_btn.text = "تکرار آرک دوم"
	_update_quest_banner("آرک دوم: از جنگل مه‌آلود بگذرید و نگهبان بیشه، آتوسا، را بیابید.")

func _connect_level_signals() -> void:
	if atousa and atousa.interactable_component:
		atousa.interactable_component.interacted.connect(_on_atousa_interacted)

func _process(delta: float) -> void:
	super._process(delta)
	if not _boss_fight_started and not _arboris_purified and _atousa_met and player \
			and player.global_position.x > BOSS_TRIGGER_X:
		_start_boss_battle()

# ---------------------------------------------------------
# Atousa
# ---------------------------------------------------------
func _on_atousa_interacted(_actor: Node2D) -> void:
	if not dialogue_layer or not dialogue_panel:
		return
	_talking_to_atousa = true
	if atousa:
		atousa.play_talk()
	if player:
		player.set_checkpoint(ATOUSA_CHECKPOINT)
	speaker_name_label.text = "آتوسا (نگهبان جنگل مه‌آلود)"
	dialogue_text_label.text = ATOUSA_THANKS if _arboris_purified else ATOUSA_PLEA
	prompt_hint_label.text = "[یک گزینه را انتخاب کنید]"
	btn_quest.show()
	btn_quest.text = "راه غارهای بلورین؟"
	btn_upgrade.hide()
	btn_heal.show()
	btn_heal.text = "آرامش در نور آتوسا"
	btn_close.show()
	_open_dialogue_panel()

func _on_quest_dialogue_chosen() -> void:
	dialogue_text_label.text = ATOUSA_QUEST
	_update_quest_banner("ماموریت: آربوریس را از پشت سر بزنید و بلور مرگ‌مایه را بشکنید.")

func _on_heal_chosen() -> void:
	if not player or not player.health_component:
		return
	player.health_component.heal(player.health_component.max_health)
	player.health_updated.emit(player.health_component.current_health, player.health_component.max_health)
	dialogue_text_label.text = "نور فیروزه‌ای آتوسا بر زخم‌هایت نشست. جان از دست‌رفته‌ات بازگشت."

func _close_dialogue() -> void:
	var closing_atousa: bool = _talking_to_atousa and dialogue_layer and dialogue_layer.visible
	_talking_to_atousa = false
	if atousa:
		atousa.play_idle()
	super._close_dialogue()
	# Her first plea ends with her opening the way to the clearing
	if closing_atousa and not _atousa_met:
		_atousa_met = true
		if grove_bramble:
			grove_bramble.wither()
		_update_quest_banner("آتوسا دیوار خار را گشود! به صحن آربوریس در شرق بروید.")

# ---------------------------------------------------------
# Boss
# ---------------------------------------------------------
func _start_boss_battle() -> void:
	if not is_instance_valid(arboris):
		return
	_boss_fight_started = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", "boss")
	_show_boss_bar("آربوریس مسخ‌شده (نگهبان دیوانه بیشه)", arboris.health_component.current_health, arboris.max_health)
	arboris.wake_up()
	_raise_arena_walls(arboris.arena_left - 20.0, arboris.arena_right + 20.0, arboris.floor_y, Color(0.7, 0.95, 0.75))
	_update_quest_banner("نبرد باس: پشت سر آربوریس بروید و بلور بنفش را بشکنید!")

func _on_boss_phase_changed(_phase: int) -> void:
	if boss_title_label:
		boss_title_label.text = "آربوریس مسخ‌شده [فاز ۲: تندباد مه]"
	_update_quest_banner("هشدار: آربوریس اسید و مه زهرآگین می‌پراکند! بر شاخه‌های بالا پناه بگیرید.")

func _on_boss_defeated() -> void:
	_arboris_purified = true
	_boss_fight_started = false
	_lower_arena_walls()
	if boss_hud:
		boss_hud.hide()
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", music_track)
	if cavern_bramble:
		cavern_bramble.wither()
	if cavern_mouth:
		cavern_mouth.unlock()
	if atousa:
		atousa.set_freed()
	_update_quest_banner("آربوریس پاک شد! پوسته‌اش را بردارید و وارد غارهای بلورین شوید.")
	# Hook the bark reward once the purification sequence drops it
	await get_tree().create_timer(2.6).timeout
	var bark: ArborisBark = find_child("ArborisBark", true, false) as ArborisBark
	if bark:
		bark.bark_collected.connect(func():
			_update_quest_banner("پوسته آربوریس زره‌تان را محکم کرد: یک قلب افزوده شد! به دهانه غار بروید.")
		)

func _on_player_died() -> void:
	super._on_player_died()
	if _boss_fight_started and has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_music", music_track)
	_boss_fight_started = false
	_lower_arena_walls()
	if boss_hud:
		boss_hud.hide()
	if is_instance_valid(arboris) and not _arboris_purified:
		arboris.reset_boss()

func _on_pomegranate_found() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "pomegranate_pickup")
	_update_quest_banner("انار طلایی بیشه نوش جان شد! حداکثر جان قهرمان افزایش یافت.")

# ---------------------------------------------------------
# Act complete
# ---------------------------------------------------------
func _on_cavern_entered() -> void:
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "beacon_ignite")
		get_node("/root/AudioManager").call("stop_music", 1.5)
	if player:
		SceneManager.store_player_state(player)
	SceneManager.unlock_arc(2)
	_update_quest_banner("به ژرفای غارهای بلورین قدم گذاشتید...")
	_play_respawn_fade()
	await get_tree().create_timer(1.0).timeout
	_show_victory_modal()
