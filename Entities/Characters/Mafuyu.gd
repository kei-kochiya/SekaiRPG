extends Entity
class_name Mafuyu

"""
Mafuyu: Nhân vật hệ Mysterious, sở hữu chỉ số toàn diện và sát thương diện rộng (AoE).

Lối chơi của Mafuyu tập trung vào việc duy trì sát thương duy trì thông qua 
hiệu ứng Chảy máu (Bleed) và dọn dẹp kẻ địch bằng các đòn đánh diện rộng mạnh mẽ.
"""

func _init():
	entity_name = "Mafuyu"
	max_hp = 500
	current_hp = 500
	atk = 300
	defense = 135
	res = 20
	spd = 150
	type = "Mysterious"
	is_character = true
	
	skills = [
		{"name": "Nhát Chém Bóng Tối", "method": "shadow_strike", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh lên một mục tiêu.\nTỷ lệ: 150% ATK."},
		{"name": "Lời Nói Trống Rỗng", "method": "empty_words", "cooldown_turns": 3, "target": "enemy", "details": "Gây sát thương và gây Chảy máu (Bleed) trong 3 lượt.\nTỷ lệ: 100% ATK."},
		{"name": "Thế Giới Đã Mất", "method": "lost_world", "initial_cooldown": 5, "once_per_battle": true, "target": "all_enemies", "details": "Sát thương AoE xuyên thấu (Pure DMG) và gây Chảy máu diện rộng trong 4 lượt.\nTỷ lệ: 250% ATK."},
	]

func shadow_strike(target: Entity):
	"""
	[Nhát Chém Bóng Tối]: Tấn công đơn mục tiêu mạnh.

	Gây sát thương vật lý tương đương 150% lượng sát thương tính toán cơ bản.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " sử dụng [Nhát Chém Bóng Tối]!")
	var raw_dmg = DamageCalculator.calculate_damage(self , target)
	var scaled_dmg = int(raw_dmg * 1.5)
	target.take_damage(scaled_dmg)

func empty_words(target: Entity):
	"""
	[Lời Nói Trống Rỗng]: Tấn công và gây hiệu ứng xấu.

	Gây sát thương vật lý và áp dụng trạng thái Chảy máu (Bleed) trong 3 lượt.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " mấp máy [Lời Nói Trống Rỗng]...")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	target.add_status({"type": "Bleed", "duration": 3})

func lost_world(_target: Entity):
	"""
	[Thế Giới Đã Mất]: Tuyệt kỹ diện rộng (AoE) của Mafuyu.

	Gây sát thương thuần (Pure Damage) lên toàn bộ kẻ địch (250% ATK) 
	và áp dụng trạng thái Chảy máu (Bleed) diện rộng trong 4 lượt.

	Args:
		_target (Entity): Tham số không sử dụng (kỹ năng tác động toàn đội địch).
	"""
	print(entity_name, " kéo tất cả vào [Thế Giới Đã Mất]!")
	for e in enemies:
		if e.current_hp > 0:
			var multiplier = TypeChart.get_multiplier(self.type, e.type)
			var massive_dmg = int(self.atk * 2.5 * multiplier)
			e.take_damage(massive_dmg, "pure")
			e.add_status({"type": "Bleed", "duration": 4})
