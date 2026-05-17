extends Control

"""
StartMenu: Màn hình tiêu đề chính của game.

Hiển thị các tùy chọn: Tiếp tục (nếu có save), Game Mới, LOAD, Sandbox, Thoát.
Tự động kiểm tra và thêm nút 'Tiếp tục' nếu tìm thấy file save mặc định.
"""

func _ready():
	AudioManager.play_music("main_menu")
	_apply_kenney_styles()
	
	# Check for existing save
	if GameManager.has_save():
		var continue_btn = Button.new()
		continue_btn.text = "Tiếp tục"
		continue_btn.name = "ContinueBtn"
		$CenterContainer/VBoxContainer.add_child(continue_btn)
		$CenterContainer/VBoxContainer.move_child(continue_btn, 1) # Put it after title/banner
		_style_button(continue_btn)
		continue_btn.pressed.connect(_on_continue)
	
	$CenterContainer/VBoxContainer/NewGameBtn.pressed.connect(_on_new_game)
	$CenterContainer/VBoxContainer/SandboxBtn.pressed.connect(_on_sandbox)
	
	var option_menu_btn = Button.new()
	option_menu_btn.text = "CÀI ĐẶT"
	$CenterContainer/VBoxContainer.add_child(option_menu_btn)
	_style_button(option_menu_btn)
	$CenterContainer/VBoxContainer.move_child(option_menu_btn, $CenterContainer/VBoxContainer/ExitBtn.get_index())
	option_menu_btn.pressed.connect(_on_open_options)
	
	$CenterContainer/VBoxContainer/ExitBtn.pressed.connect(_on_exit)
	
	ScreenFade.fade_in(1.0)

func _style_button(btn: Button):
	var ns = StyleBoxTexture.new()
	ns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	ns.texture_margin_left = 10
	ns.texture_margin_right = 10
	ns.texture_margin_top = 10
	ns.texture_margin_bottom = 14
	btn.add_theme_stylebox_override("normal", ns)
	
	var hs = StyleBoxTexture.new()
	hs.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg")
	hs.texture_margin_left = 10
	hs.texture_margin_right = 10
	hs.texture_margin_top = 10
	hs.texture_margin_bottom = 14
	btn.add_theme_stylebox_override("hover", hs)
	btn.add_theme_stylebox_override("focus", hs)
	
	btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))
	btn.add_theme_font_override("font", load("res://Fonts/#9Slide03 AMPLESOFT MEDIUM.ttf"))

func _apply_kenney_styles():
	# Title Background using NinePatchRect for better stretching
	var banner = NinePatchRect.new()
	banner.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/banner_modern.svg")
	banner.patch_margin_left = 20
	banner.patch_margin_right = 20
	banner.patch_margin_top = 20
	banner.patch_margin_bottom = 20
	banner.custom_minimum_size = Vector2(400, 80)
	banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	$CenterContainer/VBoxContainer.add_child(banner)
	$CenterContainer/VBoxContainer.move_child(banner, 0)
	
	# CenterContainer inside banner to hold the title
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.add_child(cc)
	
	# Move Title to the CenterContainer
	var title = $CenterContainer/VBoxContainer/Title
	$CenterContainer/VBoxContainer.remove_child(title)
	cc.add_child(title)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	title.add_theme_font_override("font", load("res://Fonts/zhcn.ttf"))

	for btn in [$CenterContainer/VBoxContainer/NewGameBtn, $CenterContainer/VBoxContainer/SandboxBtn, $CenterContainer/VBoxContainer/ExitBtn]:
		_style_button(btn)

func _on_continue():
	await ScreenFade.fade_out(0.5)
	GameManager.load_game()

func _on_new_game():
	await ScreenFade.fade_out(1.0)
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://Maps/Prologue/PrologueMap.tscn")

func _on_sandbox():
	await ScreenFade.fade_out(0.5)
	get_tree().change_scene_to_file("res://Menus/Sandbox/SandboxMenu.tscn")

func _on_open_options():
	PauseMenu.show_options(true)

func _on_exit():
	get_tree().quit()
