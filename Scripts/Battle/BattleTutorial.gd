extends Node
class_name BattleTutorial

"""
Tóm tắt: BattleTutorial quản lý giao diện hướng dẫn chiến đấu theo từng bước.

Chức năng chính:
- Hiển thị bảng giải thích cơ chế chiến đấu (Turn-based, Action Gauge, Kỹ năng) cho người chơi.
- Khóa cờ `is_tutorial` trong GameManager để đảm bảo hướng dẫn chỉ hiện một lần duy nhất.
- Tự động xây dựng UI bằng UITheme, hỗ trợ BBCode (màu trong nội dung được quy về bảng màu chung).
- Là lớp phủ modal: báo PauseMenu để ESC không mở menu tạm dừng chồng lên hướng dẫn.
"""

const PANEL_WIDTH = 640

# [tiêu đề, nội dung BBCode] của từng bước
const STEPS = [
	["Hướng dẫn chiến đấu (1/5)",
	 "Chào mừng đến với màn hình chiến đấu lượt theo lượt!\n\nBạn điều khiển [color=#4a9e9e]Ichika[/color]. Mỗi nhân vật hành động theo thứ tự dựa trên [color=#ffdd77]chỉ số Tốc độ (SPD)[/color]."],
	["Thanh hành động (2/5)",
	 "[color=#ffdd77]Action Gauge[/color] ở góc màn hình hiển thị thứ tự lượt của tất cả nhân vật.\n\n• Màu [color=#88ccff]xanh[/color] = đồng đội\n• Màu [color=#ff7777]đỏ[/color] = kẻ địch"],
	["Lệnh tấn công (3/5)",
	 "Khi đến lượt bạn, [color=#aaffaa]menu lệnh[/color] sẽ hiện ra.\n\n• [color=#ffffff]Attack[/color] — Đòn thường, không hồi chiêu.\n• [color=#ffaaff]Skill[/color] — Kỹ năng đặc biệt, có thể có hồi chiêu."],
	["Kỹ năng: Ảnh Sát (4/5)",
	 "[color=#cc88ff]Ảnh Sát[/color] là tuyệt kỹ chủ lực của Ichika.\n\nGây sát thương khổng lồ và kích nổ toàn bộ hiệu ứng Chảy máu (Bleed) thành Sát thương chuẩn (True Damage). Chỉ dùng được [color=#ffdd77]1 lần mỗi trận[/color]. Dùng đúng lúc!"],
	["Sẵn sàng chiến đấu (5/5)",
	 "Chọn lệnh rồi chọn mục tiêu để hành động.\n\nHãy tiêu diệt tất cả kẻ địch để [color=#aaffaa]chiến thắng[/color]. Nếu toàn bộ đồng đội bị hạ, bạn [color=#ff7777]thua[/color].\n\nChúc may mắn, [color=#4a9e9e]Ichika[/color]!"]
]

# ── Chạy Hướng Dẫn ─────────────────────────────────────────────────────────


static func run_tutorial(main: Node):
	"""
	Bắt đầu chuỗi hướng dẫn chiến đấu.

	Hàm này sẽ khóa cờ tutorial trong GameManager để không hiển thị lại,
	sau đó chạy qua danh sách các bước hướng dẫn đã định nghĩa.

	Args:
		main (Node): Scene chính của trận đấu (BattleManager) để gắn UI hướng dẫn.
	"""
	if main == null:
		print("[BattleTutorial] Lỗi: Tham chiếu 'main' bị null, không thể chạy hướng dẫn.")
		return

	GameManager.is_tutorial = false   # Đảm bảo chỉ hiện một lần duy nhất

	var panel = _build_tutorial_panel(main)
	var vbox: VBoxContainer = null

	for child in panel.get_children():
		if child is VBoxContainer:
			vbox = child
			break

	if vbox == null:
		print("[BattleTutorial] Lỗi: Không tìm thấy VBoxContainer trong panel hướng dẫn.")
		return

	for step in STEPS:
		await _show_tutorial_step(main, vbox, step[0], step[1])

	# Xóa toàn bộ CanvasLayer chứa panel hướng dẫn
	panel.get_parent().queue_free()

# ── Xây Dựng Giao Diện ─────────────────────────────────────────────────────

# Đổi các mã màu BBCode cũ trong nội dung sang token của UITheme để khớp bảng màu chung (không đổi chữ)
static func _themed_bbcode(content: String) -> String:
	var remap = {
		"#4a9e9e": UITheme.PLAYER,
		"#88ccff": UITheme.PLAYER,
		"#ff7777": UITheme.ENEMY,
		"#ffdd77": UITheme.ACCENT,
		"#aaffaa": UITheme.SUCCESS,
		"#ffaaff": UITheme.ELEMENT_COLORS["Cute"],
		"#cc88ff": UITheme.ELEMENT_COLORS["Mysterious"],
		"#ffffff": UITheme.TEXT,
	}
	for hex in remap:
		content = content.replace("[color=%s]" % hex, "[color=#%s]" % remap[hex].to_html(false))
	return content

static func _show_tutorial_step(_main: Node, vbox: VBoxContainer, title: String, content: String):
	"""
	Hiển thị một bước hướng dẫn cụ thể và đợi người chơi nhấn nút 'Tiếp theo'.

	Args:
		_main (Node): Scene chính.
		vbox (VBoxContainer): Container chứa nội dung hiển thị.
		title (String): Tiêu đề của bước hướng dẫn.
		content (String): Nội dung hướng dẫn (hỗ trợ BBCode).
	"""
	# Xóa nội dung bước trước
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()

	var t_lbl = Label.new()
	t_lbl.text = title
	UITheme.style_title(t_lbl, UITheme.FS_HEADING, UITheme.ACCENT)
	vbox.add_child(t_lbl)

	var c_lbl = RichTextLabel.new()
	c_lbl.bbcode_enabled = true
	c_lbl.text = _themed_bbcode(content)
	c_lbl.fit_content = true
	c_lbl.scroll_active = false
	c_lbl.add_theme_font_size_override("normal_font_size", UITheme.FS_READING)
	c_lbl.add_theme_color_override("default_color", UITheme.TEXT)
	vbox.add_child(c_lbl)

	var btn = Button.new()
	btn.text = "Tiếp theo"
	UITheme.style_button(btn, UITheme.Kind.PRIMARY)
	btn.custom_minimum_size.x = 160
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	vbox.add_child(btn)
	btn.call_deferred("grab_focus")

	await btn.pressed

static func _build_tutorial_panel(main: Node) -> PanelContainer:
	"""
	Xây dựng cấu trúc UI cơ bản cho bảng hướng dẫn.

	Args:
		main (Node): Node cha để gắn CanvasLayer.

	Returns:
		PanelContainer: Bảng nội dung hướng dẫn.
	"""
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	main.add_child(canvas)

	# ESC không mở menu tạm dừng khi hướng dẫn đang hiện (nhả khi lớp phủ bị xóa)
	PauseMenu.push_modal()
	canvas.tree_exiting.connect(PauseMenu.pop_modal)

	var dim = ColorRect.new()
	dim.color = UITheme.overlay_dim(0.7)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(dim)

	var panel = PanelContainer.new()
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.ACCENT, UITheme.SP_6))
	canvas.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_4)
	panel.add_child(vbox)

	return panel
