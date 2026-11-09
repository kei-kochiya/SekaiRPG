extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho GameLogger (định dạng `[LEVEL] [Tag] Message` và cấp độ trả về).
"""

func test_log_formatting_per_level():
	var out = GameLogger.info("BattleEngine", "Enemy spawned with 100 HP")
	assert_eq(out, "[INFO] [BattleEngine] Enemy spawned with 100 HP", "INFO: đúng định dạng")
	assert_true(GameLogger.warn("Tag", "x").begins_with("[WARN] [Tag]"), "WARN mang nhãn WARN")
