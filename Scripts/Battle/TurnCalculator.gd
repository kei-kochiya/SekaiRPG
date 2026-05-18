extends Node
class_name TurnCalculator

"""
Tóm tắt: TurnCalculator tính toán thứ tự hành động (Turn Order) dựa trên Action Value (AV).

Chức năng chính:
- Quy đổi chỉ số tốc độ (SPD) thành Action Value (`get_action_value`).
- Dự báo danh sách lượt đi trong tương lai (`get_timeline`) với cơ chế tie-breaker để giải quyết các trường hợp trùng AV.
- Lọc bỏ lượt của các thực thể đã bị hạ gục khỏi dòng thời gian (`remove_dead_from_timeline`).
"""

# ── Cấu Hình ───────────────────────────────────────────────────────────────

const BASE_VALUE = 10000.0

# ── Xử Lý Lượt Đi ──────────────────────────────────────────────────────────

static func get_action_value(spd: int) -> float:
	"""
	Hàm này tính toán Action Value (AV) dựa trên chỉ số tốc độ (SPD).
	
	Args:
		spd (int): Chỉ số tốc độ của thực thể.
	Returns: 
		float: Giá trị AV. Số càng thấp lượt đến càng nhanh.
	"""
	if spd <= 0: return 10000.0
	return BASE_VALUE / spd

static func get_timeline(entities: Array, depth: int = 20) -> Array:
	"""
	Tạo ra danh sách dự báo các lượt đánh trong tương lai.
	Sử dụng action_gauge để tính toán thời gian thực tế đến lượt tiếp theo.
	
	Args:
		entities (Array): Danh sách các thực thể trong trận đấu.
		depth (int): Số lượng lượt cần dự báo (mặc định 20).
	Returns: 
		Array: Danh sách các Dictionary chứa thông tin lượt đi.
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
	Lọc bỏ các lượt của một thực thể đã bị hạ gục khỏi dòng thời gian.
	
	Args:
		timeline (Array): Danh sách lượt hiện tại.
		dead_entity (Entity): Thực thể vừa chết.
	Returns: 
		Array: Danh sách lượt mới sau khi lọc.
	"""
	var updated_timeline = []
	for turn in timeline:
		if turn["entity"] != dead_entity:
			updated_timeline.append(turn)
	return updated_timeline
