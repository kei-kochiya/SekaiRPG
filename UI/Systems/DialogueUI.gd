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
var name_label: Label
var text_label: RichTextLabel
var left_portrait: TextureRect
var right_portrait: TextureRect
var narrator_box: PanelContainer
var narrator_label: RichTextLabel
var choice_box: VBoxContainer
var choice_panel: PanelContainer

const BOX_MARGIN = 120
const BOX_HEIGHT = 190 # chiều cao tối thiểu: đủ 3 dòng chữ; dòng dài hơn thì hộp tự cao thêm lên phía trên
const BOX_BOTTOM = UITheme.SP_8
const MIN_CONTRAST = 4.5

# ── Khởi Tạo UI ────────────────────────────────────────────────────────────

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_ui()

func _init_ui():
	var d_layer = Control.new()
	d_layer.name = "DialogueLayer"
	d_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d_layer)

	var clicker = TextureButton.new()
	clicker.name = "Clicker"
	clicker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clicker.mouse_filter = Control.MOUSE_FILTER_STOP
	clicker.focus_mode = Control.FOCUS_NONE
	d_layer.add_child(clicker)

	_build_narrator_box(d_layer)
	_build_portraits(d_layer)
	_build_dialogue_box(d_layer)
	_build_choice_panel(d_layer)

func _build_narrator_box(parent: Control):
	narrator_box = PanelContainer.new()
	narrator_box.set_anchors_preset(Control.PRESET_CENTER)
	narrator_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	narrator_box.grow_vertical = Control.GROW_DIRECTION_BOTH
	narrator_box.offset_left = -420; narrator_box.offset_right = 420
	narrator_box.offset_top = -60; narrator_box.offset_bottom = 60
	narrator_box.add_theme_stylebox_override("panel", UITheme.panel(UITheme.overlay_dim(0.85), UITheme.INK_600, Color.TRANSPARENT, UITheme.SP_6))
	narrator_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(narrator_box)
	
	narrator_label = RichTextLabel.new()
	narrator_label.bbcode_enabled = true
	narrator_label.fit_content = true
	narrator_label.scroll_active = false
	narrator_label.add_theme_font_size_override("normal_font_size", UITheme.FS_READING)
	narrator_label.add_theme_font_override("normal_font", UITheme.font_body())
	narrator_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	narrator_box.add_child(narrator_label)
	narrator_box.visible = false

func _build_portraits(parent: Control):
	left_portrait = _create_portrait(Control.PRESET_BOTTOM_LEFT, 80, -456)
	right_portrait = _create_portrait(Control.PRESET_BOTTOM_RIGHT, -336, -456)
	parent.add_child(left_portrait)
	parent.add_child(right_portrait)

func _build_dialogue_box(parent: Control):
	dialogue_box = PanelContainer.new()
	dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialogue_box.custom_minimum_size.y = BOX_HEIGHT
	dialogue_box.offset_top = -(BOX_HEIGHT + BOX_BOTTOM); dialogue_box.offset_bottom = -BOX_BOTTOM
	dialogue_box.offset_left = BOX_MARGIN; dialogue_box.offset_right = -BOX_MARGIN
	dialogue_box.add_theme_stylebox_override("panel", UITheme.panel(UITheme.overlay_dim(0.92), UITheme.INK_600, Color.TRANSPARENT, UITheme.SP_4))
	dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dialogue_box)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UITheme.SP_2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_box.add_child(column)

	name_label = Label.new()
	UITheme.style_title(name_label, UITheme.FS_HEADING, UITheme.ACCENT)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_label)

	var italic_font = FontVariation.new()
	italic_font.base_font = UITheme.font_body()
	italic_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-0.2, 1.0), Vector2.ZERO)
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_label.add_theme_font_size_override("normal_font_size", UITheme.FS_READING)
	text_label.add_theme_font_size_override("italics_font_size", UITheme.FS_READING)
	text_label.add_theme_color_override("default_color", UITheme.TEXT)
	text_label.add_theme_font_override("normal_font", UITheme.font_body())
	text_label.add_theme_font_override("italics_font", italic_font)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(text_label)

	var hint := UITheme.make_label("Enter / chạm để tiếp tục  ›", UITheme.FS_CAPTION, UITheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hint)

func _build_choice_panel(parent: Control):
	choice_panel = PanelContainer.new()
	choice_panel.set_anchors_preset(Control.PRESET_CENTER)
	choice_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	choice_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	choice_panel.custom_minimum_size.x = 520
	choice_panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.ACCENT, UITheme.SP_4))
	parent.add_child(choice_panel)
	
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", UITheme.SP_2)
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
		narrator_label.text = "[center][color=#%s]%s[/color][/center]" % [UITheme.TEXT.to_html(false), text]
	else:
		name_label.text = speaker_name
		name_label.add_theme_color_override("font_color", _readable(color) if color != Color.WHITE else UITheme.ACCENT)
		text_label.text = "[i]%s[/i]" % text if type == "action" else text
		_update_portraits(speaker_name, speaker_side)

func display_choices(options: Array):
	"""
	Hiển thị danh sách các lựa chọn lên màn hình.
	
	Args:
		options (Array): Mảng chứa chuỗi văn bản của các lựa chọn.
	Returns: Không có
	"""
	choice_panel.visible = true
	# Gỡ nút cũ ngay (queue_free chỉ xóa cuối frame) để focus không rơi vào nút cũ
	for c in choice_box.get_children():
		choice_box.remove_child(c)
		c.queue_free()
	var first: Button = null
	for i in options.size():
		var btn = Button.new()
		btn.text = options[i]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.style_button(btn, UITheme.Kind.SECONDARY, UITheme.FS_LABEL)
		btn.pressed.connect(func(): choice_selected.emit(i))
		choice_box.add_child(btn)
		if first == null:
			first = btn
	
	if first:
		first.call_deferred("grab_focus")

# Xóa nội dung trên màn hình
func clear():
	left_portrait.texture = null
	right_portrait.texture = null
	name_label.text = ""
	text_label.text = ""
	narrator_label.text = ""
	narrator_box.visible = false
	dialogue_box.visible = false
	choice_panel.visible = false

# ── Tiện Ích Nội Bộ ────────────────────────────────────────────────────────

# Màu tên người nói lấy từ dữ liệu (nhiều màu tối): nâng sáng dần tới khi đạt tương phản tối thiểu trên nền hộp thoại
func _readable(c: Color) -> Color:
	for i in 8:
		if _contrast(c, UITheme.INK_900) >= MIN_CONTRAST:
			break
		c = c.lerp(Color.WHITE, 0.15)
	return c

func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func _luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b

# Cập nhật hình ảnh và animation cho chân dung nhân vật
func _update_portraits(character_name: String, side: String):
	var path = "res://Assets/Portraits/%s.png" % character_name.to_lower()
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
