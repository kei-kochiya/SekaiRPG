extends PanelContainer
class_name SkillDetailPopup

"""
SkillDetailPopup: Cửa sổ hiển thị thông tin chuyên sâu của một kỹ năng.
Bao gồm mô tả, tỉ lệ sát thương và các hiệu ứng đi kèm.
Tách ra từ CommandMenu để giữ code điều khiển gọn gàng.

Gốc là lớp mờ phủ toàn màn hình (top_level), bên trong là một bảng giữa màn hình. ESC hoặc nút Đóng để thoát.
"""

const PANEL_WIDTH = 560
const MAX_LIST_HEIGHT = 420
const MAX_SKILLS_UNSCROLLED = 4

var _content_vbox: VBoxContainer
var _close_btn: Button
var _prev_focus: Control = null
var _modal_pushed: bool = false

func _init():
	visible = false
	top_level = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UITheme.box(UITheme.overlay_dim(0.78), Color.TRANSPARENT, 0, 0, 0))

	var center = CenterContainer.new()
	add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.PLAYER, UITheme.SP_6))
	center.add_child(panel)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", UITheme.SP_3)
	panel.add_child(_content_vbox)

func _exit_tree():
	_set_modal(false)

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func display_skill(skill: Dictionary):
	"""
	Cập nhật nội dung và hiển thị bảng chi tiết kỹ năng.
	"""
	_reset("Chi tiết kỹ năng")

	# Nội dung tên chiêu
	_content_vbox.add_child(UITheme.make_label(skill["name"], UITheme.FS_HEADING, UITheme.ACCENT))

	# Nội dung mô tả chi tiết (scaling, effects)
	_content_vbox.add_child(_make_details(skill.get("details", "Không có thông tin chi tiết."), UITheme.FS_LABEL))

	_open()

func display_entity_skills(entity: Entity):
	"""
	Hiển thị toàn bộ danh sách kỹ năng của một thực thể.
	"""
	_reset("Kỹ năng: " + entity.entity_name)

	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UITheme.SP_3)
	# Danh sách ngắn thì hiện thẳng; chỉ dùng khung cuộn khi nhiều kỹ năng
	if entity.skills.size() > MAX_SKILLS_UNSCROLLED:
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size.y = MAX_LIST_HEIGHT
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		_content_vbox.add_child(scroll)
		scroll.add_child(list)
	else:
		_content_vbox.add_child(list)

	for i in range(entity.skills.size()):
		var skill = entity.skills[i]
		if i > 0:
			list.add_child(HSeparator.new())

		var item = VBoxContainer.new()
		item.add_theme_constant_override("separation", UITheme.SP_1)
		list.add_child(item)
		item.add_child(UITheme.make_label(skill["name"], UITheme.FS_LABEL, UITheme.ACCENT))
		item.add_child(_make_details(skill.get("details", "Không có thông tin chi tiết."), UITheme.FS_BODY))

	_open()

# ── Dựng nội dung ──────────────────────────────────────────────────────────

# Xóa nội dung cũ và dựng hàng tiêu đề (tiêu đề + nút Đóng)
func _reset(title_text: String):
	for c in _content_vbox.get_children():
		_content_vbox.remove_child(c)
		c.queue_free()

	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", UITheme.SP_3)
	_content_vbox.add_child(header)

	var title = Label.new()
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UITheme.style_title(title, UITheme.FS_HEADING, UITheme.TEXT)
	header.add_child(title)

	_close_btn = Button.new()
	_close_btn.text = "Đóng"
	UITheme.style_button(_close_btn, UITheme.Kind.GHOST)
	_close_btn.custom_minimum_size.x = 96
	_close_btn.pressed.connect(_close)
	header.add_child(_close_btn)

func _make_details(text: String, size: int) -> Label:
	var details = UITheme.make_label(text, size, UITheme.TEXT)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return details

# ── Mở / đóng ──────────────────────────────────────────────────────────────

func _open():
	if not visible and is_inside_tree():
		_prev_focus = get_viewport().gui_get_focus_owner()
	visible = true
	_set_modal(true)
	_focus_later.call_deferred(_close_btn)

func _close():
	visible = false
	_set_modal(false)
	# Trả focus về nút đã mở popup (nút "Kỹ năng" của CommandMenu)
	if is_instance_valid(_prev_focus) and _prev_focus.is_visible_in_tree():
		_focus_later.call_deferred(_prev_focus)
	_prev_focus = null

# Báo PauseMenu để ESC đóng popup thay vì mở menu tạm dừng; push/pop luôn cân bằng nhờ cờ `_modal_pushed`
func _set_modal(on: bool):
	if on == _modal_pushed:
		return
	_modal_pushed = on
	if on:
		PauseMenu.push_modal()
	else:
		PauseMenu.pop_modal()

# Focus trễ một nhịp (sau khi các node queue_free() đã dọn); bỏ qua nếu nút đã bị xóa/gỡ khỏi cây trước đó
func _focus_later(ctrl):
	if is_instance_valid(ctrl) and ctrl.is_inside_tree():
		ctrl.grab_focus()
