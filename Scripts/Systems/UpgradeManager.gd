extends Node
class_name UpgradeManager

"""
Tóm tắt: UpgradeManager là lớp tĩnh (Static Class) phụ trách logic sử dụng Điểm Kỹ Năng (SP) để nâng cấp chỉ số.

Chức năng chính:
- Xác định chi phí SP và hệ số gia tăng cơ bản cho mỗi loại chỉ số (HP, ATK, DEF, SPD).
- Cung cấp API `upgrade_stat` để kiểm tra điều kiện (đủ SP, chưa đạt giới hạn Max Cap) và thực hiện cộng chỉ số.
- Cung cấp API `bulk_upgrade` giúp thực hiện nâng cấp hàng loạt hoặc nâng tối đa chỉ số chỉ trong một lần bấm để tăng tính tiện dụng cho UI.
"""

# ── Hằng Số Nâng Cấp ───────────────────────────────────────────────────────

const UPGRADE_COST = 1

const UPGRADE_AMOUNTS = {
	"max_hp": 30,
	"atk": 10,
	"defense": 5,
	"spd": 2
}

# ── API Nâng Cấp Đơn ───────────────────────────────────────────────────────

static func upgrade_stat(entity: Entity, stat_name: String) -> bool:
	"""
	Thực hiện nâng cấp một chỉ số cụ thể cho thực thể nếu đủ SP và chưa đạt giới hạn.
	
	Args:
		entity (Entity): Thực thể thực hiện nâng cấp.
		stat_name (String): Tên thuộc tính cần nâng, ví dụ: 'atk', 'max_hp'.
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


# ── API Nâng Cấp Hàng Loạt ─────────────────────────────────────────────────

static func bulk_upgrade(entity: Entity, stat_name: String, count: int) -> int:
	"""
	Thực hiện nâng cấp hàng loạt một chỉ số để tiết kiệm thời gian.
	
	Args:
		entity (Entity): Thực thể cần nâng cấp.
		stat_name (String): Tên chỉ số.
		count (int): Số lần muốn nâng (dùng giá trị lớn để nâng tối đa).
	Returns: 
		int: Số lần nâng cấp đã thực hiện thành công.
	"""
	var upgrades_done = 0
	for i in range(count):
		if upgrade_stat(entity, stat_name):
			upgrades_done += 1
		else:
			break
	return upgrades_done
