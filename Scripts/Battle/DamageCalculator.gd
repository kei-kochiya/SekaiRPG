extends Node
class_name DamageCalculator

"""
DamageCalculator: Xử lý logic tính toán sát thương trong trận đấu.

Lớp này tính toán lượng sát thương cuối cùng dựa trên các chỉ số của người tấn công
và người phòng thủ, bao gồm Công (ATK), Thủ (DEF), Kháng (RES) và hệ thuộc tính.
"""

static func calculate_damage(attacker: Entity, defender: Entity) -> int:
	"""
	Tính toán lượng sát thương thực tế mà mục tiêu sẽ nhận.

	Công thức tính toán bao gồm:
	- Sát thương thô (Raw Damage) = max(0, ATK - DEF).
	- Giảm trừ theo chỉ số Kháng: raw * (1 - res/100).
	- Nhân hệ số tương khắc thuộc tính từ TypeChart.
	- Đảm bảo sát thương tối thiểu không thấp hơn 5% ATK của người tấn công.

	Args:
		attacker (Entity): Thực thể thực hiện tấn công.
		defender (Entity): Thực thể nhận sát thương.

	Returns:
		int: Lượng sát thương cuối cùng sau khi áp dụng toàn bộ hệ số.
	"""
	if attacker == null or defender == null:
		return 0
		
	var raw_damage = max(0, attacker.atk - defender.defense)
	
	var after_res = raw_damage * (1.0 - (defender.res / 100.0))
	
	var multiplier = TypeChart.get_multiplier(attacker.type, defender.type)
	var final_damage = after_res * multiplier
	
	var min_damage = attacker.atk * 0.05
	if final_damage < min_damage:
		final_damage = min_damage
		
	return int(final_damage)
