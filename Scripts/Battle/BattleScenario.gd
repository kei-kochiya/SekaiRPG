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

func on_before_action(_main: Node, _actor: Entity):
	"""Gọi (có thể await) ngay trước khi một thực thể chọn/thực hiện hành động, vd. để chèn thoại giữa trận."""
	pass

func skips_turn(_main: Node, _actor: Entity) -> bool:
	"""true: thực thể này bị bỏ qua lượt (đóng băng, không chống cự...)."""
	return false

func on_turn_skipped(_main: Node, _actor: Entity):
	"""Gọi (có thể await) khi một lượt bị bỏ qua, để hiện thông báo/thoại."""
	pass

func get_forced_action(_main: Node, _actor: Entity) -> Dictionary:
	"""Trả về {"action": String, "target": Entity} nếu hành động của người chơi bị ép buộc; rỗng nếu không."""
	return {}

func get_allowed_actions(_main: Node, _actor: Entity) -> Array:
	"""Danh sách hành động người chơi được chọn ("attack" hoặc tên method kỹ năng); rỗng = không giới hạn."""
	return []

# Phát một đoạn hội thoại và chờ tới khi xong (dùng trong các hook có thể await).
func say_lines(key: String):
	var done := [false]
	DialogueManager.play_dialogue(DialogueLoader.get_lines(key), func(): done[0] = true)
	while not done[0]:
		await (Engine.get_main_loop() as SceneTree).process_frame

func on_action_executed(_main: Node, _actor: Entity, _action: String, _target: Entity):
	"""Gọi sau khi một hành động (đòn đánh/kỹ năng/vật phẩm) được thực thi xong."""
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
