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
	Tính toán Action Value cơ bản dựa trên chỉ số tốc độ.
	
	Args:
		spd (int): Chỉ số tốc độ (SPD) của thực thể.
		
	Returns:
		float: Giá trị Action Value. Số càng thấp thì lượt đến càng nhanh.
	"""
	if spd <= 0: return 10000.0
	return BASE_VALUE / spd

static func get_timeline(entities: Array, depth: int = 20) -> Array:
	"""
	Tạo danh sách dòng thời gian các lượt đánh sắp tới.
	
	Sử dụng thuật toán tích lũy AV để dự đoán thứ tự. Nếu hai thực thể có 
	cùng tick thời gian, instance_id sẽ được dùng làm tiêu chí phụ để đảm bảo 
	thứ tự không bị thay đổi ngẫu nhiên.
	
	Args:
		entities (Array): Danh sách các thực thể đang tham chiến.
		depth (int): Số lượng lượt dự báo tối đa cần trả về.
		
	Returns:
		Array: Mảng các Dictionary chứa 'entity' và 'tick'.
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
	Loại bỏ toàn bộ các lượt dự kiến của một thực thể vừa bị hạ gục.
	
	Args:
		timeline (Array): Danh sách timeline hiện tại.
		dead_entity (Entity): Thực thể cần loại bỏ.
		
	Returns:
		Array: Danh sách timeline mới đã được lọc sạch.
	"""
	var updated_timeline = []
	for turn in timeline:
		if turn["entity"] != dead_entity:
			updated_timeline.append(turn)
	return updated_timeline
