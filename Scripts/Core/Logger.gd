class_name GameLogger
extends RefCounted

"""
Tóm tắt: GameLogger ghi log có cấu trúc cho SekaiRPG: `[LEVEL] [Tag] Message`.

- INFO in ra console; WARN và ERROR còn gọi `push_warning()` / `push_error()` để hiện trong trình gỡ lỗi của engine.
- API tĩnh: `GameLogger.info()`, `GameLogger.warn()`, `GameLogger.error()`; mỗi hàm trả về chuỗi đã định dạng.
"""

enum Level { INFO, WARN, ERROR }

static func log_message(level: Level, tag: String, message: String) -> String:
	var formatted = "[%s] [%s] %s" % [Level.keys()[level], tag, message]
	match level:
		Level.INFO:
			print(formatted)
		Level.WARN:
			print(formatted)
			push_warning(formatted)
		Level.ERROR:
			printerr(formatted)
			push_error(formatted)
	return formatted

static func info(tag: String, message: String) -> String:
	return log_message(Level.INFO, tag, message)

static func warn(tag: String, message: String) -> String:
	return log_message(Level.WARN, tag, message)

static func error(tag: String, message: String) -> String:
	return log_message(Level.ERROR, tag, message)
