extends Node2D

"""
TestRunner: tự động tìm và chạy mọi suite `Test*.gd` trong Tests/Unit/ (trừ BaseTest).

Chạy: godot --headless res://Tests/TestRunnerScene.tscn
Chỉ chạy vài suite: godot --headless res://Tests/TestRunnerScene.tscn -- TestResources TestCombat
Thoát với exit code 0 nếu tất cả đạt, 1 nếu có lỗi.
"""

const UNIT_DIR = "res://Tests/Unit/"

func _ready():
	print("\n" + "=".repeat(65))
	print("       SEKAI RPG — AUTOMATED TEST SUITE")
	print("=".repeat(65))
	
	var suites = _discover_suites()
	
	var total_tests = 0
	var total_passed_assertions = 0
	var total_failed_assertions = 0
	var all_failures = []
	
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
				all_failures.append(f)
				print("    -> " + f)
				
	print("-".repeat(65))
	print("SUMMARY: %d Test Suites | %d Total Tests | %d Assertions" % [
		suites.size(),
		total_tests,
		total_passed_assertions + total_failed_assertions
	])
	print("ASSERTIONS: %d Passed, %d Failed" % [total_passed_assertions, total_failed_assertions])
	
	if total_failed_assertions == 0:
		print("\n>>> ALL TESTS COMPLETED SUCCESSFULLY WITH ZERO ERRORS! <<<\n")
		print("=".repeat(65) + "\n")
		get_tree().quit(0)
	else:
		printerr("\n>>> %d TEST FAILURES DETECTED! <<<\n" % total_failed_assertions)
		print("=".repeat(65) + "\n")
		get_tree().quit(1)

func _discover_suites() -> Array:
	var suites = []
	var names = []
	var only := OS.get_cmdline_user_args()
	for file in DirAccess.get_files_at(UNIT_DIR):
		if file.begins_with("Test") and file.ends_with(".gd"):
			if only.is_empty() or file.get_basename() in only:
				names.append(file)
	names.sort()
	for file in names:
		var script = load(UNIT_DIR + file)
		if script:
			suites.append(script.new())
	return suites
