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

func _ready():
	AudioManager.play_music("battle") # Đổi sang nhạc căng thẳng
	
	# Tạo hình nền tối
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.08, 0.08, 0.1)
	add_child(bg)
	
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
	# 1. Vẽ 4 góc trống của bản đồ (vỉa hè / khu sinh thái với cỏ và cây)
	for x in range(3, 28):
		for y in range(3, 18):
			var is_horiz_road = (y >= 9 and y <= 11)
			var is_vert_road = (x >= 14 and x <= 16)
			if not is_horiz_road and not is_vert_road:
				_place_tile("floor.png", Vector2(x, y))
				# Trồng cây ngẫu nhiên hoặc theo cụm ở các góc để làm rậm rạp
				if (x * 7 + y * 13) % 5 == 0:
					_place_tile("tree.png", Vector2(x, y))

	# 2. Vẽ các ngõ đường (Roads)
	# Đường ngang (Horizontal road: Y ∈ [9, 11])
	for x in range(3, 28):
		var is_intersect = (x >= 14 and x <= 16)
		# Làn trên (Y=9)
		if not is_intersect:
			_place_road_asset("Road_Edge_Horizontal_Up.png", Vector2(x, 9))
		else:
			_place_road_asset("Road_Plain.png", Vector2(x, 9))
		# Làn giữa (Y=10)
		_place_road_asset("Road_Plain.png", Vector2(x, 10))
		# Làn dưới (Y=11)
		if not is_intersect:
			_place_road_asset("Road_Edge_Horizontal_Down.png", Vector2(x, 11))
		else:
			_place_road_asset("Road_Plain.png", Vector2(x, 11))

	# Đường dọc (Vertical road: X ∈ [14, 16])
	for y in range(3, 18):
		var is_intersect = (y >= 9 and y <= 11)
		if not is_intersect:
			# Làn trái (X=14)
			_place_road_asset("Road_Edge_Vertical_Left.png", Vector2(14, y))
			# Làn giữa (X=15)
			_place_road_asset("Road_Plain.png", Vector2(15, y))
			# Làn phải (X=16)
			_place_road_asset("Road_Edge_Vertical_Right.png", Vector2(16, y))

	# 3. Vẽ vạch kẻ đường (Crosswalks) ở các cửa vào ngã tư đúng kỹ thuật:
	# - Đường Ngang (X=13 và X=17) dùng Crosswalk_Horizontal (Up, Middle, Down) theo thứ tự từ trên xuống (Y=9->11)
	# Cửa Tây (X=13)
	_place_road_asset("Crosswalk_Horizontal_Up.png", Vector2(13, 9))
	_place_road_asset("Crosswalk_Horizontal_Middle.png", Vector2(13, 10))
	_place_road_asset("Crosswalk_Horizontal_Down.png", Vector2(13, 11))
	# Cửa Đông (X=17)
	_place_road_asset("Crosswalk_Horizontal_Up.png", Vector2(17, 9))
	_place_road_asset("Crosswalk_Horizontal_Middle.png", Vector2(17, 10))
	_place_road_asset("Crosswalk_Horizontal_Down.png", Vector2(17, 11))
	
	# - Đường Dọc (Y=8 và Y=12) dùng Crosswalk_Vertical (Left, Middle, Right) theo thứ tự từ trái sang phải (X=14->16)
	# Cửa Bắc (Y=8)
	_place_road_asset("Crosswalk_Vertical_Left.png", Vector2(14, 8))
	_place_road_asset("Crosswalk_Vertical_Middle.png", Vector2(15, 8))
	_place_road_asset("Crosswalk_Vertical_Right.png", Vector2(16, 8))
	# Cửa Nam (Y=12)
	_place_road_asset("Crosswalk_Vertical_Left.png", Vector2(14, 12))
	_place_road_asset("Crosswalk_Vertical_Middle.png", Vector2(15, 12))
	_place_road_asset("Crosswalk_Vertical_Right.png", Vector2(16, 12))

	# 4. Dàn dựng tường vỉa hè bao quanh 4 góc phố khép kín (Bo góc & kết nối hoàn chỉnh 100%)
	_draw_corner_walls()

	# 5. Dàn dựng tường bao quanh (Walls) bảo vệ rìa bản đồ, trừ các ngả đường đi ra ngoài
	_draw_street_walls()

	# 6. Đặt Xe Đỏ (Red Car) phe mình tại tâm ngã tư (quay mặt sang trái)
	_place_road_asset("Red_Car_Facing_Left_1.png", Vector2(14, 10))
	_place_road_asset("Red_Car_Facing_Left_2.png", Vector2(15, 10))

	# 7. Đặt Xe Xanh Lá Cây (Green Cars) lộn xộn vây xung quanh
	# Phía Bắc (hướng xuống)
	_place_road_asset("Green_Car_Facing_Down_1.png", Vector2(15, 6))
	_place_road_asset("Green_Car_Facing_Down_2.png", Vector2(15, 7))
	# Phía Nam (hướng lên)
	_place_road_asset("Green_Car_Facing_Up_1.png", Vector2(15, 13))
	_place_road_asset("Green_Car_Facing_Up_2.png", Vector2(15, 14))
	# Phía Tây (hướng sang phải)
	_place_road_asset("Green_Car_Facing_Right_1.png", Vector2(8, 10))
	_place_road_asset("Green_Car_Facing_Right_2.png", Vector2(9, 10))
	# Phía Đông (hướng sang trái)
	_place_road_asset("Green_Car_Facing_Left_1.png", Vector2(20, 10))
	_place_road_asset("Green_Car_Facing_Left_2.png", Vector2(21, 10))

	# 8. Nhân vật phe mình: Ichika và Mizuki đứng sát cạnh xe đỏ
	_create_dummy_char("Ichika", Vector2(14, 11), Color(0.29, 0.62, 0.62))
	_create_dummy_char("Mizuki", Vector2(15, 11), Color(0.85, 0.65, 0.8))

	# 9. Tùy trạng thái kịch bản để vẽ quái (Khủng Bố) đứng xen kẽ giữa các xe xanh
	if not GameManager.get_flag("street_skirmish_done"):
		_create_dummy_char("Khủng Bố 1", Vector2(11, 10), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 2", Vector2(18, 10), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 3", Vector2(16, 13), Color.DARK_RED)
	elif not GameManager.get_flag("street_survival_done"):
		# Pha bị bao vây dồn dập
		_create_dummy_char("Khủng Bố 1", Vector2(11, 9), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 2", Vector2(18, 9), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 3", Vector2(14, 6), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 4", Vector2(16, 6), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 5", Vector2(13, 13), Color.DARK_RED)
		_create_dummy_char("Khủng Bố 6", Vector2(17, 13), Color.DARK_RED)

