extends Node

"""
Tóm tắt: DialogueLoader là Node hệ thống có nhiệm vụ nạp và xử lý toàn bộ dữ liệu hội thoại từ các file JSON.

Chức năng chính:
- Tự động quét toàn bộ thư mục `res://Data/storyline/` lúc khởi động game.
- Phân tích cú pháp (parse) và chuyển đổi các file JSON thành một Dictionary `_data` tập trung trên bộ nhớ.
- Cung cấp API `get_lines(key)` để trích xuất và chuẩn hóa dữ liệu dòng thoại (xác định loại thoại, người nói, màu sắc, vị trí chân dung) cho `DialogueManager` sử dụng.
"""

# ── Biến Lưu Trữ ───────────────────────────────────────────────────────────


var _data: Dictionary = {}

# ── Khởi Tạo & Tải Dữ Liệu ─────────────────────────────────────────────────

# Khởi tạo loader
func _ready() -> void:
	_load_json()

func _load_json() -> void:
	"""
	Quét thư mục chứa hội thoại và tải tuần tự từng tệp JSON tìm thấy.
	
	Args: Không có
	Returns: Không có
	"""
	var path = "res://Data/storyline/"
	var dir = DirAccess.open(path)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_load_single_file(path + file_name)
		file_name = dir.get_next()

func _load_single_file(file_path: String) -> void:
	"""
	Tải một tệp JSON đơn lẻ và gộp nội dung vào bộ nhớ đệm dùng chung.
	
	Args:
		file_path (String): Đường dẫn tuyệt đối đến tệp JSON cần nạp.
	Returns: Không có
	"""
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return
		
	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		return

	var new_data: Dictionary = parsed as Dictionary
	for key in new_data:
		_data[key] = new_data[key]

# ── API Truy Xuất ──────────────────────────────────────────────────────────

func get_lines(key: String) -> Array:
	"""
	Lấy và chuẩn hóa danh sách các dòng thoại tương ứng với một khóa (key) chỉ định.
	
	Args:
		key (String): Khóa định danh hội thoại trong file JSON.
	Returns:
		Array: Mảng các dòng thoại đã chuẩn hóa (chứa type, text, name, speaker, color). Trả về mảng trống nếu không tìm thấy.
	"""
	if not _data.has(key):
		return []

	var raw: Array = _data[key]
	var out: Array = []
	for entry in raw:
		var line: Dictionary = {}
		line["type"]    = entry.get("type", "dialogue")
		line["text"]    = entry.get("text", "")
		line["name"]    = entry.get("name", "")
		line["speaker"] = entry.get("speaker", "left")
		
		var hex: String = entry.get("color", "#ffffff")
		line["color"] = Color(hex)
		out.append(line)
		
	return out
