class_name QuestDefinition
extends Resource

"""
Tóm tắt: QuestDefinition là lớp Resource lưu trữ siêu dữ liệu cho một nhiệm vụ trong game.

Chức năng:
- Định danh nhiệm vụ (quest_id, quest_name, arc_name, description).
- Liên kết với map scene vật lý (linked_map_scene) mà không cần di chuyển file scene.
- Chỉ định stage tương ứng trong BaseMap nếu là quest xuất phát từ Safehouse (entry_stage_script).
- Chỉ định Scenario chiến đấu và các file hội thoại liên quan.
- Xác định điều kiện StoryState trước (pre_conditions) và sau (post_conditions) khi hoàn thành.
"""

@export var quest_id: String = ""
@export var quest_name: String = ""
@export var arc_name: String = ""
@export_multiline var description: String = ""
@export_file("*.tscn") var linked_map_scene: String = ""
@export var entry_stage_script: String = ""
@export var battle_scenario_class: String = ""
@export var dialogue_files: Array[String] = []
@export var pre_conditions: Dictionary = {}
@export var post_conditions: Dictionary = {}
