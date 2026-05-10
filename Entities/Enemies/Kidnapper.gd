extends Entity
class_name Kidnapper

"""
Kidnapper: Kẻ bắt cóc xuất hiện trong Prologue và Warehouse.

Đây là loại kẻ địch cơ bản nhất, phục vụ việc giới thiệu cơ chế chiến đấu. 
Chỉ có các kỹ năng tấn công vật lý đơn giản.
"""

func _init():
	entity_name = "Kẻ Bắt Cóc"
	max_hp = 80
	current_hp = 80
	atk = 40
	defense = 20
	res = 0
	spd = 80
	type = "None"
	is_character = false
	
	skills = [
		{"name": "Đâm Lén", "method": "basic_attack", "cooldown_turns": 1, "target": "enemy"}
	]

func basic_attack(target: Entity):
	"""
	[Đâm Lén]: Đòn tấn công vật lý cơ bản.

	Args:
		target (Entity): Mục tiêu bị tấn công.
	"""
	print(entity_name, " đâm lén!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
