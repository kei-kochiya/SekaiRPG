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
		
		var load_btn = Button.new()
		load_btn.text = "TẢI GAME (LOAD)"
		load_btn.name = "LoadGameBtn"
		$CenterContainer/VBoxContainer.add_child(load_btn)
		$CenterContainer/VBoxContainer.move_child(load_btn, 2)
		_style_button(load_btn)
		load_btn.pressed.connect(_on_load_menu)
	
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

func _style_button(btn: Button, normal_svg: String = "res://Assets/UI/btn_angular_brown.svg", hover_svg: String = "res://Assets/UI/btn_angular_brown_hover.svg", text_color: Color = Color(0.96, 0.92, 0.85)):
	var ns = StyleBoxTexture.new()
	ns.texture = load(normal_svg)
	ns.texture_margin_left = 10
	ns.texture_margin_right = 10
	ns.texture_margin_top = 10
	ns.texture_margin_bottom = 14
	btn.add_theme_stylebox_override("normal", ns)
	
	if hover_svg != "":
		var hs = StyleBoxTexture.new()
		hs.texture = load(hover_svg)
		hs.texture_margin_left = 10
		hs.texture_margin_right = 10
		hs.texture_margin_top = 10
		hs.texture_margin_bottom = 14
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("focus", hs)
	else:
		btn.add_theme_stylebox_override("hover", ns)
		btn.add_theme_stylebox_override("focus", ns)
	
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_font_override("font", load("res://Assets/Fonts/#9Slide03 AMPLESOFT MEDIUM.ttf"))

func _apply_kenney_styles():
	# Title Background using angular brown banner
	var banner = NinePatchRect.new()
	banner.texture = load("res://Assets/UI/banner_angular_title.svg")
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
	title.add_theme_color_override("font_color", Color(0.96, 0.85, 0.62))
	title.add_theme_font_override("font", load("res://Assets/Fonts/zhcn.ttf"))

	_style_button($CenterContainer/VBoxContainer/NewGameBtn, "res://Assets/UI/btn_angular_brown.svg", "res://Assets/UI/btn_angular_brown_hover.svg", Color(0.96, 0.92, 0.85))
	_style_button($CenterContainer/VBoxContainer/SandboxBtn, "res://Assets/UI/btn_angular_amber.svg", "res://Assets/UI/btn_angular_amber_hover.svg", Color(0.98, 0.90, 0.80))
	_style_button($CenterContainer/VBoxContainer/ExitBtn, "res://Assets/UI/btn_angular_red.svg", "", Color(1.0, 0.88, 0.88))



func _on_continue():
	await ScreenFade.fade_out(0.5)
	GameManager.load_game("")

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
