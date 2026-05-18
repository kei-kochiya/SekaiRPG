extends Node
class_name DamageCalculator

"""
Tóm tắt: DamageCalculator phụ trách tính toán lượng sát thương cuối cùng trong trận đấu.

Chức năng chính:
- Cung cấp phương thức tĩnh `calculate_damage` để xử lý công thức sát thương: raw_dmg = (ATK * Multiplier) - DEF.
- Tự động áp dụng hệ số giảm trừ theo kháng (RES) và tương khắc thuộc tính (thông qua TypeChart).
- Đảm bảo sát thương tối thiểu gây ra không bao giờ thấp hơn 5% ATK của người tấn công.
"""

# ── Xử Lý Sát Thương ───────────────────────────────────────────────────────


static func calculate_damage(attacker: Entity, defender: Entity, skill_multiplier: float = 1.0) -> int:
	"""
	Tính toán lượng sát thương thực tế mà mục tiêu sẽ nhận.
	
	Công thức tính toán bao gồm:
	- Sát thương thô: max(0, (ATK * Multiplier) - DEF).
	- Giảm trừ theo kháng: raw * (1 - RES/100).
	- Nhân hệ số tương khắc thuộc tính từ TypeChart.
	- Sát thương tối thiểu: 5% ATK của người tấn công.
	
	Args:
		attacker (Entity): Thực thể thực hiện tấn công.
		defender (Entity): Thực thể nhận sát thương.
		skill_multiplier (float): Hệ số nhân sát thương của kỹ năng (mặc định là 1.0).
	Returns: 
		int: Lượng sát thương cuối cùng sau khi áp dụng toàn bộ hệ số.
	"""
	if attacker == null or defender == null:
		return 0
		
	var modified_atk = attacker.atk * skill_multiplier
	var raw_damage = max(0, modified_atk - defender.defense)
	
	var after_res = raw_damage * (1.0 - (defender.res / 100.0))
	
	var multiplier = TypeChart.get_multiplier(attacker.type, defender.type)
	var final_damage = after_res * multiplier
	
	var min_damage = modified_atk * 0.05
	if final_damage < min_damage:
		final_damage = min_damage
		
	return int(final_damage)
