class_name ItemCatalog
extends RefCounted

"""
ItemCatalog: danh mục vật phẩm tiêu hao (tên, mô tả, giá) và hiệu ứng của từng món khi dùng lên một thực thể.
Kho đồ và credits của người chơi nằm ở GameManager; chỗ này chỉ là dữ liệu và hiệu ứng.
"""

const ITEMS := {
	"potion": {
		"name": "Bình Máu",
		"desc": "Hồi phục 40% HP tối đa cho 1 mục tiêu.",
		"price": 80
	},
	"energy_drink": {
		"name": "Nước Tăng Lực",
		"desc": "Làm đầy thanh hành động (Hành động ngay lập tức).",
		"price": 120
	},
	"bandage": {
		"name": "Băng Cứu Thương",
		"desc": "Xóa toàn bộ hiệu ứng trạng thái bất lợi (Debuff).",
		"price": 60
	}
}

# Áp hiệu ứng của vật phẩm lên `target` (không trừ kho: GameManager.use_item lo việc đó).
static func apply_effect(item_id: String, target: Entity) -> void:
	match item_id:
		"potion":
			var heal_amt = int(target.max_hp * 0.4)
			target.heal(heal_amt)
			print("[Item] Sử dụng Bình Máu lên ", target.entity_name, ": +", heal_amt, " HP")
		"energy_drink":
			target.action_gauge = 10000.0
			print("[Item] Sử dụng Nước Tăng Lực lên ", target.entity_name, ": Đầy thanh hành động!")
		"bandage":
			target.active_statuses.clear()
			target.status_changed.emit(target.active_statuses)
			print("[Item] Sử dụng Băng Cứu Thương lên ", target.entity_name, ": Xóa sạch debuff!")
