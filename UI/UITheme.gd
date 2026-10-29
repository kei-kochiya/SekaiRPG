class_name UITheme
extends RefCounted

"""
UITheme: nguồn duy nhất cho màu sắc, cỡ chữ, khoảng cách và StyleBox của toàn bộ giao diện.

- Mọi màn hình lấy token từ đây thay vì tự hard-code màu/cỡ chữ.
- `make_theme()` dựng Theme dùng chung; chạy `Scripts/Editor/BuildTheme.gd` để ghi lại `default_theme.tres`.
- Bảng màu: nền xám xanh (tint về hue 215) để panel không bị "xám chết", accent vàng hổ phách cho hành động
  chính, teal cho phe ta, san hô cho phe địch. Tỷ lệ tương phản chữ/nền đều >= 4.5:1.
"""

# ── Màu: nền (tối -> sáng) ─────────────────────────────────────────────────
const INK_900 := Color("0f1318") # backdrop toàn màn hình
const INK_800 := Color("161c24") # panel
const INK_700 := Color("1f2731") # control / vùng lõm
const INK_600 := Color("2c3744") # viền
const INK_500 := Color("455364") # viền nhấn / disabled

# ── Màu: chữ ───────────────────────────────────────────────────────────────
const TEXT := Color("eef1f5")
const TEXT_MUTED := Color("9aa7b6")
const TEXT_DISABLED := Color("6b7888")
const TEXT_ON_ACCENT := Color("1a1208")

# ── Màu: ngữ nghĩa ─────────────────────────────────────────────────────────
const ACCENT := Color("f0b95a")
const ACCENT_HOVER := Color("f7cb7d")
const ACCENT_PRESSED := Color("c8923a")
const PLAYER := Color("4fc3b8")
const ENEMY := Color("f08a6a")
const DANGER := Color("b83232")
const DANGER_HOVER := Color("c03636")
const DANGER_TEXT := Color("ff6b6b")
const SUCCESS := Color("5ac46e")
const BREAK := Color("59c7f0")
const WARNING := Color("f0b95a")

# Màu hệ nguyên tố (khớp TypeChart) và hiệu ứng trạng thái
const ELEMENT_COLORS := {
	"Cool": Color("5aa9f0"),
	"Happy": Color("f2c94c"),
	"Cute": Color("f08fb8"),
	"Mysterious": Color("a78bfa"),
	"Pure": Color("e8edf3"),
}
const STATUS_INFO := {
	"Bleed": {"label": "Chảy máu", "color": Color("e5484d"), "icon": "res://Assets/Icons/bleed.png"},
	"Poison": {"label": "Trúng độc", "color": Color("5ac46e"), "icon": "res://Assets/Icons/poison.png"},
	"Stun": {"label": "Choáng", "color": Color("f2c94c"), "icon": "res://Assets/Icons/stun.png"},
}

# ── Cỡ chữ (thang 6 bậc, sàn 14 để đọc được trên điện thoại) ───────────────────────────────────────────────────
const FS_CAPTION := 14 # sàn tối thiểu, không dùng chữ nhỏ hơn
const FS_BODY := 16
const FS_LABEL := 18
const FS_HEADING := 22
const FS_READING := 22 # văn bản hội thoại / đoạn đọc dài
const FS_TITLE := 30
const FS_DISPLAY := 44

# ── Khoảng cách (thang 4px) ────────────────────────────────────────────────
const SP_1 := 4
const SP_2 := 8
const SP_3 := 12
const SP_4 := 16
const SP_6 := 24
const SP_8 := 32
const SP_12 := 48

const RADIUS_SM := 4
const RADIUS_MD := 8
const MIN_TOUCH := 48 # chiều cao tối thiểu của nút bấm (hợp mobile)

# Chakra Petch (tiêu đề, nút, số liệu) + Be Vietnam Pro (hội thoại, văn bản). Cả hai đều OFL, có đủ dấu tiếng Việt.
const FONT_BODY_PATH := "res://Assets/Fonts/BeVietnamPro-Regular.ttf"
const FONT_BODY_MEDIUM_PATH := "res://Assets/Fonts/BeVietnamPro-Medium.ttf"
const FONT_BODY_STRONG_PATH := "res://Assets/Fonts/BeVietnamPro-SemiBold.ttf"
const FONT_DISPLAY_MEDIUM_PATH := "res://Assets/Fonts/ChakraPetch-Medium.ttf"
const FONT_DISPLAY_PATH := "res://Assets/Fonts/ChakraPetch-SemiBold.ttf"
const FONT_DISPLAY_BOLD_PATH := "res://Assets/Fonts/ChakraPetch-Bold.ttf"

