extends Node

"""
GameManager: Bộ não trung tâm quản lý toàn bộ trạng thái của trò chơi.

Lớp này quản lý các thành phần cốt lõi: Đội hình (Party), Hệ thống Save/Load, 
và Dòng chảy kịch bản (thông qua StoryState). Đảm bảo tính nhất quán của dữ liệu 
giữa các màn chơi và trạng thái trận đấu.
"""

# ── Tham chiếu đến các Manager thành phần ──────────────────────────────────
var story: StoryState = StoryState.new()

# ── Thông tin Bản đồ & Vị trí ──────────────────────────────────────────────
var current_map_file: String = "res://Scenes/PrologueMap.tscn"
var last_player_position: Vector2 = Vector2.ZERO

# ── Trạng thái Luyện tập ────────────────────────────────────────────────────
var is_training_mode: bool = false
var training_participants: Array = []
var training_used_opponents: Array = []
var last_battle_max_lv: int = 1

# ── Trạng thái Hệ thống ─────────────────────────────────────────────────────
var is_in_dialogue: bool = false
var is_tutorial: bool = false
var is_sandbox: bool = false
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []

# ── Dữ liệu Đội hình (Party) ───────────────────────────────────────────────
var party: Dictionary = {}

func _ready():
	_init_party()

func _init_party():
	"""
	Khởi tạo các đối tượng nhân vật chính trong đội hình mặc định.
	
	Thiết lập các thuộc tính cơ bản và cấp độ khởi đầu cho từng thành viên.
	"""
	party["Ichika"] = Ichika.new()
	party["Kanade"] = Kanade.new()
	party["Mafuyu"] = Mafuyu.new()
	party["Ena"]    = Ena.new()
	party["Mizuki"] = Mizuki.new()
	party["Honami"] = Honami.new()
	
	LevelManager.set_initial_level(party["Ichika"], 1)
	LevelManager.set_initial_level(party["Kanade"], 5)
	LevelManager.set_initial_level(party["Mafuyu"], 8)
	LevelManager.set_initial_level(party["Ena"],    8)
	LevelManager.set_initial_level(party["Mizuki"], 10)
	LevelManager.set_initial_level(party["Honami"], 5)

# ── Proxy Getters/Setters cho StoryState (Đảm bảo tương thích ngược) ───────
var flags: Dictionary: 
	get: return story.flags
var warehouse_wave: int: 
	get: return story.warehouse_wave
	set(v): story.warehouse_wave = v
var harbor_wave: int: 
	get: return story.harbor_wave
	set(v): story.harbor_wave = v
var enemies_defeated: int: 
	get: return story.enemies_defeated
	set(v): story.enemies_defeated = v
var harbor_guards_defeated: int: 
	get: return story.harbor_guards_defeated
	set(v): story.harbor_guards_defeated = v
var harbor_route: String: 
	get: return story.harbor_route
	set(v): story.harbor_route = v

func set_flag(id: String, value: Variant):
	"""
	Ghi đè một cờ trạng thái (flag) trong hệ thống StoryState.
	
	Args:
		id (String): Tên định danh của cờ.
		value (Variant): Giá trị cần lưu (thường là bool, int hoặc String).
	"""
	story.set_flag(id, value)

func get_flag(id: String, default: Variant = false) -> Variant:
	"""
	Lấy giá trị của một cờ trạng thái từ StoryState.
	
	Args:
		id (String): Tên định danh của cờ.
		default (Variant): Giá trị mặc định nếu không tìm thấy cờ.
		
	Returns:
		Variant: Giá trị hiện tại của cờ hoặc giá trị mặc định.
	"""
	return story.get_flag(id, default)

var prologue_phase: int: 
	get: return story.get_flag("prologue_phase", 0)
	set(v): story.set_flag("prologue_phase", v)
var harbor_mission_done: bool: 
	get: return story.get_flag("harbor_mission_done", false)
	set(v): story.set_flag("harbor_mission_done", v)
