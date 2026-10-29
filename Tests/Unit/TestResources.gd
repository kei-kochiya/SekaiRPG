extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra mọi script, scene và resource trong dự án đều nạp được (bắt lỗi cú pháp/đường dẫn hỏng).
"""

const SKIP_DIRS = ["addons", "screenshots", "tools", "Export"]

func test_all_scripts_and_scenes_load():
	var paths: Array = []
	_collect("res://", paths)
	assert_gt(paths.size(), 100, "Found project resources to check")
	for path in paths:
		var res = ResourceLoader.load(path)
		assert_true(res != null, "Loads: " + path)
		if res is GDScript:
			assert_true(res.can_instantiate() or res.is_abstract(), "Script compiles: " + path)

func _collect(dir_path: String, out: Array):
	for file in DirAccess.get_files_at(dir_path):
		if file.get_extension() in ["gd", "tscn", "tres"]:
			out.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		if sub.begins_with(".") or (dir_path == "res://" and sub in SKIP_DIRS):
			continue
		_collect(dir_path.path_join(sub), out)
