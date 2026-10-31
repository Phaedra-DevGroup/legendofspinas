class_name SceneManagerSingleton
extends Node

## Global scene and state manager for "The Legend of Espinas".
## Handles asynchronous scene transitions, character persistence, and game state.

signal scene_transition_started(target_scene_path: String)
signal scene_transition_finished(target_scene_path: String)
signal character_selected(character_type: PlayerController.CharacterType)

var selected_character: PlayerController.CharacterType = PlayerController.CharacterType.BARDIA
var has_chosen_character: bool = false
var pending_scene_path: String = ""
var is_transitioning: bool = false

# Current game state / inventory basics
var player_health: int = 100
var max_health: int = 100
var gold_coins: int = 0
var current_checkpoint: String = "res://levels/Level_Forge.tscn"

## Story arcs in play order; "Continue" resumes the highest unlocked one.
const ARC_SCENES: Array[String] = [
	"res://levels/Level_Forge.tscn",
	"res://levels/Level_Forest.tscn",
]
const PROGRESS_PATH: String = "user://progress.cfg"

## Highest arc the player has reached (1-based).
var unlocked_arc: int = 1
## Hero progress carried between arcs: scraps, max hearts and forge upgrade.
var carried_state: Dictionary = {}

func _ready() -> void:
	_load_progress()

## Starting over from Act I drops everything carried from a previous run (unlocks stay).
func start_new_game() -> void:
	carried_state = {}

func store_player_state(player: PlayerController) -> void:
	carried_state = {
		"scraps": player.ancient_scraps,
		"max_health": player.health_component.max_health if player.health_component else 5,
		"attack_bonus": player.attack_damage_bonus,
	}

## Restores what the hero earned in earlier arcs onto a freshly spawned player.
func apply_player_state(player: PlayerController) -> void:
	if carried_state.is_empty() or player == null:
		return
	player.ancient_scraps = int(carried_state.get("scraps", 0))
	player.attack_damage_bonus = int(carried_state.get("attack_bonus", 0))
	if player.melee_hitbox:
		player.melee_hitbox.damage = player.get_attack_damage()
	if player.health_component:
		player.health_component.max_health = maxi(player.health_component.max_health, int(carried_state.get("max_health", 0)))
		player.health_component.current_health = player.health_component.max_health
	player.scraps_updated.emit(player.ancient_scraps)
	if player.health_component:
		player.health_updated.emit(player.health_component.current_health, player.health_component.max_health)

func unlock_arc(arc: int) -> void:
	unlocked_arc = maxi(unlocked_arc, arc)
	_save_progress()

func can_continue() -> bool:
	return unlocked_arc > 1 and unlocked_arc <= ARC_SCENES.size()

## Resumes the furthest arc reached with the hero and items saved at the time.
func continue_game() -> void:
	has_chosen_character = true
	change_scene(ARC_SCENES[clampi(unlocked_arc, 1, ARC_SCENES.size()) - 1], true)

func _save_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "unlocked_arc", unlocked_arc)
	cfg.set_value("progress", "hero", int(selected_character))
	cfg.set_value("progress", "carried_state", carried_state)
	cfg.save(PROGRESS_PATH)

func _load_progress() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(PROGRESS_PATH) != OK:
		return
	unlocked_arc = int(cfg.get_value("progress", "unlocked_arc", 1))
	selected_character = cfg.get_value("progress", "hero", 0) as PlayerController.CharacterType
	var saved: Variant = cfg.get_value("progress", "carried_state", {})
	if saved is Dictionary:
		carried_state = saved

func set_character(type: PlayerController.CharacterType) -> void:
	selected_character = type
	has_chosen_character = true
	character_selected.emit(type)

func change_scene(target_scene_path: String, use_loading_screen: bool = true) -> void:
	if is_transitioning:
		return
	
	is_transitioning = true
	pending_scene_path = target_scene_path
	scene_transition_started.emit(target_scene_path)
	
	if use_loading_screen:
		get_tree().change_scene_to_file("res://ui/loading/LoadingScreen.tscn")
	else:
		get_tree().change_scene_to_file(target_scene_path)
		is_transitioning = false
		scene_transition_finished.emit(target_scene_path)

func finish_loading(loaded_resource: Resource = null) -> void:
	if loaded_resource is PackedScene:
		get_tree().change_scene_to_packed(loaded_resource)
	elif not pending_scene_path.is_empty():
		var err: Error = get_tree().change_scene_to_file(pending_scene_path)
		if err != OK:
			push_error("SceneManager: Failed to load target scene: %s" % pending_scene_path)
	
	var loaded_path: String = pending_scene_path
	pending_scene_path = ""
	is_transitioning = false
	scene_transition_finished.emit(loaded_path)
