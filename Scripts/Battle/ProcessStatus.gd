extends Node
class_name ProcessStatus

"""
ProcessStatus: Xử lý các hiệu ứng trạng thái (Status Effects) cho thực thể.

Lớp này quản lý các logic gây sát thương theo thời gian (DoT), làm choáng (Stun),
và cập nhật thời hạn (duration) của các hiệu ứng đang có trên thực thể vào đầu mỗi lượt.
"""

static func handle_turn_start(entity: Entity) -> bool:
	"""
	Xử lý toàn bộ hiệu ứng trạng thái khi thực thể bắt đầu lượt đánh.

	Quy trình xử lý các loại trạng thái:
	- Bleed: Gây sát thương dựa trên 20% máu hiện tại của thực thể.
	- Poison: Gây sát thương theo % máu tối đa, tỷ lệ này giảm dần sau mỗi lượt.
	- Stun: Chặn đứng mọi hành động của thực thể trong lượt hiện tại.
	- Cập nhật thời hạn: Giảm thời hạn (duration) của mọi hiệu ứng và tự động loại bỏ.

	Args:
		entity (Entity): Thực thể đang bắt đầu lượt và cần kiểm tra trạng thái.

	Returns:
		bool: True nếu thực thể có thể thực hiện hành động, False nếu bị khống chế (Stun).
	"""
	if entity == null:
		return true
		
	if entity.active_statuses.is_empty():
		return true
	
	var can_act = true
	var statuses_to_remove = []
	
	for status in entity.active_statuses:
		match status["type"]:
			"Bleed":
				var dmg = int(entity.current_hp * 0.2)
				entity.take_damage(dmg, "dot")
			"Poison":
				var pct = status.get("percent", 0.1)
				var dmg = int(entity.max_hp * pct)
				entity.take_damage(dmg, "dot")
				status["percent"] = max(0.01, pct - 0.03)
			"Stun":
				print("[ProcessStatus] ", entity.entity_name, " đang bị Choáng!")
				can_act = false
		
		status["duration"] -= 1
		if status["duration"] <= 0:
			statuses_to_remove.append(status)
	
	entity.remove_statuses(statuses_to_remove)
	
	return can_act
