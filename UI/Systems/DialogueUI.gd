extends Control
class_name DialogueUI

"""
Tóm tắt: DialogueUI là thành phần hiển thị (View) của hệ thống hội thoại.

Chức năng chính:
- Khởi tạo và thiết lập các phần tử giao diện người dùng: khung thoại (PanelContainer), text (RichTextLabel), ảnh chân dung (TextureRect), nút bấm.
- Xử lý hiệu ứng hiển thị: đổi màu text (BBCode), đổi kích thước/độ mờ của chân dung nhân vật đang nói.
- Cung cấp API `display_line` và `display_choices` cho DialogueManager gọi đến.
- Quản lý giao diện của màn hình tường thuật (Narrator mode) không có chân dung nhân vật.
"""

# ── Biến Giao Diện ──────────────────────────────────────────────────────────



signal choice_selected(idx: int)

var dialogue_box: PanelContainer
var text_label: RichTextLabel
var left_portrait: TextureRect
var right_portrait: TextureRect
var narrator_box: PanelContainer
var narrator_label: RichTextLabel
var choice_box: VBoxContainer
var choice_panel: PanelContainer

# ── Khởi Tạo UI ────────────────────────────────────────────────────────────

# Thiết lập căn chỉnh ban đầu
func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_ui()

# Khởi tạo các thành phần giao diện
func _init_ui():
	var d_layer = Control.new()
	d_layer.name = "DialogueLayer"
	d_layer.anchor_right = 1.0
	d_layer.anchor_bottom = 1.0
	d_layer.offset_left = 0
	d_layer.offset_right = 0
	d_layer.offset_top = 0
	d_layer.offset_bottom = 0
	d_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d_layer)

	var clicker = TextureButton.new()
	clicker.name = "Clicker"
	clicker.anchor_right = 1.0
	clicker.anchor_bottom = 1.0
	clicker.offset_left = 0
	clicker.offset_right = 0
	clicker.offset_top = 0
	clicker.offset_bottom = 0
	clicker.mouse_filter = Control.MOUSE_FILTER_STOP
	d_layer.add_child(clicker)

	var base_font = load("res://Fonts/#9Slide03 AMPLESOFT MEDIUM.ttf")
	var italic_font = FontVariation.new()
	italic_font.base_font = base_font
	italic_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)

	_build_narrator_box(d_layer, base_font)
	_build_portraits(d_layer)
	_build_dialogue_box(d_layer, base_font, italic_font)
	_build_choice_panel(d_layer)

func _build_narrator_box(parent: Control, font: Font):
	narrator_box = PanelContainer.new()
	narrator_box.set_anchors_preset(Control.PRESET_CENTER)
	narrator_box.offset_left = -400; narrator_box.offset_right = 400
	narrator_box.offset_top = -40; narrator_box.offset_bottom = 40
	narrator_box.add_theme_stylebox_override("panel", _get_style("panel_brown_dark.svg", 12, 20))
	narrator_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(narrator_box)
	
	narrator_label = RichTextLabel.new()
	narrator_label.bbcode_enabled = true
	narrator_label.fit_content = true
	narrator_label.add_theme_font_size_override("normal_font_size", 20)
	narrator_label.add_theme_font_override("normal_font", font)
	narrator_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	narrator_box.add_child(narrator_label)
	narrator_box.visible = false

func _build_portraits(parent: Control):
	left_portrait = _create_portrait(Control.PRESET_BOTTOM_LEFT, 80, -456)
	right_portrait = _create_portrait(Control.PRESET_BOTTOM_RIGHT, -336, -456)
	parent.add_child(left_portrait)
	parent.add_child(right_portrait)

func _build_dialogue_box(parent: Control, base_font: Font, italic_font: FontVariation):
	dialogue_box = PanelContainer.new()
	dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_box.offset_top = -200; dialogue_box.offset_bottom = -30
	dialogue_box.offset_left = 100; dialogue_box.offset_right = -100
	dialogue_box.add_theme_stylebox_override("panel", _get_style("panel_brown.svg", 12, 25))
	dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dialogue_box)

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.add_theme_font_size_override("normal_font_size", 22)
	text_label.add_theme_font_size_override("bold_font_size", 28)
	text_label.add_theme_color_override("default_color", Color(0.15, 0.08, 0.05))
	text_label.add_theme_font_override("normal_font", base_font)
	text_label.add_theme_font_override("bold_font", base_font)
	text_label.add_theme_font_override("italic_font", italic_font)
	text_label.add_theme_font_override("italics_font", italic_font)
	text_label.add_theme_font_override("bold_italic_font", italic_font)
	text_label.add_theme_font_override("bold_italics_font", italic_font)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_box.add_child(text_label)

