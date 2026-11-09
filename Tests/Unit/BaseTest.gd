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

# Hook chạy quanh MỖI test: test nào đụng vào trạng thái toàn cục (GameManager, Engine...) tự dọn lại ở after_each.
func before_each():
	pass

func after_each():
	# Mặc định trả lại các trạng thái toàn cục dễ bị test làm bẩn (suite sau không phải tự reset_game mới chạy đúng)
	GameManager.is_sandbox = false
	GameManager.reduce_motion = false
	Engine.time_scale = 1.0

func run_all_tests() -> Dictionary:
	var methods = get_method_list()
	var test_methods = []
	for m in methods:
		if m["name"].begins_with("test_"):
			test_methods.append(m["name"])
			
	for m_name in test_methods:
		current_test_name = m_name
		var before := passed_count + failed_count
		before_each()
		call(m_name)
		after_each()
		if passed_count + failed_count == before:
			# Test lỗi giữa chừng (script error) hoặc quên assert sẽ không bao giờ được tính là đạt
			failed_count += 1
			var err = "[FAIL] %s: không có assertion nào được chạy" % m_name
			failures.append(err)
			push_error(err)
		
	return {
		"name": get_script().resource_path.get_file().get_basename(),
		"tests_run": test_methods.size(),
		"passed_assertions": passed_count,
		"failed_assertions": failed_count,
		"failures": failures
	}
