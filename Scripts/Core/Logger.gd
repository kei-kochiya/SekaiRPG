class_name GameLogger
extends RefCounted

"""
Tóm tắt: GameLogger là framework ghi log có cấu trúc (Structured Logging Framework) cho SekaiRPG.

Chức năng chính:
- Cung cấp 4 cấp độ log chuẩn: DEBUG (0), INFO (1), WARN (2), ERROR (3).
- Định dạng chuỗi log chuẩn hóa: `[LEVEL] [Tag] Message`.
- Tích hợp cảnh báo engine: `push_warning()` cho WARN và `push_error()` cho ERROR.
- Lưu trữ bộ đệm lịch sử log (`log_history`) phục vụ việc trích xuất báo cáo lỗi hoặc kiểm thử tự động.
- Cung cấp API tĩnh tiện lợi: `GameLogger.debug()`, `GameLogger.info()`, `GameLogger.warn()`, `GameLogger.error()`.
"""

enum Level {
	DEBUG = 0,
	INFO = 1,
	WARN = 2,
	ERROR = 3
}

static var current_level: int = Level.INFO
static var log_history: Array[Dictionary] = []
static var max_history_size: int = 200

static func set_level(level: int) -> void:
	current_level = level

static func get_level_name(level: int) -> String:
	match level:
		Level.DEBUG: return "DEBUG"
		Level.INFO: return "INFO"
		Level.WARN: return "WARN"
		Level.ERROR: return "ERROR"
		_: return "UNKNOWN"

static func log_message(level: int, tag: String, message: String) -> String:
	if level < current_level:
		return ""
		
	var level_str = get_level_name(level)
	var formatted = "[%s] [%s] %s" % [level_str, tag, message]
	
	var entry = {
		"level": level,
		"level_str": level_str,
		"tag": tag,
		"message": message,
		"timestamp": Time.get_datetime_string_from_system()
	}
	
	log_history.append(entry)
	if log_history.size() > max_history_size:
		log_history.pop_front()
		
	match level:
		Level.DEBUG, Level.INFO:
			print(formatted)
		Level.WARN:
			print(formatted)
			push_warning(formatted)
		Level.ERROR:
			printerr(formatted)
			push_error(formatted)
			
	return formatted

static func debug(tag: String, message: String) -> String:
	return log_message(Level.DEBUG, tag, message)

static func info(tag: String, message: String) -> String:
	return log_message(Level.INFO, tag, message)

static func warn(tag: String, message: String) -> String:
	return log_message(Level.WARN, tag, message)

static func error(tag: String, message: String) -> String:
	return log_message(Level.ERROR, tag, message)

static func get_history() -> Array[Dictionary]:
	return log_history.duplicate()

static func clear_history() -> void:
	log_history.clear()
