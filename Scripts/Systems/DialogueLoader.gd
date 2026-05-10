extends Node

"""
DialogueLoader: Tải và quản lý dữ liệu hội thoại từ các tệp JSON.

Lớp này tự động quét thư mục 'res://Data/storyline/', tải toàn bộ các tệp JSON
hội thoại và gộp chúng vào một kho lưu trữ tập trung. Nó cung cấp các phương thức
để truy xuất danh sách lời thoại dựa trên từ khóa (key) đã được chuẩn hóa.
"""

var _data: Dictionary = {}

func _ready() -> void:
	"""
	Khởi tạo loader và thực hiện tải toàn bộ dữ liệu hội thoại vào bộ nhớ.
	"""
	_load_json()

func _load_json() -> void:
	"""
	Quét thư mục chứa hội thoại và tải tuần tự từng tệp JSON tìm thấy.
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

func get_lines(key: String) -> Array:
	"""
	Lấy danh sách các dòng thoại tương ứng với một khóa (key) chỉ định.

	Dữ liệu trả về được chuẩn hóa thành một mảng các Dictionary chứa:
	- type: Loại hội thoại (dialogue/narrator).
	- text: Nội dung chữ.
	- name: Tên nhân vật hiển thị.
	- speaker: Vị trí hiển thị (left/right).
	- color: Đối tượng Color đã được chuyển đổi từ mã Hex.

	Args:
		key (String): Khóa định danh hội thoại trong file JSON.

	Returns:
		Array: Mảng các dòng thoại đã chuẩn hóa. Trả về mảng trống nếu không tìm thấy key.
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
