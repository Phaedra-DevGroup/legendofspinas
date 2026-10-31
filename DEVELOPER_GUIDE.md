# 🌄 The Legend of Espinas (افسانه اسپیناس)
## Developer & Contributor Architecture Guide

خوش آمدید! این راهنما برای تمام توسعه‌دهندگان، طراحان و هوش‌های مصنوعی همکار تهیه شده است تا ساختار مهندسی، استانداردها و اصول فنی بازی **«افسانه اسپیناس»** را با دقت دنبال کنند.

---

## ۱. خلاصه‌ی داستان و دنیای بازی (Story Context & Lore)
* **روستای اسپیناس:** روستایی پلکانی و باستانی در دل کوهستان که با جادوی **اشک آناهیتا** (سنگ فیروزه‌ای محراب قله) سرسبز و زنده بود.
* **شومی ظلمات (Zolmat):** جادوگر کینه‌توز که سنگ مقدس را ربوده و با خارهای زهرآگین بنفش به نام **مرگ‌مایه** (Marg-mayeh) طبیعت و موجودات را مسخ کرده است.
* **دو قهرمان قابل بازی (انتخاب اول بازی):**
  1. **بردیا (Bardia):** شاگرد تنومند آهنگر؛ نبرد نزدیک با مچ‌بند جادویی فیروزه‌ای و قلاب برنزی برای صعود.
  2. **روژان (Rojan):** کماندار چابک؛ نبرد دوربرد با تیرهای طبیعت، سرعت بالاتر، قابلیت پرش دوبل و پرش از دیوار.
* **شخصیت‌های کلیدی (NPCs):**
  * **استاد پولاد (Master Poolad):** آهنگر کوره زیرزمینی؛ ارتقای سلاح و مچ‌بند.
  * **زال کهنسال (Old Zal):** پیرمرد دانا در استراحتگاه‌های امن؛ ذخیره بازی (Checkpoint) و روایت تاریخ.
  * **نسیم (Nasim):** دختر دوره‌گرد؛ فروش انارهای طلایی (افزایش جان) و کلیدهای باستانی.
  * **آتوسا (Atousa):** نگهبان باستانی جنگل که نیمی از پیکرش در بند مرگ‌مایه گرفتار شده است.

---

## ۲. مشخصات فنی و استانداردهای کدنویسی (Tech Stack)
* **موتور بازی:** Godot Engine 4.x
* **زبان:** GDScript 2.0 با **Strict Static Typing** (استفاده اجباری از مشخص کردن نوع متغیرها و خروجی توابع).
  ```gdscript
  # نمونه استاندارد:
  var player_speed: float = 145.0
  func calculate_damage(base_amount: int) -> int:
      return base_amount * 2
  ```
* **رزولوشن پایه (Pixel Art Viewport):** `640x360` (نسبت ابعاد ۱۶:۹).
* **فونت اصلی بازی:** `Vazirmatn.ttf` و `Vazirmatn-Bold.ttf` در مسیر `res://assets/fonts/`.
* **تنظیمات متن و جهت‌گیری:** تمام دیالوگ‌ها و منوها به زبان **فارسی**، با جهت‌گیری راست‌به‌چپ (`text_direction = 2`) و تراز راست (`horizontal_alignment = 2`).

---

## ۳. ساختار پوشه‌بندی پروژه (Folder Structure)

```text
res://
├── project.godot
├── assets/
│   ├── fonts/               # فونت وزیرمتن (Vazirmatn.ttf, Vazirmatn-Bold.ttf)
│   ├── sprites/
│   │   ├── characters/      # اسپرایت‌های بردیا و روژان
│   │   ├── npcs/            # اسپرایت‌های استاد پولاد، زال، نسیم، آتوسا
│   │   └── environment/     # پس‌زمینه‌ها، تایل‌ست‌ها و موانع مرگ‌مایه
│   ├── ui/                  # دکمه‌های لمسی مدالیونی (btn_left, btn_attack, ...)
│   └── audio/               # موسیقی متن و جلوه‌های صوتی (SFX)
├── characters/
│   └── player/
│       ├── Player.tscn
│       ├── PlayerController.gd
│       └── state_machine/   # ماشین حالت بازیکن (Idle, Run, Jump, Fall, ...)
├── components/              # کامپوننت‌های ماژولار و قابل اتصال
│   ├── InteractableComponent.gd
│   ├── HealthComponent.gd   (در دست توسعه)
│   └── HitboxComponent.gd   (در دست توسعه)
├── npcs/                    # صحنه‌ها و اسکریپت‌های هر NPC
├── levels/                  # مراحل بازی (Level_Forge.tscn و ...)
├── systems/                 # سیستم‌های مرکزی و سینگلتون‌ها
│   └── scene_manager/       # مدیریت جابجایی مراحل و لودینگ
└── ui/
    ├── loading/             # صفحه لودینگ با نکات داستانی
    ├── main_menu/           # منوی اصلی و انتخاب کاراکتر
    └── touch_controls/      # دکمه‌های لمسی موبایل (CanvasLayer)
```

