extends Node2D

"""
HarborMap: Bản đồ nhiệm vụ Bến Cảng (Harbor) của cốt truyện.

Người chơi (Ichika + Ena) có 2 lựa chọn tiếp cận:
- Cổng chính: Đánh tuần tự 3 wave lính gác rồi gặp Boss.
- Đường vòng: Dẫn thẳng tới trận Boss (Captain).
Sau khi Boss thua, chuyển sang AlleywayMap.
"""

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

func _ready():
	ScreenFade.fade_in(0.8)
	
	_build_map()
	_spawn_player()
	_spawn_interactables()
	_build_mission_hud()
	
	if not GameManager.harbor_intro_done:
		# Brief delay to let fade-in finish
		await get_tree().create_timer(0.5).timeout
		_play_intro()

func _play_intro():
	GameManager.harbor_intro_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_arrival"))

func _build_map():
	# 1. Ground / Pier (Top half)
	_fill_rect("floor.png", 0, 0, 80, 18, false)
	
	# 2. Water (Bottom half)
	_fill_rect("water_body.png", 0, 19, 80, 30, true)
	
	# 3. Water Edge
	for x in range(0, 81):
		_place_tile("upper_horizontal_water.png", Vector2(x, 19), true)
	
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

func _fill_rect(tile: String, x1, y1, x2, y2, collision: bool):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			_place_tile(tile, Vector2(x, y), collision)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)
	if has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

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
	
	var vis = ColorRect.new()
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = Color(0.8, 0.2, 0.2) if route == "guards" else Color(0.2, 0.2, 0.8)
	root.add_child(vis)
	
	var lbl = Label.new()
	lbl.text = label
	lbl.position = Vector2(-40, -70)
	root.add_child(lbl)
	
	var zone = InteractableZone.new()
	zone.prompt_text = "Nhấn ENTER để chiến đấu"
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60
	col.shape = shape
	zone.add_child(col)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		GameManager.harbor_route = route
		GameManager.store_map_state("res://Maps/Harbor/HarborMap.tscn", get_node("OverworldPlayer").global_position)
		GameManager.trigger_battle()
	)
	
	add_child(root)

func _spawn_player():
	var p = OverworldPlayer.new()
	p.name = "OverworldPlayer"
	if GameManager.last_player_position == Vector2.ZERO:
		p.position = Vector2(100, 350)
	else:
		p.position = GameManager.last_player_position
	add_child(p)

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
