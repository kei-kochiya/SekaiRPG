extends Node
class_name ProcessStatus

"""
Tóm tắt: ProcessStatus xử lý các hiệu ứng trạng thái (Status Effects) cho thực thể.

Chức năng chính:
- Quản lý logic gây sát thương theo thời gian (DoT) như Poison, Bleed.
- Xử lý trạng thái khống chế (Stun) và cập nhật thời hạn (duration) của các hiệu ứng đang có trên thực thể vào đầu mỗi lượt (`handle_turn_start`).
- Tự động xóa các hiệu ứng đã hết thời hạn.
"""

# ── Xử Lý Lượt Đi ───────────────────────────────────────────────────────────


static func handle_turn_start(entity: Entity) -> bool:
	"""
	Xử lý toàn bộ các hiệu ứng trạng thái (DoT, Stun...) khi thực thể bắt đầu lượt.
	
	Args:
		entity (Entity): Thực thể cần xử lý trạng thái.
	Returns: 
		bool: True nếu thực thể có thể hành động, False nếu bị choáng/khống chế.
	"""
	if entity == null:
		return true
		
	if entity.active_statuses.is_empty():
		return true
	
	var can_act = true
	var statuses_to_remove = []
	
	# Xử lý Bleed riêng để tính sát thương gộp từ các stack
	var bleed_count = entity.get_status_count("Bleed")
	if bleed_count > 0:
		var bleed_dmg = int(entity.current_hp * (0.1 * bleed_count))
		entity.take_damage(bleed_dmg, "dot")
		print("[ProcessStatus] ", entity.entity_name, " chịu ", bleed_dmg, " sát thương Chảy máu (", bleed_count, " stacks)")

	for status in entity.active_statuses:
		match status["type"]:
			"Bleed":
				pass # Đã xử lý sát thương gộp ở trên
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
