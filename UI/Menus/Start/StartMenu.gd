extends Control

"""
StartMenu: màn hình tiêu đề chính.

Nút chính (vàng) là "Tiếp tục" nếu có save, ngược lại là "Chơi mới".
"""

const MENU_WIDTH = 320

var _error_label: Label
var _built_with_save := false # cột nút được dựng lúc có/không có save

func _ready():
	# Mọi đường về màn hình tiêu đề (thoát từ menu tạm dừng, thắng/thua, kết thúc game) đều dọn trạng thái tạm của lượt chơi trước:
	# nếu không, cờ Holo-Sim/luyện tập còn sót làm trận Sandbox kế tiếp biến thành trận khác
	GameManager.clear_transient_state()
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
	_built_with_save = has_save
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
	var btn := UITheme.make_button(text, kind, UITheme.FS_HEADING if kind == UITheme.Kind.PRIMARY else UITheme.FS_LABEL, handler)
	parent.add_child(btn)
	if kind == UITheme.Kind.PRIMARY:
		UITheme.focus_later(btn)
	return btn

# Đang chạy một lần chuyển cảnh (fade): bấm thêm nút khác hay bấm đúp không được chạy lần thứ hai
var _busy: bool = false

func _on_continue():
	if _busy:
		return
	_busy = true
	await ScreenFade.fade_out(0.5)
	if not GameManager.load_game(""):
		_busy = false
		ScreenFade.fade_in(0.3)
		var reason := GameManager.last_load_error
		_error_label.text = reason if reason != "" else "Không thể tải file save."
		_error_label.visible = true

func _on_load_menu():
	if _busy:
		return
	var save_load_scene = preload("res://UI/Menus/SaveLoad/SaveLoadMenu.tscn").instantiate()
	add_child(save_load_scene)
	save_load_scene.tree_exited.connect(_on_save_menu_closed)

# Xóa hết save trong "Tải game" thì "Tiếp tục"/"Tải game" không còn nghĩa (bấm vào chỉ fade rồi báo không có file): dựng lại cột nút
func _on_save_menu_closed() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or GameManager.has_save() == _built_with_save:
		return
	UITheme.clear_children(self)
	_build()

func _on_new_game():
	if _busy:
		return
	_busy = true
	await ScreenFade.fade_out(1.0)
	GameManager.reset_game()
	get_tree().change_scene_to_file(MapPaths.PROLOGUE)

func _on_sandbox():
	if _busy:
		return
	_busy = true
	await ScreenFade.fade_out(0.5)
	get_tree().change_scene_to_file(MapPaths.SANDBOX_MENU)

func _on_open_options():
	if _busy:
		return
	PauseMenu.show_options(true)

func _on_exit():
	get_tree().quit()
