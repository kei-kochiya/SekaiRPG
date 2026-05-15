extends Entity
class_name Ichika

"""
Ichika: Nhân vật hệ Pure, thiên hướng sát thương vật lý mạnh và kỹ năng tự tổn hại.

Lối chơi của Ichika tập trung vào việc gây sát thương lớn và áp dụng hiệu ứng 
Chảy máu (Bleed). Tuyệt kỹ của cô có khả năng bỏ qua phòng thủ nhưng đổi lại 
bằng việc tiêu tốn sinh lực của bản thân.
"""

func _init():
	# Khởi tạo chỉ số cơ bản cho Ichika.
	entity_name = "Ichika"
	max_hp = 175
	current_hp = 175
	atk = 150
	defense = 90
	res = 20
	spd = 70
	type = "Pure"
	is_character = true
	
	skills = [
		{"name": "Xuyên Tâm Kích", "method": "piercing_chord", "cooldown_turns": 2, "target": "enemy", "details": "Lướt nhanh và đâm xuyên mục tiêu. Gây 150% ATK DMG và 1 stack Bleed."},
		{"name": "Âm Vang Đồng Điệu", "method": "resonant_edge", "cooldown_turns": 3, "target": "self", "details": "Tăng 40 SPD và cập nhật thứ tự hành động."},
		{"name": "Ảnh Sát", "method": "shadow_strike", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Chém chí mạng (400% ATK). Kích nổ tất cả stack Bleed để gây thêm Sát thương chuẩn (True Damage)."},
	]

func can_use_skill(skill_name: String) -> bool:
	# Kiểm tra điều kiện thời gian hồi chiêu của kỹ năng.
	return CooldownManager.is_skill_ready(self , skill_name)

func piercing_chord(target: Entity):
	# [Xuyên Tâm Kích]: Đòn đơn vật lý + 1 stack Bleed (3 lượt).
	print(entity_name, " sử dụng [Xuyên Tâm Kích] lên ", target.entity_name)
	var dmg = DamageCalculator.calculate_damage(self , target, 1.5)
	target.take_damage(dmg)
	target.add_status({"type": "Bleed", "duration": 3})

func resonant_edge(_target: Entity):
	# [Âm Vang Đồng Điệu]: Tăng 40 SPD cho bản thân.
	print(entity_name, " kích hoạt [Âm Vang Đồng Điệu]! Tăng tốc độ.")
	self.spd += 40

func shadow_strike(target: Entity):
	# [Ảnh Sát]: Tuyệt kỹ - kích nổ toàn bộ Bleed stacks, gây True Damage theo số stack.
	print(entity_name, " giáng xuống [Ảnh Sát]!")
	var bleed_stacks = target.get_status_count("Bleed")
	var base_dmg = DamageCalculator.calculate_damage(self , target, 4.0)
	var bonus_dmg = bleed_stacks * int(self.atk * 0.5)
	target.remove_all_status_type("Bleed")
	target.take_damage(base_dmg + bonus_dmg, "pure")
