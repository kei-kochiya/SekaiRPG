extends CanvasLayer

"""
Tóm tắt: UpgradeUI là hệ thống giao diện cho phép người chơi nâng cấp chỉ số nhân vật.

Chức năng chính:
- Khởi tạo bảng UI động hiển thị danh sách các nhân vật trong đội hình.
- Lấy và hiển thị các chỉ số hiện tại (HP, ATK, DEF, SPD) và Điểm Kỹ Năng (SP) của nhân vật được chọn.
- Xây dựng cụm nút nâng cấp (+1, +10, +25, MAX) kết nối trực tiếp với API của `UpgradeManager`; nút nào không đủ SP hoặc đã chạm trần sẽ bị khóa.
- Tự động khóa sự kiện di chuyển của người chơi (thông qua `GameManager.start_dialogue()`) khi đang hiển thị, và nhả đúng một lần khi đóng.
- Là hộp thoại modal: ESC để đóng, báo PauseMenu để ESC không mở menu tạm dừng bên dưới.
"""

# ── Biến Giao Diện & Dữ Liệu ───────────────────────────────────────────────

signal closed

const PANEL_WIDTH = 900
const COL_NAME = 176
const COL_VALUE = 72
const COL_GAIN = 104
const STAT_ORDER = ["max_hp", "atk", "defense", "spd"]
const STAT_LABELS = {
	"max_hp": "Máu (HP)",
	"atk": "Tấn công (ATK)",
	"defense": "Phòng thủ (DEF)",
	"spd": "Tốc độ (SPD)"
}
# [nhãn nút, số lần nâng]; MAX dùng 999 và chỉ cần còn 1 SP là bấm được
const STEPS = [["+1", 1], ["+10", 10], ["+25", 25], ["MAX", 999]]

var characters: Array[Entity] = []
var selected_index: int = 0

var char_list: VBoxContainer
var stat_vbox: VBoxContainer
var sp_label: Label
var char_name_label: Label
var level_label: Label

var _close_btn: Button
var _char_buttons: Array[Button] = []
var _stat_rows: Dictionary = {}
var _open: bool = false

# ── Vòng Đời & Khởi Tạo UI ──────────────────────────────────────────────────

# Khởi tạo giao diện
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120 # Trên HUD nhiệm vụ (10), dưới PauseMenu (130)
	_build_ui()
	visible = false

func _input(event):
	if _open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_ui()

# ── API Hiển Thị ───────────────────────────────────────────────────────────

func show_ui(chars: Array[Entity]):
	"""
	Hiển thị giao diện nâng cấp với danh sách nhân vật hiện có.

	Args:
		chars (Array[Entity]): Danh sách các nhân vật có thể nâng cấp.
	Returns: Không có
	"""
	if chars.is_empty():
		return
	characters = chars
	selected_index = 0
	visible = true
	if not _open:
		_open = true
		PauseMenu.push_modal()
		GameManager.start_dialogue()
	_rebuild_char_list()
	_rebuild_stats()
	if not _char_buttons.is_empty():
		_focus_later.call_deferred(_char_buttons[0])

func close_ui():
	"""Đóng giao diện, nhả khóa hội thoại và cờ modal đúng một lần rồi phát tín hiệu `closed`."""
	if not _open:
		return
	_open = false
	visible = false
	GameManager.end_dialogue()
	PauseMenu.pop_modal()
	closed.emit()

# ── Xây Dựng Cấu Trúc UI ───────────────────────────────────────────────────

