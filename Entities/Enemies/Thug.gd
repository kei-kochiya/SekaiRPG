extends Entity
class_name Thug

"""
Tóm tắt: Định nghĩa lớp kẻ địch Thug (Giang Hồ).

Chức năng chính:
- Khởi tạo chỉ số trung bình, xuất hiện trong các sự kiện đường phố.
- Thực thi kỹ năng [Chém Ngang]: Tấn công vật lý, luôn kèm Chảy Máu (Bleed) 2 lượt.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Giang Hồ"
	max_hp = 120
	current_hp = 120
	atk = 55
	defense = 25
	res = 5
	spd = 95
	type = "Happy"
	is_character = false
	
	skills = [
		{"name": "Chém Ngang", "method": "slash_attack", "cooldown_turns": 1, "target": "enemy"}
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func slash_attack(target: Entity):
	# [Chém Ngang]: Tấn công vật lý gây sát thương.
	print(entity_name, " vung dao chém!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	
	# Luôn gây Bleed nhẹ (2 lượt)
	target.add_status({"type": "Bleed", "duration": 2})

func get_portrait_path() -> String:
	return "res://Assets/Person/thug.svg"
