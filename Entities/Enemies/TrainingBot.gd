extends Entity
class_name TrainingBot

"""
Tóm tắt: Định nghĩa lớp kẻ địch TrainingBot (Robot Huấn Luyện).

Chức năng chính:
- Khởi tạo chỉ số trung bình dùng để làm "bia tập bắn" trong Safehouse.
- Không có kỹ năng kích hoạt, chỉ nhận đòn để người chơi thử nghiệm sát thương.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


func _init():
	entity_name = "Robot Huấn Luyện"
	max_hp = 100
	current_hp = 100
	atk = 45
	defense = 25
	res = 5
	spd = 90
	type = "Mysterious"
	is_character = false

func get_portrait_path() -> String:
	return "res://Assets/Person/warehouse_worker.png"
