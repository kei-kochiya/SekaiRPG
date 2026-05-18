extends Node

"""
Tóm tắt: GameManager là bộ não trung tâm (Autoload) quản lý toàn bộ vòng đời của trò chơi.

Chức năng chính:
- Lưu trữ và cung cấp đối tượng đội hình (Party).
- Quản lý bộ đệm trạng thái cốt truyện thông qua StoryState (cờ sự kiện, tiến độ map).
- Xử lý hệ thống lưu và tải game (Save/Load) qua JSON.
- Điều phối các chế độ chơi đặc biệt: Sandbox, Training, Scripted Battle.
- Xử lý luồng sau khi trận chiến kết thúc (tính exp, kích hoạt sự kiện, chuyển cảnh).
- Quản lý tùy chọn cài đặt hệ thống (Volume, Battle Speed, Skip Battle).
"""

# ── Tham chiếu đến các Manager thành phần ──────────────────────────────────
var story: StoryState = StoryState.new()

# ── Biến Quản Lý Trạng Thái ────────────────────────────────────────────────

var current_map_file: String = "res://Maps/Prologue/PrologueMap.tscn"
var last_player_position: Vector2 = Vector2.ZERO

var is_training_mode: bool = false
var training_participants: Array = []
var training_used_opponents: Array = []
var last_battle_max_lv: int = 1

var is_in_dialogue: bool = false
var is_tutorial: bool = false
var is_sandbox: bool = false
var is_scripted_battle: bool = false
var scripted_battle_id: String = ""
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []

var battle_speed: float = 1.2
var master_volume: float = 1.0:
	set(v):
		master_volume = clamp(v, 0.0, 1.0)
		if AudioManager: AudioManager.update_volume(master_volume)

var skip_battle_unlocked: bool = false
var skip_battle_enabled: bool = false

# ── Đội Hình (Party) ───────────────────────────────────────────────────────
var party: Dictionary = {}

# Khởi tạo đội hình
func _ready():
	_init_party()

func _init_party():
	"""
	Khởi tạo các đối tượng nhân vật chính và cấp độ ban đầu cho đội hình.
	
	Args: Không có
	Returns: Không có
	"""
	party["Ichika"] = Ichika.new()
	party["Kanade"] = Kanade.new()
	party["Mafuyu"] = Mafuyu.new()
	party["Ena"] = Ena.new()
	party["Mizuki"] = Mizuki.new()
	party["Honami"] = Honami.new()
	
	LevelManager.set_initial_level(party["Ichika"], 1)
	LevelManager.set_initial_level(party["Kanade"], 5)
	LevelManager.set_initial_level(party["Mafuyu"], 25)
	LevelManager.set_initial_level(party["Ena"], 20)
	LevelManager.set_initial_level(party["Mizuki"], 25)
	LevelManager.set_initial_level(party["Honami"], 25)

# ── Kết nối StoryState (Flags & Variables) ─────────────────────────────────
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

# Thiết lập một cờ trạng thái
func set_flag(id: String, value: Variant):
	story.set_flag(id, value)

# Lấy giá trị của một cờ trạng thái
func get_flag(id: String, default: Variant = false) -> Variant:
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

# ── Tiện Ích Trò Chơi ──────────────────────────────────────────────────────
func get_party_member(m_name: String) -> Entity:
	return party.get(m_name)

# Bắt đầu trạng thái hội thoại
func start_dialogue():
	is_in_dialogue = true

# Kết thúc trạng thái hội thoại
func end_dialogue():
	is_in_dialogue = false

# ── Hệ Thống Lưu/Tải (Save/Load) ───────────────────────────────────────────
const SAVE_PATH = "user://sekai_save.json"

func save_game(path: String = SAVE_PATH):
	"""
	Thực hiện lưu toàn bộ dữ liệu game vào một file cụ thể.
	
	Args:
		path (String): Đường dẫn file lưu. Mặc định là SAVE_PATH.
	Returns: Không có
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

# Trả về đường dẫn save mặc định dựa trên bản đồ hiện tại
func get_current_save_path() -> String:
	var map_name = current_map_file.get_file().get_basename()
	return "user://" + map_name + ".json"

func load_game(path: String = SAVE_PATH) -> bool:
	"""
	Nạp dữ liệu từ một file save cụ thể và phục hồi trạng thái game.
	
	Args:
		path (String): Đường dẫn file nạp. Mặc định là SAVE_PATH.
	Returns: 
		bool: True nếu nạp thành công, False nếu thất bại.
	"""
	if not FileAccess.file_exists(path):
		print("[GameManager] Lỗi: Không tìm thấy file tại ", path)
		return false
	
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	
	if not data is Dictionary: return false
	
	current_map_file = data.get("current_map", "res://Maps/Base/BaseMap.tscn")
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

# Kiểm tra sự tồn tại của file save
func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

func get_save_files() -> Array:
	"""
	Lấy danh sách tất cả các file save (.json) có trong thư mục user://.
	
	Args: Không có
	Returns:
		Array: Mảng chứa đường dẫn các file save.
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

