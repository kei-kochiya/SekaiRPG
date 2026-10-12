extends Node

const ARTIFACT_DIR = "C:/Users/Admin/.gemini/antigravity/brain/0e67e76d-9e73-4b1c-a530-b5eb821eff2c/"

func _ready():
	print("[Screenshot Tool] Initializing screenshot capture...")
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("screenshots"):
		dir.make_dir("screenshots")
		
	# 1. Capture SandboxMenu
	await _capture_sandbox_menu()
	
	# 2. Capture UpgradeUI
	await _capture_upgrade_ui()
	
	# 3. Capture Defeat Banner in Sandbox
	await _capture_defeat_banner()

	# 4. Capture Battle Cards with Enemy SVGs
	await _capture_battle_cards()
	
	print("[Screenshot Tool] All screenshots captured successfully!")
	get_tree().quit(0)

func _save_image(filename: String):
	var img = get_viewport().get_texture().get_image()
	img.save_png("res://screenshots/" + filename)
	img.save_png(ARTIFACT_DIR + filename)
	print("[Screenshot Tool] Saved " + filename)

func _clear_screen_fade():
	if ScreenFade and ScreenFade._rect:
		ScreenFade._rect.modulate.a = 0.0

func _capture_sandbox_menu():
	print("[Screenshot Tool] Capturing SandboxMenu...")
	var sandbox_scene = load("res://UI/Menus/Sandbox/SandboxMenu.tscn").instantiate()
	add_child(sandbox_scene)
	
	_clear_screen_fade()
	for i in range(10):
		_clear_screen_fade()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	_save_image("screenshot_sandbox_menu.png")
	sandbox_scene.queue_free()
	await get_tree().process_frame

func _capture_upgrade_ui():
	print("[Screenshot Tool] Capturing UpgradeUI...")
	var bg_dummy = ColorRect.new()
	bg_dummy.color = Color(0.18, 0.22, 0.28) # Map-like blue-grey background to test transparency
	bg_dummy.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_dummy)
	
	var UpgradeUIClass = load("res://UI/Systems/UpgradeUI.gd")
	var upgrade_ui = UpgradeUIClass.new()
	add_child(upgrade_ui)
	
	var e1 = Ichika.new()
	e1.skill_points = 12
	var e2 = Kanade.new()
	e2.skill_points = 8
	var e3 = Mafuyu.new()
	e3.skill_points = 5
	var party: Array[Entity] = [e1, e2, e3]
	
	upgrade_ui.show_ui(party)
	
	_clear_screen_fade()
	for i in range(10):
		_clear_screen_fade()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	_save_image("screenshot_upgrade_ui.png")
	upgrade_ui.queue_free()
	bg_dummy.queue_free()
	await get_tree().process_frame

func _capture_defeat_banner():
	print("[Screenshot Tool] Capturing Defeat Banner (Sandbox)...")
	var bg_dummy = ColorRect.new()
	bg_dummy.color = Color(0.1, 0.09, 0.08)
	bg_dummy.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_dummy)
	
	GameManager.is_sandbox = true
	var BattleHUDClass = load("res://UI/Battle/BattleHUD.gd")
	var hud = BattleHUDClass.new()
	add_child(hud)
	
	hud.show_defeat()
	# Fast-forward alpha tween for screenshot
	for child in hud.get_children():
		if child is PanelContainer:
			child.modulate.a = 1.0
	
	_clear_screen_fade()
	for i in range(10):
		_clear_screen_fade()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	_save_image("screenshot_defeat_sandbox.png")
	hud.queue_free()
	bg_dummy.queue_free()
	await get_tree().process_frame

func _capture_battle_cards():
	print("[Screenshot Tool] Capturing Battle Cards (New Enemy SVGs)...")
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.10, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var container = HBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 20)
	bg.add_child(container)
	
	var CharacterCardClass = load("res://UI/Battle/CharacterCard.gd")
	
	# Player: Ichika
	var player = Ichika.new()
	var p_card = CharacterCardClass.new()
	p_card.custom_minimum_size = Vector2(220, 100)
	container.add_child(p_card)
	p_card.setup(player, true)
	
	# Enemies: Captain, Terrorist, Cyborg Enforcer
	var enemies = [Captain.new(), Terrorist.new(), CyborgEnforcer.new()]
	for enemy in enemies:
		var e_card = CharacterCardClass.new()
		e_card.custom_minimum_size = Vector2(220, 100)
		container.add_child(e_card)
		e_card.setup(enemy, false)
	
	_clear_screen_fade()
	for i in range(15):
		_clear_screen_fade()
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	
	_save_image("screenshot_battle_cards_svg.png")
	bg.queue_free()
	await get_tree().process_frame

