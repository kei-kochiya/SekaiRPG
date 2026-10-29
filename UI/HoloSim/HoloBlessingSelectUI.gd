extends CanvasLayer
class_name HoloBlessingSelectUI

"""
Tóm tắt: HoloBlessingSelectUI hiển thị giao diện chọn 1 trong 3 Phước Lành Roguelite sau mỗi tầng thắng.

Là hộp thoại modal: chạy cả khi cây node bị pause và báo PauseMenu để ESC không mở menu tạm dừng bên dưới.
"""

signal blessing_chosen(blessing_id: String)

const CARD_WIDTH = 264
const CARD_HEIGHT = 288

var cards_container: HBoxContainer
var _card_buttons: Array[Button] = []
var _modal_pushed: bool = false
var _chosen: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 150
	PauseMenu.push_modal()
	_modal_pushed = true
	_build_ui()

func _exit_tree():
	if _modal_pushed:
		_modal_pushed = false
		PauseMenu.pop_modal()

func setup_options(options: Array):
	for c in cards_container.get_children():
		cards_container.remove_child(c)
		c.queue_free()
	_card_buttons.clear()

	for opt in options:
		cards_container.add_child(_create_blessing_card(opt))

	# Focus thẻ đầu tiên để chọn được ngay bằng bàn phím / tay cầm
	if not _card_buttons.is_empty():
		_card_buttons[0].call_deferred("grab_focus")

func _build_ui():
	var dimmer = ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = UITheme.overlay_dim(0.85)
	add_child(dimmer)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", UITheme.SP_4)
	add_child(vbox)

	var title = Label.new()
	title.text = "Chọn phước lành"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_title(title, UITheme.FS_TITLE, UITheme.ACCENT)
	vbox.add_child(title)

	var subtitle = UITheme.make_label("Chọn 1 sức mạnh bị động để cường hóa đội hình trong suốt phần còn lại của lượt leo tháp.", UITheme.FS_LABEL, UITheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size.x = 640
	subtitle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(subtitle)

	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", UITheme.SP_6)
	vbox.add_child(cards_container)

func _create_blessing_card(data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.PLAYER, UITheme.SP_6))

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_3)
	panel.add_child(vbox)

	var name_lbl = UITheme.make_label(data.get("name", "Phước Lành"), UITheme.FS_HEADING, UITheme.ACCENT)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)

	var desc_lbl = UITheme.make_label(data.get("desc", ""), UITheme.FS_LABEL, UITheme.TEXT)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)

	var btn = Button.new()
	btn.text = "Chọn này"
	UITheme.style_button(btn, UITheme.Kind.SECONDARY, UITheme.FS_BODY)
	btn.pressed.connect(func():
		if _chosen:
			return
		_chosen = true
		blessing_chosen.emit(data["id"])
		queue_free()
	)
	vbox.add_child(btn)
	_card_buttons.append(btn)

	return panel
