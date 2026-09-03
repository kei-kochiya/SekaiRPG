class_name PauseMenuBuilder
extends RefCounted

const PANEL_BROWN_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg"
const PANEL_GREY_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/panel_grey.svg"
const BUTTON_BROWN_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg"
const BUTTON_GREY_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg"
const FONT_PATH = "res://Assets/Fonts/#9Slide03 AMPLESOFT MEDIUM.ttf"

static func build_base_ui(menu: Node) -> Dictionary:
	var _root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.add_child(_root)
	
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	_root.add_child(dim)
	
	var _panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -200
	_panel.offset_right = 200
	_panel.offset_top = -220
	_panel.offset_bottom = 220
	
	var sb = StyleBoxTexture.new()
	sb.texture = load(PANEL_BROWN_TEX)
	sb.texture_margin_left = 12; sb.texture_margin_right = 12
	sb.texture_margin_top = 12; sb.texture_margin_bottom = 12
	sb.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_font_override("font", load(FONT_PATH))
	vbox.add_child(title)
	
	var _guide_panel = PanelContainer.new()
	_guide_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_guide_panel.offset_left = 50
	_guide_panel.offset_right = -50
	_guide_panel.offset_top = 50
	_guide_panel.offset_bottom = -50
	_guide_panel.visible = false
	
	var gsb = StyleBoxFlat.new()
	gsb.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	gsb.border_width_left = 4
	gsb.border_color = Color(0.4, 1.0, 0.7)
	_guide_panel.add_theme_stylebox_override("panel", gsb)
	_root.add_child(_guide_panel)

	var _options_panel = PanelContainer.new()
	_options_panel.set_anchors_preset(Control.PRESET_CENTER)
	_options_panel.offset_left = -200; _options_panel.offset_right = 200
	_options_panel.offset_top = -150; _options_panel.offset_bottom = 150
	_options_panel.visible = false
	
	var osb = StyleBoxTexture.new()
	osb.texture = load(PANEL_GREY_TEX)
	osb.texture_margin_left = 12; osb.texture_margin_right = 12
	osb.texture_margin_top = 12; osb.texture_margin_bottom = 12
	osb.set_content_margin_all(20)
	_options_panel.add_theme_stylebox_override("panel", osb)
	_root.add_child(_options_panel)

	return {
		"root": _root,
		"panel": _panel,
		"vbox": vbox,
		"guide_panel": _guide_panel,
		"options_panel": _options_panel
	}

static func create_button(txt: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.add_theme_font_size_override("font_size", 18)
	
	var normal = StyleBoxTexture.new()
	normal.texture = load(BUTTON_BROWN_TEX)
	normal.texture_margin_left = 8; normal.texture_margin_right = 8
	normal.texture_margin_top = 8; normal.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxTexture.new()
	hover.texture = load(BUTTON_GREY_TEX)
	hover.texture_margin_left = 8; hover.texture_margin_right = 8
	hover.texture_margin_top = 8; hover.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(0.15, 0.08, 0.05))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	btn.add_theme_color_override("font_focus_color", Color(0, 0, 0))
	
	btn.pressed.connect(callback)
	return btn

static func build_guide_panel(_guide_panel: PanelContainer) -> void:
	for child in _guide_panel.get_children():
		child.queue_free()
		
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_guide_panel.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var close = Button.new()
	close.text = "[ ĐÓNG HƯỚNG DẪN ]"
	close.pressed.connect(func(): _guide_panel.visible = false)
	vbox.add_child(close)
	
	var title = Label.new()
	title.text = "CẨM NANG CHIẾN ĐẤU NÂNG CAO"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = """
1. CÔNG THỨC TÍNH SÁT THƯƠNG:
   Sát thương = (ATK - DEF) * (1 - RES/100) * Hệ số hệ
   - ATK: Tấn công của bạn.
   - DEF: Phòng thủ của kẻ địch (giảm trực tiếp sát thương).
   - RES: Kháng (giảm theo % sát thương sau khi trừ DEF).
   * Sát thương tối thiểu luôn bằng 5% ATK của người đánh.

2. HỆ THỐNG HỆ (TYPE CHART):
   - Cool > Happy
   - Happy > Cute
   - Cute > Cool
   - Mysterious <> Pure
   * Hệ khắc chế gây 125% sát thương. Hệ bị khắc gây 80%.

3. THỨ TỰ LƯỢT (ACTION GAUGE):
   - Tốc độ (SPD) càng cao, bạn càng xuất hiện nhiều lần trong thanh hành động bên trái.
   - Sử dụng các kỹ năng Stun hoặc giảm tốc kẻ địch để chiếm ưu thế lượt đánh.

4. NÂNG CẤP CHỈ SỐ:
   - Nói chuyện với Kanade tại căn cứ để dùng Điểm Kỹ Năng (SP) nâng cấp vĩnh viễn các chỉ số cho cả đội.
"""
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text)
	
	_guide_panel.visible = true
