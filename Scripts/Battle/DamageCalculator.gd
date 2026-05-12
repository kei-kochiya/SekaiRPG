extends Node
class_name DamageCalculator

"""
DamageCalculator: Tính toán lượng sát thương cuối cùng trong trận đấu.

Áp dụng công thức: raw_dmg = ATK - DEF, nhân hệ số kháng (RES) và tương khắc
thuộc tính (TypeChart). Đảm bảo sát thương tối thiểu không thấp hơn 5% ATK.
"""

static func calculate_damage(attacker: Entity, defender: Entity) -> int:
	"""
	Tính toán lượng sát thương thực tế mà mục tiêu sẽ nhận.

	Công thức tính toán bao gồm:
	- Sát thương thô: max(0, ATK - DEF).
	- Giảm trừ theo kháng: raw * (1 - RES/100).
	- Nhân hệ số tương khắc thuộc tính từ TypeChart.
	- Sát thương tối thiểu: 5% ATK của người tấn công.

	- attacker: Thực thể thực hiện tấn công (Entity).
	- defender: Thực thể nhận sát thương (Entity).
	- Return: Lượng sát thương cuối cùng sau khi áp dụng toàn bộ hệ số (int).
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
