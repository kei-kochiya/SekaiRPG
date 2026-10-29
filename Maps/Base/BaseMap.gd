extends Node2D

"""
BaseMap: Lớp điều khiển chính (Shell) cho Safehouse.
Chứa toàn bộ logic xây dựng bản đồ (Visual) và điều phối các Stage (Kịch bản).
"""

const TILE_SIZE = 32

# Các map của Hồi kết 2 (dùng chuỗi, không preload, để Base vẫn nạp được khi thiếu một map)
const BOUNTY_SCENE := "res://Maps/Bounty/BountyMap.tscn"
const INTERROGATION_SCENE := "res://Maps/Interrogation/InterrogationMap.tscn"
const HONAMI_HOUSE_SCENE := "res://Maps/HonamiHouse/HonamiHouseMap.tscn"

const NPC_COLORS := {
	"Mafuyu": Color(0.4,  0.3,  0.5),
	"Ena":    Color(0.72, 0.38, 0.16),
	"Kanade": Color(0.8,  0.8,  0.9),
	"Mizuki": Color(0.85, 0.65, 0.8),
	"Ichika": Color(0.29, 0.62, 0.62),
	"Honami": Color(1.0, 0.67, 0.53),
}

var current_stage: BaseMapStage
var _quest_label: Label
var _quest_panel: PanelContainer
var _leaving: bool = false

func _ready() -> void:
	# Hồi kết 2: ở vài giai đoạn Base không phải nơi người chơi nên đứng -> đưa thẳng tới map đúng của tiến trình
	var redirect := _arc2_redirect_target()
	if redirect != "":
		GameManager.store_map_state(redirect, Vector2.ZERO)
		get_tree().change_scene_to_file.call_deferred(redirect)
		return
	
	_init_stage()
	
	var base_music = "base"
	if current_stage and current_stage.has_method("get_bgm_track"):
		base_music = current_stage.get_bgm_track()
			
	AudioManager.play_music(base_music)
	
	_build_map()
	_spawn_npcs()
	_spawn_player()
	_spawn_transitions()
	_spawn_shop_and_sim()
	_build_quest_hud()
	
	# Áp dụng ánh sáng TRUỚC fade_in để tránh flash sáng khi vào ban đêm
	if current_stage:
		var light_color = current_stage.get_scene_lighting()
		if light_color != Color.WHITE:
			var scene_lighting = CanvasModulate.new()
			scene_lighting.name = "SceneLighting"
			scene_lighting.color = light_color
			add_child(scene_lighting)
	
	# Chờ màn hình chuyển cảnh sáng hoàn toàn trước khi chạy hội thoại kịch bản
	await ScreenFade.fade_in(0.8)
	
	if current_stage:
		current_stage.on_stage_start()

func _init_stage():
	var stage_script
	
	# Logic chọn Stage dựa trên tiến độ câu chuyện (Hồi kết 2 đứng đầu, khớp đầu tiên thắng)
	if GameManager.get_flag("game_completed"):
		stage_script = preload("res://Maps/Base/Stages/EpilogueStage.gd")
	elif GameManager.get_flag("final_confront_started"):
		stage_script = preload("res://Maps/Base/Stages/FinalStage.gd")
	elif GameManager.get_flag("kanade_killed") and not GameManager.get_flag("honami_rescue_done"):
		stage_script = preload("res://Maps/Base/Stages/RevealStage.gd")
	elif GameManager.get_flag("interrogation_seen") and not GameManager.get_flag("ena_kill_ordered"):
		stage_script = preload("res://Maps/Base/Stages/OrdersStage.gd")
	elif GameManager.get_flag("pm_boss_defeated") and not GameManager.get_flag("finale_done"):
		stage_script = preload("res://Maps/Base/Stages/FinaleStage.gd")
	elif GameManager.get_flag("honami_house_unlocked"):
		stage_script = preload("res://Maps/Base/Stages/HonamiHouseUnlockedStage.gd")
	elif GameManager.get_flag("street_mission_fully_done"):
		stage_script = preload("res://Maps/Base/Stages/PostStreetStage.gd")
	elif GameManager.get_flag("ena_cafe_done"):
		stage_script = preload("res://Maps/Base/Stages/PostCafeStreetMissionStage.gd")
	elif GameManager.get_flag("mizuki_report_done"):
		stage_script = preload("res://Maps/Base/Stages/PostHarborMorningStage.gd")
	elif GameManager.get_flag("harbor_mission_done"):
		stage_script = preload("res://Maps/Base/Stages/PostHarborStage.gd")
	elif GameManager.warehouse_wave > 5 or GameManager.get_flag("harbor_mission_unlocked"):
		stage_script = preload("res://Maps/Base/Stages/PostWarehouseStage.gd")
	else:
		stage_script = preload("res://Maps/Base/Stages/IntroStage.gd")
		
	current_stage = stage_script.new()
	add_child(current_stage)
	current_stage.setup(self)

