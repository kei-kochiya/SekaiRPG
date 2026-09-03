extends Entity
class_name CyberJammer

"""
Tóm tắt: Kẻ địch Chuyên Viên Nhiễu Sóng (Cyber Jammer).

Đặc điểm:
- Hệ: Happy (Khắc chế Cute, Yếu trước Cool).
- Quấy nhiễu điện tử: Khóa kỹ năng đối thủ hoặc cường hóa hành động cho đồng minh.
- Kỹ năng: Hack Nhiễu Hệ Thống (System Hack) và Cường Hóa Tác Chiến (Adrenaline Hack).
"""

func _init():
	entity_name = "Chuyên Viên Nhiễu Sóng"
	max_hp = 260
	current_hp = 260
	atk = 70
	defense = 30
	res = 20
	spd = 115
	type = "Happy"
	is_character = false
	max_break_gauge = 100
	break_gauge = 100
	
	skills = [
		{"name": "Hack Nhiễu Sóng", "method": "system_hack", "cooldown_turns": 2, "target": "enemy"},
		{"name": "Xung Trợ Lực Đồng Minh", "method": "overclock_ally", "cooldown_turns": 3, "target": "ally"}
	]

func system_hack(target: Variant = null):
	print(entity_name, " tung đòn [Hack Nhiễu Sóng]!")
	if target and target.current_hp > 0:
		var dmg = DamageCalculator.calculate_damage(self, target) * 0.8
		target.take_damage(int(dmg), "tech")
		target.add_status({"type": "Stun", "duration": 1})
		print("   -> Tê liệt hệ thống của ", target.entity_name)

func overclock_ally(target: Variant = null):
	var ally_target = target
	if not ally_target or ally_target.current_hp <= 0:
		for a in allies:
			if a != self and a.current_hp > 0:
				ally_target = a
				break
	if not ally_target:
		ally_target = self
		
	print(entity_name, " phát [Xung Trợ Lực Đồng Minh] lên ", ally_target.entity_name)
	ally_target.atk += 25
	ally_target.action_gauge = min(10000.0, ally_target.action_gauge + 3000.0)

func get_portrait_path() -> String:
	return "res://Assets/Icons/poison.png"
