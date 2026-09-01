extends Node2D

"""
StreetMap: Quản lý bối cảnh đường phố và logic chuỗi nhiệm vụ thám thính.
- Trận 1: Skirmish (đánh thường, phải thắng).
- Trận 2: Survival & Rescue (kịch bản sinh tồn, bị vây hãm).
- Trận 3: Aftermath (kết thúc và rút về Safehouse).

Thiết kế ngã tư chuyên nghiệp (Level Design & Set Dressing):
- Xe đỏ phe mình ở tâm bên cạnh Ichika và Mizuki.
- Xe xanh lá cây bao vây 4 phía.
- Kẻ địch (Khủng Bố) đứng xen kẽ giữa các xe xanh.
- 4 góc vỉa hè được bao bọc bởi tường xám khép kín, nối góc hoàn hảo (giống PrologueMap).
"""

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

var _lighting: CanvasModulate

func _ready():
	AudioManager.play_music("battle") # Đổi sang nhạc căng thẳng
	
	# Tạo hình nền tối
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.08, 0.08, 0.1)
	add_child(bg)
	
	_lighting = CanvasModulate.new()
	_lighting.color = Color(1.0, 1.0, 1.0)
	add_child(_lighting)
	
	# Vẽ ngã tư đường phố
	_build_street()
	
	# Camera căn giữa
	var cam = Camera2D.new()
	cam.position = Vector2(15 * TILE_SIZE, 10 * TILE_SIZE)
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _build_street():
	_draw_corners()
	_draw_roads()
	_draw_crosswalks()
	_draw_corner_walls()
	_draw_street_walls()
	_place_cars()
	_place_characters()

func _draw_corners():
	for x in range(3, 28):
		for y in range(3, 18):
			var is_horiz_road = (y >= 9 and y <= 11)
			var is_vert_road = (x >= 14 and x <= 16)
			if not is_horiz_road and not is_vert_road:
				MapUtils.place_tile(self, "floor.png", Vector2(x, y))
				if (x * 7 + y * 13) % 5 == 0:
					MapUtils.place_tile(self, "tree.png", Vector2(x, y))

func _draw_roads():
	for x in range(3, 28):
		var is_intersect = (x >= 14 and x <= 16)
		if not is_intersect:
			MapUtils.place_road_asset(self, "Road_Edge_Horizontal_Up.png", Vector2(x, 9))
		else:
			MapUtils.place_road_asset(self, "Road_Plain.png", Vector2(x, 9))
		MapUtils.place_road_asset(self, "Road_Plain.png", Vector2(x, 10))
		if not is_intersect:
			MapUtils.place_road_asset(self, "Road_Edge_Horizontal_Down.png", Vector2(x, 11))
		else:
			MapUtils.place_road_asset(self, "Road_Plain.png", Vector2(x, 11))

	for y in range(3, 18):
		var is_intersect = (y >= 9 and y <= 11)
		if not is_intersect:
			MapUtils.place_road_asset(self, "Road_Edge_Vertical_Left.png", Vector2(14, y))
			MapUtils.place_road_asset(self, "Road_Plain.png", Vector2(15, y))
			MapUtils.place_road_asset(self, "Road_Edge_Vertical_Right.png", Vector2(16, y))

func _draw_crosswalks():
	MapUtils.place_road_asset(self, "Crosswalk_Horizontal_Up.png", Vector2(13, 9))
	MapUtils.place_road_asset(self, "Crosswalk_Horizontal_Middle.png", Vector2(13, 10))
	MapUtils.place_road_asset(self, "Crosswalk_Horizontal_Down.png", Vector2(13, 11))
	MapUtils.place_road_asset(self, "Crosswalk_Horizontal_Up.png", Vector2(17, 9))
	MapUtils.place_road_asset(self, "Crosswalk_Horizontal_Middle.png", Vector2(17, 10))
	MapUtils.place_road_asset(self, "Crosswalk_Horizontal_Down.png", Vector2(17, 11))
	
	MapUtils.place_road_asset(self, "Crosswalk_Vertical_Left.png", Vector2(14, 8))
	MapUtils.place_road_asset(self, "Crosswalk_Vertical_Middle.png", Vector2(15, 8))
	MapUtils.place_road_asset(self, "Crosswalk_Vertical_Right.png", Vector2(16, 8))
	MapUtils.place_road_asset(self, "Crosswalk_Vertical_Left.png", Vector2(14, 12))
	MapUtils.place_road_asset(self, "Crosswalk_Vertical_Middle.png", Vector2(15, 12))
	MapUtils.place_road_asset(self, "Crosswalk_Vertical_Right.png", Vector2(16, 12))

func _place_cars():
	MapUtils.place_road_asset(self, "Red_Car_Facing_Left_1.png", Vector2(14, 10))
	MapUtils.place_road_asset(self, "Red_Car_Facing_Left_2.png", Vector2(15, 10))

	MapUtils.place_road_asset(self, "Green_Car_Facing_Down_1.png", Vector2(15, 6))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Down_2.png", Vector2(15, 7))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Up_1.png", Vector2(15, 13))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Up_2.png", Vector2(15, 14))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Right_1.png", Vector2(8, 10))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Right_2.png", Vector2(9, 10))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Left_1.png", Vector2(20, 10))
	MapUtils.place_road_asset(self, "Green_Car_Facing_Left_2.png", Vector2(21, 10))

