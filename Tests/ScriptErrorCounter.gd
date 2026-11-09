extends Logger
class_name ScriptErrorCounter

"""
ScriptErrorCounter: đếm lỗi script của engine (gọi hàm không tồn tại, truy cập null...) xảy ra trong lúc chạy test.

Một test chết giữa chừng chỉ in "Invalid call" rồi thoát khỏi hàm; nếu năm assert đầu đã qua thì suite vẫn báo đạt.
BaseTest so sánh bộ đếm này trước/sau mỗi test và tính là thất bại nếu nó tăng. push_error() không tính (đó là lỗi chủ ý của
chính test hoặc của assert).
"""

# Số lỗi script từ đầu phiên chạy; luồng khác (vd. render) cũng có thể báo lỗi nên đọc qua mutex
static var count: int = 0
static var last_message: String = ""
static var _mutex := Mutex.new()

func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array) -> void:
	if error_type != Logger.ERROR_TYPE_SCRIPT:
		return
	_mutex.lock()
	count += 1
	last_message = "%s (%s:%d) %s" % [rationale if rationale != "" else code, file.get_file(), line, function]
	_mutex.unlock()

static func snapshot() -> int:
	_mutex.lock()
	var n := count
	_mutex.unlock()
	return n
