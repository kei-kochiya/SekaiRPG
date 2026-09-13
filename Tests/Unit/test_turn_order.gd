extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho TurnCalculator (Action Value và dự báo thứ tự lượt đánh).
"""

func test_action_value_speed_inversion():
	# AV = 10000 / SPD
	var av_fast = TurnCalculator.get_action_value(100)
	var av_slow = TurnCalculator.get_action_value(50)
	
	assert_eq(av_fast, 100.0, "Action Value for SPD 100 is 100.0 (10000 / 100)")
	assert_eq(av_slow, 200.0, "Action Value for SPD 50 is 200.0 (10000 / 50)")
	assert_lt(av_fast, av_slow, "Faster entity has smaller Action Value")

func test_action_value_zero_speed_guard():
	var av_zero = TurnCalculator.get_action_value(0)
	assert_eq(av_zero, 10000.0, "Zero speed entity gets max fallback Action Value (no division by zero)")

func test_timeline_generation():
	var e1 = Ichika.new()
	e1.spd = 120
	e1.action_gauge = 0.0
	
	var e2 = Guard.new()
	e2.spd = 60
	e2.action_gauge = 0.0
	
	var timeline = TurnCalculator.get_timeline([e1, e2], 6)
	assert_eq(timeline.size(), 6, "Timeline generates requested 6 turns depth")
	assert_eq(timeline[0]["entity"], e1, "First turn belongs to faster entity (Ichika)")
