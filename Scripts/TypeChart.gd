extends Node
class_name TypeChart

static var chart = {
	"Cool": {"weak_to": "Cute", "strong_against": "Happy"},
	"Happy": {"weak_to": "Cool", "strong_against": "Cute"},
	"Cute": {"weak_to": "Happy", "strong_against": "Cool"},
	"Mysterious": {"weak_to": "None", "strong_against": "Pure"},
	"Pure": {"weak_to": "None", "strong_against": "Mysterious"},
}

static func get_multiplier(attacker_element: String, defender_element: String) -> float:
	# Nếu mục tiêu không có hệ (None), sát thương luôn là 1.0
	if defender_element == "None" or attacker_element == "None":
		return 1.0
		
	# Kiểm tra xem hệ tấn công có tồn tại trong bảng không
	if not chart.has(attacker_element):
		return 1.0
	
	var data = chart[attacker_element]
	
	if data["strong_against"] == defender_element:
		return 1.25
	elif data["weak_to"] == defender_element:
		return 0.8
		
	return 1.0
