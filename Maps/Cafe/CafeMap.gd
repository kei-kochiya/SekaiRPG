extends Node2D

"""
CafeMap: Quản lý bối cảnh và logic sự kiện tại quán Cafe.

Lớp này xây dựng môi trường quán Cafe bằng các Asset đồ họa, điều phối chuỗi hội thoại
say xỉn của Ena, các lựa chọn rẽ nhánh dẫn đến các trận chiến kịch bản và xử lý
kết cục sau trận đấu trước khi quay trở lại căn cứ.
"""

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

func _ready():
	AudioManager.play_music("base")
	
	# Draw background (outside walls)
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.1, 0.05, 0.05)
	add_child(bg)
	
	# Build the Cafe room
	_build_cafe()
	
	# Add a Camera to center the view
	var cam = Camera2D.new()
	cam.position = Vector2(15 * TILE_SIZE, 10 * TILE_SIZE)
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _build_cafe():
	# Floor and Walls
	_fill_floor(5, 4, 25, 16)
	_draw_room_walls(5, 4, 25, 16)
	
	# Counter (Kitchen assets)
	for i in range(1, 7):
		_place_indoor_asset("kitchen_%d.png" % i, Vector2(10 + i, 5), true)
		
	# Table 1: Ena & Mizuki (Vertical table)
	_place_indoor_asset("table_1.png", Vector2(10, 10), true)
	_place_indoor_asset("table_2.png", Vector2(10, 11), true)
	_place_indoor_asset("table_3.png", Vector2(10, 12), true)
	
	# Chairs for Table 1 (1 tile away)
	_place_indoor_asset("chair_facing_right.png", Vector2(8, 11), true)
	_place_indoor_asset("chair_facing_right.png", Vector2(12, 11), true, true) # Mirrored
	
	# Table 2: 3 Thugs (Vertical table)
	_place_indoor_asset("table_1.png", Vector2(20, 10), true)
	_place_indoor_asset("table_2.png", Vector2(20, 11), true)
	_place_indoor_asset("table_3.png", Vector2(20, 12), true)
	
	# Chairs for Table 2 (3 Thugs sitting along the table, 1 tile away)
	_place_indoor_asset("chair_facing_right.png", Vector2(18, 10), true)
	_place_indoor_asset("chair_facing_right.png", Vector2(18, 11), true)
	_place_indoor_asset("chair_facing_right.png", Vector2(18, 12), true)
	
	# Characters as dummy sprites
	_create_dummy_char("Ena", Vector2(8, 11), Color(0.72, 0.38, 0.16))
	_create_dummy_char("Mizuki", Vector2(12, 11), Color(0.85, 0.65, 0.8))
	
	_create_dummy_char("Giang Hồ 1", Vector2(18, 10), Color.DARK_GRAY)
	_create_dummy_char("Giang Hồ 2", Vector2(18, 11), Color.DARK_GRAY)
	_create_dummy_char("Giang Hồ 3", Vector2(18, 12), Color.DARK_GRAY)

func _create_dummy_char(name: String, grid_pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = grid_pos * TILE_SIZE
	
	var vis = ColorRect.new()
	vis.size = Vector2(16, 24)
	vis.position = Vector2(-8, -24)
	vis.color = color
	root.add_child(vis)
	
	var lbl = Label.new()
	lbl.text = name
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -40)
	root.add_child(lbl)
	
	add_child(root)

# ── Tile Helpers ─────────────────────────────────────────────────────────────
func _fill_floor(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			_place_tile("floor.png", Vector2(x, y))

func _draw_room_walls(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		_place_tile("horizontal_wall.png", Vector2(x, y1))
		_place_tile("horizontal_wall.png", Vector2(x, y2))
	for y in range(y1, y2 + 1):
		_place_tile("left_vertical_wall.png", Vector2(x1, y))
		_place_tile("right_vertical_wall.png", Vector2(x2, y))
	_place_tile("top_left_wall.png", Vector2(x1, y1))
	_place_tile("top_right_wall.png", Vector2(x2, y1))
	_place_tile("bottom_left_wall.png", Vector2(x1, y2))
	_place_tile("bottom_right_wall.png", Vector2(x2, y2))

func _place_tile(file: String, grid_pos: Vector2):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)

func _place_indoor_asset(file: String, grid_pos: Vector2, has_collision: bool, flip_h: bool = false):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Indoors/" + file)
	sprite.scale = Vector2(-4 if flip_h else 4, 4)
	sprite.position = tile_pos
	add_child(sprite)

func _run_logic():
	if GameManager.get_flag("ena_vs_thugs_done"):
		# Outcome of thugs fight
		var won = GameManager.get_flag("ena_vs_thugs_won")
		var key = "cafe_thugs_won" if won else "cafe_thugs_lost"
		DialogueManager.play_dialogue(DialogueLoader.get_lines(key), func():
			_return_to_base()
		)
	elif GameManager.get_flag("ena_vs_mizuki_done"):
		# Outcome of mizuki fight
		var won = GameManager.get_flag("ena_vs_mizuki_won")
		if won:
			# Ena defeated Mizuki, so she goes on to fight the thugs!
			DialogueManager.play_dialogue(DialogueLoader.get_lines("cafe_mizuki_won"), func():
				_trigger_thugs_battle()
			)
		else:
			# Mizuki defeated Ena, calls Mafuyu to drag her home
			DialogueManager.play_dialogue(DialogueLoader.get_lines("cafe_mizuki_lost"), func():
				_return_to_base()
			)
	else:
		# Initial sequence
		DialogueManager.play_dialogue(DialogueLoader.get_lines("cafe_p1"), func():
			DialogueManager.show_choice(["[Hất tay ra] Xê ra! Tụi này tao cân hết!", "[Nổi cáu] Mày cản tao? Muốn ăn đòn à?!"])
			var choice_idx = await DialogueManager.choice_made
			if choice_idx == 0:
				DialogueManager.play_dialogue(DialogueLoader.get_lines("cafe_choice_fight_thugs"), func():
					_trigger_thugs_battle()
				)
			else:
				DialogueManager.play_dialogue(DialogueLoader.get_lines("cafe_choice_fight_mizuki"), func():
					_trigger_mizuki_battle()
				)
		)

func _trigger_mizuki_battle():
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "ena_vs_mizuki"
	GameManager.store_map_state("res://Maps/Cafe/CafeMap.tscn", Vector2.ZERO)
	GameManager.trigger_battle()

func _trigger_thugs_battle():
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "ena_vs_thugs"
	GameManager.store_map_state("res://Maps/Cafe/CafeMap.tscn", Vector2.ZERO)
	GameManager.trigger_battle()

func _return_to_base():
	GameManager.set_flag("ena_cafe_done", true)
	# Trả quyền điều khiển lại cho Ichika
	GameManager.set_flag("ena_control_phase", false)
	await ScreenFade.fade_out(1.5)
	GameManager.last_player_position = Vector2.ZERO
	get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
