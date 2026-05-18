extends Node
class_name CooldownManager

"""
Tóm tắt: CooldownManager quản lý thời gian hồi chiêu (cooldown) của kỹ năng.

Chức năng chính:
- Cung cấp các phương thức tĩnh để đếm ngược cooldown mỗi lượt (`process_cooldowns`).
- Kiểm tra trạng thái sẵn sàng của kỹ năng (`is_skill_ready`).
- Thiết lập thời gian chờ sau khi thực thể sử dụng kỹ năng (`set_cooldown`).
"""

# ── Xử Lý Cooldown ─────────────────────────────────────────────────────────

static func process_cooldowns(entity: Entity):
	"""
	Giảm thời gian hồi chiêu của tất cả kỹ năng xuống 1 lượt.
	
	Thường được gọi vào đầu lượt của thực thể để giải phóng
	các kỹ năng đã hết thời gian chờ.
	
	Args:
		entity (Entity): Thực thể cần cập nhật cooldown.
	Returns: Không có
	"""
	if entity == null:
		return
		
	var keys = entity.cooldowns.keys()
	for skill in keys:
		if entity.cooldowns[skill] > 0:
			entity.cooldowns[skill] -= 1
			entity.cooldown_updated.emit(skill, entity.cooldowns[skill])

static func is_skill_ready(entity: Entity, skill_name: String) -> bool:
	"""
	Kiểm tra xem một kỹ năng đã sẵn sàng để sử dụng hay chưa.
	
	Args:
		entity (Entity): Thực thể sở hữu kỹ năng.
		skill_name (String): Tên method của kỹ năng cần kiểm tra.
	Returns: 
		bool: True nếu cooldown bằng 0, ngược lại False.
	"""
	if entity == null:
		return false
	return entity.cooldowns.get(skill_name, 0) == 0

static func set_cooldown(entity: Entity, skill_name: String, turns: int):
	"""
	Thiết lập thời gian hồi chiêu mới cho một kỹ năng sau khi sử dụng.
	
	Args:
		entity (Entity): Thực thể thực hiện kỹ năng.
		skill_name (String): Tên kỹ năng.
		turns (int): Số lượt cần chờ.
	Returns: Không có
	"""
	if entity == null:
		return
		
	entity.cooldowns[skill_name] = turns
	entity.cooldown_updated.emit(skill_name, turns)
