extends Entity
class_name Honami

"""
Tóm tắt: Định nghĩa nhân vật Honami (Hệ Pure), quản lý chỉ số và bộ kỹ năng chiến đấu.

Chức năng chính:
- Khởi tạo các chỉ số sức mạnh cơ bản (HP, ATK, DEF, SPD) và danh sách kỹ năng (thiên hướng phòng thủ/hồi phục).
- Ghi đè hàm nhận sát thương `take_damage` để kích hoạt trạng thái bất tử (miễn sát thương) trong các màn cốt truyện đặc biệt.
- Thực thi logic kỹ năng [Vệt Cắt Xót Thương]: Gây sát thương diện rộng.
- Thực thi logic kỹ năng [Điểm Tựa Vững Chắc]: Thanh tẩy debuff và hồi máu mạnh cho mục tiêu chỉ định.
- Thực thi logic tuyệt kỹ [Án Tử Bình Yên]: Xuyên giáp mạnh, nếu kết liễu sẽ hồi nhiều máu cho toàn đội, nếu không kết liễu sẽ Làm Choáng (Stun) và hồi ít máu.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


@export var is_harbor: bool = false

func _init():
	entity_name = "Honami"
	max_hp = 600
	current_hp = 600
	atk = 90
	defense = 140
	res = 50
	spd = 120
	type = "Pure"
	is_character = true
	
	skills = [
		{"name": "Vệt Cắt Xót Thương", "method": "merciful_cleave", "cooldown_turns": 2, "target": "all_enemies", "details": "Vung vũ khí hình bán nguyệt, gây sát thương AoE lên toàn bộ kẻ địch."},
		{"name": "Điểm Tựa Vững Chắc", "method": "rearguard_stance", "cooldown_turns": 3, "target": "ally", "details": "Xóa toàn bộ debuff cho bản thân và 1 đồng minh, sau đó hồi máu cho cả hai."},
		{"name": "Án Tử Bình Yên", "method": "painless_execution", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Đập tan mục tiêu, bỏ qua 50% DEF. Hồi máu toàn đội dựa trên kết quả."},
	]

# ── Ghi Đè Logic Chiến Đấu ─────────────────────────────────────────────────

func take_damage(amount: int, damage_type: String = "physical", is_crit: bool = false) -> bool:
	# Khi is_harbor = true (trong trận Harbor): miễn tổn thương hoàn toàn.
	if is_harbor:
		damage_received.emit(0, damage_type)
		damage_received_detailed.emit(0, damage_type, false, false)
		return false
	return super.take_damage(amount, damage_type, is_crit)

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func merciful_cleave(_target: Entity):
	# [Vệt Cắt Xót Thương]: AoE 80% ATK cho toàn bộ kẻ địch còn sống.
	print(entity_name, " vung vũ khí: [Vệt Cắt Xót Thương]!")
	for enemy in enemies:
		if enemy.current_hp > 0:
			var dmg = DamageCalculator.calculate_damage(self, enemy, 0.8)
			enemy.take_damage(dmg)

func rearguard_stance(target: Entity):
	# [Điểm Tựa Vững Chắc]: Xóa debuff + hồi 30% max_hp cho bản thân và 1 đồng minh.
	print(entity_name, " thiết lập [Điểm Tựa Vững Chắc] cho ", target.entity_name)
	self.clear_all_debuffs()
	target.clear_all_debuffs()
	var heal_amount = int(self.max_hp * 0.3)
	self.heal(heal_amount)
	target.heal(heal_amount)

func painless_execution(target: Entity):
	# [Án Tử Bình Yên]: Tuyệt kỹ - bỏ qua 50% DEF. Tiêu diệt → hồi 50% HP đội; sống sót → Stun + hồi 25%.
	print(entity_name, " giáng xuống [Án Tử Bình Yên]!")
	var original_def = target.defense
	target.defense = int(target.defense * 0.5)
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.defense = original_def
	
	var killed = target.take_damage(dmg)
	
	if killed:
		print("Kẻ địch gục ngã! Hồi 50% HP toàn đội.")
		for ally in allies:
			ally.heal(int(self.max_hp * 0.5))
	else:
		print("Kẻ địch còn sống. Gây Stun và hồi 25% HP toàn đội.")
		target.add_status({"type": "Stun", "duration": 1})
		for ally in allies:
			ally.heal(int(self.max_hp * 0.25))
