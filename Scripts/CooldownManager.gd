extends Node
class_name CooldownManager

# Gọi hàm này ở đầu mỗi lượt để giảm cooldown
static func process_cooldowns(entity: Entity):
	var keys = entity.cooldowns.keys()
	for skill in keys:
		if entity.cooldowns[skill] > 0:
			entity.cooldowns[skill] -= 1
			# Báo cáo UI cập nhật số lượt chờ
			entity.cooldown_updated.emit(skill, entity.cooldowns[skill])

# Kiểm tra xem chiêu đã dùng được chưa
static func is_skill_ready(entity: Entity, skill_name: String) -> bool:
	return entity.cooldowns.get(skill_name, 0) == 0

# Cài đặt cooldown sau khi dùng chiêu
static func set_cooldown(entity: Entity, skill_name: String, turns: int):
	entity.cooldowns[skill_name] = turns
	# Báo cáo UI bắt đầu đếm ngược
	entity.cooldown_updated.emit(skill_name, turns)
