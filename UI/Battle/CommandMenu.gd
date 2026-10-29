extends PanelContainer
class_name CommandMenu

"""
Tóm tắt: CommandMenu quản lý hệ thống lựa chọn hành động trong trận đấu.

Chức năng chính:
- Hiển thị danh sách kỹ năng khả dụng của thực thể hiện tại (`show_for`).
- Cung cấp luồng chọn 2 bước: Chọn kỹ năng (Action) -> Chọn mục tiêu (Target).
- Hỗ trợ nút Info (Tooltip) để xem mô tả chi tiết của kỹ năng thông qua `SkillDetailPopup`.
"""

signal command_chosen(action: String, target: Entity)

var current_entity: Entity
var enemy_team: Array
var chosen_action: String = ""

# ── Tham chiếu UI ──────────────────────────────────────────────────────────
const SkillDetailPopupClass = preload("res://UI/Popups/SkillDetailPopup.gd")

const MENU_WIDTH = 340

var action_container: VBoxContainer
var target_container: VBoxContainer
var title_label: Label
var _skill_detail_popup: Node

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

func _ready():
	"""
	Khởi tạo cấu trúc menu và các thành phần hỗ trợ hiển thị thông tin.
	"""
	visible = false
	_build_shell()
	
	_skill_detail_popup = SkillDetailPopupClass.new()
	add_child(_skill_detail_popup)

func _build_shell():
	"""Xây dựng khung giao diện chính cho menu lệnh."""
	custom_minimum_size = Vector2(MENU_WIDTH, 0)
	add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.PLAYER, UITheme.SP_4))
	
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", UITheme.SP_2)
	add_child(root)
	
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", UITheme.SP_2)
	root.add_child(title_row)
	
	title_label = UITheme.make_label("LỆNH CHIẾN ĐẤU", UITheme.FS_HEADING, UITheme.TEXT)
	title_label.add_theme_font_override("font", UITheme.font_display_bold())
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_label)
	
	var info_btn = Button.new()
	info_btn.text = "Kỹ năng"
	UITheme.style_button(info_btn, UITheme.Kind.GHOST, UITheme.FS_BODY)
	info_btn.custom_minimum_size.y = 32
	info_btn.pressed.connect(func(): if current_entity: _skill_detail_popup.display_entity_skills(current_entity))
	title_row.add_child(info_btn)
	
	action_container = VBoxContainer.new()
	action_container.add_theme_constant_override("separation", UITheme.SP_2)
	root.add_child(action_container)
	
	target_container = VBoxContainer.new()
	target_container.add_theme_constant_override("separation", UITheme.SP_2)
	target_container.visible = false
	root.add_child(target_container)


# ── API Công khai ──────────────────────────────────────────────────────────

func show_for(entity: Entity, enemies: Array, allowed: Array = []):
	"""
	Hiển thị menu và liệt kê các hành động khả dụng cho thực thể chỉ định.

	Args:
		entity (Entity): Nhân vật đang thực hiện lượt.
		enemies (Array): Danh sách kẻ địch trên sân.
		allowed (Array): Nếu không rỗng, chỉ hiện các hành động trong danh sách (kịch bản giới hạn lựa chọn).
	"""
	current_entity = entity
	enemy_team = enemies
	chosen_action = ""
	
	title_label.text = entity.entity_name.to_upper()
	title_label.add_theme_color_override("font_color", UITheme.PLAYER)
	
	_clear(action_container)
	_clear(target_container)
	action_container.visible = true
	target_container.visible = false
	
	if allowed.is_empty() or allowed.has("attack"):
		action_container.add_child(_make_btn("TẤN CÔNG", "attack", true, UITheme.Kind.PRIMARY))
	
	for skill in entity.skills:
		if not allowed.is_empty() and not allowed.has(skill["method"]):
			continue
		var skill_ready = entity.can_use_skill(skill["method"])
		var cd = entity.cooldowns.get(skill["method"], 0)
		var label = skill["name"]
		
		if cd >= CooldownManager.LOCKED_FOR_BATTLE: label += " [Hết lượt]"
		elif cd > 0: label += " (Hồi: %d)" % cd
			
		var btn = _make_btn(label, skill["method"], skill_ready)
		action_container.add_child(btn)
		
	# Nút vật phẩm
	var has_items = false
	for item_id in GameManager.inventory:
		if GameManager.inventory[item_id] > 0:
			has_items = true
			break
	if has_items and allowed.is_empty():
		var item_btn = _make_btn("VẬT PHẨM", "menu_items", true)
		action_container.add_child(item_btn)
	
	visible = true
	_focus_first_enabled(action_container)