# Map mà người chơi phải ở khi tiến trình Hồi kết 2 không dùng Base (chuỗi rỗng = ở lại Base).
# Cũng là lưới an toàn: luyện tập/trận thua thường luôn quay về Base, ta đưa họ trở lại đúng chỗ.
func _arc2_redirect_target() -> String:
	if not GameManager.get_flag("ena_left_nightcord") or GameManager.get_flag("game_completed"):
		return ""
	if GameManager.get_flag("final_confront_started"):
		return "" # FinalStage diễn ra ngay tại Base
	var target := ""
	if GameManager.get_flag("honami_rescue_done"):
		target = HONAMI_HOUSE_SCENE
	elif GameManager.get_flag("kanade_killed"):
		target = "" # RevealStage
	elif GameManager.get_flag("interrogation_seen"):
		target = INTERROGATION_SCENE if GameManager.get_flag("ena_kill_ordered") else "" # "" = OrdersStage
	else:
		target = BOUNTY_SCENE
	if target != "" and not ResourceLoader.exists(target):
		return ""
	return target

# ── Tiện ích dùng chung cho các Stage ─────────────────────────────────────────

# Node của NPC đã spawn theo tên (null nếu không có)
func get_npc_node(npc_name: String) -> Node2D:
	for child in get_children():
		if child.has_meta("is_npc") and child.get_meta("npc_name", "") == npc_name:
			return child as Node2D
	return null

# Nhân vật trang trí không tương tác (toạ độ theo ô lưới), trả về node để Stage điều khiển
func spawn_dummy(char_name: String, grid_pos: Vector2, color: Color) -> Node2D:
	MapUtils.create_dummy_char(self, char_name, grid_pos, color)
	return get_child(get_child_count() - 1) as Node2D

# Cho một nhân vật đi lần lượt qua các điểm (toạ độ pixel), quay mặt theo hướng đi, và chờ đến khi tới nơi
func walk_node(node: Node2D, points: Array, speed: float = 150.0) -> void:
	if node == null or not is_instance_valid(node) or points.is_empty():
		return
	var tw := create_tween()
	var from := node.position
	for p in points:
		var target: Vector2 = p
		tw.tween_callback(_face_node.bind(node, target - from))
		tw.tween_property(node, "position", target, maxf(from.distance_to(target) / speed, 0.01))
		from = target
	await tw.finished

func _face_node(node: Node2D, dir: Vector2) -> void:
	if node == null or not is_instance_valid(node) or dir == Vector2.ZERO:
		return
	var row := 0
	if absf(dir.x) > absf(dir.y):
		row = 2 if dir.x > 0 else 1
	else:
		row = 0 if dir.y > 0 else 3
	for child in node.get_children():
		if child is Sprite2D and child.hframes == 3 and child.vframes == 4:
			child.frame = row * 3 + 1
			return

# Khoá di chuyển người chơi (dùng ở các cảnh tự chạy, tránh bấm tương tác giữa lúc chuyển cảnh)
func freeze_player() -> void:
	var player := get_node_or_null("OverworldPlayer")
	if player:
		player.set_physics_process(false)

# ── Map Construction (Dùng chung cho mọi Stage) ───────────────────────────────

