extends Node2D

"""
BaseMap: Lớp điều khiển chính (Shell) cho Safehouse.
Chứa toàn bộ logic xây dựng bản đồ (Visual) và điều phối các Stage (Kịch bản).
"""

const TILE_SIZE = MapUtils.TILE_SIZE

# Các map của Hồi kết 2 (dùng chuỗi, không preload, để Base vẫn nạp được khi thiếu một map)
const BOUNTY_SCENE := MapPaths.BOUNTY
const INTERROGATION_SCENE := MapPaths.INTERROGATION
const HONAMI_HOUSE_SCENE := MapPaths.HONAMI_HOUSE

# Bảng màu nhân vật dùng chung với OverworldPlayer (một nguồn duy nhất ở MapUtils)
const NPC_COLORS := MapUtils.CHARACTER_COLORS

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
	if current_stage:
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
		# Bỏ qua node đã xếp hàng chờ xóa (NPC vừa được dựng lại trong cùng frame: bản cũ vẫn còn trong cây tới cuối frame)
		if child.has_meta("is_npc") and child.get_meta("npc_name", "") == npc_name and not child.is_queued_for_deletion():
			return child as Node2D
	return null

# Nhân vật trang trí không tương tác (toạ độ theo ô lưới), trả về node để Stage điều khiển
func spawn_dummy(char_name: String, grid_pos: Vector2, color: Color) -> Node2D:
	return MapUtils.create_dummy_char(self, char_name, grid_pos, color)

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

func unfreeze_player() -> void:
	var player := get_node_or_null("OverworldPlayer")
	if player:
		player.set_physics_process(true)

# Đổi nhân vật người chơi theo tên (màu -> sprite); thay cho khối get_node_or_null("OverworldPlayer") + character_color chép ở nhiều Stage
func set_player(char_name: String) -> void:
	var player := get_node_or_null("OverworldPlayer") as OverworldPlayer
	if player:
		player.character_color = NPC_COLORS[char_name]

# Đặt người chơi tại ô lưới (và hướng nhìn nếu có); thay cho `player.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)` chép ở nhiều Stage
func place_player(grid_pos: Vector2, facing: String = "") -> void:
	var player := get_node_or_null("OverworldPlayer") as OverworldPlayer
	if player:
		player.position = grid_pos * TILE_SIZE
		if facing != "":
			player.set_facing(facing)

# ── Map Construction (Dùng chung cho mọi Stage) ───────────────────────────────

func _build_map():
	MapUtils.fill_floor(self, 5, 2, 43, 20)
	MapUtils.draw_room_walls(self, 5, 2, 43, 10)   # Rest Area
	MapUtils.draw_room_walls(self, 5, 10, 17, 20)  # Office
	MapUtils.draw_room_walls(self, 17, 10, 31, 20) # Hall
	MapUtils.draw_room_walls(self, 31, 10, 43, 20) # Dining
	
	MapUtils.remove_wall_at(self, Vector2(17, 15))
	MapUtils.remove_wall_at(self, Vector2(31, 15))
	MapUtils.remove_wall_at(self, Vector2(24, 10))
	MapUtils.place_tile(self, "door_1.png", Vector2(24, 10))
	MapUtils.remove_wall_at(self, Vector2(24, 20))
	MapUtils.place_tile(self, "door_1.png", Vector2(24, 20))
	
	_add_room_label("Khu Nghỉ Ngơi", Vector2(24, 4))
	# Ba phòng dưới: để bảng tên ở hàng sát tường dưới (hàng 19) vì NPC luôn đứng ở hàng 11-17, tên không bị sprite đè
	_add_room_label("Phòng Mafuyu", Vector2(11, 19))
	_add_room_label("Sảnh Chính", Vector2(24, 19))
	_add_room_label("Phòng Ăn", Vector2(37, 19))
	
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
	
	MapUtils.add_character_body(root, npc_name, color)
	
	root.add_child(MapUtils.make_world_label(npc_name, color))
	
	var zone = MapUtils.circle_zone(40, "Nói chuyện với " + npc_name)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		if current_stage: current_stage.talk_to_npc(npc_name)
	)
	
	MapUtils.add_static_box(root, Vector2(16, 16), Vector2.ZERO, 2, Vector2(0, -8)) # thân NPC: người chơi không đi xuyên được
	add_child(root)

func _spawn_player():
	var player = OverworldPlayer.new()
	
	# Nếu Mizuki Control Phase đang bật, đổi màu Player thành Mizuki
	if GameManager.get_flag("mizuki_control_phase"):
		player.character_color = NPC_COLORS["Mizuki"]
		player.position = Vector2(35 * TILE_SIZE, 13 * TILE_SIZE)
	else:
		player.position = Vector2(24 * TILE_SIZE, 18 * TILE_SIZE)

	add_child(player) # OverworldPlayer tự nạp last_player_position khi vào cây

func _spawn_transitions():
	var exit = MapUtils.rect_zone(Vector2(64, 32), "Rời khỏi nhà", Vector2(24 * TILE_SIZE, 21 * TILE_SIZE))
	add_child(exit)
	exit.interacted.connect(_on_exit_interacted)

