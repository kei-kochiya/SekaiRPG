extends "res://Tests/Unit/BaseTest.gd"

const GameLoggerClass = preload("res://Scripts/Core/Logger.gd")

"""
Tóm tắt: Unit test cho Hệ thống Ghi Log Có Cấu Trúc (Structured GameLogger Framework).
"""

func test_log_levels_filtering():
	GameLoggerClass.clear_history()
	GameLoggerClass.set_level(GameLoggerClass.Level.WARN)
	
	var res_debug = GameLoggerClass.debug("TestTag", "This is a debug message")
	var res_info = GameLoggerClass.info("TestTag", "This is an info message")
	var res_warn = GameLoggerClass.warn("TestTag", "This is a warning message")
	
	assert_eq(res_debug, "", "DEBUG message is suppressed when log level is WARN")
	assert_eq(res_info, "", "INFO message is suppressed when log level is WARN")
	assert_ne(res_warn, "", "WARN message is logged when log level is WARN")
	
	# Reset level
	GameLoggerClass.set_level(GameLoggerClass.Level.DEBUG)
	var res_debug2 = GameLoggerClass.debug("TestTag", "This debug should now pass")
	assert_ne(res_debug2, "", "DEBUG message is logged when log level is DEBUG")
	
	GameLoggerClass.set_level(GameLoggerClass.Level.INFO)

func test_log_formatting_and_history():
	GameLoggerClass.clear_history()
	GameLoggerClass.set_level(GameLoggerClass.Level.INFO)
	
	var out = GameLoggerClass.info("BattleEngine", "Enemy spawned with 100 HP")
	assert_true(out.contains("[INFO]"), "Log output contains [INFO] tag")
	assert_true(out.contains("[BattleEngine]"), "Log output contains [BattleEngine] tag")
	assert_true(out.contains("Enemy spawned with 100 HP"), "Log output contains message content")
	
	var hist = GameLoggerClass.get_history()
	assert_eq(hist.size(), 1, "Log history records 1 entry")
	assert_eq(hist[0]["tag"], "BattleEngine", "History records correct tag")
	assert_eq(hist[0]["level_str"], "INFO", "History records correct level string")
	
	GameLoggerClass.clear_history()
	assert_eq(GameLoggerClass.get_history().size(), 0, "clear_history() resets history buffer")