enum Kind { PRIMARY, SECONDARY, DANGER, GHOST }

# ── StyleBox ───────────────────────────────────────────────────────────────

static func box(bg: Color, border: Color = Color.TRANSPARENT, radius: int = RADIUS_MD, pad_h: int = SP_4, pad_v: int = SP_3, border_w: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w if border.a > 0.0 else 0)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	return sb

# Panel chuẩn. `accent` (nếu có) vẽ vạch màu dày ở cạnh trên để phân biệt phe/ngữ cảnh.
static func panel(bg: Color = INK_800, border: Color = INK_600, accent: Color = Color.TRANSPARENT, pad: int = SP_4) -> StyleBoxFlat:
	var sb := box(bg, border, RADIUS_MD, pad, pad)
	if accent.a > 0.0:
		sb.border_width_top = 3
		sb.border_color = accent
		sb.border_blend = false
	return sb

static func element_color(element: String) -> Color:
	return ELEMENT_COLORS.get(element, TEXT_MUTED)

# Nền toàn màn hình: vignette tròn tối dần ra mép, thay cho màu xám mặc định.
static func backdrop() -> TextureRect:
	var grad := Gradient.new()
	grad.set_color(0, INK_700)
	grad.set_color(1, INK_900)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.45)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func overlay_dim(alpha: float = 0.6) -> Color:
	return Color(INK_900.r, INK_900.g, INK_900.b, alpha)

# ── Control helper ─────────────────────────────────────────────────────────

static func font_body() -> Font:
	return load(FONT_BODY_PATH)

static func font_body_medium() -> Font:
	return load(FONT_BODY_MEDIUM_PATH)

static func font_body_strong() -> Font:
	return load(FONT_BODY_STRONG_PATH)

# Chakra Petch SemiBold: nút bấm và tiêu đề vừa.
static func font_display() -> Font:
	return load(FONT_DISPLAY_PATH)

# Chakra Petch Medium: số liệu nhỏ (HP, thanh lượt) cần nét mảnh hơn.
static func font_display_medium() -> Font:
	return load(FONT_DISPLAY_MEDIUM_PATH)

# Chakra Petch Bold: tên nhân vật, tiêu đề lớn.
static func font_display_bold() -> Font:
	return load(FONT_DISPLAY_BOLD_PATH)

static func style_label(label: Control, size: int = FS_BODY, color: Color = TEXT) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if size <= FS_CAPTION:
		label.add_theme_font_override("font", font_body_medium()) # nét dày hơn một chút để dễ đọc ở cỡ 14

static func style_title(label: Label, size: int = FS_TITLE, color: Color = ACCENT) -> void:
	style_label(label, size, color)
	label.add_theme_font_override("font", font_display_bold())

static func style_panel(ctrl: Control, accent: Color = Color.TRANSPARENT, bg: Color = INK_800) -> void:
	ctrl.add_theme_stylebox_override("panel", panel(bg, INK_600, accent))