var harbor_mission_unlocked: bool: 
	get: return story.get_flag("harbor_mission_unlocked", false)
	set(v): story.set_flag("harbor_mission_unlocked", v)
var intro_quest_done: bool:
	get: return story.get_flag("intro_quest_done", false)
	set(v): story.set_flag("intro_quest_done", v)
var safehouse_intro_done: bool:
	get: return story.get_flag("safehouse_intro_done", false)
	set(v): story.set_flag("safehouse_intro_done", v)
var npcs_greeted: Array:
	get: return story.get_flag("npcs_greeted", [])
	set(v): story.set_flag("npcs_greeted", v)
var warehouse_mission_accepted: bool:
	get: return story.get_flag("warehouse_mission_accepted", false)
	set(v): story.set_flag("warehouse_mission_accepted", v)
var talked_to_mafuyu_training: bool:
	get: return story.get_flag("talked_to_mafuyu_training", false)
	set(v): story.set_flag("talked_to_mafuyu_training", v)
var accepted_harbor_mission: bool:
	get: return story.get_flag("accepted_harbor_mission", false)
	set(v): story.set_flag("accepted_harbor_mission", v)
var harbor_intro_done: bool:
	get: return story.get_flag("harbor_intro_done", false)
	set(v): story.set_flag("harbor_intro_done", v)
var upgrade_tutorial_done: bool:
	get: return story.get_flag("upgrade_tutorial_done", false)
	set(v): story.set_flag("upgrade_tutorial_done", v)
var guards_defeated: bool:
	get: return story.get_flag("guards_defeated", false)
	set(v): story.set_flag("guards_defeated", v)
var training_ichika_done: bool:
	get: return story.get_flag("training_ichika_done", false)
	set(v): story.set_flag("training_ichika_done", v)
var training_kanade_done: bool:
	get: return story.get_flag("training_kanade_done", false)
	set(v): story.set_flag("training_kanade_done", v)

# ── Logic Điều khiển ───────────────────────────────────────────────────────

func get_party_member(m_name: String) -> Entity:
	"""
	Lấy đối tượng thành viên đội hình theo tên.
	
	Args:
		m_name (String): Tên nhân vật (ví dụ: 'Ichika').
		
	Returns:
		Entity: Đối tượng thực thể nhân vật hoặc null nếu không tồn tại.
	"""
	return party.get(m_name)

func start_dialogue():
	"""Bắt đầu trạng thái hội thoại, tạm dừng các hành động Overworld."""
	is_in_dialogue = true

func end_dialogue():
	"""Kết thúc trạng thái hội thoại."""
	is_in_dialogue = false

# ── Hệ thống Save/Load ─────────────────────────────────────────────────────

const SAVE_PATH = "user://sekai_save.json"

func save_game():
	"""
	Lưu toàn bộ trạng thái trò chơi hiện tại vào file JSON.
	
	Dữ liệu bao gồm: Bản đồ hiện tại, vị trí người chơi, các cờ cốt truyện 
	và chỉ số chi tiết của toàn bộ thành viên trong đội hình.
	"""
	var save_data = {
		"current_map": current_map_file,
		"player_pos": {"x": last_player_position.x, "y": last_player_position.y},
		"story": story.serialize(),
		"party": {}
	}
	
	for p_name in party:
		var e = party[p_name]
		save_data["party"][p_name] = {
			"level": e.level, "exp": e.current_exp, "skill_points": e.skill_points,
			"atk": e.atk, "defense": e.defense, "spd": e.spd, "max_hp": e.max_hp
		}
	
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		print("[GameManager] Lỗi: Không thể lưu file tại ", SAVE_PATH)
		return
	f.store_string(JSON.stringify(save_data))
	f.close()
	print("[GameManager] Game đã được lưu.")

