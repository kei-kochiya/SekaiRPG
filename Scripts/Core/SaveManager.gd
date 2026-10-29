class_name SaveManager
extends RefCounted

"""
Tóm tắt: SaveManager quản lý toàn bộ hệ thống Lưu & Tải (Save/Load) của SekaiRPG.

Chức năng chính:
- Lưu trữ các file save vào thư mục chuyên biệt `user://saves/`.
- Hỗ trợ số lượng file lưu không giới hạn với tên file tự do (được làm sạch), cùng Quick Save và Auto-Save.
- Ghi file an toàn (ghi `.tmp` rồi đổi tên) để một lần lưu hỏng không phá file save cũ.
- Tự động đóng gói siêu dữ liệu (Metadata: Quest Name, Map Name, Timestamp, Version) cùng Game State.
- Đọc siêu dữ liệu nhanh (get_save_metadata, get_all_save_slots) để hiển thị danh sách trực quan trên UI.
- Cung cấp API tải game an toàn (load_game: kiểm tra hợp lệ trước, chỉ ghi vào GameManager khi file hợp lệ),
  xóa file (delete_save), và tìm file save mới nhất. Lỗi gần nhất nằm trong `last_error`.
"""

const SAVES_DIR = "user://saves/"
const QUICK_SAVE_PATH = "user://saves/quicksave.json"
const AUTOSAVE_PATH = "user://saves/autosave.json"
const SAVE_VERSION = "1.0"

# Tên slot dành riêng cho Quick Save / Auto-Save: người chơi không được đặt trùng khi lưu thủ công
const RESERVED_SLOT_NAMES = ["quicksave", "autosave"]

const FALLBACK_MAP = "res://Maps/Base/BaseMap.tscn"
# Map luyện tập không thể khôi phục từ save (cần training_participants...), nên lưu như đang đứng ở Base
const TRAINING_MAP = "res://Maps/Warehouse/TrainingWarehouseMap.tscn"

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

# Mô tả lỗi của lần save_game/load_game gần nhất ("" nếu thành công); GameManager sao chép ra last_save_error/last_load_error
static var last_error: String = ""

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

# Làm sạch tên file (bỏ đường dẫn, ký tự cấm, đuôi .json); trả về "" nếu không còn tên hợp lệ
static func _clean_file_name(raw_name: String) -> String:
	var base = raw_name.strip_edges().get_file().validate_filename().strip_edges()
	if base.to_lower().ends_with(".json"):
		base = base.substr(0, base.length() - 5).strip_edges()
	# Chuỗi rỗng hoặc chỉ toàn dấu chấm ("." / "..") không phải tên file
	if base == "" or base.replace(".", "") == "":
		return ""
	return base

static func sanitize_save_name(raw_name: String) -> String:
	"""
	Làm sạch tên save do người chơi nhập (get_file + validate_filename).
	Trả về "" nếu tên rỗng/không hợp lệ hoặc trùng tên slot dành riêng (quicksave, autosave).
	"""
	var clean = _clean_file_name(raw_name)
	if clean.to_lower() in RESERVED_SLOT_NAMES:
		return ""
	return clean

# Trả về đường dẫn đầy đủ trong user://saves/ hoặc "" nếu tên/đường dẫn không hợp lệ.
# for_save = true: tên nhập tay không được trùng slot dành riêng (đường dẫn user:// đầy đủ như QUICK_SAVE_PATH thì được).
static func _resolve_full_path(path_or_name: String, for_save: bool = false) -> String:
	if path_or_name.begins_with("user://"):
		# Đường dẫn đầy đủ (từ danh sách slot, QUICK_SAVE_PATH...) chỉ được nằm trực tiếp trong thư mục saves
		if not path_or_name.begins_with(SAVES_DIR):
			return ""
		var file_name = path_or_name.substr(SAVES_DIR.length())
		if file_name == "" or file_name.begins_with(".") or file_name.contains("/") or file_name.contains("\\"):
			return ""
		if not file_name.ends_with(".json"):
			file_name += ".json"
		return SAVES_DIR + file_name

	var clean = sanitize_save_name(path_or_name) if for_save else _clean_file_name(path_or_name)
	if clean == "":
		return ""
	return SAVES_DIR + clean + ".json"

