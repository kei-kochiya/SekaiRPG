extends Entity
class_name WarehouseWorker

"""
Tóm tắt: Định nghĩa lớp kẻ địch WarehouseWorker (Nhân viên kho hàng biến chất).

Chức năng chính:
- Khởi tạo chỉ số với phòng thủ cao.
- Thực thi kỹ năng [Ném Thùng Hàng]: Tấn công vật lý đơn mục tiêu.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Nhân Viên Kho"
	max_hp = 100
	current_hp = 100
	atk = 40
	defense = 30
	res = 5
	spd = 90
	type = "Cool"
	is_character = false
	
	skills = [
		{"name": "Ném Thùng Hàng", "method": "throw_box", "cooldown_turns": 2, "target": "enemy"}
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func throw_box(target: Entity):
	# [Ném Thùng Hàng]: Tấn công vật lý đơn mục tiêu.
	print(entity_name, " ném một thùng hàng nặng vào ", target.entity_name, "!")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)

func get_portrait_path() -> String:
	return "res://Assets/Person/warehouse_worker.svg"
