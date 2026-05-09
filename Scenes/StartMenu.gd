extends Control

func _ready():
	_apply_kenney_styles()
	$CenterContainer/VBoxContainer/NewGameBtn.pressed.connect(_on_new_game)
	$CenterContainer/VBoxContainer/SandboxBtn.pressed.connect(_on_sandbox)
	$CenterContainer/VBoxContainer/ExitBtn.pressed.connect(_on_exit)
	ScreenFade.fade_in(1.0)

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

	for btn in [$CenterContainer/VBoxContainer/NewGameBtn, $CenterContainer/VBoxContainer/SandboxBtn, $CenterContainer/VBoxContainer/ExitBtn]:
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
		
		btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))

func _on_new_game():
	await ScreenFade.fade_out(1.0)
	# Reset GameManager state if necessary (simple enough for now)
	GameManager.is_sandbox = false
	get_tree().change_scene_to_file("res://Scenes/PrologueMap.tscn")

func _on_sandbox():
	await ScreenFade.fade_out(0.5)
	get_tree().change_scene_to_file("res://Scenes/SandboxMenu.tscn")

func _on_exit():
	get_tree().quit()