static func _fail(message: String, as_warning: bool = false) -> bool:
	last_error = message
	if as_warning:
		GameLogger.warn("SaveManager", message)
	else:
		GameLogger.error("SaveManager", message)
	return false

# ── API Lưu Dữ Liệu ────────────────────────────────────────────────────────

static func save_game(path_or_name: String = QUICK_SAVE_PATH) -> bool:
	"""
	Lưu trạng thái trò chơi hiện tại kèm siêu dữ liệu (Quest, Map, Timestamp).
	Trả về false (và điền last_error) nếu tên không hợp lệ hoặc không ghi được file.
	"""
	last_error = ""
	var full_path = _resolve_full_path(path_or_name, true)
	if full_path == "":
		return _fail("Tên file save không hợp lệ hoặc trùng tên dành riêng: \"%s\"" % path_or_name, true)
	ensure_saves_dir()

	# Trích xuất Quest hiện tại từ QuestRegistry nếu có
	var quest_id = "unknown_quest"
	var quest_name = "Nhiệm vụ chưa xác định"
	var current_q = QuestRegistry.get_current_quest()
	if current_q:
		quest_id = current_q.quest_id
		quest_name = current_q.quest_name

	var map_file: String = GameManager.current_map_file
	var player_pos: Vector2 = GameManager.last_player_position
	if map_file == TRAINING_MAP:
		map_file = FALLBACK_MAP
		player_pos = Vector2.ZERO
	var map_display = get_map_display_name(map_file)
	var timestamp = _get_timestamp_string()

	var metadata = {
		"version": SAVE_VERSION,
		"timestamp": timestamp,
		"unix_time": Time.get_unix_time_from_system(),
		"quest_id": quest_id,
		"quest_name": quest_name,
		"map_file": map_file,
		"map_name": map_display,
		"file_name": full_path.get_file()
	}

	var party_data = {}
	for p_name in GameManager.party:
		var e = GameManager.party[p_name]
		party_data[p_name] = {
			"level": e.level,
			"exp": e.current_exp,
			"next_level_exp": e.next_level_exp,
			"skill_points": e.skill_points,
			"atk": e.atk,
			"defense": e.defense,
			"spd": e.spd,
			"max_hp": e.max_hp
		}

	var game_state = {
		"current_map": map_file,
		"player_pos": {
			"x": player_pos.x,
			"y": player_pos.y
		},
		"story": GameManager.story.serialize(),
		"party": party_data,
		"credits": GameManager.credits,
		"inventory": GameManager.inventory.duplicate(),
		"opened_chests": GameManager.opened_chests.duplicate()
	}

	var save_package = {
		"metadata": metadata,
		"game_state": game_state
	}

	# Ghi ra file .tmp trước rồi đổi tên đè lên file save, để lỗi giữa chừng không làm hỏng save cũ
	var tmp_path = full_path + ".tmp"
	var f = FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		return _fail("Không thể ghi file save tại %s (lỗi %d)" % [tmp_path, FileAccess.get_open_error()])

	f.store_string(JSON.stringify(save_package, "\t"))
	var write_err = f.get_error()
	f.close()

	var dir = DirAccess.open(SAVES_DIR)
	if write_err != OK or dir == null:
		if dir: dir.remove(tmp_path.get_file())
		return _fail("Ghi file save thất bại tại %s (lỗi %d)" % [full_path, write_err])

	var rename_err = dir.rename(tmp_path.get_file(), full_path.get_file())
	if rename_err != OK:
		dir.remove(tmp_path.get_file())
		return _fail("Không thể hoàn tất việc ghi file save %s (lỗi %d)" % [full_path, rename_err])

	GameLogger.info("SaveManager", "Đã lưu game thành công tại: %s [%s | %s]" % [full_path, quest_name, map_display])
	return true

