extends Node2D

const TILE_SIZE = 32
const HOUSE_SCENE := "res://Maps/HonamiHouse/HonamiHouseMap.tscn"
const TRAINING_SCENE := "res://Maps/Warehouse/TrainingWarehouseMap.tscn"
const BASE_SCENE := "res://Maps/Base/BaseMap.tscn"

# Hồi kết 2 (sau khi Honami cứu Ichika): nhà Honami là trung tâm cuối cùng, người chơi tự chọn lúc nào đối đầu Mafuyu
const CONFRONT_WARNING := "Đây là trận cuối cùng. Nếu thất bại, cô sẽ tỉnh lại ngay tại căn nhà này và còn có thể luyện tập thêm."
const DOOR_BLOCKED := "Ngoài kia chỉ còn màn đêm và Mafuyu. Không còn nơi nào để đi, cô chỉ có thể ở lại đây và chuẩn bị."

# Đang chạy chuỗi kịch bản/chuyển cảnh: chặn tương tác lặp
var _busy: bool = false
var _player: OverworldPlayer
var _quest_label: Label

func _ready():
	AudioManager.play_music("map")
	
	# Draw background
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.1, 0.1, 0.1)
	add_child(bg)
	
	_build_house()
	
	# Camera
	var cam = Camera2D.new()
	cam.position = Vector2(15 * TILE_SIZE, 10 * TILE_SIZE)
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)
	
	var lighting = CanvasModulate.new()
	lighting.color = Color(0.9, 0.95, 1.0)
	add_child(lighting)
	
	if _is_arc2() and not GameManager.get_flag("final_mafuyu_defeated"):
		_build_arc2_hud()
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _build_house():
	# Floor and Walls
	for x in range(5, 25):
		for y in range(4, 16):
			MapUtils.place_tile(self, "floor.png", Vector2(x, y))
	
	for x in range(5, 26):
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 4), true)
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 16), true)
	for y in range(4, 17):
		MapUtils.place_tile(self, "left_vertical_wall.png", Vector2(5, y), true)
		MapUtils.place_tile(self, "right_vertical_wall.png", Vector2(25, y), true)
		
	MapUtils.place_tile(self, "top_left_wall.png", Vector2(5, 4), true)
	MapUtils.place_tile(self, "top_right_wall.png", Vector2(25, 4), true)
	MapUtils.place_tile(self, "bottom_left_wall.png", Vector2(5, 16), true)
	MapUtils.place_tile(self, "bottom_right_wall.png", Vector2(25, 16), true)
	
	# Cửa ra ngoài (về Nightcord) - Dùng Sprite giả hoặc Tile
	var door = Sprite2D.new()
	door.texture = load("res://Assets/kenney_micro-roguelike/Tiles/door_1.png")
	door.scale = Vector2(4, 4)
	door.position = Vector2(15 * TILE_SIZE, 16 * TILE_SIZE)
	add_child(door)
	
	# Tạo InteractableZone cho cửa
	var zone = InteractableZone.new()
	zone.position = Vector2(15 * TILE_SIZE, 15 * TILE_SIZE)
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	col.shape = rect
	zone.add_child(col)
	zone.interacted.connect(func():
		if _is_arc2():
			# Hồi kết 2: không còn đường về Nightcord cũ
			if not _busy:
				DialogueManager.play_dialogue([{"text": DOOR_BLOCKED, "type": "narrator"}])
			return
		DialogueManager.show_choice(["[Trở về Nightcord]", "[Ở lại]"])
		var idx = await DialogueManager.choice_made
		if idx == 0:
			await ScreenFade.fade_out(1.0)
			GameManager.last_player_position = Vector2.ZERO
			get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
	)
	add_child(zone)
	
	# Giường bệnh, tủ thuốc (Dùng asset tạm)
	_place_indoor_asset("green_bed_facing_right.png", Vector2(8, 7), true, true, PI/2)
	_place_indoor_asset("green_bed_facing_right.png", Vector2(10, 7), true, true, PI/2)
	_place_indoor_asset("kitchen_1.png", Vector2(20, 6), true)
	_place_indoor_asset("kitchen_2.png", Vector2(21, 6), true)
	_place_indoor_asset("kitchen_4.png", Vector2(22, 6), true)
	
	# Spawn NPCs
	var honami_pos = Vector2(15, 8)
	MapUtils.create_dummy_char(self, "Honami", honami_pos, Color(0.5, 0.35, 0.25))
	var honami_zone = InteractableZone.new()
	honami_zone.position = honami_pos * TILE_SIZE
	var honami_col = CollisionShape2D.new()
	var honami_rect = RectangleShape2D.new()
	honami_rect.size = Vector2(32, 32)
	honami_col.shape = honami_rect
	honami_zone.add_child(honami_col)
	honami_zone.interacted.connect(func(): _on_npc_interacted("Honami"))
	add_child(honami_zone)
	
	# Rương thuốc y tế của Honami
	MapUtils.place_chest(self, "honami_clinic_chest", Vector2(18, 7), 200, "bandage", 2)
	
	# Spawn Player
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	
	if GameManager.last_player_position != Vector2.ZERO:
		player.position = GameManager.last_player_position
	else:
		player.position = Vector2(12 * TILE_SIZE, 8 * TILE_SIZE)
	player.character_color = Color(0.29, 0.62, 0.62)
	add_child(player)
	_player = player