func _build_map():
	_fill_floor(5, 2, 43, 20)
	_draw_room_walls(5, 2, 43, 10)   # Rest Area
	_draw_room_walls(5, 10, 17, 20)  # Office
	_draw_room_walls(17, 10, 31, 20) # Hall
	_draw_room_walls(31, 10, 43, 20) # Dining
	
	_remove_wall_at(Vector2(17, 15))
	_remove_wall_at(Vector2(31, 15))
	_remove_wall_at(Vector2(24, 10))
	_place_tile("door_1.png", Vector2(24, 10), false)
	_remove_wall_at(Vector2(24, 20))
	_place_tile("door_1.png", Vector2(24, 20), false)
	
	_add_room_label("Khu Nghỉ Ngơi", Vector2(24, 4))
	_add_room_label("Phòng Mafuyu", Vector2(11, 12))
	_add_room_label("Sảnh Chính", Vector2(24, 12))
	_add_room_label("Phòng Ăn", Vector2(37, 12))
	
	_place_indoor_assets()

func _place_indoor_assets():
	_place_indoor_asset("table_1.png", Vector2(13, 13), true)
	_place_indoor_asset("table_2.png", Vector2(13, 14), true)
	_place_indoor_asset("table_3.png", Vector2(13, 15), true)
	_place_indoor_asset("chair_facing_right.png", Vector2(10, 14), false)
	_place_indoor_asset("office_1.png", Vector2(6, 11), true)
	_place_indoor_asset("office_2.png", Vector2(7, 11), true)
	_place_indoor_asset("office_3.png", Vector2(8, 11), true)
	_place_indoor_asset("piano_1.png", Vector2(18, 11), true)
	_place_indoor_asset("piano_2.png", Vector2(19, 11), true)
	
	for y in [4, 6, 8]:
		_place_indoor_asset("green_bed_facing_right.png", Vector2(6, y), true)
		_place_indoor_asset("red_bed_facing_left.png", Vector2(42, y), true)
	
	for i in range(1, 7):
		_place_indoor_asset("kitchen_%d.png" % i, Vector2(31 + i, 11), true)

# ── Spawning & Interactions ───────────────────────────────────────────────────

func _spawn_npcs():
	# Xóa các NPC cũ nếu có (dùng cho trường hợp chuyển Stage giữa chừng)
	for child in get_children():
		if child.has_meta("is_npc"): child.queue_free()
		
	if not current_stage: return
	
	var positions = current_stage.get_npc_positions()
	for npc_name in positions:
		_create_npc(npc_name, positions[npc_name], NPC_COLORS.get(npc_name, Color.WHITE))

func _create_npc(npc_name: String, pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = pos
	root.set_meta("is_npc", true)
	root.set_meta("npc_name", npc_name)
	
	var char_sprite = MapUtils.create_character_sprite(npc_name)
	if char_sprite:
		root.add_child(char_sprite)
	else:
		var vis = ColorRect.new()
		vis.size = Vector2(16, 24)
		vis.position = Vector2(-8, -24)
		vis.color = color
		root.add_child(vis)
	
	var lbl = Label.new()
	lbl.text = npc_name
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -42)
	root.add_child(lbl)
	
	var zone = InteractableZone.new()
	zone.prompt_text = "Nói chuyện với " + npc_name
	var zc = CollisionShape2D.new()
	var zs = CircleShape2D.new()
	zs.radius = 40
	zc.shape = zs
	zone.add_child(zc)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		if current_stage: current_stage.handle_npc_interaction(npc_name)
	)
	
	var sb = StaticBody2D.new()
	sb.collision_layer = 2
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	col.position = Vector2(0, -8)
	sb.add_child(col)
	root.add_child(sb)
	add_child(root)

func _spawn_player():
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	
	# Nếu Mizuki Control Phase đang bật, đổi màu Player thành Mizuki
	if GameManager.get_flag("mizuki_control_phase"):
		player.character_color = NPC_COLORS["Mizuki"]
		player.position = Vector2(35 * TILE_SIZE, 13 * TILE_SIZE)
	else:
		player.position = Vector2(24 * TILE_SIZE, 18 * TILE_SIZE)
		
	if GameManager.last_player_position != Vector2.ZERO:
		player.position = GameManager.last_player_position
		
	add_child(player)

