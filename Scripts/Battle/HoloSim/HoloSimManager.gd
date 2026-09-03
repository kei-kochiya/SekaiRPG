extends Node

"""
Tóm tắt: HoloSimManager điều phối toàn bộ trạng thái của chế độ leo tháp Roguelite (Holo-Simulation).

Chức năng chính:
- Quản lý tiến trình 10 tầng thử thách (Floors), danh sách Phước Lành đã thu thập (Active Blessings).
- Áp dụng các hiệu ứng bị động của Phước Lành lên chỉ số và hành vi của đội hình.
- Cung cấp cấu hình kẻ địch cho từng tầng mô phỏng.
- Lưu trữ điểm kỷ lục (High Score) của người chơi.
"""

var is_sim_active: bool = false
var current_floor: int = 1
const MAX_FLOORS: int = 10

var active_blessings: Array = []
var high_score_floor: int = 0

func start_new_run():
	is_sim_active = true
	current_floor = 1
	active_blessings.clear()
	print("[HoloSim] Bắt đầu lượt leo tháp Mô Phỏng mới từ Tầng 1!")

func advance_floor():
	current_floor += 1
	if current_floor > high_score_floor:
		high_score_floor = current_floor
	print("[HoloSim] Tiến tới Tầng ", current_floor)

func has_blessing(b_id: String) -> bool:
	return active_blessings.has(b_id)

func add_blessing(b_id: String):
	if not active_blessings.has(b_id):
		active_blessings.append(b_id)
		print("[HoloSim] Đã nhận Phước Lành: ", b_id)

func apply_blessings_to_team(team: Array):
	"""Áp dụng các buff chỉ số khởi đầu của Phước Lành lên đội hình."""
	for member in team:
		if member == null: continue
		if has_blessing("blessing_speed"):
			member.spd += 35
		if has_blessing("blessing_crit"):
			member.crit_rate = member.get("crit_rate") + 0.25
			member.crit_dmg = member.get("crit_dmg") + 0.50

func is_rest_floor(floor_num: int) -> bool:
	return floor_num == 4 or floor_num == 9

func get_floor_info(floor_num: int) -> Dictionary:
	match floor_num:
		1:
			return {
				"name": "Tầng 1: Toán Cướp Mở Đầu",
				"is_rest": false,
				"enemies": ["Kidnapper", "Kidnapper"],
				"enemy_levels": [5, 5]
			}
		2:
			return {
				"name": "Tầng 2: Nhân Viên Kho Nổi Loạn",
				"is_rest": false,
				"enemies": ["Nhân Viên Kho", "Nhân Viên Kho"],
				"enemy_levels": [8, 8]
			}
		3:
			return {
				"name": "Tầng 3: Đội Tuần Tra",
				"is_rest": false,
				"enemies": ["Lính Cảng", "Lính Cảng", "Kidnapper"],
				"enemy_levels": [12, 12, 10]
			}
		4:
			return {
				"name": "Tầng 4: Trạm Nghỉ Ngơi (Hồi Phục)",
				"is_rest": true,
				"enemies": [],
				"enemy_levels": []
			}
		5:
			return {
				"name": "Tầng 5: Tinh Anh Du Côn (Mini-Boss)",
				"is_rest": false,
				"enemies": ["Thug", "Thug", "Kidnapper"],
				"enemy_levels": [16, 16, 14]
			}
		6:
			return {
				"name": "Tầng 6: Toán Khủng Bố Đột Kích",
				"is_rest": false,
				"enemies": ["Terrorist", "Terrorist"],
				"enemy_levels": [20, 20]
			}
		7:
			return {
				"name": "Tầng 7: Đội Giáp Thép",
				"is_rest": false,
				"enemies": ["Lính Cảng", "Lính Cảng", "Terrorist"],
				"enemy_levels": [24, 24, 22]
			}
		8:
			return {
				"name": "Tầng 8: Biệt Đội Cảm Tử",
				"is_rest": false,
				"enemies": ["Terrorist", "Nhân Viên Kho", "Lính Cảng"],
				"enemy_levels": [28, 28, 28]
			}
		9:
			return {
				"name": "Tầng 9: Trạm Tiếp Tế Tối Hậu",
				"is_rest": true,
				"enemies": [],
				"enemy_levels": []
			}
		10:
			return {
				"name": "Tầng 10: TRÙM CUỐI MÔ PHỎNG (SUPER CAPTAIN)",
				"is_rest": false,
				"enemies": ["Đội Trưởng (BOSS)", "Lính Cảng", "Lính Cảng"],
				"enemy_levels": [35, 30, 30]
			}
		_:
			return {
				"name": "Tầng Vô Danh",
				"is_rest": false,
				"enemies": ["Lính Cảng"],
				"enemy_levels": [15]
			}