func _place_characters():
	if GameManager.get_flag("street_mission_fully_done"):
		# Sandbox/Thăm lại: Chỉ spawn Player và 1 lối ra
		var player = OverworldPlayer.new()
		player.name = "OverworldPlayer"
		if GameManager.last_player_position != Vector2.ZERO:
			player.position = GameManager.last_player_position
		else:
			player.position = Vector2(15 * TILE_SIZE, 11 * TILE_SIZE)
		player.character_color = Color(0.29, 0.62, 0.62)
		add_child(player)
		
		# Thêm 1 exit zone để về Base
		var exit = InteractableZone.new()
		exit.position = Vector2(15 * TILE_SIZE, 13 * TILE_SIZE)
		exit.prompt_text = "Rời khỏi đường phố"
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(96, 32)
		col.shape = rect
		exit.add_child(col)
		exit.interacted.connect(func():
			DialogueManager.show_choice(["[Trở về Nightcord]", "[Hủy]"])
			var idx = await DialogueManager.choice_made
			if idx == 0:
				await ScreenFade.fade_out(1.0)
				GameManager.last_player_position = Vector2.ZERO
				get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
		)
		add_child(exit)
		return
		
	MapUtils.create_dummy_char(self, "Ichika", Vector2(14, 11), Color(0.29, 0.62, 0.62))
	MapUtils.create_dummy_char(self, "Mizuki", Vector2(15, 11), Color(0.85, 0.65, 0.8))

	if not GameManager.get_flag("street_skirmish_done"):
		MapUtils.create_dummy_char(self, "Khủng Bố 1", Vector2(11, 10), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 2", Vector2(18, 10), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 3", Vector2(16, 13), Color.DARK_RED)
	elif not GameManager.get_flag("street_survival_done"):
		MapUtils.create_dummy_char(self, "Khủng Bố 1", Vector2(11, 9), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 2", Vector2(18, 9), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 3", Vector2(14, 6), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 4", Vector2(16, 6), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 5", Vector2(13, 13), Color.DARK_RED)
		MapUtils.create_dummy_char(self, "Khủng Bố 6", Vector2(17, 13), Color.DARK_RED)

func _fill_floor(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			MapUtils.place_tile(self, "floor.png", Vector2(x, y))

func _draw_corner_walls():
	MapUtils.draw_corner_walls(self)

func _draw_street_walls():
	# 1. Tường trên viền map (Y = 3, chừa lối đi X ∈ [14, 16])
	for x in range(4, 13):
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 3))
	for x in range(18, 27):
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 3))
		
	# 2. Tường dưới viền map (Y = 17, chừa lối đi X ∈ [14, 16])
	for x in range(4, 13):
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 17))
	for x in range(18, 27):
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 17))
		
	# 3. Tường trái viền map (X = 3, chừa lối đi Y ∈ [9, 11])
	for y in range(4, 8):
		MapUtils.place_tile(self, "left_vertical_wall.png", Vector2(3, y))
	for y in range(13, 17):
		MapUtils.place_tile(self, "left_vertical_wall.png", Vector2(3, y))
		
	# 4. Tường phải viền map (X = 27, chừa lối đi Y ∈ [9, 11])
	for y in range(4, 8):
		MapUtils.place_tile(self, "right_vertical_wall.png", Vector2(27, y))
	for y in range(13, 17):
		MapUtils.place_tile(self, "right_vertical_wall.png", Vector2(27, y))

func _run_logic():
	if GameManager.get_flag("street_mission_fully_done"):
		return # Đi lại tự do
	elif GameManager.get_flag("street_survival_done"):
		# Sau khi thắng trận sinh tồn/cứu viện của Mafuyu
		DialogueManager.play_dialogue(DialogueLoader.get_lines("street_aftermath"), func():
			# Mafuyu dẫn Mizuki về, để Ichika lại
			DialogueManager.play_dialogue(DialogueLoader.get_lines("street_intel_search"), func():
				await ScreenFade.fade_out(1.0)
				_lighting.color = Color(0.1, 0.1, 0.15) # Tối khuya
				# Biến mất các nhân vật khác
				for child in get_children():
					if child.has_meta("is_npc") and child.get_meta("npc_name") != "Ichika":
						child.queue_free()
				await ScreenFade.fade_in(1.0)
				
				# Spawn Honami
				MapUtils.create_dummy_char(self, "Honami", Vector2(16, 11), Color(0.5, 0.35, 0.25))
				
				DialogueManager.play_dialogue(DialogueLoader.get_lines("street_honami_encounter"), func():
					GameManager.set_flag("street_mission_fully_done", true)
					_return_to_base()
				)
			)
		)
	elif GameManager.get_flag("street_skirmish_done"):
		# Sau khi thắng trận đấu thường 1
		DialogueManager.play_dialogue(DialogueLoader.get_lines("street_surrounded"), func():
			_trigger_survival_battle()
		)
	else:
		# Lần đầu đến đường phố
		DialogueManager.play_dialogue(DialogueLoader.get_lines("street_followed"), func():
			_trigger_skirmish_battle()
		)

func _trigger_skirmish_battle():
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "street_skirmish"
	GameManager.store_map_state("res://Maps/Street/StreetMap.tscn", Vector2.ZERO)
	GameManager.trigger_battle()

func _trigger_survival_battle():
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "street_survival"
	GameManager.store_map_state("res://Maps/Street/StreetMap.tscn", Vector2.ZERO)
	GameManager.trigger_battle()

func _return_to_base():
	await ScreenFade.fade_out(1.5)
	GameManager.last_player_position = Vector2.ZERO
	get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
