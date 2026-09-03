class_name SaveManager
extends RefCounted

"""
Tóm tắt: SaveManager quản lý toàn bộ hệ thống Lưu & Tải (Save/Load) của SekaiRPG.

Chức năng chính:
- Lưu trữ các file save vào thư mục chuyên biệt `user://saves/`.
- Hỗ trợ số lượng file lưu không giới hạn với tên file tự do, cùng Quick Save và Auto-Save.
- Tự động đóng gói siêu dữ liệu (Metadata: Quest Name, Map Name, Timestamp, Version) cùng Game State.
- Đọc siêu dữ liệu nhanh (get_save_metadata, get_all_save_slots) để hiển thị danh sách trực quan trên UI.
- Cung cấp API tải game an toàn (load_game), xóa file (delete_save), và tìm file save mới nhất.
"""

const SAVES_DIR = "user://saves/"
const QUICK_SAVE_PATH = "user://saves/quicksave.json"
const AUTOSAVE_PATH = "user://saves/autosave.json"
const SAVE_VERSION = "1.0"

const MAP_NAMES = {
	"res://Maps/Prologue/PrologueMap.tscn": "Hẻm vắng (Mở màn)",
	"res://Maps/Base/BaseMap.tscn": "Căn cứ Nightcord (Safehouse)",
	"res://Maps/Warehouse/WarehouseMap.tscn": "Nhà kho cũ",
	"res://Maps/Warehouse/TrainingWarehouseMap.tscn": "Phòng tập Nhà kho",
	"res://Maps/Cafe/CafeMap.tscn": "Quán Cafe",
	"res://Maps/Harbor/HarborMap.tscn": "Bến cảng thành phố",
	"res://Maps/Alleyway/AlleywayMap.tscn": "Hẻm nhỏ",
	"res://Maps/Street/StreetMap.tscn": "Ngã tư đường phố",
	"res://Maps/HonamiHouse/HonamiHouseMap.tscn": "Phòng khám Honami",
	"res://Maps/CityOperations/CityOperationsMap.tscn": "Khu tác chiến phòng vệ",
	"res://Maps/Highway/HighwayMap.tscn": "Xa lộ đêm"
}

# ── Khởi Tạo Thư Mục ────────────────────────────────────────────────────────

static func ensure_saves_dir() -> void:
	"""Đảm bảo thư mục user://saves/ luôn tồn tại."""
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

# ── Helpers Metadata ───────────────────────────────────────────────────────

static func get_map_display_name(map_file: String) -> String:
	return MAP_NAMES.get(map_file, map_file.get_file().get_basename())

static func _get_timestamp_string() -> String:
	var dt = Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d %02d:%02d:%02d" % [
		dt["day"], dt["month"], dt["year"],
		dt["hour"], dt["minute"], dt["second"]
	]

static func _resolve_full_path(path_or_name: String) -> String:
	if path_or_name.begins_with("user://"):
		return path_or_name
	var file_name = path_or_name
	if not file_name.ends_with(".json"):
		file_name += ".json"
	return SAVES_DIR + file_name

# ── API Lưu Dữ Liệu ────────────────────────────────────────────────────────

static func save_game(path_or_name: String = QUICK_SAVE_PATH) -> bool:
	"""
	Lưu trạng thái trò chơi hiện tại kèm siêu dữ liệu (Quest, Map, Timestamp).
	"""
	ensure_saves_dir()
	var full_path = _resolve_full_path(path_or_name)
	
	# Trích xuất Quest hiện tại từ QuestRegistry nếu có
	var quest_id = "unknown_quest"
	var quest_name = "Nhiệm vụ chưa xác định"
	var current_q = QuestRegistry.get_current_quest()
	if current_q:
		quest_id = current_q.quest_id
		quest_name = current_q.quest_name
		
	var map_display = get_map_display_name(GameManager.current_map_file)
	var timestamp = _get_timestamp_string()
	
	var metadata = {
		"version": SAVE_VERSION,
		"timestamp": timestamp,
		"unix_time": Time.get_unix_time_from_system(),
		"quest_id": quest_id,
		"quest_name": quest_name,
		"map_file": GameManager.current_map_file,
		"map_name": map_display,
		"file_name": full_path.get_file()
	}
	
	var party_data = {}
	for p_name in GameManager.party:
		var e = GameManager.party[p_name]
		party_data[p_name] = {
			"level": e.level,
			"exp": e.current_exp,
			"skill_points": e.skill_points,
			"atk": e.atk,
			"defense": e.defense,
			"spd": e.spd,
			"max_hp": e.max_hp
		}
	
	var game_state = {
		"current_map": GameManager.current_map_file,
		"player_pos": {
			"x": GameManager.last_player_position.x,
			"y": GameManager.last_player_position.y
		},
		"story": GameManager.story.serialize(),
		"party": party_data
	}
	
	var save_package = {
		"metadata": metadata,
		"game_state": game_state
	}
	
	var f = FileAccess.open(full_path, FileAccess.WRITE)
	if f == null:
		print("[SaveManager] Lỗi: Không thể ghi file save tại ", full_path)
		return false
		
	f.store_string(JSON.stringify(save_package, "\t"))
	f.close()
	print("[SaveManager] Đã lưu game thành công tại: ", full_path, " [", quest_name, " | ", map_display, "]")
	return true

# ── API Tải Dữ Liệu ────────────────────────────────────────────────────────

