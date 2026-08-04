extends Entity
class_name Ichika

"""
Tóm tắt: Định nghĩa nhân vật Ichika (Hệ Pure), quản lý chỉ số và bộ kỹ năng chiến đấu.

Chức năng chính:
- Khởi tạo các chỉ số sức mạnh cơ bản (HP, ATK, DEF, SPD) và danh sách kỹ năng của Ichika.
- Thực thi logic kỹ năng [Xuyên Tâm Kích]: Gây sát thương vật lý mạnh và thêm trạng thái Chảy máu (Bleed).
- Thực thi logic kỹ năng [Âm Vang Đồng Điệu]: Buff tốc độ (SPD) cho bản thân để giành lợi thế lượt đánh.
- Thực thi logic tuyệt kỹ [Ảnh Sát]: Gây sát thương khổng lồ và kích nổ toàn bộ hiệu ứng Bleed trên mục tiêu thành sát thương chuẩn (True Damage).
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
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

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func piercing_chord(target: Entity):
	# [Xuyên Tâm Kích]: Đòn đơn vật lý + 1 stack Bleed (3 lượt).
	print(entity_name, " sử dụng [Xuyên Tâm Kích] lên ", target.entity_name)
	var dmg = DamageCalculator.calculate_damage(self, target, 1.5)
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
	var base_dmg = DamageCalculator.calculate_damage(self, target, 4.0)
	var bonus_dmg = bleed_stacks * int(self.atk * 0.5)
	target.remove_all_status_type("Bleed")
	target.take_damage(base_dmg + bonus_dmg, "pure")
