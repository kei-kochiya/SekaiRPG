extends Node
class_name TurnCalculator

"""
TurnCalculator: Tính toán thứ tự hành động (Turn Order) dựa trên đối tượng Entity.

Hệ thống này sử dụng khái niệm Action Value (AV) để dự báo danh sách lượt đi 
trong tương lai. Hỗ trợ cơ chế tie-breaker giúp đan xen lượt ổn định khi 
các thực thể có cùng tốc độ hoặc trùng tên.
"""

const BASE_VALUE = 10000.0

static func get_action_value(spd: int) -> float:
	"""
	Hàm này tính toán Action Value (AV) dựa trên chỉ số tốc độ (SPD).
	- spd: Chỉ số tốc độ của thực thể (int).
	- Return: Giá trị AV (float). Số càng thấp lượt đến càng nhanh.
	"""
	if spd <= 0: return 10000.0
	return BASE_VALUE / spd

static func get_timeline(entities: Array, depth: int = 20) -> Array:
	"""
	Hàm này tạo ra danh sách dự báo các lượt đánh trong tương lai.
	- entities: Danh sách các thực thể đang tham chiến (Array).
	- depth: Số lượng lượt cần dự báo (int).
	- Return: Mảng chứa thông tin thực thể và thời điểm đến lượt (Array).
	"""
	if entities.is_empty(): return []
		
	var timeline = []
	
	for entity in entities:
		var av = get_action_value(entity.spd)
		for i in range(1, depth + 1):
			timeline.append({
				"entity": entity,
				"tick": av * i
			})
	
	timeline.sort_custom(func(a, b):
		if abs(a["tick"] - b["tick"]) < 0.001:
			return a["entity"].get_instance_id() < b["entity"].get_instance_id()
		return a["tick"] < b["tick"]
	)
	
	return timeline.slice(0, depth)

static func remove_dead_from_timeline(timeline: Array, dead_entity: Entity) -> Array:
	"""
	Hàm này lọc bỏ các lượt của một thực thể đã bị hạ gục khỏi dòng thời gian.
	- timeline: Danh sách lượt hiện tại (Array).
	- dead_entity: Thực thể vừa chết (Entity).
	- Return: Danh sách lượt mới sau khi lọc (Array).
	"""
	var updated_timeline = []
	for turn in timeline:
		if turn["entity"] != dead_entity:
			updated_timeline.append(turn)
	return updated_timeline
