extends Node
class_name UpgradeManager

"""
UpgradeManager: Quản lý hệ thống nâng cấp chỉ số vĩnh viễn bằng Skill Points (SP).

Lớp này cho phép người chơi hoặc hệ thống tự động phân bổ điểm SP
vào các chỉ số cơ bản như Máu, Tấn công, Phòng thủ và Tốc độ, đồng thời đảm bảo
các chỉ số này không vượt quá giới hạn (Cap) đã định.
"""

# Chi phí SP cho mỗi lần nâng cấp
const UPGRADE_COST = 1

# Lượng chỉ số tăng thêm cụ thể cho mỗi lần nâng cấp
const UPGRADE_AMOUNTS = {
	"max_hp": 30,
	"atk": 10,
	"defense": 5,
	"spd": 2
}

static func upgrade_stat(entity: Entity, stat_name: String) -> bool:
	"""
	Thực hiện nâng cấp một chỉ số cụ thể cho thực thể.

	Quy trình kiểm tra bao gồm:
	- Tính hợp lệ của tên chỉ số (stat_name).
	- Số lượng điểm Skill Points (SP) hiện có của thực thể.
	- Giới hạn tối đa (Hard Cap) của chỉ số đó từ dữ liệu Entity.
	- Tính toán lượng tăng thực tế để không vượt quá giới hạn.

	Args:
		entity (Entity): Thực thể thực hiện nâng cấp.
		stat_name (String): Tên thuộc tính cần nâng (ví dụ: 'atk').

	Returns:
		bool: True nếu nâng cấp thành công, False nếu không đủ SP hoặc đạt giới hạn.
	"""
	if entity == null:
		return false
		
	if not UPGRADE_AMOUNTS.has(stat_name):
		return false
		
	if entity.skill_points < UPGRADE_COST:
		return false
		
	var current_val = entity.get(stat_name)
	var cap_val = entity.stat_caps.get(stat_name, 9999)
	var increment = UPGRADE_AMOUNTS[stat_name]

	if current_val >= cap_val:
		return false

	var actual_increment = min(increment, cap_val - current_val)

	entity.set(stat_name, current_val + actual_increment)
	entity.skill_points -= UPGRADE_COST

	if stat_name == "max_hp":
		entity.current_hp = min(entity.current_hp + actual_increment, entity.max_hp)
		
	return true
