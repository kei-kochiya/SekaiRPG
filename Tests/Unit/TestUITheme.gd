extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Bảo vệ design token của UITheme (tương phản chữ/nền, theme dựng được, nút đủ lớn cho cảm ứng).
"""

const MIN_CONTRAST = 4.5

func _luminance(c: Color) -> float:
	var f = func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)

func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

func test_text_contrast_on_surfaces():
	var surfaces = {"INK_900": UITheme.INK_900, "INK_800": UITheme.INK_800, "INK_700": UITheme.INK_700}
	var texts = {
		"TEXT": UITheme.TEXT, "TEXT_MUTED": UITheme.TEXT_MUTED, "ACCENT": UITheme.ACCENT,
		"PLAYER": UITheme.PLAYER, "ENEMY": UITheme.ENEMY, "DANGER_TEXT": UITheme.DANGER_TEXT,
		"SUCCESS": UITheme.SUCCESS, "BREAK": UITheme.BREAK,
	}
	for s_name in surfaces:
		for t_name in texts:
			assert_gt(_contrast(texts[t_name], surfaces[s_name]), MIN_CONTRAST - 0.001, "%s on %s meets WCAG AA" % [t_name, s_name])

func test_button_text_contrast():
	assert_gt(_contrast(UITheme.TEXT_ON_ACCENT, UITheme.ACCENT), MIN_CONTRAST, "Primary button text readable")
	assert_gt(_contrast(UITheme.TEXT, UITheme.DANGER), MIN_CONTRAST - 0.001, "Danger button text readable")

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
