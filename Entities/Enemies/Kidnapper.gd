extends Entity
class_name Kidnapper

"""
Tóm tắt: Định nghĩa lớp kẻ địch Kidnapper (Kẻ bắt cóc).

Chức năng chính:
- Khởi tạo chỉ số yếu, phục vụ chủ yếu cho màn chơi hướng dẫn (Prologue).
- Thực thi kỹ năng [Đâm Lén]: Đòn tấn công vật lý cơ bản nhất.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Kẻ Bắt Cóc"
	max_hp = 80
	current_hp = 80
	atk = 40
	defense = 20
	res = 0
	spd = 80
	type = "Happy"
	is_character = false
	
	skills = [
		{"name": "Đâm Lén", "method": "basic_attack", "cooldown_turns": 1, "target": "enemy"}
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func basic_attack(target: Entity):
	# [Đâm Lén]: Tấn công vật lý cơ bản.
	print(entity_name, " đâm lén!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)

func get_portrait_path() -> String:
	return "res://Assets/Person/kidnapper.png"
