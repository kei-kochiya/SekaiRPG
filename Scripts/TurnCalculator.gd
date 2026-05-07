extends Node
class_name TurnCalculator

# Hằng số cơ sở theo công thức của bạn
const BASE_VALUE = 10000.0

# Task 2.1: Tính toán Action Value (AV) cho một thực thể
static func get_action_value(spd: int) -> float:
	if spd <= 0: return 10000.0
	return BASE_VALUE / spd

# Task 2.2: Tạo danh sách dự báo lượt đi
static func get_timeline(entities: Array, depth: int = 20) -> Array:
	var timeline = []
	
	for entity in entities:
		var av = get_action_value(entity.spd)
		# Tính toán các điểm mốc cho 20 lượt tiếp theo của nhân vật này
		for i in range(1, depth + 1):
			timeline.append({
				"name": entity.entity_name,
				"tick": av * i
			})
	
	# Sắp xếp: Ai có tick thấp hơn (đến mốc thời gian sớm hơn) thì đi trước
	timeline.sort_custom(func(a, b): return a["tick"] < b["tick"])
	
	# Chỉ lấy đúng số lượng lượt dự báo cần thiết (ví dụ 20 lượt đầu tiên)
	return timeline.slice(0, depth)

# Xóa các lượt của thực thể đã chết khỏi Timeline
static func remove_dead_from_timeline(timeline: Array, dead_entity_name: String) -> Array:
	var updated_timeline = []
	for turn in timeline:
		if turn["name"] != dead_entity_name:
			updated_timeline.append(turn)
	return updated_timeline
