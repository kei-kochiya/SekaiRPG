extends Entity
class_name Sniper

"""
Tóm tắt: Kẻ địch Xạ Thủ Bắn Tỉa Ngầm (Sniper).

Đặc điểm:
- Hệ: Mysterious (Khắc chế Pure, Yếu trước Pure).
- Sát thương đơn mục tiêu cực mạnh, có tỷ lệ chí mạng cao (Crit Rate 35%).
- Kỹ năng: Bắn Tỉa Chí Mạng (Headshot) và Lựu Đạn Khói (Smoke Screen).
"""

func _init():
	entity_name = "Xạ Thủ Bắn Tỉa"
	max_hp = 220
	current_hp = 220
	atk = 110
	defense = 25
	res = 10
	spd = 105
	type = "Mysterious"
	is_character = false
	crit_rate = 0.35
	crit_dmg = 2.0
	max_break_gauge = 90
	break_gauge = 90
	
	skills = [
		{"name": "Bắn Tỉa Trúng Đích", "method": "headshot", "cooldown_turns": 2, "target": "enemy"},
		{"name": "Lựu Đạn Khói", "method": "smoke_screen", "cooldown_turns": 3, "target": "self"}
	]

func headshot(target: Variant = null):
	print(entity_name, " ngắm bắn phát đạn tử thần [Bắn Tỉa Trúng Đích]!")
	if target and target.current_hp > 0:
		var dmg = DamageCalculator.calculate_damage(self, target) * 1.3
		target.take_damage(int(dmg), "physical")
		target.add_status({"type": "Bleed", "duration": 2})
		target.add_status({"type": "Bleed", "duration": 2})

func smoke_screen(_target: Variant = null):
	print(entity_name, " tung [Lựu Đạn Khói] che khuất tầm nhìn!")
	defense += 30
	for ally in allies:
		if ally.current_hp > 0:
			ally.defense += 20

func get_portrait_path() -> String:
	return "res://Assets/Person/thug.png"