---

## ۴. الگوهای معماری اصلی (Core Architecture)

### ۱. ماشین حالت متناهی (Finite State Machine - FSM)
کنترلر بازیکن و دشمنان هرگز نباید از زنجیره‌های طولانی `if/else` در `_physics_process` استفاده کنند.
* هر حالت یک نود فرزند مستقل زیرمجموعه `StateMachine` است و از `PlayerState` ارث‌بری می‌کند.
* هوک‌های چرخه حیات: `enter(msg)`, `exit()`, `physics_update(delta)`, `handle_input(event)`.
* برای اضافه کردن یک حالت جدید (مثلاً `GrappleState` برای قلاب بردیا یا `WallJumpState` برای روژان):
  1. یک اسکریپت جدید مشتق از `PlayerState` در پوشه `res://characters/player/state_machine/states/` بسازید.
  2. نود آن را زیرمجموعه `StateMachine` در `Player.tscn` قرار دهید.
  3. انتقال به آن را با `state_machine.transition_to("Grapple")` فراخوانی کنید.

### ۲. معماری کامپوننت‌محور (Component-Based Design)
رفتارها باید در قالب کامپوننت‌های مستقل ساخته شوند:
* **`InteractableComponent` (`Area2D`):** 
  * به هر شیء، صندوق، یا کاراکتر تعاملی متصل می‌شود.
  * روی لایه فیزیکی ۴ (`Layer 4: Interactables`) کار می‌کند.
  * دارای سیگنال‌های `focused`, `unfocused`, `interacted`.
  * بازیکن با نود `InteractionDetector` خود، نزدیک‌ترین اینترکتور را شناسایی کرده و دکمه لمسی تعامل را روشن می‌کند.

### ۳. کنترل‌های لمسی موبایل (Android Touch Controls)
* فایل `TouchControls.tscn` روی یک `CanvasLayer` مستقل قرار دارد.
* دکمه‌های لمسی جهت (`BtnLeft` و `BtnRight`) دارای `passby_press = true` هستند تا بازیکن بتواند شست خود را بدون برداشتن از صفحه بین چپ و راست بلغزاند.
* در تنظیمات پروژه (`project.godot`)، گزینه `emulate_touch_from_mouse = true` فعال است تا روی رایانه با موس نیز قابل تست باشد.

### ۴. سیستم مدیریت صحنه‌ها (`SceneManager`)
* سینگلتون `SceneManager` به صورت اتولود ثبت شده است.
* کاراکتر انتخاب‌شده توسط کاربر در `SceneManager.selected_character` ذخیره می‌شود.
* برای تغییر مرحله از طریق لودینگ اسکرین با نکات داستانی فارسی:
  ```gdscript
  SceneManager.change_scene("res://levels/Level_Forest.tscn", true)
  ```

---

## ۵. راهنمای گام‌به‌گام اضافه کردن یک NPC جدید (مانند زال یا نسیم)
1. یک پوشه در `res://npcs/<نام_npc>/` بسازید.
2. نود ریشه را از نوع `CharacterBody2D` قرار دهید.
3. یک نود فرزند `InteractableComponent` به آن اضافه کنید و پیام دلخواه (مثلاً `"استراحت و ثبت بازی"`) به آن بدهید.
4. در اسکریپت NPC، سیگنال `interacted` را متصل کرده و منوی اختصاصی آن را باز کنید:
   ```gdscript
   func _ready() -> void:
       $InteractableComponent.interacted.connect(_on_interacted)

   func _on_interacted(actor: Node2D) -> void:
       print("تعامل انجام شد با: ", actor.name)
   ```

---

## ۶. گیت و پیام‌های کامیت (Git Guidelines)
* هر تغییر را در یک برنچ مشخص با نام مرتبط ایجاد کنید (مثلاً `feature/bardia-grapple` یا `feature/nasim-shop`).
* پیام‌های کامیت واضح و ترجیحاً به فرمت Conventional Commits باشند (مانند `feat: implement double jump for Rojan`).

---

