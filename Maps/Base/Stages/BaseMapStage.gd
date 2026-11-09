extends Node
class_name BaseMapStage

"""
BaseMapStage: Lớp cơ sở cho các kịch bản diễn ra tại BaseMap.
Mỗi Stage quản lý vị trí NPC, hội thoại và logic nhiệm vụ riêng biệt.
"""

# Tham chiếu ngược lại BaseMap để điều khiển visual
var map: Node2D

func setup(p_map: Node2D):
	map = p_map

# Trả về danh sách vị trí NPC: { "Name": Vector2 }
func get_npc_positions() -> Dictionary:
	return {}

# Logic chạy ngay khi vào Map
func on_stage_start():
	pass

# Trả về màu ánh sáng của bản đồ (Color.WHITE = bình thường, tối hơn = ban đêm)
# Được gọi TRƯỚC fade_in để tránh flash sáng
func get_scene_lighting() -> Color:
	return Color.WHITE

# Xác định bài nhạc nền sẽ phát ở Stage này
func get_bgm_track() -> String:
	return "base"

# Xử lý tương tác với NPC
func handle_npc_interaction(_npc_name: String):
	pass

# Trả về text hiển thị trên HUD Quest
func get_quest_text() -> String:
	return ""

# Đội hình chính của cốt truyện (Honami chỉ là người giúp đỡ nên không có trong bảng nâng cấp ở giai đoạn này)
const MAIN_TEAM := ["Ichika", "Kanade", "Mafuyu", "Ena", "Mizuki"]

# Mở bảng nâng cấp chỉ số cho các thành viên (mặc định cả đội chính); ai đã chết trong cốt truyện thì bị bỏ qua
func open_upgrade_ui(names: Array = MAIN_TEAM):
	var p_list: Array[Entity] = []
	for member in names:
		if GameManager.is_member_alive_in_story(member):
			p_list.append(GameManager.get_party_member(member))
	UpgradeUI.show_ui(p_list)

# Trả về true nếu stage tự xử lý việc rời map (vd. khóa cửa trong cảnh tự chạy); false = BaseMap tự xử lý
func handle_exit() -> bool:
	return false