func _create_dummy_char(p_name: String, grid_pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = grid_pos * TILE_SIZE
	
	if p_name.begins_with("Khủng Bố"):
		var sprite = Sprite2D.new()
		sprite.texture = load("res://Assets/Person/terrorist.png")
		sprite.scale = Vector2(2, 2)
		sprite.position = Vector2(0, -6)
		root.add_child(sprite)
	else:
		var vis = ColorRect.new()
		vis.size = Vector2(16, 24)
		vis.position = Vector2(-8, -24)
		vis.color = color
		root.add_child(vis)
	
	var lbl = Label.new()
	lbl.text = p_name
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -40)
	root.add_child(lbl)
	
	add_child(root)

func _fill_floor(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			_place_tile("floor.png", Vector2(x, y))

func _draw_corner_walls():
	# =========================================================================
	# 1. Top-Left Block (Sidewalk góc Trên-Trái: X ∈ [3, 13], Y ∈ [3, 8])
	# =========================================================================
	# Tường ngang dưới (Y = 8, X ∈ [4, 12])
	for x in range(4, 13):
		_place_tile("horizontal_wall.png", Vector2(x, 8))
	# Tường dọc phải (X = 13, Y ∈ [4, 7])
	for y in range(4, 8):
		_place_tile("right_vertical_wall.png", Vector2(13, y))
	
	# Cấu hình bo góc hoàn hảo cho Top-Left block:
	_place_tile("top_left_wall.png", Vector2(3, 3))       # Góc Trên-Trái
	_place_tile("top_right_wall.png", Vector2(13, 3))     # Góc Trên-Phải
	_place_tile("bottom_left_wall.png", Vector2(3, 8))    # Góc Dưới-Trái
	_place_tile("bottom_right_wall.png", Vector2(13, 8))  # Góc Dưới-Phải (Ngã tư)

	# =========================================================================
	# 2. Top-Right Block (Sidewalk góc Trên-Phải: X ∈ [17, 27], Y ∈ [3, 8])
	# =========================================================================
	# Tường ngang dưới (Y = 8, X ∈ [18, 26])
	for x in range(18, 27):
		_place_tile("horizontal_wall.png", Vector2(x, 8))
	# Tường dọc trái (X = 17, Y ∈ [4, 7])
	for y in range(4, 8):
		_place_tile("left_vertical_wall.png", Vector2(17, y))
	
	# Cấu hình bo góc hoàn hảo cho Top-Right block:
	_place_tile("top_left_wall.png", Vector2(17, 3))      # Góc Trên-Trái
	_place_tile("top_right_wall.png", Vector2(27, 3))     # Góc Trên-Phải
	_place_tile("bottom_left_wall.png", Vector2(17, 8))   # Góc Dưới-Trái (Ngã tư)
	_place_tile("bottom_right_wall.png", Vector2(27, 8))  # Góc Dưới-Phải

	# =========================================================================
	# 3. Bottom-Left Block (Sidewalk góc Dưới-Trái: X ∈ [3, 13], Y ∈ [12, 17])
	# =========================================================================
	# Tường ngang trên (Y = 12, X ∈ [4, 12])
	for x in range(4, 13):
		_place_tile("horizontal_wall.png", Vector2(x, 12))
	# Tường dọc phải (X = 13, Y ∈ [13, 16])
	for y in range(13, 17):
		_place_tile("right_vertical_wall.png", Vector2(13, y))
	
	# Cấu hình bo góc hoàn hảo cho Bottom-Left block:
	_place_tile("top_left_wall.png", Vector2(3, 12))      # Góc Trên-Trái
	_place_tile("top_right_wall.png", Vector2(13, 12))    # Góc Trên-Phải (Ngã tư)
	_place_tile("bottom_left_wall.png", Vector2(3, 17))   # Góc Dưới-Trái
	_place_tile("bottom_right_wall.png", Vector2(13, 17)) # Góc Dưới-Phải

	# =========================================================================
	# 4. Bottom-Right Block (Sidewalk góc Dưới-Phải: X ∈ [17, 27], Y ∈ [12, 17])
	# =========================================================================
	# Tường ngang trên (Y = 12, X ∈ [18, 26])
	for x in range(18, 27):
		_place_tile("horizontal_wall.png", Vector2(x, 12))
	# Tường dọc trái (X = 17, Y ∈ [13, 16])
	for y in range(13, 17):
		_place_tile("left_vertical_wall.png", Vector2(17, y))
	
	# Cấu hình bo góc hoàn hảo cho Bottom-Right block:
	_place_tile("top_left_wall.png", Vector2(17, 12))     # Góc Trên-Trái (Ngã tư)
	_place_tile("top_right_wall.png", Vector2(27, 12))    # Góc Trên-Phải
	_place_tile("bottom_left_wall.png", Vector2(17, 17))  # Góc Dưới-Trái
	_place_tile("bottom_right_wall.png", Vector2(27, 17)) # Góc Dưới-Phải

func _draw_street_walls():
	# 1. Tường trên viền map (Y = 3, chừa lối đi X ∈ [14, 16])
	for x in range(4, 13):
		_place_tile("horizontal_wall.png", Vector2(x, 3))
	for x in range(18, 27):
		_place_tile("horizontal_wall.png", Vector2(x, 3))
		
	# 2. Tường dưới viền map (Y = 17, chừa lối đi X ∈ [14, 16])
	for x in range(4, 13):
		_place_tile("horizontal_wall.png", Vector2(x, 17))
	for x in range(18, 27):
		_place_tile("horizontal_wall.png", Vector2(x, 17))
		
	# 3. Tường trái viền map (X = 3, chừa lối đi Y ∈ [9, 11])
	for y in range(4, 8):
		_place_tile("left_vertical_wall.png", Vector2(3, y))
	for y in range(13, 17):
		_place_tile("left_vertical_wall.png", Vector2(3, y))
		
	# 4. Tường phải viền map (X = 27, chừa lối đi Y ∈ [9, 11])
	for y in range(4, 8):
		_place_tile("right_vertical_wall.png", Vector2(27, y))
	for y in range(13, 17):
		_place_tile("right_vertical_wall.png", Vector2(27, y))

func _place_tile(file: String, grid_pos: Vector2):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)

func _place_road_asset(file: String, grid_pos: Vector2):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Roads/" + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)

func _run_logic():
	if GameManager.get_flag("street_survival_done"):
		# Sau khi thắng trận sinh tồn/cứu viện của Mafuyu
		DialogueManager.play_dialogue(DialogueLoader.get_lines("street_aftermath"), func():
			_return_to_base()
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
