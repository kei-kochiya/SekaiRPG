extends Node2D

"""
HarborMap: Bản đồ nhiệm vụ Bến Cảng (Harbor) của cốt truyện.

Người chơi (Ichika + Ena) có 2 lựa chọn tiếp cận:
- Cổng chính: Đánh tuần tự 3 wave lính gác rồi gặp Boss.
- Đường vòng: Dẫn thẳng tới trận Boss (Captain).
Sau khi Boss thua, chuyển sang AlleywayMap.
"""


func _ready():
	AudioManager.play_music("map")
	
	_build_map()
	_spawn_player()
	_spawn_interactables()
	_build_mission_hud()
	
	# Chờ màn hình sáng hẳn để Dialogue UI (Layer 100) không bị ScreenFade (Layer 200) che
	await ScreenFade.fade_in(0.8)
	if not GameManager.harbor_intro_done:
		_play_intro()

func _play_intro():
	GameManager.harbor_intro_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_arrival"))

func _build_map():
	# 1. Ground / Pier (Top half)
	MapUtils.fill_floor(self, 0, 0, 80, 18)
	
	# 2. Water (Bottom half)
	MapUtils.fill_tiles(self, "water_body.png", 0, 20, 80, 30, true)
	
	# 3. Water Edge (hàng 19, đè lên mép nước)
	MapUtils.fill_tiles(self, "upper_horizontal_water.png", 0, 19, 80, 19, true)
	
	# 4. Decor
	# Some crates (chests) and barrels (not sure if barrel exists, use grave as placeholder for barrel?)
	# Actually I'll use chest.png
	_place_tile("chest.png", Vector2(10, 10), false)
	_place_tile("chest.png", Vector2(11, 10), false)
	_place_tile("chest.png", Vector2(10, 11), false)
	
	_place_tile("chest.png", Vector2(40, 15), false)
	_place_tile("chest.png", Vector2(70, 8), false)
	
	# Some trees near the top edge
	for i in range(10):
		_place_tile("tree.png", Vector2(i * 8, 2), true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	MapUtils.place_tile(self, file, grid_pos, has_collision)

func _spawn_interactables():
	# --- Cổng chính: 3 wave lính gác tuần tự, sau đó là Boss ---
	if GameManager.harbor_route == "guards" or GameManager.harbor_route == "":
		if GameManager.harbor_wave <= 3:
			var wave_positions = [
				Vector2(400, 350), # Wave 1
				Vector2(800, 350), # Wave 2
				Vector2(1200, 350) # Wave 3
			]
			_create_trigger(wave_positions[GameManager.harbor_wave - 1], "Đội Tuần Tra (Wave " + str(GameManager.harbor_wave) + ")", "guards")
		else:
			_create_trigger(Vector2(1600, 350), "Đội Trưởng (BOSS)", "guards")
	
	# --- Đường vòng: Tiếp cận Boss trực tiếp (bỏ qua lính gác) ---
	if GameManager.harbor_route == "boss" or GameManager.harbor_route == "":
		_create_trigger(Vector2(1000, 500), "Đường Vòng (BOSS)", "boss")

func _create_trigger(pos: Vector2, label: String, route: String):
	var root = Node2D.new()
	root.position = pos
	root.add_to_group("objectives")
	
	var sprite = Sprite2D.new()
	var texture_path = "res://Assets/Person/guard.svg"
	if route == "boss" or GameManager.harbor_wave > 3:
		texture_path = "res://Assets/Person/captain.svg"
	sprite.texture = load(texture_path)
	sprite.scale = Vector2(1, 1)
	sprite.position = Vector2(0, -16)
	root.add_child(sprite)
	
	root.add_child(MapUtils.make_world_label(label, UITheme.TEXT, -70.0))
	
	var zone = MapUtils.circle_zone(60, "Nhấn ENTER để chiến đấu")
	root.add_child(zone)
	
	zone.interacted.connect(func():
		GameManager.harbor_route = route
		var player_pos: Vector2 = get_node("OverworldPlayer").global_position
		# Boss được tính là trận đấu kịch bản (Scripted)
		if route == "boss" or GameManager.harbor_wave > 3:
			GameManager.start_scripted_battle("harbor_boss", MapPaths.HARBOR, player_pos)
			return
		
		GameManager.store_map_state(MapPaths.HARBOR, player_pos)
		# Lần đầu chạm trán lính gác ở cổng (chương 4): đoạn súng nổ ở cổng phát một lần, rồi mới vào trận
		if GameManager.harbor_wave <= 1 and not GameManager.get_flag("harbor_gate_firefight_done"):
			GameManager.set_flag("harbor_gate_firefight_done", true)
			DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_gate_firefight"), func():
				GameManager.trigger_battle()
			)
		else:
			GameManager.trigger_battle()
	)
	
	add_child(root)

func _spawn_player():
	MapUtils.spawn_player(self, Vector2(100, 350))

func _build_mission_hud():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0.1, 0.2, 0.7)
	sb.border_width_left = 4
	sb.border_color = Color(0.2, 0.6, 1.0)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	
	var progress = ""
	if GameManager.harbor_wave <= 3:
		progress = "Wave " + str(GameManager.harbor_wave) + " / 3"
	else:
		progress = "Đã đến Boss"
		
	label.text = "NHIỆM VỤ: Thám thính bến cảng\nTiến độ: " + progress
	panel.add_child(label)
