extends Node
class_name BattleTutorial

## Handles the step-by-step battle tutorial UI.

static func run_tutorial(main: Node):
	GameManager.is_tutorial = false   # Only show once

	var panel = _build_tutorial_panel(main)
	var vbox = panel.get_child(0) as VBoxContainer

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

	panel.get_parent().queue_free()

static func _show_tutorial_step(main: Node, vbox: VBoxContainer, title: String, content: String):
	# Clear previous
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
	vbox.add_child(c_lbl)
	
	var btn = Button.new()
	btn.text = " TIẾP THEO "
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)
	
	await btn.pressed

static func _build_tutorial_panel(main: Node) -> PanelContainer:
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	main.add_child(canvas)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 300)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	canvas.add_child(panel)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.border_width_left = 4
	sb.border_color = Color(0.3, 0.6, 0.8)
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	return panel
