class_name PauseMenuBuilder
extends RefCounted

"""
PauseMenuBuilder: dựng khung giao diện cho PauseMenu (menu tạm dừng, cẩm nang, tùy chọn) bằng UITheme.
"""

const PAUSE_WIDTH = 400
const OPTIONS_WIDTH = 460

const GUIDE_SECTIONS = [
	["Công thức sát thương", "Sát thương = (ATK × hệ số kỹ năng − DEF) × (1 − RES/100) × hệ số hệ.\nSát thương tối thiểu luôn bằng 5% ATK của người đánh. Chí mạng nhân thêm Crit DMG."],
	["Hệ nguyên tố", "Cool > Happy > Cute > Cool. Mysterious và Pure khắc chế lẫn nhau.\nĐánh trúng hệ khắc gây 125% sát thương, đánh vào hệ bị khắc chỉ còn 80%."],
	["Phá điểm yếu (Break)", "Mỗi đòn đánh làm giảm thanh Break của kẻ địch, mạnh nhất khi đánh trúng hệ yếu.\nKhi thanh Break cạn: kẻ địch bị Choáng 1 lượt và bị đẩy lùi trên thanh thứ tự lượt."],
	["Thứ tự lượt", "Tốc độ (SPD) càng cao thì càng tới lượt thường xuyên. Dải thứ tự lượt nằm ở giữa mép trên màn hình.\nDùng Choáng hoặc làm cạn thanh Break để chiếm lượt."],
	["Nâng cấp chỉ số", "Nói chuyện với Kanade tại căn cứ (về sau là Honami) để dùng Điểm Kỹ Năng (SP) nâng cấp vĩnh viễn chỉ số. Nâng cấp cho ai thì người đó mạnh lên, kể cả khi họ trở thành kẻ địch."],
]

static func build_base_ui(menu: Node) -> Dictionary:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(root)

	root.add_child(UITheme.dim_layer(0.78))

	var panel := UITheme.centered_panel(PAUSE_WIDTH)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_3)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Tạm dừng"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, UITheme.FS_TITLE, UITheme.ACCENT)
	vbox.add_child(title)

	var guide_panel := PanelContainer.new()
	guide_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guide_panel.offset_left = 120; guide_panel.offset_right = -120
	guide_panel.offset_top = 60; guide_panel.offset_bottom = -60
	guide_panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.BREAK, UITheme.SP_6))
	guide_panel.visible = false
	root.add_child(guide_panel)

	var options_panel := UITheme.centered_panel(OPTIONS_WIDTH)
	options_panel.visible = false
	root.add_child(options_panel)

	return {
		"root": root,
		"panel": panel,
		"vbox": vbox,
		"guide_panel": guide_panel,
		"options_panel": options_panel,
	}

static func build_guide_panel(guide_panel: PanelContainer, on_close: Callable = Callable()) -> void:
	UITheme.clear_children(guide_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UITheme.SP_3)
	guide_panel.add_child(outer)

	var header := HBoxContainer.new()
	outer.add_child(header)
	var title := UITheme.make_label("Cẩm nang chiến đấu", UITheme.FS_TITLE, UITheme.BREAK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := UITheme.make_button("Đóng", UITheme.Kind.GHOST, UITheme.FS_LABEL, on_close)
	if not on_close.is_valid():
		close_btn.pressed.connect(func(): guide_panel.visible = false)
	header.add_child(close_btn)
	UITheme.focus_later(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", UITheme.SP_4)
	scroll.add_child(column)

	for section in GUIDE_SECTIONS:
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", UITheme.SP_1)
		block.add_child(UITheme.make_label(section[0], UITheme.FS_HEADING, UITheme.ACCENT))
		var body := UITheme.make_label(section[1], UITheme.FS_LABEL, UITheme.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		block.add_child(body)
		column.add_child(block)

	guide_panel.visible = true
