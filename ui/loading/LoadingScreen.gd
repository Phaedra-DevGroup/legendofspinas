class_name LoadingScreen
extends Control

## Asynchronous loading screen with Persian lore tips and animated progress bar.
## Displays during level transitions and scene changes.

@onready var lore_label: Label = $VBoxContainer/LoreLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var status_label: Label = $VBoxContainer/StatusLabel

var _target_path: String = ""
var _lore_tips: Array[String] = [
	"اشک آناهیتا: سنگ فیروزه‌ای مقدسی که قرن‌ها حیات را به کوهستان اسپیناس هدیه می‌داد، توسط ظلمات ربوده شده است.",
	"مرگ‌مایه: خارهای زهرآگین بنفش که طبیعت و موجودات کوهستان را مسخ و تباه کرده‌اند.",
	"استاد پولاد: در گرمای کوره زیرزمینی منتظر است تا سلاح قهرمان را برای نبرد آماده کند.",
	"روژان: کماندار چابک با تیرهای آمیخته به جادوی طبیعت و توانایی پرش دوبل بر فراز صخره‌ها.",
	"بردیا: شاگرد شجاع آهنگر با مچ‌بند درخشان و قلاب برنزی برای صعود از دیواره‌های سنگی.",
	"زال کهنسال: پیرمرد دانا در اعماق غارها با داستان‌های باستانی و آتش امنش، راهنمای مسیر است."
]

var _progress: Array = []
var _simulated_timer: float = 0.0

func _ready() -> void:
	_target_path = SceneManager.pending_scene_path
	
	# Pick random Persian lore tip
	var random_index: int = randi() % _lore_tips.size()
	if lore_label:
		lore_label.text = _lore_tips[random_index]
	
	if progress_bar:
		progress_bar.value = 0.0
	
	if not _target_path.is_empty():
		ResourceLoader.load_threaded_request(_target_path)
	else:
		# Fallback to level forge
		_target_path = "res://levels/Level_Forge.tscn"
		ResourceLoader.load_threaded_request(_target_path)

func _process(delta: float) -> void:
	_simulated_timer += delta
	
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(_target_path, _progress)
	var load_percentage: float = 0.0
	if not _progress.is_empty():
		load_percentage = float(_progress[0]) * 100.0
	
	# Smooth visual progress animation (ensure at least 0.8s for smooth feel)
	var visual_progress: float = minf(load_percentage, _simulated_timer * 110.0)
	if progress_bar:
		progress_bar.value = visual_progress
	
	if status == ResourceLoader.THREAD_LOAD_LOADED and _simulated_timer >= 0.7:
		set_process(false)
		var res: Resource = ResourceLoader.load_threaded_get(_target_path)
		SceneManager.finish_loading(res)
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		set_process(false)
		push_error("LoadingScreen: Failed to load scene: %s" % _target_path)
		SceneManager.finish_loading()