func _spawn_transitions():
	var exit = InteractableZone.new()
	exit.prompt_text = "Rời khỏi nhà"
	exit.position = Vector2(24 * TILE_SIZE, 21 * TILE_SIZE)
	var ecol = CollisionShape2D.new()
	var erect = RectangleShape2D.new()
	erect.size = Vector2(64, 32)
	ecol.shape = erect
	exit.add_child(ecol)
	add_child(exit)
	exit.interacted.connect(_on_exit_interacted)

func _on_exit_interacted():
	# Chặn gọi lại trong lúc đang chọn/đang fade_out (tránh đổi scene hai lần)
	if _leaving:
		return
	
	# Một số Stage (Hồi kết 2) chặn cửa ra; handle_exit() trả về true nếu Stage đã tự xử lý
	if current_stage and current_stage.has_method("handle_exit") and current_stage.handle_exit():
		return
	
	_leaving = true
	
	# Ưu tiên đi Harbor nếu đã nhận nhiệm vụ và chưa hoàn thành
	if GameManager.get_flag("honami_house_unlocked"):
		DialogueManager.show_choice(["[Đến nhà Honami]", "[Đi dạo (Khu phố)]", "[Hủy]"])
		var idx = await DialogueManager.choice_made
		if idx == 0:
			_leave_to("res://Maps/HonamiHouse/HonamiHouseMap.tscn")
		elif idx == 1:
			_leave_to("res://Maps/Street/StreetMap.tscn")
		else:
			_leaving = false
	elif (GameManager.accepted_harbor_mission or GameManager.get_flag("harbor_mission_unlocked")) and not GameManager.harbor_mission_done:
		_leave_to("res://Maps/Harbor/HarborMap.tscn")
	# Kiểm tra chuyển cảnh sang StreetMap
	elif GameManager.get_flag("ena_cafe_done") and not GameManager.get_flag("street_survival_done"):
		if GameManager.get_flag("street_mission_ready"):
			_leave_to("res://Maps/Street/StreetMap.tscn")
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("lobby_street_mission_not_ready"))
			_leaving = false
	# Chỉ đi Warehouse nếu chưa xong 5 wave
	elif GameManager.warehouse_mission_accepted and GameManager.warehouse_wave <= 5:
		_leave_to("res://Maps/Warehouse/WarehouseMap.tscn")
	else:
		DialogueManager.play_dialogue([{"text": "Bạn chưa có lý do gì để ra ngoài lúc này.", "type": "narrator"}])
		_leaving = false

func _leave_to(scene_path: String):
	_leaving = true
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state(scene_path, Vector2.ZERO)
	get_tree().change_scene_to_file(scene_path)

