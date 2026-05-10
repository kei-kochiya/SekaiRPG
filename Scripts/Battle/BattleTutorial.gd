extends Node
class_name BattleTutorial

"""
BattleTutorial: Quản lý giao diện hướng dẫn chiến đấu theo từng bước.

Lớp này hiển thị các thông báo và giải thích cơ chế trận đấu cho người chơi
lần đầu tham gia chiến đấu trong chế độ cốt truyện.
"""

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
		
	GameManager.is_tutorial = false   # Đảm bảo chỉ hiện một lần

	var panel = _build_tutorial_panel(main)
	var vbox: VBoxContainer = null
	
	for child in panel.get_children():
		if child is VBoxContainer:
			vbox = child
			break
			
	if vbox == null:
		print("[BattleTutorial] Lỗi: Không tìm thấy VBoxContainer trong panel hướng dẫn.")
		return

	var steps = [
		["⚔️  Hướng dẫn chiến đấu (1/5)",
		 "Chào mừng đến với màn hình chiến đấu lượt theo lượt!\n\nBạn điều khiển [color=#4a9e9e]Ichika[/color]. Mỗi nhân vật hành động theo thứ tự dựa trên [color=#ffdd77]chỉ số Tốc độ (SPD)[/color]."],
		["📊  Thanh hành động (2/5)",
		 "[color=#ffdd77]Action Gauge[/color] ở góc màn hình hiển thị thứ tự lượt của tất cả nhân vật.\n\n• Màu [color=#88ccff]xanh[/color] = đồng đội\n• Màu [color=#ff7777]đỏ[/color] = kẻ địch"],
		["🗡️  Lệnh tấn công (3/5)",
		 "Khi đến lượt bạn, [color=#aaffaa]menu lệnh[/color] sẽ hiện ra.\n\n• [color=#ffffff]Attack[/color] — Đòn thường, không hồi chiêu.\n• [color=#ffaaff]Skill[/color] — Kỹ năng đặc biệt, có thể có hồi chiêu."],
		["💀  Kỹ năng: Shadow Blade (4/5)",
		 "[color=#cc88ff]Shadow Blade[/color] là kỹ năng chủ lực của Ichika.\n\nGây sát thương cao và hút máu một phần. Chỉ dùng được [color=#ffdd77]1 lần mỗi trận[/color]. Dùng đúng lúc!"],
		["✅  Sẵn sàng chiến đấu (5/5)",
		 "Chọn lệnh rồi chọn mục tiêu để hành động.\n\nHãy tiêu diệt tất cả kẻ địch để [color=#aaffaa]chiến thắng[/color]. Nếu toàn bộ đồng đội bị hạ, bạn [color=#ff7777]thua[/color].\n\nChúc may mắn, [color=#4a9e9e]Ichika[/color]!"]
	]

	for step in steps:
		await _show_tutorial_step(main, vbox, step[0], step[1])

	# Xóa toàn bộ CanvasLayer chứa panel hướng dẫn
	panel.get_parent().queue_free()

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
		child.queue_free()
	
	var t_lbl = Label.new()
	t_lbl.text = title
	t_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(t_lbl)
	
	var c_lbl = RichTextLabel.new()
	c_lbl.bbcode_enabled = true
	c_lbl.text = content
	c_lbl.fit_content = true
	c_lbl.custom_minimum_size = Vector2(400, 150)
	c_lbl.add_theme_color_override("default_color", Color(0.95, 0.9, 0.8))
	vbox.add_child(c_lbl)
	
	var btn = Button.new()
	btn.text = " TIẾP THEO "
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var bns = StyleBoxTexture.new()
	bns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	bns.texture_margin_left = 10
	bns.texture_margin_right = 10
	bns.texture_margin_top = 10
	bns.texture_margin_bottom = 14
	btn.add_theme_stylebox_override("normal", bns)
	btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	
	vbox.add_child(btn)
	
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
	main.add_child(canvas)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	canvas.add_child(panel)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.05, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(bg)

	var sb = StyleBoxTexture.new()
	sb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_border_brown.svg")
	sb.texture_margin_left = 32
	sb.texture_margin_right = 32
	sb.texture_margin_top = 32
	sb.texture_margin_bottom = 32
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	return panel
