extends "res://Tests/Unit/BaseTest.gd"

const GameLoggerClass = preload("res://Scripts/Core/Logger.gd")

"""
Tóm tắt: Unit test cho GameLogger (Structured Logging).
"""

func test_logger_levels():
	GameLoggerClass.clear_history()
	GameLoggerClass.set_level(GameLoggerClass.Level.WARN)
	
	var d = GameLoggerClass.debug("Unit", "Debug msg")
	var i = GameLoggerClass.info("Unit", "Info msg")
	var w = GameLoggerClass.warn("Unit", "Warn msg")
	
	assert_eq(d, "", "DEBUG message filtered out under WARN level")
	assert_eq(i, "", "INFO message filtered out under WARN level")
	assert_ne(w, "", "WARN message emitted under WARN level")
	
	GameLoggerClass.set_level(GameLoggerClass.Level.INFO)

func test_logger_message_structure():
	GameLoggerClass.clear_history()
	GameLoggerClass.set_level(GameLoggerClass.Level.INFO)
	
	var msg = GameLoggerClass.info("Combat", "Player attacked enemy")
	assert_true(msg.contains("[INFO]"), "Formatted log includes [INFO]")
	assert_true(msg.contains("[Combat]"), "Formatted log includes [Combat] tag")
	assert_true(msg.contains("Player attacked enemy"), "Formatted log includes message body")
	
	var hist = GameLoggerClass.get_history()
	assert_gt(hist.size(), 0, "History buffer stores emitted logs")
	assert_eq(hist[0]["tag"], "Combat", "History captures correct tag")
	
	GameLoggerClass.clear_history()
