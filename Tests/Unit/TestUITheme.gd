extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Bảo vệ design token của UITheme (tương phản chữ/nền, theme dựng được, nút đủ lớn cho cảm ứng).
"""

const MIN_CONTRAST = 4.5
const MIN_NON_TEXT_CONTRAST = 3.0

# Giá trị chuẩn của WCAG: các bài kiểm tra tương phản bên dưới dùng chính UITheme.contrast nên cần một mốc độc lập
func test_contrast_matches_wcag_reference_values():
	assert_lt(absf(UITheme.contrast(Color.WHITE, Color.BLACK) - 21.0), 0.01, "trắng trên đen = 21:1")
	assert_lt(absf(UITheme.contrast(Color.WHITE, Color.WHITE) - 1.0), 0.001, "cùng màu = 1:1")
	assert_lt(absf(UITheme.contrast(Color.BLACK, Color.WHITE) - UITheme.contrast(Color.WHITE, Color.BLACK)), 0.001, "đối xứng")

func test_text_contrast_on_surfaces():
	var surfaces = {"INK_900": UITheme.INK_900, "INK_800": UITheme.INK_800, "INK_700": UITheme.INK_700}
	var texts = {
		"TEXT": UITheme.TEXT, "TEXT_MUTED": UITheme.TEXT_MUTED, "ACCENT": UITheme.ACCENT,
		"PLAYER": UITheme.PLAYER, "ENEMY": UITheme.ENEMY, "DANGER_TEXT": UITheme.DANGER_TEXT,
		"SUCCESS": UITheme.SUCCESS, "BREAK": UITheme.BREAK,
	}
	for s_name in surfaces:
		for t_name in texts:
			assert_gt(UITheme.contrast(texts[t_name], surfaces[s_name]), MIN_CONTRAST - 0.001, "%s on %s meets WCAG AA" % [t_name, s_name])

func test_button_text_contrast():
	assert_gt(UITheme.contrast(UITheme.TEXT_ON_ACCENT, UITheme.ACCENT), MIN_CONTRAST, "Primary button text readable")
	assert_gt(UITheme.contrast(UITheme.TEXT, UITheme.DANGER), MIN_CONTRAST - 0.001, "Danger button text readable")

# Ô nhập, công tắc, ô tích, thanh trượt: viền/rãnh là phần tử không phải chữ nên cần >= 3:1 (WCAG 1.4.11)
func test_control_edges_meet_non_text_contrast():
	var surfaces = {"INK_900": UITheme.INK_900, "INK_800": UITheme.INK_800, "INK_700": UITheme.INK_700}
	for s_name in surfaces:
		assert_gt(UITheme.contrast(UITheme.CONTROL_EDGE, surfaces[s_name]), MIN_NON_TEXT_CONTRAST - 0.001, "CONTROL_EDGE on %s" % s_name)
	# Núm công tắc (tắt) phải tách khỏi rãnh CONTROL_EDGE
	assert_gt(UITheme.contrast(UITheme.TEXT, UITheme.CONTROL_EDGE), MIN_NON_TEXT_CONTRAST, "Switch knob stands out from the off track")

# Tuỳ chọn "Giảm rung màn hình": rung và hit-stop không được chạy khi bật
func test_reduce_motion_disables_shake_and_hitstop():
	var shaker := ScreenShake.new()
	GameManager.reduce_motion = true
	shaker.shake(8.0, 0.3)
	assert_eq(shaker.shake_timer, 0.0, "shake() does nothing with reduce_motion on")
	shaker.hitstop(0.1)
	assert_eq(Engine.time_scale, 1.0, "hitstop() leaves time_scale alone with reduce_motion on")
	GameManager.reduce_motion = false
	shaker.shake(8.0, 0.3)
	assert_gt(shaker.shake_timer, 0.0, "shake() runs again with reduce_motion off")
	shaker.free()

func test_element_colors_cover_type_chart():
	for element in TypeChart.chart:
		assert_true(UITheme.ELEMENT_COLORS.has(element), "Element color defined for " + element)

func test_every_status_has_an_existing_icon():
	for status_name in UITheme.STATUS_INFO:
		assert_true(UITheme.status_icon(status_name) != null, "Status icon loads for " + status_name)

func test_theme_builds_and_buttons_are_touch_sized():
	var theme := UITheme.make_theme()
	assert_true(theme.has_stylebox("normal", "Button"), "Theme styles Button")
	assert_true(theme.has_stylebox("panel", "PanelContainer"), "Theme styles PanelContainer")
	var btn := Button.new()
	UITheme.style_button(btn)
	assert_true(btn.custom_minimum_size.y >= UITheme.MIN_TOUCH, "Buttons meet the minimum touch height")
	btn.free()

# make_button dựng nút đã style và nối sẵn `pressed`
func test_make_button_is_styled_and_connected():
	var fired := [0]
	var btn := UITheme.make_button("Thử", UITheme.Kind.PRIMARY, UITheme.FS_BODY, func(): fired[0] += 1)
	assert_eq(btn.text, "Thử", "make_button sets the text")
	assert_true(btn.custom_minimum_size.y >= UITheme.MIN_TOUCH, "make_button applies the touch height")
	btn.pressed.emit()
	assert_eq(fired[0], 1, "make_button connects the press handler")
	var plain := UITheme.make_button("Không handler")
	assert_eq(plain.pressed.get_connections().size(), 0, "make_button without a handler connects nothing")
	btn.free()
	plain.free()

# ModalScope: enter/exit idempotent nên bộ đếm modal của PauseMenu luôn cân bằng
func test_modal_scope_is_balanced_and_idempotent():
	var before: int = PauseMenu._modal_count
	var scope := ModalScope.new()
	scope.exit()
	assert_eq(PauseMenu._modal_count, before, "exit() before enter() does nothing")
	scope.enter()
	scope.enter()
	assert_eq(PauseMenu._modal_count, before + 1, "enter() twice pushes once")
	scope.exit()
	scope.exit()
	assert_eq(PauseMenu._modal_count, before, "exit() twice pops once")

func test_clear_children_detaches_immediately():
	var parent := Control.new()
	var a := Control.new()
	var b := Control.new()
	parent.add_child(a)
	parent.add_child(b)
	UITheme.clear_children(parent)
	assert_eq(parent.get_child_count(), 0, "clear_children removes every child at once")
	assert_true(a.is_queued_for_deletion() and b.is_queued_for_deletion(), "clear_children queues the removed children for deletion")
	a.free()
	b.free()
	parent.free()

# default_theme.tres là sản phẩm sinh ra từ UITheme.make_theme() (project.godot trỏ tới nó): đổi token mà quên chạy BuildTheme.gd thì
# game vẫn chạy với màu cũ. So từng màu, hằng số, cỡ chữ và các thuộc tính chính của StyleBoxFlat.
func test_default_theme_tres_matches_make_theme():
	var saved := load("res://default_theme.tres") as Theme
	assert_true(saved != null, "default_theme.tres nạp được")
	var fresh := UITheme.make_theme()
	var checked := 0
	for t in fresh.get_type_list():
		for n in fresh.get_color_list(t):
			assert_eq(saved.get_color(n, t), fresh.get_color(n, t), "%s/%s: màu" % [t, n])
			checked += 1
		for n in fresh.get_constant_list(t):
			assert_eq(saved.get_constant(n, t), fresh.get_constant(n, t), "%s/%s: hằng số" % [t, n])
			checked += 1
		for n in fresh.get_font_size_list(t):
			assert_eq(saved.get_font_size(n, t), fresh.get_font_size(n, t), "%s/%s: cỡ chữ" % [t, n])
			checked += 1
		for n in fresh.get_stylebox_list(t):
			var a := saved.get_stylebox(n, t) as StyleBoxFlat
			var b := fresh.get_stylebox(n, t) as StyleBoxFlat
			if b == null:
				continue
			assert_true(a != null, "%s/%s: có StyleBoxFlat trong file" % [t, n])
			if a == null:
				continue
			var label := "%s/%s" % [t, n]
			assert_eq(a.bg_color, b.bg_color, label + ": nền")
			assert_eq(a.border_color, b.border_color, label + ": viền")
			assert_eq([a.border_width_left, a.border_width_top, a.border_width_right, a.border_width_bottom], [b.border_width_left, b.border_width_top, b.border_width_right, b.border_width_bottom], label + ": độ dày viền")
			assert_eq(a.corner_radius_top_left, b.corner_radius_top_left, label + ": bo góc")
			assert_eq([a.content_margin_left, a.content_margin_top, a.content_margin_right, a.content_margin_bottom], [b.content_margin_left, b.content_margin_top, b.content_margin_right, b.content_margin_bottom], label + ": lề")
			checked += 1
	assert_gt(checked, 40, "Đã so đủ nhiều mục (chống kiểm tra rỗng)")