# Nhãn nhỏ dạng "chip" (hệ nguyên tố, hiệu ứng trạng thái...). Nền là màu chủ đạo pha tối, chữ là chính màu đó.
static func chip(text: String, color: Color, size: int = FS_CAPTION, icon: Texture2D = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(Color(color.r, color.g, color.b, 0.18), Color(color.r, color.g, color.b, 0.55), RADIUS_SM, SP_2, 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", SP_1)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	if icon:
		var tex := TextureRect.new()
		tex.texture = icon
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.custom_minimum_size = Vector2(16, 16)
		tex.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS # icon 32px thu về 16px
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(tex)
	var l := Label.new()
	l.text = text
	style_label(l, size, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

# Icon của một hiệu ứng trạng thái (Bleed/Poison/Stun); null nếu loại đó không có icon.
static func status_icon(type_name: String) -> Texture2D:
	var path: String = STATUS_INFO.get(type_name, {}).get("icon", "")
	return load(path) if path != "" and ResourceLoader.exists(path) else null

static func make_label(text: String, size: int = FS_BODY, color: Color = TEXT, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	style_label(l, size, color)
	return l

static func style_button(btn: Button, kind: Kind = Kind.SECONDARY, size: int = FS_LABEL) -> void:
	var boxes := button_boxes(kind)
	for state in boxes:
		btn.add_theme_stylebox_override(state, boxes[state])
	var fg := TEXT_ON_ACCENT if kind == Kind.PRIMARY else TEXT
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_focus_color", fg)
	btn.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	btn.add_theme_font_override("font", font_display())
	btn.add_theme_font_size_override("font_size", size)
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, MIN_TOUCH)
	btn.focus_mode = Control.FOCUS_ALL

static func button_boxes(kind: Kind) -> Dictionary:
	var normal_bg: Color
	var hover_bg: Color
	var pressed_bg: Color
	var border: Color
	match kind:
		Kind.PRIMARY:
			normal_bg = ACCENT
			hover_bg = ACCENT_HOVER
			pressed_bg = ACCENT_PRESSED
			border = Color.TRANSPARENT
		Kind.DANGER:
			normal_bg = DANGER
			hover_bg = DANGER_HOVER
			pressed_bg = DANGER.darkened(0.2)
			border = Color.TRANSPARENT
		Kind.GHOST:
			normal_bg = Color.TRANSPARENT
			hover_bg = INK_700
			pressed_bg = INK_600
			border = Color.TRANSPARENT
		_:
			normal_bg = INK_700
			hover_bg = INK_600
			pressed_bg = INK_500
			border = INK_600
	# Nút PRIMARY nền vàng nên viền focus phải khác màu (chữ sáng), không thì vòng focus biến mất.
	var focus := box(Color.TRANSPARENT, TEXT if kind == Kind.PRIMARY else ACCENT, RADIUS_MD, SP_4, SP_2, 2)
	return {
		"normal": box(normal_bg, border, RADIUS_MD, SP_4, SP_2),
		"hover": box(hover_bg, border, RADIUS_MD, SP_4, SP_2),
		"pressed": box(pressed_bg, border, RADIUS_MD, SP_4, SP_2),
		"disabled": box(INK_800, INK_700, RADIUS_MD, SP_4, SP_2),
		"focus": focus,
	}

static func style_bar(bar: ProgressBar, fill: Color, height: int = 12) -> void:
	bar.show_percentage = false
	bar.custom_minimum_size.y = maxf(bar.custom_minimum_size.y, height)
	bar.add_theme_stylebox_override("background", box(INK_900, INK_600, RADIUS_SM, 0, 0))
	bar.add_theme_stylebox_override("fill", box(fill, Color.TRANSPARENT, RADIUS_SM, 0, 0))

# ── Icon sinh bằng code (công tắc / ô tích) ────────────────────────────────

static func _coverage(dist: float, radius: float) -> float:
	return clampf(radius - dist + 0.5, 0.0, 1.0)

static func _blend(img: Image, x: int, y: int, color: Color, coverage: float) -> void:
	if coverage <= 0.0:
		return
	var under := img.get_pixel(x, y)
	var a := coverage * color.a
	var out_a := a + under.a * (1.0 - a)
	var rgb := (Vector3(color.r, color.g, color.b) * a + Vector3(under.r, under.g, under.b) * under.a * (1.0 - a)) / maxf(out_a, 0.0001)
	img.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, out_a))

# Công tắc 44x24: rãnh bo tròn + núm tròn (vàng khi bật, xám khi tắt).
static func switch_icon(on: bool, disabled: bool = false) -> ImageTexture:
	var w := 44
	var h := 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r := h / 2.0
	var track := ACCENT if on else INK_500
	var knob := TEXT_ON_ACCENT if on else TEXT
	if disabled:
		track = INK_600
		knob = TEXT_DISABLED
	var knob_x := (w - r) if on else r
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var seg := Vector2(clampf(p.x, r, w - r), r)
			_blend(img, x, y, track, _coverage(p.distance_to(seg), r))
			_blend(img, x, y, knob, _coverage(p.distance_to(Vector2(knob_x, r)), r - 4.0))
	return ImageTexture.create_from_image(img)

# Ô tích 22x22: ô bo góc, có dấu tích tối màu khi được chọn.
static func checkbox_icon(checked: bool, disabled: bool = false) -> ImageTexture:
	var n := 22
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var fill := ACCENT if checked else INK_900
	var border := ACCENT if checked else INK_500
	if disabled:
		fill = INK_800
		border = INK_600
	var corner := 5.0
	var tick_a := Vector2(5.5, 11.5)
	var tick_b := Vector2(9.5, 15.5)
	var tick_c := Vector2(16.5, 7.0)
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5)
			var q := (p - Vector2(n / 2.0, n / 2.0)).abs() - Vector2(n / 2.0 - corner, n / 2.0 - corner)
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - corner
			_blend(img, x, y, border, _coverage(d, 0.0))
			_blend(img, x, y, fill, _coverage(d + 2.0, 0.0))
			if checked:
				var dist := minf(_segment_distance(p, tick_a, tick_b), _segment_distance(p, tick_b, tick_c))
				_blend(img, x, y, TEXT_ON_ACCENT, _coverage(dist, 1.3))
	return ImageTexture.create_from_image(img)

static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)

# ── Theme dùng chung ───────────────────────────────────────────────────────