func cancel():
	"""Đóng menu và phát tín hiệu hủy lệnh để tránh treo game khi skip."""
	visible = false
	command_chosen.emit("cancel", null)


# ── Logic Nội bộ ───────────────────────────────────────────────────────────

func _on_action_picked(action_name: String):
	"""Xử lý sự kiện khi người chơi chọn một hành động cụ thể."""
	if action_name == "menu_items":
		_show_items()
		return
		
	chosen_action = action_name
	action_container.visible = false
	
	var target_type = GameManager.get_skill_target_type(current_entity, action_name)
	
	if target_type == "all_allies" or target_type == "all_enemies" or target_type == "self":
		visible = false
		command_chosen.emit(chosen_action, current_entity)
	else:
		_show_targets(target_type)

func _show_items():
	"""Hiển thị danh sách các vật phẩm có thể dùng trong túi đồ."""
	_clear(target_container)
	action_container.visible = false
	target_container.visible = true
	
	target_container.add_child(UITheme.make_label("CHỌN VẬT PHẨM", UITheme.FS_BODY, UITheme.BREAK))
	
	for item_id in GameManager.inventory:
		var count = GameManager.inventory[item_id]
		if count <= 0: continue
		var item_info = GameManager.ITEM_CATALOG.get(item_id, {"name": item_id})
		var btn = _make_btn("%s (x%d)" % [item_info["name"], count], "", true)
		btn.pressed.connect(func():
			chosen_action = "item:" + item_id
			_show_targets("ally")
		)
		target_container.add_child(btn)
		
	var back_btn = Button.new()
	back_btn.text = "‹ Quay lại"
	UITheme.style_button(back_btn, UITheme.Kind.GHOST)
	back_btn.pressed.connect(func():
		action_container.visible = true
		target_container.visible = false
		_focus_first_enabled(action_container)
	)
	target_container.add_child(back_btn)
	_focus_first_enabled(target_container)

func _show_targets(target_type: String = "enemy"):
	"""Hiển thị danh sách các mục tiêu hợp lệ để người chơi lựa chọn."""
	_clear(target_container)
	target_container.visible = true
	
	target_container.add_child(UITheme.make_label("CHỌN MỤC TIÊU", UITheme.FS_BODY, UITheme.ACCENT))
	
	var team = enemy_team if target_type == "enemy" else current_entity.allies
	var alive = AIManager.get_alive_targets(team)
	for member in alive:
		var label = "%s  HP %d/%d" % [member.entity_name, member.current_hp, member.max_hp]
		var btn = _make_btn(label, "", true)
		btn.pressed.connect(_on_target_picked.bind(member))
		target_container.add_child(btn)
	_focus_first_enabled(target_container)

func _on_target_picked(target: Entity):
	"""Xác nhận mục tiêu cuối cùng và phát tín hiệu hoàn thành lệnh."""
	visible = false
	command_chosen.emit(chosen_action, target)

func _make_btn(label: String, action_name: String, enabled: bool, kind: UITheme.Kind = UITheme.Kind.SECONDARY) -> Button:
	"""Khởi tạo một nút bấm trong menu."""
	var btn = Button.new()
	btn.text = label
	btn.disabled = not enabled
	UITheme.style_button(btn, kind)
	
	if action_name != "":
		btn.pressed.connect(_on_action_picked.bind(action_name))
	
	return btn

func _focus_first_enabled(container: Container):
	"""Đưa focus bàn phím/tay cầm vào nút khả dụng đầu tiên của danh sách."""
	for c in container.get_children():
		if c is Button and not c.disabled and not c.is_queued_for_deletion():
			c.call_deferred("grab_focus")
			return

func _clear(container: Container):
	"""Xóa sạch các Node con trong một Container chỉ định."""
	for c in container.get_children(): c.queue_free()
