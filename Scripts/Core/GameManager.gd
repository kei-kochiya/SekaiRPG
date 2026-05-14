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
var is_scripted_battle: bool = false
var scripted_battle_id: String = ""
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []

# ── Cài đặt (Settings) ──────────────────────────────────────────────────────
var battle_speed: float = 1.2 # Giây giữa các lượt AI
var master_volume: float = 1.0:
	set(v):
		master_volume = clamp(v, 0.0, 1.0)
		if AudioManager: AudioManager.update_volume(master_volume)

# ── Dữ liệu Đội hình (Party) ───────────────────────────────────────────────
var party: Dictionary = {}

func _ready():
	_init_party()

func _init_party():
	# Khởi tạo các đối tượng nhân vật chính và cấp độ ban đầu cho đội hình.
	party["Ichika"] = Ichika.new()
	party["Kanade"] = Kanade.new()
	party["Mafuyu"] = Mafuyu.new()
	party["Ena"] = Ena.new()
	party["Mizuki"] = Mizuki.new()
	party["Honami"] = Honami.new()
	
	LevelManager.set_initial_level(party["Ichika"], 1)
	LevelManager.set_initial_level(party["Kanade"], 5)
	LevelManager.set_initial_level(party["Mafuyu"], 25)
	LevelManager.set_initial_level(party["Ena"], 15)
	LevelManager.set_initial_level(party["Mizuki"], 25)
	LevelManager.set_initial_level(party["Honami"], 25)

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
	# Ghi đè một cờ trạng thái (flag) trong hệ thống StoryState.
	story.set_flag(id, value)

func get_flag(id: String, default: Variant = false) -> Variant:
	# Lấy giá trị của một cờ trạng thái từ StoryState.
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
var harbor_meeting_p1_done: bool:
	get: return story.get_flag("harbor_meeting_p1_done", false)
	set(v): story.set_flag("harbor_meeting_p1_done", v)
var mafuyu_honami_talked: bool:
	get: return story.get_flag("mafuyu_honami_talked", false)
	set(v): story.set_flag("mafuyu_honami_talked", v)
var mizuki_control_phase: bool:
	get: return story.get_flag("mizuki_control_phase", false)
	set(v): story.set_flag("mizuki_control_phase", v)
var harbor_mizuki_snack_done: bool:
	get: return story.get_flag("harbor_mizuki_snack_done", false)
	set(v): story.set_flag("harbor_mizuki_snack_done", v)


# ── Logic Điều khiển ───────────────────────────────────────────────────────

func get_party_member(m_name: String) -> Entity:
	# Lấy đối tượng thành viên đội hình theo tên.
	return party.get(m_name)

func start_dialogue():
	# Bắt đầu trạng thái hội thoại.
	is_in_dialogue = true

func end_dialogue():
	# Kết thúc trạng thái hội thoại.
	is_in_dialogue = false

# ── Hệ thống Save/Load ─────────────────────────────────────────────────────

const SAVE_PATH = "user://sekai_save.json"

func save_game(path: String = SAVE_PATH):
	"""
	Hàm này thực hiện lưu toàn bộ dữ liệu game vào một đường dẫn cụ thể.
	- path: Đường dẫn lưu file (String). Mặc định là SAVE_PATH.
	- Return: Không có.
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
	
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("[GameManager] Lỗi: Không thể lưu file tại ", path)
		return
	f.store_string(JSON.stringify(save_data))
	f.close()
	print("[GameManager] Game đã được lưu tại: ", path)

func get_current_save_path() -> String:
	"""
	Trả về đường dẫn save mặc định dựa trên bản đồ hiện tại.
	Ví dụ: 'user://PrologueMap.json'
	"""
	var map_name = current_map_file.get_file().get_basename()
	return "user://" + map_name + ".json"

func load_game(path: String = SAVE_PATH) -> bool:
	"""
	Hàm này thực hiện nạp dữ liệu từ một file save cụ thể.
	- path: Đường dẫn file cần nạp (String). Mặc định là SAVE_PATH.
	- Return: True nếu nạp thành công, ngược lại False (bool).
	"""
	if not FileAccess.file_exists(path):
		print("[GameManager] Lỗi: Không tìm thấy file tại ", path)
		return false
	
	var f = FileAccess.open(path, FileAccess.READ)
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
	
	print("[GameManager] Game đã tải thành công từ: ", path)
	get_tree().change_scene_to_file(current_map_file)
	return true

func has_save(path: String = SAVE_PATH) -> bool:
	# Kiểm tra sự tồn tại của một file save cụ thể.
	return FileAccess.file_exists(path)

func get_save_files() -> Array:
	"""
	Trả về danh sách tất cả các file save (.json) có trong thư mục user://.
	Dùng để hiển thị danh sách cho người chơi chọn file để load.
	"""
	var saves = []
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				saves.append("user://" + file_name)
			file_name = dir.get_next()
	return saves

func reset_game():
	# Thiết lập lại toàn bộ trạng thái để bắt đầu trò chơi mới.
	story.reset()
	last_player_position = Vector2.ZERO
	current_map_file = "res://Scenes/PrologueMap.tscn"
	is_sandbox = false
	is_tutorial = false
	is_scripted_battle = false
	_init_party()

func store_map_state(map_path: String, player_pos: Vector2):
	# Ghi nhớ bản đồ và vị trí hiện tại của người chơi.
	current_map_file = map_path
	last_player_position = player_pos

func reset_mission_stats():
	# Đặt lại bộ đếm kẻ địch bị hạ gục.
	story.enemies_defeated = 0

func trigger_battle():
	# Chuyển cảnh đến màn hình chiến đấu.
	AudioManager.play_music("battle")
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func finish_battle(victory: bool, count: int = 1):
	"""
	Hàm này xử lý các logic sau trận đấu như phân phối EXP và cập nhật cốt truyện.
	- victory: Thắng hay thua (bool).
	- count: Số lượng địch bị hạ (int).
	- Return: Không có.
	"""
	if is_sandbox:
		get_tree().change_scene_to_file("res://Scenes/SandboxMenu.tscn")
		return

	if is_scripted_battle:
		if scripted_battle_id == "mizuki_vs_mafuyu":
			story.set_flag("mizuki_vs_mafuyu_done", true)
		
		is_scripted_battle = false
		scripted_battle_id = ""
		get_tree().change_scene_to_file(current_map_file)
		return

	if not victory and is_training_mode:
		var bonus_exp = int(last_battle_max_lv * 50)
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
		await get_tree().create_timer(1.5, false).timeout # Đợi 1.5s để đọc nốt câu cuối
		await ScreenFade.fade_out(0.8)
		get_tree().change_scene_to_file("res://Scenes/AlleywayMap.tscn")
	else:
		get_tree().change_scene_to_file(current_map_file)
