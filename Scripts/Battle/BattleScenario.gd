extends Node
class_name BattleScenario

"""
Tóm tắt: BattleScenario là lớp cơ sở (Base Class) cho các kịch bản trận đấu đặc biệt.

Chức năng chính:
- Định nghĩa các phương thức ảo (Virtual Methods) như `on_start`, `on_turn_start`, `on_turn_end`, `on_entity_died`.
- Cung cấp điểm nối (hooks) để các kịch bản cốt truyện có thể ghi đè và thực thi logic tùy chỉnh mà không cần sửa đổi Engine trận đấu.
"""

# ── Hooks Vòng Lặp Trận Đấu ────────────────────────────────────────────────


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

# ── Hooks Kết Thúc Trận Đấu ────────────────────────────────────────────────

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