## ۷. رابط کاربری، گرافیک و موبایل (UI, Art & Mobile)
* **تم سراسری UI:** `res://assets/ui/theme/espinas_theme.tres` (پنل‌ها و دکمه‌های پیکسلی برنزی/فیروزه‌ای). برای تغییر رنگ‌ها `python generate_ui_theme.py` را ویرایش و اجرا کنید. واریانت‌ها: `DarkPanel` و `CardPanel` (از طریق `theme_type_variation`).
* **پس‌زمینه‌های منطقه‌ای:** `levels/ZoneBackdrop.gd` برای هر منطقه (خرابه‌ها، کوره، معدن، صحن، قله) یک `Parallax2D` می‌سازد و هنگام عبور بازیکن آن‌ها را محو/ظاهر می‌کند. نقاشی‌های خام با `python process_zone_backgrounds.py <raw_dir>` به نوارهای پیکسلی ۱۲۸۰×۳۶۰ تبدیل می‌شوند.
* **موبایل:** `stretch/aspect="expand"` فعال است؛ دکمه‌های لمسی در `TouchControls._layout()` به گوشه‌های صفحه و ناحیه امن (notch) چسبانده می‌شوند. دکمه بازگشت اندروید منو/دیالوگ را می‌بندد یا بازی را متوقف می‌کند و با رفتن برنامه به پس‌زمینه بازی خودکار متوقف می‌شود. تنظیمات صدا در `user://settings.cfg` ذخیره می‌شود.
* **پلی‌تست خودکار:** `tests/playtest/Boot.tscn` سناریوهای `menu`, `tour`, `ui`, `boss`, `run` را اجرا و اسکرین‌شات ذخیره می‌کند:
  ```
  Godot_v4.7.2-stable_win64_console.exe --path . res://tests/playtest/Boot.tscn -- out=C:/tmp/shots scenario=boss hero=0
  ```

---

## ۸. آرک دوم: جنگل مه‌آلود (Act II — The Misty Forest)
* **صحنه:** `res://levels/Level_Forest.tscn` با اسکریپت `Level_Forest.gd`. پنج ناحیه: لبه جنگل، گودال قارچ‌ها، بیشه مقدس (آتوسا)، صحن آربوریس و دهانه غارهای بلورین.
* **کلاس پایه مراحل:** `levels/LevelBase.gd` (HUD، دیالوگ، نوار باس، دیوارهای صحن، صفحه پیروزی، انتخاب قهرمان). هر مرحله جدید از آن ارث‌بری می‌کند و هوک‌های `_setup_level()`، `_connect_level_signals()`، `_on_quest_dialogue_chosen()`، `_on_upgrade_chosen()`، `_on_heal_chosen()` و `_on_victory_primary_pressed()` را بازنویسی می‌کند. ساختار نودهای `TopHUD` / `DialogueUI` / `VictoryUI` باید مانند `Level_Forge.tscn` باشد.
* **پیشروی و ذخیره:** `SceneManager.store_player_state()` / `apply_player_state()` قطعات، قلب‌ها و ارتقای سلاح را به آرک بعد می‌برد (مراحلی با `carry_progress = true`). `unlock_arc()` پیشرفت را در `user://progress.cfg` ذخیره می‌کند و منوی اصلی دکمه «ادامه» را نشان می‌دهد. فهرست آرک‌ها در `SceneManager.ARC_SCENES` است.
* **مکانیک‌های محیطی:** `BounceMushroom` (قارچ ارتجاعی؛ نگه داشتن پرش = جهش بلندتر)، `CrumblingBranch` (شاخه شکننده که دوباره می‌روید)، `AcidPool` (چشمه اسیدی با `width` قابل تنظیم)، `BrambleWall` (دیواره خار با `wither()`)، `CavernMouth` (خروجی آرک).
* **دشمن تازه:** `RootStalker` (پیچک جهنده) زیر خاک پنهان می‌شود، بیرون می‌جهد، بادبزنی از تیغ شلیک می‌کند و فقط وقتی بیرون است آسیب‌پذیر است.
* **باس:** `CorruptedArboris` — ضربه از روبرو با `ArborisBarkHurtbox` دفع می‌شود؛ باید از پشت زد یا وقتی شاخه‌هایش پس از کوبش در خاک گیر کرده‌اند. فاز ۱: ریشه‌های فوران‌کننده، جاروب شاخه، کوبش، چرخش تیغ. فاز ۲: گلوله‌های اسیدی و مه زهرآگین که بازیکن را به شاخه‌های بالا می‌فرستد. پس از شکست، درخت پاک می‌شود و «پوسته آربوریس» (+۱ قلب) می‌اندازد.
* **گرافیک:** پس‌زمینه‌ها با `python process_zone_backgrounds.py <raw_dir>` (فایل‌های `forest_edge/hollow/grove.jpg`)، کاشی‌ها و اشیای پیکسلی با `python generate_act2_assets.py`، اسپرایت‌شیت‌های هوش مصنوعی با `python process_sprite_sheet.py` (گزینه‌های `--grid` و `--flip`). موسیقی جنگل: `python generate_audio_assets.py forest`.
* **پلی‌تست آرک دوم:** سناریوهای `forest_tour`، `forest_mechanics`، `forest_flow`، `forest_fog`، `forest_bossbot` و `arc_transition` در `tests/playtest/Driver.gd`. (این سناریوها `user://progress.cfg` را می‌نویسند.)