func _on_exit_interacted():
	# Chặn gọi lại trong lúc đang chọn/đang fade_out (tránh đổi scene hai lần)
	if _leaving:
		return
	
	# Một số Stage (Hồi kết 2) chặn cửa ra; handle_exit() trả về true nếu Stage đã tự xử lý
	if current_stage and current_stage.handle_exit():
		return
	
	_leaving = true
	
	# Ưu tiên đi Harbor nếu đã nhận nhiệm vụ và chưa hoàn thành
	if GameManager.get_flag("honami_house_unlocked"):
		var idx: int = await DialogueManager.ask(["[Đến nhà Honami]", "[Đi dạo (Khu phố)]", "[Hủy]"])
		if idx == 0:
			_leave_to(MapPaths.HONAMI_HOUSE)
		elif idx == 1:
			_leave_to(MapPaths.STREET)
		else:
			_leaving = false
	elif GameManager.get_flag("harbor_mission_unlocked") and not GameManager.get_flag("accepted_harbor_mission"):
		# Chưa nhận nhiệm vụ từ Ena: cảnh Bến Cảng (harbor_arrival) giả định cô ấy đã giao việc
		DialogueManager.play_dialogue([{"text": "Ena đang đợi để giao nhiệm vụ Bến Cảng. Nên gặp cô ấy trước khi đi.", "type": "narrator"}])
		_leaving = false
	elif GameManager.get_flag("accepted_harbor_mission") and not GameManager.get_flag("harbor_mission_done"):
		_leave_to(MapPaths.HARBOR)
	# Kiểm tra chuyển cảnh sang StreetMap
	elif GameManager.get_flag("ena_cafe_done") and not GameManager.get_flag("street_survival_done"):
		if GameManager.get_flag("street_mission_ready"):
			_leave_to(MapPaths.STREET)
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("lobby_street_mission_not_ready"))
			_leaving = false
	# Chỉ đi Warehouse nếu chưa xong 5 wave
	elif GameManager.get_flag("warehouse_mission_accepted") and GameManager.warehouse_wave <= 5:
		_leave_to(MapPaths.WAREHOUSE)
	else:
		DialogueManager.play_dialogue([{"text": "Bạn chưa có lý do gì để ra ngoài lúc này.", "type": "narrator"}])
		_leaving = false

func _leave_to(scene_path: String):
	_leaving = true
	await GameManager.change_map(scene_path, 1.0)

func _spawn_shop_and_sim():
	# 1. Máy bán hàng tự động (Shop)
	var shop_vis = Sprite2D.new()
	var shop_tex = load("res://Assets/Sprites/chest_closed.svg")
	if shop_tex:
		shop_vis.texture = shop_tex
		shop_vis.scale = Vector2(0.8, 0.8)
		shop_vis.position = Vector2(0, -10)
	_build_terminal(Vector2(16, 15), shop_vis, "Cửa Hàng", UITheme.ACCENT, "Mở Cửa Hàng (Shop)", _open_shop)

	# 2. Terminal Mô Phỏng Holo-Sim (Roguelite Leo Tháp)
	var sim_vis = ColorRect.new()
	sim_vis.size = Vector2(20, 24)
	sim_vis.position = Vector2(-10, -24)
	sim_vis.color = Color(0.2, 0.8, 1.0)
	_build_terminal(Vector2(20, 15), sim_vis, "Holo-Sim (Leo Tháp)", UITheme.BREAK, "Máy Mô Phỏng Holo-Sim", _on_sim_interacted)

# Dựng một bệ tương tác (hình + nhãn + vùng chạm bán kính 38) tại ô lưới; thay cho hai khối gần giống nhau của cửa hàng và Holo-Sim
func _build_terminal(grid_pos: Vector2, visual: Node, label_text: String, label_color: Color, prompt: String, on_interact: Callable):
	var root = Node2D.new()
	root.position = grid_pos * TILE_SIZE
	root.add_child(visual)
	root.add_child(MapUtils.make_world_label(label_text, label_color, -48.0))
	
	var zone = MapUtils.circle_zone(38.0, prompt)
	zone.interacted.connect(on_interact)
	root.add_child(zone)
	add_child(root)

func _open_shop():
	var shop_menu = ShopMenu.new()
	add_child(shop_menu)

func _on_sim_interacted():
	var idx: int = await DialogueManager.ask(["[Bắt đầu Leo Tháp (Tầng 1-10)]", "[Xem Kỷ Lục]", "[Rời khỏi]"])
	if idx == 0:
		await ScreenFade.fade_out(0.8)
		var p = get_node_or_null("OverworldPlayer")
		var p_pos = p.global_position if p else Vector2.ZERO
		GameManager.store_map_state(MapPaths.BASE, p_pos)
		HoloSimManager.start_new_run()
		get_tree().change_scene_to_file(MapPaths.BATTLE_SCENE)
	elif idx == 1:
		DialogueManager.play_dialogue([
			{"text": "Kỷ lục leo tháp cao nhất của bạn: Tầng %d / 10." % HoloSimManager.high_score_floor, "type": "narrator"}
		])

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

func _place_indoor_asset(file: String, grid_pos: Vector2, has_collision: bool):
	MapUtils.place_indoor_asset(self, file, grid_pos, has_collision)

func _add_room_label(text: String, grid_pos: Vector2):
	# Bảng tên khu: căn giữa theo ô, chữ xám xanh đặc (không mờ 40% như trước) để vẫn đọc được trên sàn tối
	var lbl := MapUtils.make_world_label(text, UITheme.TEXT_MUTED, 0.0)
	lbl.position += grid_pos * TILE_SIZE
	add_child(lbl)
