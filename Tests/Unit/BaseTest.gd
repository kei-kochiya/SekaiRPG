class_name BaseTest
extends RefCounted

"""
Tóm tắt: BaseTest cung cấp các assertion helpers và theo dõi kết quả test.
"""

var passed_count: int = 0
var failed_count: int = 0
var current_test_name: String = ""
var failures: Array = []

func assert_true(condition: bool, message: String = ""):
	if condition:
		passed_count += 1
	else:
		failed_count += 1
		var err = "[FAIL] %s: %s (Expected true, got false)" % [current_test_name, message]
		failures.append(err)
		push_error(err)

func assert_false(condition: bool, message: String = ""):
	if not condition:
		passed_count += 1
	else:
		failed_count += 1
		var err = "[FAIL] %s: %s (Expected false, got true)" % [current_test_name, message]
		failures.append(err)
		push_error(err)

func assert_eq(actual, expected, message: String = ""):
	if actual == expected:
		passed_count += 1
	else:
		failed_count += 1
		var err = "[FAIL] %s: %s (Expected '%s', got '%s')" % [current_test_name, message, str(expected), str(actual)]
		failures.append(err)
		push_error(err)

func assert_ne(actual, expected, message: String = ""):
	if actual != expected:
		passed_count += 1
	else:
		failed_count += 1
		var err = "[FAIL] %s: %s (Expected not equal to '%s')" % [current_test_name, message, str(expected)]
		failures.append(err)
		push_error(err)

func assert_gt(actual, expected, message: String = ""):
	if actual > expected:
		passed_count += 1
	else:
		failed_count += 1
		var err = "[FAIL] %s: %s (Expected > %s, got %s)" % [current_test_name, message, str(expected), str(actual)]
		failures.append(err)
		push_error(err)

func assert_lt(actual, expected, message: String = ""):
	if actual < expected:
		passed_count += 1
	else:
		failed_count += 1
		var err = "[FAIL] %s: %s (Expected < %s, got %s)" % [current_test_name, message, str(expected), str(actual)]
		failures.append(err)
		push_error(err)

func run_all_tests() -> Dictionary:
	var methods = get_method_list()
	var test_methods = []
	for m in methods:
		if m["name"].begins_with("test_"):
			test_methods.append(m["name"])
			
	for m_name in test_methods:
		current_test_name = m_name
		call(m_name)
		
	return {
		"name": get_script().resource_path.get_file().get_basename(),
		"tests_run": test_methods.size(),
		"passed_assertions": passed_count,
		"failed_assertions": failed_count,
		"failures": failures
	}
