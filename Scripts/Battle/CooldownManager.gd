extends Node
class_name CooldownManager

"""
Tóm tắt: CooldownManager quản lý thời gian hồi chiêu (cooldown) của kỹ năng.

Chức năng chính:
- Cung cấp các phương thức tĩnh để đếm ngược cooldown mỗi lượt (`process_cooldowns`).
- Thiết lập thời gian chờ sau khi thực thể sử dụng kỹ năng (`set_cooldown`).
"""

# Giá trị cooldown đặc biệt: kỹ năng "một lần mỗi trận" đã dùng xong, không đếm ngược nữa.
const LOCKED_FOR_BATTLE = 99

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
		if entity.cooldowns[skill] > 0 and entity.cooldowns[skill] < LOCKED_FOR_BATTLE:
			entity.cooldowns[skill] -= 1
			entity.cooldown_updated.emit(skill, entity.cooldowns[skill])

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
