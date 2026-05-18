extends Entity
class_name Guard

"""
Tóm tắt: Định nghĩa lớp kẻ địch Guard (Vệ binh tuần tra cảng).

Chức năng chính:
- Khởi tạo chỉ số của lính gác (HP và phòng thủ khá).
- Thực thi kỹ năng [Trấn Áp]: Tấn công vật lý có tỷ lệ làm choáng (Stun) mục tiêu.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Lính Cảng"
	max_hp = 250
	current_hp = 250
	atk = 75
	defense = 40
	res = 10
	spd = 95
	type = "Mysterious"
	is_character = false
	
	skills = [
		{"name": "Trấn Áp", "method": "suppress", "cooldown_turns": 2, "target": "enemy"}
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func suppress(target: Entity):
	# [Trấn Áp]: Tấn công vật lý + 30% tỷ lệ gây Stun 1 lượt.
	print(entity_name, " sử dụng [Trấn Áp]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	if randf() < 0.3:
		print(entity_name, " đã làm choáng mục tiêu!")
		target.add_status({"type": "Stun", "duration": 1})
