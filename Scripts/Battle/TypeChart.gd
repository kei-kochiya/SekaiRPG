extends Node
class_name TypeChart

"""
Tóm tắt: TypeChart quản lý bảng tương khắc thuộc tính giữa các hệ trong game.

Chức năng chính:
- Định nghĩa ma trận tương khắc cho 5 hệ: Cool, Happy, Cute, Mysterious, Pure.
- Cung cấp phương thức tĩnh `get_multiplier` để trả về hệ số nhân: x1.25 (Mạnh hơn), x0.8 (Yếu hơn) hoặc x1.0 (Bình thường).
"""

# ── Dữ Liệu Tương Khắc ─────────────────────────────────────────────────────

static var chart = {
	"Cool":       {"weak_to": "Cute",  "strong_against": "Happy"},
	"Happy":      {"weak_to": "Cool",  "strong_against": "Cute"},
	"Cute":       {"weak_to": "Happy", "strong_against": "Cool"},
	"Mysterious": {"weak_to": "None",  "strong_against": "Pure"},
	"Pure":       {"weak_to": "None",  "strong_against": "Mysterious"},
}

# ── Xử Lý Logic ────────────────────────────────────────────────────────────

static func get_multiplier(attacker_element: String, defender_element: String) -> float:
	"""
	Lấy hệ số nhân sát thương dựa trên tương khắc thuộc tính.
	
	- Mạnh hơn (Strong): 1.25x.
	- Yếu hơn (Weak): 0.8x.
	- Mysterious và Pure khắc chế lẫn nhau: 1.25x.
	- Bình thường hoặc không có hệ: 1.0x.
	
	Args:
		attacker_element (String): Hệ của người tấn công.
		defender_element (String): Hệ của mục tiêu.
	Returns: 
		float: Hệ số nhân sát thương.
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