static func load_game(path_or_name: String = "") -> bool:
	"""
	Tải dữ liệu từ file save chỉ định. Nếu để trống, tự động tải file save mới nhất.
	"""
	var target_path = path_or_name
	if target_path == "":
		target_path = get_latest_save_path()
		
	if target_path == "":
		print("[SaveManager] Lỗi: Không tìm thấy bất kỳ file save nào để tải.")
		return false
		
	var full_path = _resolve_full_path(target_path)
	if not FileAccess.file_exists(full_path):
		print("[SaveManager] Lỗi: File không tồn tại tại ", full_path)
		return false
		
	var f = FileAccess.open(full_path, FileAccess.READ)
	if f == null:
		print("[SaveManager] Lỗi: Không thể mở file tại ", full_path)
		return false
		
	var json_str = f.get_as_text()
	f.close()
	
	var data = JSON.parse_string(json_str)
	if not data is Dictionary:
		print("[SaveManager] Lỗi: File save bị hỏng hoặc không đúng định dạng JSON.")
		return false
		
	var game_state = data.get("game_state", data)
	
	# Khôi phục Map & Vị trí người chơi
	GameManager.current_map_file = game_state.get("current_map", "res://Maps/Base/BaseMap.tscn")
	var pos = game_state.get("player_pos", {"x": 0, "y": 0})
	GameManager.last_player_position = Vector2(pos.x, pos.y)
	
	# Khôi phục StoryState
	if game_state.has("story"):
		GameManager.story.deserialize(game_state["story"])
	else:
		GameManager.story.flags = game_state.get("flags", GameManager.story.flags.duplicate())
		var m_state = game_state.get("mission_state", {})
		GameManager.story.warehouse_wave = m_state.get("warehouse_wave", 1)
		GameManager.story.harbor_wave = m_state.get("harbor_wave", 1)
		GameManager.story.enemies_defeated = m_state.get("enemies_defeated", 0)
	
	# Khôi phục Party Stats
	var p_data = game_state.get("party", {})
	for p_name in p_data:
		if GameManager.party.has(p_name):
			var e = GameManager.party[p_name]
			var d = p_data[p_name]
			e.level = d.get("level", 1)
			e.current_exp = d.get("exp", 0)
			e.skill_points = d.get("skill_points", 0)
			e.atk = d.get("atk", e.atk)
			e.defense = d.get("defense", e.defense)
			e.spd = d.get("spd", e.spd)
			e.max_hp = d.get("max_hp", e.max_hp)
			e.current_hp = e.max_hp
			
	print("[SaveManager] Tải game thành công từ: ", full_path)
	GameManager.get_tree().change_scene_to_file.call_deferred(GameManager.current_map_file)
	return true

# ── API Đọc Siêu Dữ Liệu & Danh Sách ───────────────────────────────────────

static func get_save_metadata(path_or_name: String) -> Dictionary:
	"""
	Đọc siêu dữ liệu preview của 1 file save mà không tải game_state.
	"""
	var full_path = _resolve_full_path(path_or_name)
	if not FileAccess.file_exists(full_path):
		return {}
		
	var f = FileAccess.open(full_path, FileAccess.READ)
	if f == null: return {}
	
	var json_str = f.get_as_text()
	f.close()
	
	var data = JSON.parse_string(json_str)
	if not data is Dictionary: return {}
	
	if data.has("metadata"):
		var meta = data["metadata"]
		meta["path"] = full_path
		return meta
		
	# Fallback cho file định dạng cũ nếu có
	var map_f = data.get("current_map", "res://Maps/Base/BaseMap.tscn")
	return {
		"version": "legacy",
		"timestamp": "(Save cũ)",
		"unix_time": FileAccess.get_modified_time(full_path),
		"quest_id": "legacy",
		"quest_name": "Tiến trình lưu trước đó",
		"map_file": map_f,
		"map_name": get_map_display_name(map_f),
		"file_name": full_path.get_file(),
		"path": full_path
	}

static func get_all_save_slots() -> Array[Dictionary]:
	"""
	Lấy toàn bộ danh sách các file save trong user://saves/ đã được sắp xếp
	theo thời gian chỉnh sửa mới nhất trước.
	"""
	ensure_saves_dir()
	var slots: Array[Dictionary] = []
	var dir = DirAccess.open(SAVES_DIR)
	if not dir:
		return slots
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path = SAVES_DIR + file_name
			var meta = get_save_metadata(full_path)
			if not meta.is_empty():
				slots.append(meta)
		file_name = dir.get_next()
		
	# Sắp xếp theo unix_time giảm dần (mới nhất lên đầu)
	slots.sort_custom(func(a, b):
		return a.get("unix_time", 0) > b.get("unix_time", 0)
	)
	return slots

static func get_latest_save_path() -> String:
	"""Trả về đường dẫn file save được cập nhật gần đây nhất."""
	var slots = get_all_save_slots()
	if slots.is_empty():
		return ""
	return slots[0]["path"]

static func has_save() -> bool:
	return not get_all_save_slots().is_empty()

static func delete_save(path_or_name: String) -> bool:
	"""Xóa một file save khỏi thư mục."""
	var full_path = _resolve_full_path(path_or_name)
	if FileAccess.file_exists(full_path):
		var dir = DirAccess.open(SAVES_DIR)
		if dir:
			var err = dir.remove(full_path.get_file())
			if err == OK:
				print("[SaveManager] Đã xóa file save: ", full_path)
				return true
	return false
