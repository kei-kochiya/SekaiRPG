extends Node
class_name CooldownManager

"""
CooldownManager: Quản lý thời gian hồi chiêu của các kỹ năng.

Lớp này cung cấp các phương thức để xử lý việc đếm ngược thời gian hồi chiêu
vào mỗi lượt đánh, kiểm tra trạng thái sẵn sàng của kỹ năng và thiết lập
thời gian chờ mới sau khi kỹ năng được sử dụng.
"""

static func process_cooldowns(entity: Entity):
	"""
	Giảm thời gian hồi chiêu của tất cả kỹ năng cho một thực thể.
	
	Thường được gọi vào đầu mỗi lượt đánh của thực thể để giải phóng 
	các kỹ năng đã hết thời gian chờ.

	Args:
		entity (Entity): Thực thể cần cập nhật thời gian hồi chiêu.
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
	Kiểm tra xem một kỹ năng cụ thể đã sẵn sàng để sử dụng hay chưa.

	Args:
		entity (Entity): Thực thể sở hữu kỹ năng.
		skill_name (String): Tên phương thức (method) của kỹ năng.

	Returns:
		bool: True nếu thời gian hồi chiêu bằng 0, ngược lại False.
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
		turns (int): Số lượt cần chờ (cooldown).
	"""
	if entity == null:
		return
		
	entity.cooldowns[skill_name] = turns
	entity.cooldown_updated.emit(skill_name, turns)
