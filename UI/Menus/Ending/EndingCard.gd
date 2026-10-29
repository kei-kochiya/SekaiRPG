extends Control

"""
EndingCard: màn hình kết thúc sau trận cuối với Mafuyu.

Chỉ một nút chính "Tiếp tục". Bấm xong mới đánh dấu game_completed (sau khi màn hình đã tối),
rồi sang BaseMap, nơi EpilogueStage chạy tiếp. Lưu game ngay tại màn này vẫn quay về căn cứ (FinalStage)
(current_map_file chưa đổi) nên đoạn kết sẽ phát lại thay vì bị bỏ qua.
"""

const NEXT_SCENE := "res://Maps/Base/BaseMap.tscn"
const COLUMN_WIDTH = 520
const TITLE_SIZE = 96

var _leaving: bool = false

func _ready():
	AudioManager.play_music("night")
	_build()
	ScreenFade.fade_in(1.2)

func _build():
	add_child(UITheme.backdrop())

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.custom_minimum_size.x = COLUMN_WIDTH
	column.add_theme_constant_override("separation", UITheme.SP_3)
	center.add_child(column)

	var eyebrow := UITheme.make_label("Nightcord", UITheme.FS_LABEL, UITheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(eyebrow)

	var title := Label.new()
	title.text = "HẾT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, TITLE_SIZE, UITheme.ACCENT)
	column.add_child(title)

	var rule := ColorRect.new()
	rule.color = UITheme.INK_600
	rule.custom_minimum_size.y = 1
	column.add_child(rule)

	var thanks := UITheme.make_label("Cảm ơn bạn đã đi cùng Ichika suốt đêm dài này.", UITheme.FS_READING, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	thanks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(thanks)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = UITheme.SP_6
	column.add_child(spacer)

	var button_row := CenterContainer.new()
	column.add_child(button_row)
	var btn := Button.new()
	btn.text = "Tiếp tục"
	btn.custom_minimum_size.x = 240
	UITheme.style_button(btn, UITheme.Kind.PRIMARY, UITheme.FS_HEADING)
	btn.pressed.connect(_on_continue)
	button_row.add_child(btn)
	btn.call_deferred("grab_focus")

func _on_continue():
	if _leaving:
		return
	_leaving = true
	await ScreenFade.fade_out(1.0)
	GameManager.set_flag("game_completed", true)
	GameManager.store_map_state(NEXT_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(NEXT_SCENE)
