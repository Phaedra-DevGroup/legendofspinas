class_name PauseMenu
extends CanvasLayer

## Pause Menu for 'The Legend of Espinas'.
## Manages freezing/unfreezing the game tree, restarting from checkpoint,
## restarting the level, returning to the main menu, and exiting the game.

## Back / Escape pressed while the game is frozen by something other than this menu.
signal back_requested()

@onready var modal_panel: PanelContainer = $DarkOverlay/CenterContainer/ModalPanel
@onready var resume_btn: Button = find_child("ResumeBtn", true, false) as Button
@onready var checkpoint_btn: Button = find_child("CheckpointBtn", true, false) as Button
@onready var restart_btn: Button = find_child("RestartBtn", true, false) as Button
@onready var menu_btn: Button = find_child("MenuBtn", true, false) as Button
@onready var exit_btn: Button = find_child("ExitBtn", true, false) as Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if resume_btn:
		resume_btn.pressed.connect(resume)
	if checkpoint_btn:
		checkpoint_btn.pressed.connect(restart_checkpoint)
	if restart_btn:
		restart_btn.pressed.connect(restart_level)
	if menu_btn:
		menu_btn.pressed.connect(return_to_main_menu)
	if exit_btn:
		exit_btn.pressed.connect(quit_game)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_handle_back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			# Android back button
			_handle_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Phone call, home button, notification shade: never keep playing unattended.
			# Desktop focus changes (alt-tab, headless runs) are left alone.
			if OS.has_feature("mobile") and not get_tree().paused:
				pause()

func _handle_back() -> void:
	if visible:
		resume()
	elif get_tree().paused:
		back_requested.emit()
	else:
		pause()

func toggle_pause() -> void:
	if visible:
		resume()
	elif not get_tree().paused:
		pause()

func pause() -> void:
	if visible:
		return
	get_tree().paused = true
	visible = true
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").call("play_sfx", "ui_click")
	if modal_panel:
		modal_panel.scale = Vector2(0.85, 0.85)
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.15)
	if resume_btn:
		resume_btn.grab_focus()

func resume() -> void:
	if not visible:
		return
	get_tree().paused = false
	if modal_panel:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(modal_panel, "scale", Vector2(0.85, 0.85), 0.1)
		tween.finished.connect(func(): visible = false)
	else:
		visible = false

func restart_checkpoint() -> void:
	get_tree().paused = false
	visible = false
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty():
		var p: PlayerController = players[0] as PlayerController
		if p and p.has_method("respawn"):
			p.respawn()
		elif p and p.health_component:
			p.global_position = p.checkpoint_position
			p.health_component.heal(p.health_component.max_health)
			p.velocity = Vector2.ZERO

func restart_level() -> void:
	get_tree().paused = false
	visible = false
	get_tree().reload_current_scene()

func return_to_main_menu() -> void:
	get_tree().paused = false
	visible = false
	SceneManager.change_scene("res://ui/main_menu/MainMenu.tscn", false)

func quit_game() -> void:
	get_tree().quit()
