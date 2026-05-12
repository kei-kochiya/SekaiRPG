extends Node
class_name CooldownManager

"""
CooldownManager: Quản lý thời gian hồi chiêu (cooldown) của kỹ năng.

Cung cấp các phương thức để đếm ngược cooldown mỗi lượt, kiểm tra kỹ năng
đã sẵn sàng chưa, và thiết lập cooldown sau khi sử dụng kỹ năng.
"""

static func process_cooldowns(entity: Entity):
	"""
	Giảm thời gian hồi chiêu của tất cả kỹ năng xuống 1 lượt.

	Thường được gọi vào đầu lượt của thực thể để giải phóng
	các kỹ năng đã hết thời gian chờ.

	- entity: Thực thể cần cập nhật cooldown (Entity).
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

	- entity: Thực thể sở hữu kỹ năng (Entity).
	- skill_name: Tên method của kỹ năng cần kiểm tra (String).
	- Return: True nếu cooldown bằng 0, ngược lại False (bool).
	"""
	if entity == null:
		return false
	return entity.cooldowns.get(skill_name, 0) == 0

static func set_cooldown(entity: Entity, skill_name: String, turns: int):
	"""
	Thiết lập thời gian hồi chiêu mới cho một kỹ năng sau khi sử dụng.

	- entity: Thực thể thực hiện kỹ năng (Entity).
	- skill_name: Tên kỹ năng (String).
	- turns: Số lượt cần chờ (int).
	"""
	if entity == null:
		return
		
	entity.cooldowns[skill_name] = turns
	entity.cooldown_updated.emit(skill_name, turns)
