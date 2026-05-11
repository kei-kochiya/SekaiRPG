extends Node
class_name ProcessStatus

"""
ProcessStatus: Xử lý các hiệu ứng trạng thái (Status Effects) cho thực thể.

Lớp này quản lý các logic gây sát thương theo thời gian (DoT), làm choáng (Stun),
và cập nhật thời hạn (duration) của các hiệu ứng đang có trên thực thể vào đầu mỗi lượt.
"""

static func handle_turn_start(entity: Entity) -> bool:
	"""
	Hàm này xử lý toàn bộ các hiệu ứng trạng thái (DoT, Stun...) khi thực thể bắt đầu lượt.
	- entity: Thực thể cần xử lý trạng thái (Entity).
	- Return: True nếu thực thể có thể hành động, False nếu bị choáng/khống chế (bool).
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
				# Poison không còn giảm % sau mỗi lượt theo yêu cầu mới (giữ logic cũ nếu cần, 
				# nhưng ở đây user bảo 'logic như cũ' và 'không thể stack')
				# Trong file cũ logic là giảm 3%, mình giữ lại hoặc làm đơn giản hơn.
				status["percent"] = max(0.01, pct - 0.03) 
			"Stun":
				print("[ProcessStatus] ", entity.entity_name, " đang bị Choáng!")
				can_act = false
		
		status["duration"] -= 1
		if status["duration"] <= 0:
			statuses_to_remove.append(status)
	
	entity.remove_statuses(statuses_to_remove)
	
	return can_act
