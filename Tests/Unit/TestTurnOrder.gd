extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho TurnCalculator (Action Value và dự báo thứ tự lượt đánh).
"""

# Thời gian tới lượt = (ACTION_GAUGE_FULL - gauge) / SPD: nhanh gấp đôi thì tới sớm gấp đôi; SPD 0 được coi là 1 (không chia cho 0)
func test_time_to_first_turn_scales_inversely_with_speed():
	var fast = Ichika.new()
	fast.spd = 100
	fast.action_gauge = 0.0
	var slow = Guard.new()
	slow.spd = 40
	slow.action_gauge = 0.0
	var timeline = TurnCalculator.get_timeline([fast, slow], 3)
	assert_eq(timeline.size(), 3, "Dự báo đủ số lượt yêu cầu")
	assert_eq(timeline[0]["entity"], fast, "Người nhanh hơn đi trước")
	assert_eq(timeline[0]["tick"], TurnCalculator.ACTION_GAUGE_FULL / 100.0, "SPD 100: lượt đầu sau 100 đơn vị thời gian")
	assert_eq(timeline[1]["tick"], TurnCalculator.ACTION_GAUGE_FULL * 2.0 / 100.0, "SPD 100: lượt hai sau 200")
	assert_eq(timeline[2]["entity"], slow, "Người chậm hơn chen vào sau hai lượt của người nhanh")
	assert_eq(timeline[2]["tick"], TurnCalculator.ACTION_GAUGE_FULL / 40.0, "SPD 40: lượt đầu sau 250 đơn vị thời gian")
	fast.free()
	slow.free()

func test_zero_speed_is_treated_as_one():
	var stalled = Guard.new()
	stalled.spd = 0
	stalled.action_gauge = 0.0
	var timeline = TurnCalculator.get_timeline([stalled], 1)
	assert_eq(timeline[0]["tick"], TurnCalculator.ACTION_GAUGE_FULL, "SPD 0 không gây chia cho 0")
	stalled.free()
