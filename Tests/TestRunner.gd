extends Node2D

"""
Tóm tắt: TestRunner là bộ điều phối kiểm thử tự động toàn diện (Master Test Runner) cho SekaiRPG.

Chức năng chính:
- Tự động chạy tất cả các module Unit Test đơn lẻ (TestCore, TestCombat, TestEntities, TestEconomy, TestQuests, TestHoloSim).
- Tổng hợp số lượng test cases, số assertions đạt/hỏng.
- Xuất báo cáo chi tiết, chuyên nghiệp ra Console.
- Thoát game với Exit Code 0 (nếu tất cả đều đạt) hoặc 1 (nếu có lỗi).
"""

const TestCoreClass = preload("res://Tests/Unit/TestCore.gd")
const TestCombatClass = preload("res://Tests/Unit/TestCombat.gd")
const TestEntitiesClass = preload("res://Tests/Unit/TestEntities.gd")
const TestEconomyClass = preload("res://Tests/Unit/TestEconomy.gd")
const TestQuestsClass = preload("res://Tests/Unit/TestQuests.gd")
const TestHoloSimClass = preload("res://Tests/Unit/TestHoloSim.gd")

func _ready():
	print("\n" + "=".repeat(65))
	print("       SEKAI RPG — MASTER AUTOMATED TEST SUITE RUNNER")
	print("=".repeat(65))
	
	var suites = [
		TestCoreClass.new(),
		TestCombatClass.new(),
		TestEntitiesClass.new(),
		TestEconomyClass.new(),
		TestQuestsClass.new(),
		TestHoloSimClass.new()
	]
	
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