# ── Quản Lý Chuyển Cảnh & Trận Chiến ───────────────────────────────────────
# Thiết lập lại toàn bộ trạng thái để bắt đầu trò chơi mới
func reset_game():
	story.reset()
	last_player_position = Vector2.ZERO
	current_map_file = "res://Maps/Prologue/PrologueMap.tscn"
	is_sandbox = false
	is_tutorial = false
	is_scripted_battle = false
	_init_party()

# Ghi nhớ bản đồ và vị trí hiện tại
func store_map_state(map_path: String, player_pos: Vector2):
	current_map_file = map_path
	last_player_position = player_pos

# Đặt lại bộ đếm nhiệm vụ
func reset_mission_stats():
	story.enemies_defeated = 0

# Chuyển cảnh đến trận chiến
func trigger_battle():
	AudioManager.play_music("battle")
	get_tree().change_scene_to_file("res://BattleSystem/BattleScene.tscn")

func finish_battle(victory: bool, count: int = 1):
	"""
	Xử lý logic kết quả sau trận đấu (Exp, Cốt truyện, Chuyển cảnh).
	
	Args:
		victory (bool): Cờ báo thắng hay thua.
		count (int): Số lượng địch bị hạ.
	Returns: Không có
	"""
	if is_sandbox:
		get_tree().change_scene_to_file("res://Menus/Sandbox/SandboxMenu.tscn")
		return

	if is_scripted_battle:
		if scripted_battle_id == "mizuki_vs_mafuyu":
			story.set_flag("mizuki_vs_mafuyu_done", true)
			is_scripted_battle = false
			scripted_battle_id = ""
			get_tree().change_scene_to_file(current_map_file)
			return
		elif scripted_battle_id == "ena_vs_mizuki":
			story.set_flag("ena_vs_mizuki_done", true)
			story.set_flag("ena_vs_mizuki_won", victory)
			is_scripted_battle = false
			scripted_battle_id = ""
			get_tree().change_scene_to_file(current_map_file)
			return
		elif scripted_battle_id == "ena_vs_thugs":
			story.set_flag("ena_vs_thugs_done", true)
			story.set_flag("ena_vs_thugs_won", victory)
			is_scripted_battle = false
			scripted_battle_id = ""
			get_tree().change_scene_to_file(current_map_file)
			return
		elif scripted_battle_id == "street_skirmish":
			story.set_flag("street_skirmish_done", true)
			story.set_flag("street_skirmish_won", victory)
			is_scripted_battle = false
			scripted_battle_id = ""
			get_tree().change_scene_to_file(current_map_file)
			return
		elif scripted_battle_id == "street_survival":
			story.set_flag("street_survival_done", true)
			story.set_flag("street_survival_won", victory)
			is_scripted_battle = false
			scripted_battle_id = ""
			get_tree().change_scene_to_file(current_map_file)
			return
		
		is_scripted_battle = false
		scripted_battle_id = ""

	if not victory and is_training_mode:
		var bonus_exp = int(last_battle_max_lv * 50)
		for p_name in training_participants:
			var entity = get_party_member(p_name)
			if entity: LevelManager.gain_exp(entity, bonus_exp)
		victory = true

	if victory:
		story.enemies_defeated += count
		if current_map_file.contains("Warehouse"): story.warehouse_wave += 1
		if current_map_file == "res://Maps/Harbor/HarborMap.tscn":
			story.harbor_wave += 1
			if story.harbor_wave > 4 or harbor_route == "boss":
				story.set_flag("harbor_boss_defeated", true)
			
	if story.get_flag("harbor_boss_defeated") and current_map_file == "res://Maps/Harbor/HarborMap.tscn":
		await get_tree().create_timer(1.5, false).timeout 
		await ScreenFade.fade_out(0.8)
		last_player_position = Vector2.ZERO
		get_tree().change_scene_to_file("res://Maps/Alleyway/AlleywayMap.tscn")
	else:
		get_tree().change_scene_to_file(current_map_file)
