extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Dựng thử từng Map overworld (chạy _ready ở trạng thái game mới) để bắt lỗi khởi tạo.
Các map tự dựng nội dung bằng code nên không scene nào khác chạm tới đoạn này.
"""

const MAP_DIR = "res://Maps/"

func _map_scenes() -> Array:
	var out: Array = []
	for sub in DirAccess.get_directories_at(MAP_DIR):
		for file in DirAccess.get_files_at(MAP_DIR.path_join(sub)):
			if file.ends_with("Map.tscn"):
				out.append(MAP_DIR.path_join(sub).path_join(file))
	out.sort()
	return out

func test_every_map_builds_content():
	# Gắn vào scene đang chạy (TestRunner), không phải root: root đang bận dựng các con khi suite này chạy.
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var scenes := _map_scenes()
	assert_gt(scenes.size(), 9, "Found the overworld maps")
	for path in scenes:
		GameManager.reset_game()
		GameManager.is_training_mode = path.contains("Training") # Map luyện tập tự thoát nếu không ở chế độ luyện tập
		GameManager.training_participants = ["Ichika"]
		var map: Node = load(path).instantiate()
		root.add_child(map)
		assert_gt(map.get_child_count(), 0, "Map builds content: " + path)
		assert_true(map.find_child("OverworldPlayer", true, false) != null or map.get_script() != null, "Map is playable: " + path)
		root.remove_child(map)
		map.free()
	# Một số map mở hội thoại ngay khi vào; trả trạng thái về như cũ cho các suite sau.
	DialogueManager.active = false
	DialogueManager.visible = false
	GameManager.end_dialogue()
	GameManager.reset_game()
