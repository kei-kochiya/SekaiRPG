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

# Xử lý tương tác với NPC
func handle_npc_interaction(_npc_name: String):
	pass

# Trả về text hiển thị trên HUD Quest
func get_quest_text() -> String:
	return ""

# (Tùy chọn) Logic xử lý khi rời khỏi Map
func on_stage_exit():
	pass