func _build_choice_panel(parent: Control):
	choice_panel = PanelContainer.new()
	choice_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	choice_panel.offset_top = -390; choice_panel.offset_bottom = -215
	choice_panel.offset_left = 200; choice_panel.offset_right = -200
	choice_panel.add_theme_stylebox_override("panel", _get_style("panel_border_brown.svg", 32, 16))
	parent.add_child(choice_panel)
	
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	choice_panel.add_child(choice_box)
	choice_panel.visible = false

# ── API Hiển Thị ───────────────────────────────────────────────────────────

func display_line(line: Dictionary):
	"""
	Hiển thị một dòng thoại lên màn hình, tự động điều chỉnh khung và chân dung.
	
	Args:
		line (Dictionary): Dữ liệu dòng thoại chứa type, text, name, speaker và color.
	Returns: Không có
	"""
	var type = line.get("type", "dialogue")
	var text = line.get("text", "")
	var speaker_name = line.get("name", "")
	var speaker_side = line.get("speaker", "left")
	var color = line.get("color", Color.WHITE)

	narrator_box.visible = (type == "narrator")
	dialogue_box.visible = (type != "narrator")
	left_portrait.visible = (type != "narrator")
	right_portrait.visible = (type != "narrator")

	if type == "narrator":
		narrator_label.text = "[center][color=#ddddcc]%s[/color][/center]" % text
	else:
		var final_text = "[i]%s[/i]" % text if type == "action" else text
		text_label.text = "[b][color=#%s]%s:[/color][/b]\n\n%s" % [color.to_html(false), speaker_name, final_text]
		_update_portraits(speaker_name, speaker_side)

func display_choices(options: Array):
	"""
	Hiển thị danh sách các lựa chọn lên màn hình.
	
	Args:
		options (Array): Mảng chứa chuỗi văn bản của các lựa chọn.
	Returns: Không có
	"""
	choice_panel.visible = true
	for c in choice_box.get_children(): c.queue_free()
	for i in options.size():
		var btn = Button.new()
		btn.text = options[i]
		btn.add_theme_stylebox_override("normal", _get_style("button_brown.svg", 10, 10))
		btn.add_theme_stylebox_override("hover", _get_style("button_grey.svg", 10, 10))
		btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		btn.add_theme_font_override("font", load("res://Fonts/#9Slide03 AMPLESOFT MEDIUM.ttf"))
		btn.pressed.connect(func(): choice_selected.emit(i))
		choice_box.add_child(btn)
	
	if choice_box.get_child_count() > 0:
		choice_box.get_child(0).grab_focus()

# Xóa nội dung trên màn hình
func clear():
	left_portrait.texture = null
	right_portrait.texture = null
	text_label.text = ""
	narrator_label.text = ""
	narrator_box.visible = false
	dialogue_box.visible = false
	choice_panel.visible = false

# ── Tiện Ích Nội Bộ ────────────────────────────────────────────────────────

# Cập nhật hình ảnh và animation cho chân dung nhân vật
func _update_portraits(character_name: String, side: String):
	var path = "res://Art/Portraits/%s.png" % character_name.to_lower()
	var tex = load(path) if ResourceLoader.exists(path) else null
	
	if side == "left":
		if right_portrait.texture == tex: right_portrait.texture = null
		left_portrait.texture = tex
	else:
		if left_portrait.texture == tex: left_portrait.texture = null
		right_portrait.texture = tex
	
	var tw = create_tween().set_parallel(true)
	var focus_l = (side == "left")
	tw.tween_property(left_portrait, "modulate", Color(1,1,1,1) if focus_l else Color(0.4,0.4,0.4,1), 0.2)
	tw.tween_property(left_portrait, "scale", Vector2(1.05, 1.05) if focus_l else Vector2(0.9, 0.9), 0.2)
	tw.tween_property(right_portrait, "modulate", Color(1,1,1,1) if not focus_l else Color(0.4,0.4,0.4,1), 0.2)
	tw.tween_property(right_portrait, "scale", Vector2(1.05, 1.05) if not focus_l else Vector2(0.9, 0.9), 0.2)

# Tạo StyleBoxTexture với các thông số truyền vào
func _get_style(tex: String, margin: int, padding: int) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/" + tex)
	s.texture_margin_left = margin; s.texture_margin_right = margin
	s.texture_margin_top = margin; s.texture_margin_bottom = margin
	s.set_content_margin_all(padding)
	return s

# Khởi tạo TextureRect chân dung
func _create_portrait(preset: int, x: int, y: int) -> TextureRect:
	var t = TextureRect.new()
	t.custom_minimum_size = Vector2(256, 256)
	t.set_anchors_preset(preset)
	t.offset_left = x; t.offset_right = x + 256
	t.offset_top = y; t.offset_bottom = y + 256
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.pivot_offset = Vector2(128, 256)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