# ── API Tải Dữ Liệu ────────────────────────────────────────────────────────

static func load_game(path_or_name: String = "") -> bool:
	"""
	Tải dữ liệu từ file save chỉ định. Nếu để trống, tự động tải file save mới nhất.
	File được đọc và kiểm tra hợp lệ vào biến cục bộ trước; chỉ khi hợp lệ mới ghi vào GameManager.
	Thất bại thì trả về false, điền last_error và KHÔNG thay đổi trạng thái game.
	"""
	last_error = ""
	var target_path = path_or_name
	if target_path == "":
		target_path = get_latest_save_path()

	if target_path == "":
		return _fail("Không tìm thấy bất kỳ file save nào để tải.", true)

	var full_path = _resolve_full_path(target_path)
	if full_path == "":
		return _fail("Tên hoặc đường dẫn file save không hợp lệ: %s" % target_path)
	if not FileAccess.file_exists(full_path):
		return _fail("File save không tồn tại tại %s" % full_path)

	var f = FileAccess.open(full_path, FileAccess.READ)
	if f == null:
		return _fail("Không thể mở file save tại %s (lỗi %d)" % [full_path, FileAccess.get_open_error()])

	var json_str = f.get_as_text()
	f.close()

	var data = JSON.parse_string(json_str)
	if not data is Dictionary:
		return _fail("File save bị hỏng hoặc không đúng định dạng JSON: %s" % full_path)

	var parsed = _parse_save_data(data)
	if parsed.is_empty():
		return false

	var meta = data.get("metadata", {})
	var version = str(meta.get("version", "")) if meta is Dictionary else ""
	if version != SAVE_VERSION:
		GameLogger.warn("SaveManager", "Phiên bản save (%s) khác phiên bản hiện tại (%s): %s" % [version, SAVE_VERSION, full_path])

	_commit_save_data(parsed)

	GameLogger.info("SaveManager", "Tải game thành công từ: %s" % full_path)
	GameManager.get_tree().change_scene_to_file.call_deferred(GameManager.current_map_file)
	return true

static func _is_number(value: Variant) -> bool:
	return value is int or value is float

static func _int_or(value: Variant, fallback: int) -> int:
	return int(value) if _is_number(value) else fallback

static func _parse_save_data(data: Dictionary) -> Dictionary:
	"""
	Kiểm tra và chuẩn hóa dữ liệu save vào một Dictionary cục bộ (không đụng tới GameManager).
	Trả về {} (và điền last_error) nếu file không hợp lệ.
	"""
	var game_state = data.get("game_state")
	if not game_state is Dictionary:
		_fail("File save thiếu hoặc sai định dạng mục game_state.")
		return {}

	# Map & vị trí người chơi (vị trí null/thiếu thì về gốc; map không còn tồn tại thì về Base)
	var map_file = game_state.get("current_map", FALLBACK_MAP)
	var pos = Vector2.ZERO
	var pos_data = game_state.get("player_pos")
	if not (map_file is String and ResourceLoader.exists(map_file)):
		GameLogger.warn("SaveManager", "Map trong save không tồn tại (%s), chuyển về Base." % str(map_file))
		map_file = FALLBACK_MAP
	elif pos_data is Dictionary and _is_number(pos_data.get("x")) and _is_number(pos_data.get("y")):
		pos = Vector2(float(pos_data["x"]), float(pos_data["y"]))

	var story_data = game_state.get("story", {})
	if not story_data is Dictionary:
		_fail("File save có mục story sai định dạng.")
		return {}

	# Kinh tế & túi đồ (JSON trả số dạng float nên ép về int)
	var credits = max(0, _int_or(game_state.get("credits"), GameManager.DEFAULT_CREDITS))
	var inventory = {}
	var raw_inventory = game_state.get("inventory")
	if raw_inventory is Dictionary:
		for item_id in raw_inventory:
			var amount = _int_or(raw_inventory[item_id], 0)
			if amount > 0:
				inventory[str(item_id)] = amount
	else:
		inventory = GameManager.DEFAULT_INVENTORY.duplicate()

	var opened_chests = []
	var raw_chests = game_state.get("opened_chests")
	if raw_chests is Array:
		for chest_id in raw_chests:
			opened_chests.append(str(chest_id))

	# Party Stats (save cũ thiếu next_level_exp thì tính lại theo level)
	var party = {}
	var raw_party = game_state.get("party")
	if raw_party is Dictionary:
		for p_name in raw_party:
			if not (GameManager.party.has(p_name) and raw_party[p_name] is Dictionary):
				continue
			var e = GameManager.party[p_name]
			var d = raw_party[p_name]
			var lv = clampi(_int_or(d.get("level"), 1), 1, LevelManager.MAX_LEVEL)
			var next_exp = _int_or(d.get("next_level_exp"), 0)
			if next_exp <= 0:
				next_exp = LevelManager.exp_needed_for_level(lv)
			party[p_name] = {
				"level": lv,
				"exp": max(0, _int_or(d.get("exp"), 0)),
				"next_level_exp": next_exp,
				"skill_points": max(0, _int_or(d.get("skill_points"), 0)),
				"atk": _int_or(d.get("atk"), e.atk),
				"defense": _int_or(d.get("defense"), e.defense),
				"spd": _int_or(d.get("spd"), e.spd),
				"max_hp": max(1, _int_or(d.get("max_hp"), e.max_hp))
			}

	return {
		"map": map_file,
		"pos": pos,
		"story": story_data,
		"credits": credits,
		"inventory": inventory,
		"opened_chests": opened_chests,
		"party": party
	}

