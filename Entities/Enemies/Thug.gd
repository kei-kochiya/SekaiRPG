extends Entity
class_name Thug

"""
Thug (Giang Hồ): Kẻ địch xuất hiện tại Quán Cafe.

Sức mạnh trung bình, có khả năng gây chảy máu (Bleed) nhẹ.
"""

func _init():
	entity_name = "Giang Hồ"
	max_hp = 120
	current_hp = 120
	atk = 55
	defense = 25
	res = 5
	spd = 95
	type = "None"
	is_character = false
	
	skills = [
		{"name": "Chém Ngang", "method": "slash_attack", "cooldown_turns": 1, "target": "enemy"}
	]

func slash_attack(target: Entity):
	# [Chém Ngang]: Tấn công vật lý gây sát thương.
	print(entity_name, " vung dao chém!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	
	# Xác suất gây Bleed nhẹ (tận dụng hệ thống status nếu có)
	if target.has_method("add_status"):
		target.add_status({"type": "Bleed", "duration": 2})