# Xây dựng khung UI; phần danh sách nhân vật và chỉ số được dựng khi `show_ui`
func _build_ui():
	# Lớp nền tối mờ (Dimmer) toàn màn hình để loại bỏ hoàn toàn hiện tượng xuyên thấu
	var dimmer = ColorRect.new()
	dimmer.name = "ModalDimmer"
	dimmer.color = UITheme.overlay_dim(0.78)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.ACCENT, UITheme.SP_6))
	add_child(panel)

	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", UITheme.SP_6)
	panel.add_child(main_hbox)

	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size.x = 200
	left_vbox.add_theme_constant_override("separation", UITheme.SP_2)
	main_hbox.add_child(left_vbox)

	left_vbox.add_child(UITheme.make_label("Nhân vật", UITheme.FS_CAPTION, UITheme.TEXT_MUTED))
	char_list = VBoxContainer.new()
	char_list.name = "CharList"
	left_vbox.add_child(char_list)

	main_hbox.add_child(VSeparator.new())

	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", UITheme.SP_3)
	main_hbox.add_child(right_vbox)

	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", UITheme.SP_3)
	right_vbox.add_child(name_row)
	char_name_label = Label.new()
	char_name_label.name = "CharNameLabel"
	UITheme.style_title(char_name_label, UITheme.FS_TITLE, UITheme.ACCENT)
	name_row.add_child(char_name_label)
	level_label = UITheme.make_label("", UITheme.FS_LABEL, UITheme.TEXT_MUTED)
	level_label.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(level_label)

	var sp_row = HBoxContainer.new()
	sp_row.add_theme_constant_override("separation", UITheme.SP_2)
	right_vbox.add_child(sp_row)
	sp_row.add_child(UITheme.make_label("Điểm kỹ năng (SP)", UITheme.FS_LABEL, UITheme.TEXT_MUTED))
	sp_label = UITheme.make_label("0", UITheme.FS_HEADING, UITheme.ACCENT)
	sp_label.name = "SPLabel"
	sp_row.add_child(sp_label)

	right_vbox.add_child(HSeparator.new())

	# Tiêu đề cột (chữ phụ) khớp độ rộng với các hàng chỉ số bên dưới
	var head = HBoxContainer.new()
	head.add_theme_constant_override("separation", UITheme.SP_3)
	right_vbox.add_child(head)
	head.add_child(_cell("Chỉ số", COL_NAME, UITheme.TEXT_MUTED, UITheme.FS_CAPTION))
	head.add_child(_cell("Hiện tại", COL_VALUE, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_RIGHT))
	head.add_child(_cell("Mỗi điểm", COL_GAIN, UITheme.TEXT_MUTED, UITheme.FS_CAPTION, HORIZONTAL_ALIGNMENT_CENTER))
	head.add_child(_cell("Nâng cấp", 0, UITheme.TEXT_MUTED, UITheme.FS_CAPTION))

	stat_vbox = VBoxContainer.new()
	stat_vbox.name = "StatVBox"
	stat_vbox.add_theme_constant_override("separation", UITheme.SP_2)
	right_vbox.add_child(stat_vbox)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(spacer)

	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	right_vbox.add_child(footer)
	_close_btn = Button.new()
	_close_btn.text = "Đóng"
	UITheme.style_button(_close_btn, UITheme.Kind.GHOST)
	_close_btn.custom_minimum_size.x = 128
	_close_btn.pressed.connect(close_ui)
	footer.add_child(_close_btn)

func _cell(text: String, min_width: int, color: Color, size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var lbl = UITheme.make_label(text, size, color, align)
	lbl.custom_minimum_size.x = min_width
	return lbl

# ── Tiện Ích Cập Nhật UI ───────────────────────────────────────────────────

func _rebuild_char_list():
	for c in char_list.get_children():
		char_list.remove_child(c)
		c.queue_free()
	_char_buttons.clear()
	for i in range(characters.size()):
		var btn = Button.new()
		btn.text = characters[i].entity_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_select_character.bind(i))
		char_list.add_child(btn)
		_char_buttons.append(btn)
	_style_char_buttons()

# Nhân vật đang chọn có nền sáng + viền vàng; các nút còn lại là GHOST
func _style_char_buttons():
	for i in range(_char_buttons.size()):
		var btn = _char_buttons[i]
		UITheme.style_button(btn, UITheme.Kind.GHOST)
		if i == selected_index:
			var chosen = UITheme.box(UITheme.INK_600, UITheme.ACCENT, UITheme.RADIUS_MD, UITheme.SP_4, UITheme.SP_2, 1)
			for state in ["normal", "hover", "pressed"]:
				btn.add_theme_stylebox_override(state, chosen)

