extends PanelContainer
class_name EntityDetailPanel

"""
EntityDetailPanel: Bảng hiển thị thông tin chi tiết chỉ số và kỹ năng của thực thể.
Được tách ra từ BattleHUD để giảm độ phức tạp của code giao diện chính.

Gốc là lớp mờ phủ toàn màn hình, bên trong là một bảng gồm hai nhóm (phe ta / kẻ địch). Mỗi thực thể là một hàng
của bảng chỉ số (cột số căn phải, vạch màu phe bên trái) kèm danh sách kỹ năng. ESC hoặc nút Đóng để thoát.
"""

const MARGIN_H = 120
const MARGIN_V = 40
const BAR_WIDTH = 4
const COL_LV = 56
const COL_HP = 112
const COL_STAT = 64
const COL_TYPE = 112
const SKILL_INDENT = 4
const SKILL_NAME_WIDTH = 220
const SKILL_STATE_WIDTH = 104
const SCROLL_STEP = 64

var _scroll: ScrollContainer
var _close_btn: Button
var _prev_focus: Control = null
var _modal_pushed: bool = false

func _init():
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", UITheme.box(UITheme.overlay_dim(0.78), Color.TRANSPARENT, 0, MARGIN_H, MARGIN_V))

func _exit_tree():
	_set_modal(false)

func _input(event):
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif _scroll != null and (event.is_action_pressed("ui_down") or event.is_action_pressed("ui_up")):
		# Chỉ có một nút focus được nên mũi tên lên/xuống dùng để cuộn bảng
		_scroll.scroll_vertical += SCROLL_STEP if event.is_action_pressed("ui_down") else -SCROLL_STEP
		get_viewport().set_input_as_handled()

func show_entities(p_team: Array, e_team: Array):
	"""
	Hiển thị bảng chi tiết cho hai đội.
	"""
	# Xóa nội dung cũ
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, Color.TRANSPARENT, UITheme.SP_6))
	add_child(panel)

	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", UITheme.SP_3)
	panel.add_child(outer)

	var header = HBoxContainer.new()
	outer.add_child(header)
	var title = Label.new()
	title.text = "Chi tiết chỉ số"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_title(title, UITheme.FS_TITLE, UITheme.ACCENT)
	header.add_child(title)
	_close_btn = Button.new()
	_close_btn.text = "Đóng"
	UITheme.style_button(_close_btn, UITheme.Kind.GHOST)
	_close_btn.custom_minimum_size.x = 112
	_close_btn.pressed.connect(_close)
	header.add_child(_close_btn)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	var body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UITheme.SP_6)
	_scroll.add_child(body)

	_add_team(body, "Phe ta", p_team, UITheme.PLAYER)
	_add_team(body, "Kẻ địch", e_team, UITheme.ENEMY)

	if not visible and is_inside_tree():
		_prev_focus = get_viewport().gui_get_focus_owner()
	visible = true
	_set_modal(true)
	_focus_later.call_deferred(_close_btn)

# ── Bảng theo phe ──────────────────────────────────────────────────────────

func _add_team(parent: Control, team_title: String, team: Array, color: Color):
	if team.is_empty():
		return
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", UITheme.SP_2)
	parent.add_child(section)

	section.add_child(UITheme.make_label(team_title, UITheme.FS_HEADING, color))
	section.add_child(_make_column_header())

	for i in range(team.size()):
		if i > 0:
			section.add_child(HSeparator.new())
		section.add_child(_make_entity_block(team[i], color))

# Hàng tiêu đề cột (chữ phụ), cùng độ rộng cột với hàng chỉ số
func _make_column_header() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_3)
	row.add_child(_spacer(BAR_WIDTH))
	var name_lbl = _cell("Tên", 0, UITheme.TEXT_MUTED, UITheme.FS_CAPTION)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	row.add_child(_cell("Lv", COL_LV, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell("HP", COL_HP, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell("ATK", COL_STAT, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell("DEF", COL_STAT, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell("SPD", COL_STAT, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell("Hệ", COL_TYPE, UITheme.TEXT_MUTED, UITheme.FS_CAPTION))
	return row

# Một thực thể: vạch màu phe | hàng chỉ số | các kỹ năng
func _make_entity_block(e: Entity, faction_color: Color) -> HBoxContainer:
	var block = HBoxContainer.new()
	block.add_theme_constant_override("separation", UITheme.SP_3)

	var bar = ColorRect.new()
	bar.color = faction_color
	bar.custom_minimum_size.x = BAR_WIDTH
	block.add_child(bar)

	var content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", UITheme.SP_1)
	block.add_child(content)

	var alive = e.current_hp > 0
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_3)
	content.add_child(row)

	var name_lbl = _cell(e.entity_name, 0, UITheme.TEXT if alive else UITheme.TEXT_MUTED, UITheme.FS_LABEL)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(name_lbl)
	row.add_child(_cell(str(e.level), COL_LV, UITheme.TEXT, UITheme.FS_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell("%d/%d" % [e.current_hp, e.max_hp], COL_HP, UITheme.TEXT if alive else UITheme.DANGER_TEXT, UITheme.FS_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell(str(e.atk), COL_STAT, UITheme.TEXT, UITheme.FS_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell(str(e.defense), COL_STAT, UITheme.TEXT, UITheme.FS_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell(str(e.spd), COL_STAT, UITheme.TEXT, UITheme.FS_LABEL, HORIZONTAL_ALIGNMENT_RIGHT))

	var type_cell = HBoxContainer.new()
	type_cell.custom_minimum_size.x = COL_TYPE
	if e.type != "None":
		type_cell.add_child(UITheme.chip(e.type, UITheme.element_color(e.type)))
	else:
		type_cell.add_child(UITheme.make_label("-", UITheme.FS_LABEL, UITheme.TEXT_MUTED))
	row.add_child(type_cell)

	for s in e.skills:
		content.add_child(_make_skill_row(e, s))
	return block

func _make_skill_row(e: Entity, s: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_3)
	row.add_child(_spacer(SKILL_INDENT))

	var name_lbl = _cell(s["name"], SKILL_NAME_WIDTH, UITheme.TEXT, UITheme.FS_BODY)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_lbl)

	var details = _cell(s.get("details", ""), 0, UITheme.TEXT_MUTED, UITheme.FS_CAPTION)
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(details)

	var cd: int = e.cooldowns.get(s["method"], 0)
	var state_text = "Sẵn sàng"
	var state_color = UITheme.SUCCESS
	if cd >= 99:
		state_text = "Hết lượt"
		state_color = UITheme.TEXT_MUTED
	elif cd > 0:
		state_text = "Hồi %d lượt" % cd
		state_color = UITheme.WARNING
	row.add_child(_cell(state_text, SKILL_STATE_WIDTH, state_color, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	return row

func _cell(text: String, min_width: int, color: Color, size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl = UITheme.make_label(text, size, color, align)
	lbl.custom_minimum_size.x = min_width
	return lbl

func _spacer(width: int) -> Control:
	var c = Control.new()
	c.custom_minimum_size.x = width
	return c

# ── Mở / đóng ──────────────────────────────────────────────────────────────

func _close():
	visible = false
	_set_modal(false)
	# Trả focus về nút "Chi tiết" đã mở bảng này
	if is_instance_valid(_prev_focus) and _prev_focus.is_visible_in_tree():
		_focus_later.call_deferred(_prev_focus)
	_prev_focus = null

# Báo PauseMenu để ESC đóng bảng thay vì mở menu tạm dừng; push/pop luôn cân bằng nhờ cờ `_modal_pushed`
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