func _place_indoor_asset(file: String, grid_pos: Vector2, _has_collision: bool, flip_h: bool = false, rot: float = 0.0):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Indoors/" + file)
	sprite.scale = Vector2(-4 if flip_h else 4, 4)
	sprite.position = tile_pos
	sprite.rotation = rot
	add_child(sprite)
	
	if _has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _run_logic():
	if _is_arc2():
		_run_arc2_logic()
	elif not GameManager.get_flag("honami_house_intro_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_house_intro"), func():
			GameManager.set_flag("honami_house_intro_done", true)
		)

func _on_npc_interacted(npc_name: String):
	if npc_name != "Honami" or _busy:
		return
	if _is_arc2():
		_talk_arc2()
		return
	DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_training_offer"), func():
		_show_training_menu()
	)

func _show_training_menu():
	# Chỉ những người còn sống trong cốt truyện mới luyện tập được
	var mapping: Array = []
	for member in ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu", "Honami"]:
		if GameManager.is_member_alive_in_story(member):
			mapping.append(member)
	var opts: Array = []
	for member in mapping:
		opts.append("%s (5 Waves)" % member)
	opts.append("Để sau.")
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if idx >= mapping.size(): return
	
	GameManager.begin_training([mapping[idx]])
	
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state(HOUSE_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(TRAINING_SCENE)

# ── Hồi kết 2: Dạ Khúc Cuối ───────────────────────────────────────────────────
# Chạy khi honami_rescue_done && !game_completed: menu của Honami (luyện tập / nâng cấp / đối đầu).
# Chọn đối đầu thì sang căn cứ (BaseMap, FinalStage); thua trận cuối FinalStage đưa người chơi về lại đây.

func _is_arc2() -> bool:
	return GameManager.get_flag("honami_rescue_done") and not GameManager.get_flag("game_completed")

func _build_arc2_hud():
	var hud = QuestHUDBuilder.build(self)
	_quest_label = hud["label"]
	_quest_label.text = "MỤC TIÊU: Luyện tập cùng Honami, rồi đối đầu Mafuyu khi đã sẵn sàng."

func _run_arc2_logic():
	# Trận cuối và đoạn kết diễn ra ở căn cứ (FinalStage); ở đây chỉ còn phần mở đầu
	if not GameManager.get_flag("honami_options_intro_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_options_intro"), func():
			GameManager.set_flag("honami_options_intro_done", true)
		)

func _freeze_player():
	if _player:
		_player.set_physics_process(false)

func _talk_arc2():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_menu_prompt"), func():
		_show_arc2_menu()
	)

func _show_arc2_menu():
	DialogueManager.show_choice(["[Luyện tập]", "[Nâng cấp]", "[Đối đầu Mafuyu]", "[Rời đi]"])
	var idx: int = await DialogueManager.choice_made
	if idx == 0:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_training_offer_arc2"), func():
			_show_arc2_training_menu()
		)
	elif idx == 1:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_upgrade_offer"), func():
			_open_arc2_upgrade()
		)
	elif idx == 2:
		DialogueManager.play_dialogue([{"text": CONFRONT_WARNING, "type": "narrator"}], func():
			_ask_confront()
		)

# Luyện tập không giới hạn, chọn Ichika / Honami / cả hai. Không đặt cờ training_*_done.
func _show_arc2_training_menu():
	var members: Array = []
	for member in ["Ichika", "Honami"]:
		if GameManager.is_member_alive_in_story(member):
			members.append(member)
	
	var opts: Array = []
	var groups: Array = []
	for member in members:
		opts.append("%s (5 Waves)" % member)
		groups.append([member])
	if members.size() > 1:
		opts.append("Cả hai (10 Waves)")
		groups.append(members.duplicate())
	opts.append("Để sau.")
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if idx >= groups.size(): return
	
	_busy = true
	_freeze_player()
	GameManager.begin_training(groups[idx])
	
	await ScreenFade.fade_out(1.0)
	# Luyện tập xong BaseMap sẽ tự đưa người chơi về lại ngôi nhà này (xem BaseMap._arc2_redirect_target)
	GameManager.store_map_state(HOUSE_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(TRAINING_SCENE)

func _open_arc2_upgrade():
	var p_list: Array[Entity] = []
	for member in ["Ichika", "Honami"]:
		if GameManager.is_member_alive_in_story(member):
			p_list.append(GameManager.get_party_member(member))
	UpgradeUI.show_ui(p_list)

func _ask_confront():
	DialogueManager.show_choice(["[Đối đầu Mafuyu ngay]", "[Chưa, chuẩn bị thêm]"])
	var idx: int = await DialogueManager.choice_made
	if idx != 0: return
	_go_to_final()

# Sang căn cứ Nightcord: FinalStage phát final_mafuyu_pre rồi vào trận cuối
func _go_to_final():
	_busy = true
	_freeze_player()
	await ScreenFade.fade_out(1.0)
	GameManager.set_flag("final_confront_started", true)
	GameManager.store_map_state(BASE_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(BASE_SCENE)
