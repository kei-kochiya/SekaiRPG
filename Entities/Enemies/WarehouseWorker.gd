extends Entity
class_name WarehouseWorker

"""
WarehouseWorker: Nhân viên kho hàng biến chất.

Loại kẻ địch này có chỉ số phòng thủ và máu cao hơn Robot Huấn Luyện, 
phản ánh tính chất công việc nặng nhọc trong kho.
"""

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

func throw_box(target: Entity):
	# [Ném Thùng Hàng]: Tấn công vật lý + 30% tỷ lệ gây Slow 2 lượt (giảm 20% SPD).
	print(entity_name, " ném một thùng hàng nặng vào ", target.entity_name, "!")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	
	if randf() < 0.3:
		target.add_status({"type": "Slow", "duration": 2, "percent": 0.2})