static func make_theme() -> Theme:
	var t := Theme.new()
	var body := font_body()
	var display := font_display()
	t.default_font = body
	t.default_font_size = FS_BODY

	# Label / RichTextLabel
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", FS_BODY)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_font_size("normal_font_size", "RichTextLabel", FS_BODY)
	t.set_font("bold_font", "RichTextLabel", font_body_strong())

	# Button
	var boxes := button_boxes(Kind.SECONDARY)
	for state in boxes:
		t.set_stylebox(state, "Button", boxes[state])
	t.set_font("font", "Button", display)
	t.set_font_size("font_size", "Button", FS_LABEL)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", TEXT_DISABLED)

	# Panel
	t.set_stylebox("panel", "PanelContainer", panel())
	t.set_stylebox("panel", "Panel", panel())
	t.set_constant("separation", "VBoxContainer", SP_2)
	t.set_constant("separation", "HBoxContainer", SP_2)

	# ProgressBar
	t.set_stylebox("background", "ProgressBar", box(INK_900, INK_600, RADIUS_SM, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(PLAYER, Color.TRANSPARENT, RADIUS_SM, 0, 0))
	t.set_color("font_color", "ProgressBar", TEXT)

	# Input
	var field := box(INK_900, INK_600, RADIUS_SM, SP_3, SP_2)
	var field_focus := box(INK_900, ACCENT, RADIUS_SM, SP_3, SP_2, 2)
	t.set_stylebox("normal", "LineEdit", field)
	t.set_stylebox("focus", "LineEdit", field_focus)
	t.set_stylebox("read_only", "LineEdit", field)
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", ACCENT)
	t.set_color("selection_color", "LineEdit", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.35))

	# CheckBox / CheckButton: không nền, chỉ giữ viền focus để vẫn điều hướng được bằng bàn phím
	for toggle in ["CheckBox", "CheckButton"]:
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			t.set_stylebox(state, toggle, StyleBoxEmpty.new())
		t.set_stylebox("focus", toggle, box(Color.TRANSPARENT, ACCENT, RADIUS_SM, SP_1, SP_1, 2))
		for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			t.set_color(color_name, toggle, TEXT)
		t.set_constant("h_separation", toggle, SP_2)
	t.set_icon("checked", "CheckButton", switch_icon(true))
	t.set_icon("unchecked", "CheckButton", switch_icon(false))
	t.set_icon("checked_disabled", "CheckButton", switch_icon(true, true))
	t.set_icon("unchecked_disabled", "CheckButton", switch_icon(false, true))
	t.set_icon("checked", "CheckBox", checkbox_icon(true))
	t.set_icon("unchecked", "CheckBox", checkbox_icon(false))
	t.set_icon("checked_disabled", "CheckBox", checkbox_icon(true, true))
	t.set_icon("unchecked_disabled", "CheckBox", checkbox_icon(false, true))

	# Slider
	t.set_stylebox("slider", "HSlider", box(INK_900, INK_600, RADIUS_SM, 0, 3))
	t.set_stylebox("grabber_area", "HSlider", box(ACCENT, Color.TRANSPARENT, RADIUS_SM, 0, 3))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT_HOVER, Color.TRANSPARENT, RADIUS_SM, 0, 3))

	# Scrollbar
	# Content margin quyết định độ dày thanh cuộn; để 0 thì thanh cuộn có bề rộng bằng 0 và biến mất.
	var track := box(INK_900, Color.TRANSPARENT, RADIUS_SM, 6, 6)
	var grab := box(INK_500, Color.TRANSPARENT, RADIUS_SM, 6, 6)
	var grab_hl := box(TEXT_MUTED, Color.TRANSPARENT, RADIUS_SM, 6, 6)
	for sb in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", sb, track)
		t.set_stylebox("grabber", sb, grab)
		t.set_stylebox("grabber_highlight", sb, grab_hl)
		t.set_stylebox("grabber_pressed", sb, grab_hl)

	# Tooltip / popup
	t.set_stylebox("panel", "TooltipPanel", box(INK_700, INK_500, RADIUS_SM, SP_2, SP_1))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("panel", "PopupMenu", panel(INK_800, INK_500, Color.TRANSPARENT, SP_2))
	t.set_stylebox("hover", "PopupMenu", box(INK_600, Color.TRANSPARENT, RADIUS_SM, SP_2, SP_1))
	t.set_color("font_color", "PopupMenu", TEXT)

	# Separator
	var line := StyleBoxLine.new()
	line.color = INK_600
	line.thickness = 1
	t.set_stylebox("separator", "HSeparator", line)
	t.set_constant("separation", "HSeparator", SP_2)
	return t
