extends Node2D

"""
TestRunner: tự động tìm và chạy mọi suite `Test*.gd` trong Tests/Unit/ (trừ BaseTest).

Chạy: godot --headless res://Tests/TestRunnerScene.tscn
Chỉ chạy vài suite: godot --headless res://Tests/TestRunnerScene.tscn -- TestResources TestCombat
Thoát với exit code 0 nếu tất cả đạt, 1 nếu có lỗi.
"""

const UNIT_DIR = "res://Tests/Unit/"

# Test lưu file thử vào user://saves/ (unit_test_*, zz_capture_*). Nếu một lần chạy trước bị ngắt giữa chừng, các file đó còn lại
# và nút "Tiếp tục" sẽ chọn nhầm chúng làm save mới nhất: dọn sạch trước mỗi lần chạy.
func _sweep_leftover_test_saves():
	var dir := DirAccess.open(SaveManager.SAVES_DIR)
	if dir == null:
		return
	for f in dir.get_files():
		if f.begins_with("unit_test_") or f.begins_with("zz_capture_"):
			dir.remove(f)

func _ready():
	_sweep_leftover_test_saves()
	print("\n" + "=".repeat(65))
	print("       SEKAI RPG — AUTOMATED TEST SUITE")
	print("=".repeat(65))
	
	var suites = _discover_suites()
	
	var total_tests = 0
	var total_passed_assertions = 0
	var total_failed_assertions = 0
	# Suite không nạp/dựng được (lỗi biên dịch, sai tên gọi tên) cũng là thất bại: không được im lặng bỏ qua
	var setup_errors := _setup_errors.size()
	for err in _setup_errors:
		printerr("[FAIL] " + err)
	
	for suite in suites:
		var res = suite.run_all_tests()
		total_tests += res["tests_run"]
		total_passed_assertions += res["passed_assertions"]
		total_failed_assertions += res["failed_assertions"]
		
		var status_str = "[PASS]" if res["failed_assertions"] == 0 else "[FAIL]"
		print("%s %-16s | %d tests | %d assertions" % [
			status_str,
			res["name"],
			res["tests_run"],
			res["passed_assertions"] + res["failed_assertions"]
		])
		
		if not res["failures"].is_empty():
			for f in res["failures"]:
				print("    -> " + f)
				
	print("-".repeat(65))
	print("SUMMARY: %d Test Suites | %d Total Tests | %d Assertions" % [
		suites.size(),
		total_tests,
		total_passed_assertions + total_failed_assertions
	])
	print("ASSERTIONS: %d Passed, %d Failed" % [total_passed_assertions, total_failed_assertions])
	
	if suites.is_empty():
		setup_errors += 1
		printerr("[FAIL] Không có suite nào chạy (tên suite sai hoặc thư mục trống)")
	
	if total_failed_assertions == 0 and setup_errors == 0:
		print("\n>>> ALL TESTS COMPLETED SUCCESSFULLY WITH ZERO ERRORS! <<<\n")
		print("=".repeat(65) + "\n")
		get_tree().quit(0)
	else:
		printerr("\n>>> %d TEST FAILURES DETECTED! <<<\n" % (total_failed_assertions + setup_errors))
		print("=".repeat(65) + "\n")
		get_tree().quit(1)

var _setup_errors: Array = []

func _discover_suites() -> Array:
	var suites = []
	var names = []
	var only := OS.get_cmdline_user_args()
	var available := []
	for file in DirAccess.get_files_at(UNIT_DIR):
		if file.begins_with("Test") and file.ends_with(".gd"):
			available.append(file.get_basename())
			if only.is_empty() or file.get_basename() in only:
				names.append(file)
	for wanted in only:
		if wanted not in available:
			_setup_errors.append("Không có suite tên '%s' trong %s" % [wanted, UNIT_DIR])
	names.sort()
	for file in names:
		var script = load(UNIT_DIR + file)
		var suite = script.new() if script else null
		if suite == null:
			_setup_errors.append("Suite không nạp/dựng được (lỗi biên dịch?): " + file)
		else:
			suites.append(suite)
	return suites
