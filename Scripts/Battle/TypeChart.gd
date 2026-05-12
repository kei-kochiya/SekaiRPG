extends Node
class_name TypeChart

"""
TypeChart: Bảng tương khắc thuộc tính giữa các hệ trong game.

Hệ thuộc tính: Cool, Happy, Cute, Mysterious, Pure.
Quy tắc: Mạnh hơn x1.25, Yếu hơn x0.8, Bình thường x1.0.
"""

static var chart = {
	"Cool":       {"weak_to": "Cute",  "strong_against": "Happy"},
	"Happy":      {"weak_to": "Cool",  "strong_against": "Cute"},
	"Cute":       {"weak_to": "Happy", "strong_against": "Cool"},
	"Mysterious": {"weak_to": "None",  "strong_against": "Pure"},
	"Pure":       {"weak_to": "None",  "strong_against": "Mysterious"},
}

static func get_multiplier(attacker_element: String, defender_element: String) -> float:
	"""
	Lấy hệ số nhân sát thương dựa trên tương khắc thuộc tính.

	- Mạnh hơn (Strong): 1.25x.
	- Yếu hơn (Weak): 0.8x.
	- Mysterious và Pure khắc chế lẫn nhau: 1.25x.
	- Bình thường hoặc không có hệ: 1.0x.

	- attacker_element: Hệ của người tấn công (String).
	- defender_element: Hệ của mục tiêu (String).
	- Return: Hệ số nhân sát thương (float).
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
