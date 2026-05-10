extends Node
class_name TypeChart

"""
TypeChart: Quản lý hệ thống tương khắc thuộc tính trong trò chơi.

Lớp này xác định bảng hệ số sát thương dựa trên các hệ thuộc tính đặc trưng 
của Sekai: Cool, Happy, Cute, Mysterious và Pure.
"""

static var chart = {
	"Cool": {"weak_to": "Cute", "strong_against": "Happy"},
	"Happy": {"weak_to": "Cool", "strong_against": "Cute"},
	"Cute": {"weak_to": "Happy", "strong_against": "Cool"},
	"Mysterious": {"weak_to": "None", "strong_against": "Pure"},
	"Pure": {"weak_to": "None", "strong_against": "Mysterious"},
}

static func get_multiplier(attacker_element: String, defender_element: String) -> float:
	"""
	Lấy hệ số nhân sát thương dựa trên thuộc tính tương khắc.

	Quy tắc tương khắc:
	- Mạnh hơn (Strong): 1.25x sát thương.
	- Yếu hơn (Weak): 0.8x sát thương.
	- Mysterious và Pure khắc chế lẫn nhau (1.25x).
	- Bình thường hoặc không có hệ: 1.0x sát thương.

	Args:
		attacker_element (String): Hệ của người tấn công.
		defender_element (String): Hệ của mục tiêu.

	Returns:
		float: Hệ số nhân sát thương (multiplier).
	"""
	if defender_element == "None" or attacker_element == "None":
		return 1.0
		
	if not chart.has(attacker_element):
		return 1.0
	
	var data = chart[attacker_element]
	
	if data["strong_against"] == defender_element:
		return 1.25
	elif data["weak_to"] == defender_element:
		return 0.8
		
	if attacker_element == "Mysterious" and defender_element == "Pure": return 1.25
	if attacker_element == "Pure" and defender_element == "Mysterious": return 1.25
		
	return 1.0
