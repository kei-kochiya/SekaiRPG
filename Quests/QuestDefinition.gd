class_name QuestDefinition
extends Resource

"""
Tóm tắt: QuestDefinition là lớp Resource lưu trữ siêu dữ liệu cho một nhiệm vụ trong game.

Chỉ giữ những gì game thật sự đọc: định danh (quest_id), tên hiển thị trong danh sách save (quest_name) và mô tả cho người viết
truyện xem trong Inspector. QuestRegistry.get_current_quest() chọn nhiệm vụ hiện tại theo cờ StoryState nên không lưu điều kiện ở đây
(bản sao điều kiện trong từng .tres từng trôi lệch so với code).
"""

@export var quest_id: String = ""
@export var quest_name: String = ""
@export_multiline var description: String = ""
