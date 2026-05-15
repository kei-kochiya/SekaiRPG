extends Node
class_name BattleScenario

"""
BattleScenario: Lớp cơ sở cho các kịch bản trận đấu đặc biệt.

Các phương thức trong lớp này được thiết kế để Main.gd gọi vào tại các thời điểm 
quan trọng trong vòng lặp chiến đấu, cho phép tùy biến logic mà không cần 
sửa đổi code cốt lõi của Engine.
"""

func on_start(_main: Node):
	"""Gọi khi trận đấu bắt đầu."""
	pass

func on_turn_start(_main: Node, _actor: Entity):
	"""Gọi khi một thực thể bắt đầu lượt."""
	pass

func on_turn_end(_main: Node, _actor: Entity):
	"""Gọi khi một thực thể kết thúc lượt."""
	pass

func on_entity_died(_main: Node, _entity: Entity):
	"""Gọi khi có bất kỳ thực thể nào tử trận."""
	pass

func check_battle_end(_main: Node) -> bool:
	"""
	Kiểm tra điều kiện kết thúc trận đấu.
	Trả về true nếu kịch bản đã xử lý việc kết thúc trận đấu.
	"""
	return false

func get_victory_status(_main: Node) -> bool:
	"""Xác định kết quả thắng hay thua."""
	return false

func on_battle_completed(_main: Node, _is_victory: bool):
	"""Gọi sau khi trận đấu đã được xác định kết quả."""
	pass