func _select_character(i: int):
	if i == selected_index:
		return
	selected_index = i
	_style_char_buttons()
	_rebuild_stats()

func _rebuild_stats():
	for c in stat_vbox.get_children():
		stat_vbox.remove_child(c)
		c.queue_free()
	_stat_rows.clear()

	var entity = characters[selected_index]
	char_name_label.text = entity.entity_name

	for stat in STAT_ORDER:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", UITheme.SP_3)
		stat_vbox.add_child(row)

		var name_lbl = _cell(STAT_LABELS[stat], COL_NAME, UITheme.TEXT, UITheme.FS_LABEL)
		name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(name_lbl)
		var val_lbl = _cell("", COL_VALUE, UITheme.TEXT, UITheme.FS_LABEL, HORIZONTAL_ALIGNMENT_RIGHT)
		val_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(val_lbl)
		var gain_lbl = _cell("", COL_GAIN, UITheme.TEXT_MUTED, UITheme.FS_BODY, HORIZONTAL_ALIGNMENT_CENTER)
		gain_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(gain_lbl)

		var btn_container = HBoxContainer.new()
		btn_container.add_theme_constant_override("separation", UITheme.SP_2)
		row.add_child(btn_container)

		var buttons: Array[Button] = []
		for step in STEPS:
			var b = Button.new()
			b.text = step[0]
			UITheme.style_button(b, UITheme.Kind.SECONDARY, UITheme.FS_BODY)
			b.custom_minimum_size.x = 64
			b.set_meta("count", step[1])
			b.pressed.connect(_on_upgrade_pressed.bind(stat, step[1]))
			btn_container.add_child(b)
			buttons.append(b)

		_stat_rows[stat] = {"value": val_lbl, "gain": gain_lbl, "buttons": buttons}

	_refresh_stats()

# Cập nhật số liệu và trạng thái khóa của nút tại chỗ (không dựng lại nút nên không mất focus)
func _refresh_stats():
	var entity = characters[selected_index]
	level_label.text = "Lv.%d" % entity.level
	sp_label.text = str(entity.skill_points)

	for stat in _stat_rows:
		var ref: Dictionary = _stat_rows[stat]
		var current: int = entity.get(stat)
		var at_cap = current >= entity.stat_caps.get(stat, 9999)
		ref["value"].text = str(current)
		ref["gain"].text = "Đã tối đa" if at_cap else "+%d" % UpgradeManager.UPGRADE_AMOUNTS[stat]
		for b in ref["buttons"]:
			var count: int = b.get_meta("count")
			var needed = 1 if count >= 999 else count
			b.disabled = at_cap or entity.skill_points < maxi(needed, UpgradeManager.UPGRADE_COST)

func _on_upgrade_pressed(stat: String, count: int):
	var entity = characters[selected_index]
	var done = 0
	if count == 1:
		done = 1 if UpgradeManager.upgrade_stat(entity, stat) else 0
	else:
		done = UpgradeManager.bulk_upgrade(entity, stat, count)
	if done > 0:
		_refresh_stats()
		_keep_focus()

# Nút vừa bấm có thể bị khóa do hết SP: chuyển focus sang nút gần nhất còn bấm được cùng hàng, nếu không thì nút Đóng
func _keep_focus():
	var focused = get_viewport().gui_get_focus_owner()
	if not (focused is Button and focused.disabled and stat_vbox.is_ancestor_of(focused)):
		return
	var siblings = focused.get_parent().get_children()
	var from = siblings.find(focused)
	for i in range(from - 1, -1, -1):
		if not siblings[i].disabled:
			siblings[i].grab_focus()
			return
	for i in range(from + 1, siblings.size()):
		if not siblings[i].disabled:
			siblings[i].grab_focus()
			return
	_close_btn.grab_focus()

# Focus trễ một nhịp (sau khi các node queue_free() đã dọn); bỏ qua nếu nút đã bị xóa/gỡ khỏi cây trước đó
func _focus_later(ctrl):
	if is_instance_valid(ctrl) and ctrl.is_inside_tree():
		ctrl.grab_focus()
