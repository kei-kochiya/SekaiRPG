class_name HoloBlessing
extends RefCounted

"""
Tóm tắt: HoloBlessing định nghĩa danh mục các Phước Lành (Buffs) dạng Roguelite.
"""

const BLESSING_CATALOG := {
	"blessing_bleed": {
		"id": "blessing_bleed",
		"name": "Huyết Nguyệt",
		"icon": "🩸",
		"desc": "Mọi đòn đánh thường có 40% tỷ lệ gây thêm 2 stack Chảy Máu (Bleed) lên mục tiêu."
	},
	"blessing_speed": {
		"id": "blessing_speed",
		"name": "Tốc Hành Vô Song",
		"icon": "⚡",
		"desc": "Tăng vĩnh viễn +35 SPD cho toàn bộ nhân vật trong đội suốt lượt chạy."
	},
	"blessing_crit": {
		"id": "blessing_crit",
		"name": "Tâm Nhãn Tinh Thông",
		"icon": "🎯",
		"desc": "Tăng +25% Tỷ lệ Chí mạng và +50% Sát thương Chí mạng cho toàn đội."
	},
	"blessing_cooldown": {
		"id": "blessing_cooldown",
		"name": "Kích Nổ Năng Lượng",
		"icon": "💥",
		"desc": "Khi gây sát thương Chí mạng, lập tức giảm 1 lượt hồi chiêu toàn bộ kỹ năng."
	},
	"blessing_thorn": {
		"id": "blessing_thorn",
		"name": "Giáp Gai Phản Đòn",
		"icon": "🛡️",
		"desc": "Khi nhận sát thương, phản lại 35% sát thương nhận vào cho kẻ tấn công."
	},
	"blessing_break": {
		"id": "blessing_break",
		"name": "Chấn Lực Xuyên Giáp",
		"icon": "🔨",
		"desc": "Đòn đánh giảm thêm 100% thanh Break Gauge của đối thủ khi đánh trúng điểm yếu."
	},
	"blessing_heal_kill": {
		"id": "blessing_heal_kill",
		"name": "Hấp Thu Sinh Lực",
		"icon": "💚",
		"desc": "Hạ gục bất kỳ kẻ địch nào lập tức hồi 25% Max HP cho người hạ gục."
	},
	"blessing_undying": {
		"id": "blessing_undying",
		"name": "Dòng Máu Bất Tử",
		"icon": "✨",
		"desc": "Khi nhận đòn chí tử lần đầu trong trận, giữ lại 1 HP và hồi ngay 40% HP."
	}
}

static func get_random_blessings(count: int = 3, exclude: Array = []) -> Array:
	var available = []
	for b_id in BLESSING_CATALOG:
		if not exclude.has(b_id):
			available.append(BLESSING_CATALOG[b_id])
	available.shuffle()
	return available.slice(0, min(count, available.size()))
