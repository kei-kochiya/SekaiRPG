class_name ModalScope
extends RefCounted

"""
ModalScope: cặp push/pop modal của PauseMenu gói thành một đối tượng cân bằng, để ESC đóng hộp thoại thay vì mở menu tạm dừng.

- `enter()` / `exit()` đều idempotent: gọi thừa không làm lệch bộ đếm của PauseMenu (an toàn khi gọi cả ở đường đóng lẫn `_exit_tree`).
- Thay cho cờ `_modal_pushed` + `_set_modal` chép ở SaveLoadMenu, ShopMenu, HoloBlessingSelectUI, EntityDetailPanel, SkillDetailPopup.
"""

var _active: bool = false

func enter() -> void:
	if _active:
		return
	_active = true
	PauseMenu.push_modal()

func exit() -> void:
	if not _active:
		return
	_active = false
	PauseMenu.pop_modal()
