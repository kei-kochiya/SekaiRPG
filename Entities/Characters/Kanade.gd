extends Entity
class_name Kanade

"""
Tóm tắt: Định nghĩa nhân vật Kanade (Hệ Cool), quản lý chỉ số và bộ kỹ năng chiến đấu.

Chức năng chính:
- Khởi tạo các chỉ số sức mạnh cơ bản (HP, ATK, DEF, SPD) và danh sách kỹ năng bùng nổ sát thương.
- Thực thi logic kỹ năng [Tuyệt Âm Phân Rã] và [Giọng Ca Vô Thanh]: Gây sát thương kèm Làm Choáng (Stun).
- Thực thi logic tuyệt kỹ [Final Requiem]: Sát thương cực lớn (Pure Damage) và Stun kéo dài.
- Ghi đè hàm `take_damage` để áp dụng cơ chế nội tại: Có tỷ lệ chuyển hướng một nửa sát thương nhận vào sang đồng minh ngẫu nhiên.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Kanade"
	max_hp = 110
	current_hp = 110
	atk = 200
	defense = 30
	res = 5
	spd = 110
	type = "Cool"
	is_character = true
	
	skills = [
		{"name": "Tuyệt Âm Phân Rã", "method": "resonance", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh.\nTỷ lệ: 150% ATK."},
		{"name": "Giọng Ca Vô Thanh", "method": "soundless_voice", "cooldown_turns": 3, "target": "enemy", "details": "Gây sát thương và Làm choáng (Stun) trong 1 lượt.\nTỷ lệ: 100% ATK."},
		{"name": "Final Requiem", "method": "salvation_song", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Sát thương diện rộng xuyên thấu (Pure DMG) và Làm choáng 2 lượt.\nTỷ lệ: 350% ATK."},
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func resonance(target: Entity):
	# [Tuyệt Âm Phân Rã]: Đòn đơn 150% ATK vật lý.
	print(entity_name, " ngân lên [Tuyệt Âm Phân Rã]!")
	var scaled_dmg = DamageCalculator.calculate_damage(self, target, 1.5)
	target.take_damage(scaled_dmg)

func soundless_voice(target: Entity):
	# [Giọng Ca Vô Thanh]: Đòn đơn vật lý + Stun 1 lượt.
	print(entity_name, " bóp nghẹt bằng [Giọng Ca Vô Thanh]...")
	var dmg = DamageCalculator.calculate_damage(self, target, 1.0)
	target.take_damage(dmg)
	target.add_status({"type": "Stun", "duration": 1})

func salvation_song(target: Entity):
	# [Final Requiem]: Tuyệt kỹ - Pure DMG 350% ATK + Stun 2 lượt.
	print(entity_name, " bùng nổ với [Final Requiem]!")
	var massive_dmg = DamageCalculator.calculate_damage(self, target, 3.5)
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Stun", "duration": 2})

# ── Ghi Đè Logic Chiến Đấu ─────────────────────────────────────────────────

func take_damage(amount: int, damage_type: String = "physical", is_crit: bool = false) -> bool:
	"""
	Xử lý nhận sát thương với cơ chế Chuyển hướng (Deflect).
	
	Args:
		amount (int): Lượng sát thương gốc.
		damage_type (String): Loại sát thương.
		is_crit (bool): Có phải đòn đánh chí mạng không.
	Returns: 
		bool: True nếu Kanade bị hạ gục, ngược lại False.
	"""
	if randf() < 0.20:
		print("[DEFLECT] Kanade bẻ cong đường tấn công!")
		var halved_dmg = int(amount * 0.5)
		var alive_allies = allies.filter(func(a): return a != self and a.current_hp > 0)
		if not alive_allies.is_empty():
			var transfer_target = alive_allies[randi() % alive_allies.size()]
			transfer_target.take_damage(halved_dmg, damage_type, is_crit)
			return super.take_damage(0, damage_type, false)
	
	return super.take_damage(amount, damage_type, is_crit)