func _spawn_shop_and_sim():
	# 1. Máy bán hàng tự động (Shop)
	var shop_root = Node2D.new()
	shop_root.position = Vector2(16 * TILE_SIZE, 15 * TILE_SIZE)
	
	var shop_vis = Sprite2D.new()
	var shop_tex = load("res://Assets/Sprites/chest_closed.svg")
	if shop_tex:
		shop_vis.texture = shop_tex
		shop_vis.scale = Vector2(0.8, 0.8)
		shop_vis.position = Vector2(0, -10)
	shop_root.add_child(shop_vis)
	
	var shop_lbl = Label.new()
	shop_lbl.text = "Cửa Hàng (Shop)"
	shop_lbl.add_theme_font_size_override("font_size", 9)
	shop_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	shop_lbl.position = Vector2(-36, -34)
	shop_root.add_child(shop_lbl)
	
	var shop_zone = InteractableZone.new()
	shop_zone.prompt_text = "Mở Cửa Hàng (Shop)"
	var sz_col = CollisionShape2D.new()
	var sz_shape = CircleShape2D.new()
	sz_shape.radius = 38.0
	sz_col.shape = sz_shape
	shop_zone.add_child(sz_col)
	shop_zone.interacted.connect(func():
		var shop_menu = ShopMenu.new()
		add_child(shop_menu)
	)
	shop_root.add_child(shop_zone)
	add_child(shop_root)

	# 2. Terminal Mô Phỏng Holo-Sim (Roguelite Leo Tháp)
	var sim_root = Node2D.new()
	sim_root.position = Vector2(20 * TILE_SIZE, 15 * TILE_SIZE)
	
	var sim_vis = ColorRect.new()
	sim_vis.size = Vector2(20, 24)
	sim_vis.position = Vector2(-10, -24)
	sim_vis.color = Color(0.2, 0.8, 1.0)
	sim_root.add_child(sim_vis)
	
	var sim_lbl = Label.new()
	sim_lbl.text = "Holo-Sim (Leo Tháp)"
	sim_lbl.add_theme_font_size_override("font_size", 9)
	sim_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1.0))
	sim_lbl.position = Vector2(-46, -42)
	sim_root.add_child(sim_lbl)
	
	var sim_zone = InteractableZone.new()
	sim_zone.prompt_text = "Máy Mô Phỏng Holo-Sim"
	var mz_col = CollisionShape2D.new()
	var mz_shape = CircleShape2D.new()
	mz_shape.radius = 38.0
	mz_col.shape = mz_shape
	sim_zone.add_child(mz_col)
	sim_zone.interacted.connect(func():
		DialogueManager.show_choice(["[Bắt đầu Leo Tháp (Tầng 1-10)]", "[Xem Kỷ Lục]", "[Rời khỏi]"])
		var idx = await DialogueManager.choice_made
		if idx == 0:
			await ScreenFade.fade_out(0.8)
			var p = get_node_or_null("OverworldPlayer")
			var p_pos = p.global_position if p else Vector2.ZERO
			GameManager.store_map_state("res://Maps/Base/BaseMap.tscn", p_pos)
			HoloSimManager.start_new_run()
			get_tree().change_scene_to_file("res://Scripts/Battle/BattleScene.tscn")
		elif idx == 1:
			DialogueManager.play_dialogue([
				{"text": "Kỷ lục leo tháp cao nhất của bạn: Tầng %d / 10." % HoloSimManager.high_score_floor, "type": "narrator"}
			])
	)
	sim_root.add_child(sim_zone)
	add_child(sim_root)

# ── Quest HUD ────────────────────────────────────────────────────────────────

func _build_quest_hud():
	var hud = QuestHUDBuilder.build(self)
	_quest_panel = hud["panel"]
	_quest_label = hud["label"]
	_refresh_quest_label()

func _refresh_quest_label():
	if not _quest_label or not current_stage: return
	_quest_label.text = current_stage.get_quest_text()
	_quest_panel.visible = _quest_label.text != ""

# ── Tile Helpers ─────────────────────────────────────────────────────────────

func _fill_floor(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			_place_tile("floor.png", Vector2(x, y), false)

func _draw_room_walls(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		_place_tile("horizontal_wall.png", Vector2(x, y1), true)
		_place_tile("horizontal_wall.png", Vector2(x, y2), true)
	for y in range(y1, y2 + 1):
		_place_tile("left_vertical_wall.png", Vector2(x1, y), true)
		_place_tile("right_vertical_wall.png", Vector2(x2, y), true)
	_place_tile("top_left_wall.png", Vector2(x1, y1), true)
	_place_tile("top_right_wall.png", Vector2(x2, y1), true)
	_place_tile("bottom_left_wall.png", Vector2(x1, y2), true)
	_place_tile("bottom_right_wall.png", Vector2(x2, y2), true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	MapUtils.place_tile(self, file, grid_pos, has_collision)

func _place_indoor_asset(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Indoors/" + file)
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

func _remove_wall_at(grid_pos: Vector2):
	var target_pos = grid_pos * TILE_SIZE
	for child in get_children():
		if child is Node2D:
			if child.position.distance_to(target_pos) < 1.0:
				child.queue_free()
	_place_tile("floor.png", grid_pos, false)

func _add_room_label(text: String, grid_pos: Vector2):
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	lbl.position = grid_pos * TILE_SIZE - Vector2(40, 0)
	add_child(lbl)
