extends Entity
class_name TrainingBot

"""
TrainingBot: Robot giả lập dùng để luyện tập trong Safehouse.

Loại kẻ địch này được sử dụng trong chế độ luyện tập để người chơi kiểm tra 
sát thương và thăng cấp nhân vật một cách an toàn.
"""

func _init():
	entity_name = "Robot Huấn Luyện"
	max_hp = 100
	current_hp = 100
	atk = 45
	defense = 25
	res = 5
	spd = 90
	type = "None"
	is_character = false