func load_game() -> bool:
	"""
	Tải dữ liệu từ file save và khôi phục trạng thái trò chơi.
	
	Giải mã JSON, khôi phục story flags và cập nhật lại chỉ số thực thể. 
	Sau đó chuyển cảnh đến bản đồ đã lưu.
	
	Returns:
		bool: True nếu nạp dữ liệu thành công, False nếu file lỗi hoặc không tồn tại.
	"""
	if not FileAccess.file_exists(SAVE_PATH): return false
	
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	
	if not data is Dictionary: return false
	
	current_map_file = data.get("current_map", "res://Scenes/BaseMap.tscn")
	var pos = data.get("player_pos", {"x": 0, "y": 0})
	last_player_position = Vector2(pos.x, pos.y)
	
	if data.has("story"):
		story.deserialize(data["story"])
	else:
		story.flags = data.get("flags", story.flags.duplicate())
		var m_state = data.get("mission_state", {})
		story.warehouse_wave = m_state.get("warehouse_wave", 1)
		story.harbor_wave = m_state.get("harbor_wave", 1)
		story.enemies_defeated = m_state.get("enemies_defeated", 0)
	
	var p_data = data.get("party", {})
	for p_name in p_data:
		if party.has(p_name):
			var e = party[p_name]; var d = p_data[p_name]
			e.level = d.get("level", 1); e.current_exp = d.get("exp", 0)
			e.skill_points = d.get("skill_points", 0); e.atk = d.get("atk", e.atk)
			e.defense = d.get("defense", e.defense); e.spd = d.get("spd", e.spd)
			e.max_hp = d.get("max_hp", e.max_hp); e.current_hp = e.max_hp
	
	print("[GameManager] Game đã tải thành công.")
	get_tree().change_scene_to_file(current_map_file)
	return true

func has_save() -> bool:
	"""Kiểm tra sự tồn tại của file save."""
	return FileAccess.file_exists(SAVE_PATH)

func reset_game():
	"""
	Thiết lập lại toàn bộ trạng thái để bắt đầu trò chơi mới (New Game).
	"""
	story.reset()
	last_player_position = Vector2.ZERO
	current_map_file = "res://Scenes/PrologueMap.tscn"
	_init_party()

func store_map_state(map_path: String, player_pos: Vector2):
	"""Ghi nhớ bản đồ và vị trí hiện tại của người chơi."""
	current_map_file = map_path
	last_player_position = player_pos

func reset_mission_stats():
	"""Đặt lại bộ đếm kẻ địch bị hạ gục (dùng cho nhiệm vụ)."""
	story.enemies_defeated = 0

func trigger_battle():
	"""Chuyển cảnh đến màn hình chiến đấu."""
	AudioManager.play_music("battle")
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func finish_battle(victory: bool, count: int = 1):
	"""
	Xử lý các logic hậu chiến (EXP, Story Flags, chuyển cảnh về Map).
	
	Args:
		victory (bool): Trạng thái thắng/thua của trận đấu.
		count (int): Số lượng kẻ địch đã hạ gục để cập nhật bộ đếm.
	"""
	if is_sandbox:
		get_tree().change_scene_to_file("res://Scenes/SandboxMenu.tscn")
		return

	if not victory and is_training_mode:
		var bonus_exp = int(last_battle_max_lv * 10)
		for p_name in training_participants:
			var entity = get_party_member(p_name)
			if entity: LevelManager.gain_exp(entity, bonus_exp)
		victory = true 

	if victory:
		story.enemies_defeated += count
		if current_map_file.contains("Warehouse"): story.warehouse_wave += 1
		if current_map_file == "res://Scenes/HarborMap.tscn":
			story.harbor_wave += 1
			# If the wave was the Boss (either directly or after 3 waves)
			if story.harbor_wave > 4 or GameManager.harbor_route == "boss":
				story.set_flag("harbor_boss_defeated", true)
			
	if story.get_flag("harbor_boss_defeated") and current_map_file == "res://Scenes/HarborMap.tscn":
		get_tree().change_scene_to_file("res://Scenes/AlleywayMap.tscn")
	else:
		get_tree().change_scene_to_file(current_map_file)
