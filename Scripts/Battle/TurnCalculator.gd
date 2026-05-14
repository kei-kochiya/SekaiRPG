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
	Sử dụng action_gauge để tính toán thời gian thực tế đến lượt tiếp theo.
	"""
	if entities.is_empty(): return []
		
	var timeline = []
	
	for entity in entities:
		var spd = max(entity.spd, 1)
		var current_gauge = entity.action_gauge
		
		# AV (Action Value) = (Khoảng cách còn lại) / Tốc độ
		# Khoảng cách còn lại cho lượt đầu tiên là 10000 - gauge
		# Nếu gauge > 10000, distance sẽ âm -> ưu tiên cực cao
		for i in range(depth):
			var distance = 10000.0 - current_gauge + (i * 10000.0)
			var av_cost = distance / spd
			
			timeline.append({
				"entity": entity,
				"tick": av_cost
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
