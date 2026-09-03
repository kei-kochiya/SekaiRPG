extends Entity
class_name Terrorist

"""
Tóm tắt: Định nghĩa lớp kẻ địch Terrorist (Khủng Bố).

Chức năng chính:
- Khởi tạo chỉ số trung bình, không cung cấp điểm kinh nghiệm (gives_exp = false).
- Thực thi kỹ năng [Xả Súng]: Tấn công liên thanh kèm xác suất gây Chảy Máu (Bleed).
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Khủng Bố"
	max_hp = 200
	current_hp = 200
	atk = 75
	defense = 35
	res = 10
	spd = 98
	type = "Cute"
	is_character = false
	gives_exp = false
	
	skills = [
		{"name": "Xả Súng", "method": "gunshot", "cooldown_turns": 1, "target": "enemy"}
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func gunshot(target: Entity):
	print(entity_name, " nổ súng liên thanh vào mục tiêu!")
	var dmg = DamageCalculator.calculate_damage(self, target, 1.1)
	target.take_damage(dmg)
	
	# Thêm tỷ lệ gây Bleed
	if target.has_method("add_status") and randf() < 0.5:
		target.add_status({"type": "Bleed", "duration": 2})

func get_portrait_path() -> String:
	return "res://Assets/Person/terrorist.png"
