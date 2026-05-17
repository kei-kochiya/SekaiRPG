extends Entity
class_name Terrorist

"""
Terrorist: Kẻ địch Khủng Bố xuất hiện trong sự kiện đường phố.
"""

func _init():
	entity_name = "Khủng Bố"
	max_hp = 200
	current_hp = 200
	atk = 75
	defense = 35
	res = 10
	spd = 98
	type = "None"
	is_character = false
	gives_exp = false
	
	skills = [
		{"name": "Xả Súng", "method": "gunshot", "cooldown_turns": 1, "target": "enemy"}
	]

func gunshot(target: Entity):
	print(entity_name, " nổ súng liên thanh vào mục tiêu!")
	var dmg = DamageCalculator.calculate_damage(self, target, 1.1)
	target.take_damage(dmg)
	
	# Thêm tỷ lệ gây Bleed
	if target.has_method("add_status") and randf() < 0.5:
		target.add_status({"type": "Bleed", "duration": 2})