static func _commit_save_data(parsed: Dictionary) -> void:
	"""Ghi dữ liệu đã kiểm tra hợp lệ vào GameManager (bước duy nhất làm thay đổi trạng thái khi tải)."""
	GameManager.current_map_file = parsed["map"]
	GameManager.last_player_position = parsed["pos"]
	GameManager.story.deserialize(parsed["story"])
	GameManager.credits = parsed["credits"]
	GameManager.inventory = parsed["inventory"]
	GameManager.opened_chests = parsed["opened_chests"]

	for p_name in parsed["party"]:
		var e = GameManager.party[p_name]
		var d = parsed["party"][p_name]
		e.level = d["level"]
		e.current_exp = d["exp"]
		e.next_level_exp = d["next_level_exp"]
		e.skill_points = d["skill_points"]
		e.atk = d["atk"]
		e.defense = d["defense"]
		e.spd = d["spd"]
		e.max_hp = d["max_hp"]
		e.current_hp = e.max_hp

	# Sau khi nạp story (có training_wave) mới xóa trạng thái tạm của phiên trước (training, sandbox, trận kịch bản...)
	GameManager.clear_transient_state()

# ── API Đọc Siêu Dữ Liệu & Danh Sách ───────────────────────────────────────

static func get_save_metadata(path_or_name: String) -> Dictionary:
	"""
	Đọc siêu dữ liệu preview của 1 file save mà không tải game_state.
	Trả về {} nếu file không tồn tại, hỏng hoặc không có mục metadata.
	"""
	var full_path = _resolve_full_path(path_or_name)
	if full_path == "" or not FileAccess.file_exists(full_path):
		return {}

	var f = FileAccess.open(full_path, FileAccess.READ)
	if f == null: return {}

	var json_str = f.get_as_text()
	f.close()

	var data = JSON.parse_string(json_str)
	if not data is Dictionary: return {}

	var meta = data.get("metadata")
	if not meta is Dictionary:
		return {}
	meta["path"] = full_path
	return meta

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
	if full_path == "":
		return false
	if FileAccess.file_exists(full_path):
		var dir = DirAccess.open(SAVES_DIR)
		if dir:
			var err = dir.remove(full_path.get_file())
			if err == OK:
				GameLogger.info("SaveManager", "Đã xóa file save: %s" % full_path)
				return true
	return false
