extends Control

"""
StartMenu: màn hình tiêu đề chính.

Nút chính (vàng) là "Tiếp tục" nếu có save, ngược lại là "Chơi mới".
"""

const MENU_WIDTH = 320

var _error_label: Label

func _ready():
	AudioManager.play_music("main_menu")
	_build()
	ScreenFade.fade_in(1.0)

func _build():
	add_child(UITheme.backdrop())
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = MENU_WIDTH
	column.add_theme_constant_override("separation", UITheme.SP_3)
	center.add_child(column)
	
	var title := Label.new()
	title.text = "SEKAI RPG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, 56, UITheme.ACCENT)
	column.add_child(title)
	
	var tagline := UITheme.make_label("Nhập vai chiến thuật theo lượt", UITheme.FS_BODY, UITheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(tagline)
	
	var rule := ColorRect.new()
	rule.color = UITheme.INK_600
	rule.custom_minimum_size.y = 1
	column.add_child(rule)
	
	var spacer := Control.new()
	spacer.custom_minimum_size.y = UITheme.SP_2
	column.add_child(spacer)
	
	var has_save := GameManager.has_save()
	if has_save:
		_add_button(column, "Tiếp tục", _on_continue, UITheme.Kind.PRIMARY)
	_add_button(column, "Chơi mới", _on_new_game, UITheme.Kind.SECONDARY if has_save else UITheme.Kind.PRIMARY)
	if has_save:
		_add_button(column, "Tải game", _on_load_menu)
	_add_button(column, "Sandbox", _on_sandbox)
	_add_button(column, "Cài đặt", _on_open_options)
	_add_button(column, "Thoát", _on_exit, UITheme.Kind.GHOST)
	
	_error_label = UITheme.make_label("", UITheme.FS_BODY, UITheme.DANGER_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.visible = false
	column.add_child(_error_label)

func _add_button(parent: Control, text: String, handler: Callable, kind: UITheme.Kind = UITheme.Kind.SECONDARY) -> Button:
	var btn := Button.new()
	btn.text = text
	UITheme.style_button(btn, kind, UITheme.FS_HEADING if kind == UITheme.Kind.PRIMARY else UITheme.FS_LABEL)
	btn.pressed.connect(handler)
	parent.add_child(btn)
	if kind == UITheme.Kind.PRIMARY:
		btn.call_deferred("grab_focus")
	return btn

func _on_continue():
	await ScreenFade.fade_out(0.5)
	if not GameManager.load_game(""):
		ScreenFade.fade_in(0.3)
		var reason = GameManager.get("last_load_error")
		_error_label.text = reason if reason is String and reason != "" else "Không thể tải file save."
		_error_label.visible = true

func _on_load_menu():
	var save_load_scene = preload("res://UI/Menus/SaveLoad/SaveLoadMenu.tscn").instantiate()
	add_child(save_load_scene)

func _on_new_game():
	await ScreenFade.fade_out(1.0)
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://Maps/Prologue/PrologueMap.tscn")

func _on_sandbox():
	await ScreenFade.fade_out(0.5)
	get_tree().change_scene_to_file("res://UI/Menus/Sandbox/SandboxMenu.tscn")

func _on_open_options():
	PauseMenu.show_options(true)

func _on_exit():
	get_tree().quit()
