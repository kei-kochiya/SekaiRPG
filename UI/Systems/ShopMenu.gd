extends CanvasLayer
class_name ShopMenu

"""
Tóm tắt: ShopMenu quản lý giao diện mua sắm vật phẩm bằng Credits tại Safehouse.

Chức năng chính:
- Hiển thị số dư Credits hiện tại của người chơi.
- Liệt kê các vật phẩm tiêu hao kèm mô tả, số đang có và giá bán; món không đủ Credits hiện rõ còn thiếu bao nhiêu.
- Xử lý giao dịch mua hàng qua GameManager.spend_credits và GameManager.add_item (cập nhật tại chỗ, giữ nguyên focus).
- Là hộp thoại modal: tạm dừng cây node, ESC để đóng, báo PauseMenu để ESC không mở menu tạm dừng.
"""

const PANEL_WIDTH = 600

var _credits_value: Label
var _feedback_label: Label
var _items_container: VBoxContainer
var _close_btn: Button
var _rows: Dictionary = {}
var _modal_pushed: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	get_tree().paused = true
	PauseMenu.push_modal()
	_modal_pushed = true
	_build_ui()
	_refresh()
	_focus_first_buyable()

func _exit_tree():
	get_tree().paused = false
	if _modal_pushed:
		_modal_pushed = false
		PauseMenu.pop_modal()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()

func _build_ui():
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = UITheme.overlay_dim(0.78)
	add_child(dim)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size.x = PANEL_WIDTH
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, UITheme.ACCENT, UITheme.SP_6))
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_3)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Máy bán hàng tự động"
	UITheme.style_title(title, UITheme.FS_TITLE, UITheme.ACCENT)
	vbox.add_child(title)

	# Số dư bên trái, thông báo giao dịch bên phải
	var balance = HBoxContainer.new()
	balance.add_theme_constant_override("separation", UITheme.SP_2)
	vbox.add_child(balance)
	balance.add_child(UITheme.make_label("Số dư", UITheme.FS_LABEL, UITheme.TEXT_MUTED))
	_credits_value = UITheme.make_label("", UITheme.FS_HEADING, UITheme.ACCENT)
	balance.add_child(_credits_value)
	_feedback_label = UITheme.make_label("", UITheme.FS_BODY, UITheme.SUCCESS, HORIZONTAL_ALIGNMENT_RIGHT)
	_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance.add_child(_feedback_label)

	vbox.add_child(HSeparator.new())

	_items_container = VBoxContainer.new()
	_items_container.add_theme_constant_override("separation", UITheme.SP_2)
	vbox.add_child(_items_container)

	var first = true
	for item_id in GameManager.ITEM_CATALOG:
		if not first:
			_items_container.add_child(HSeparator.new())
		first = false
		_add_item_row(item_id, GameManager.ITEM_CATALOG[item_id])

	vbox.add_child(HSeparator.new())

	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)
	_close_btn = Button.new()
	_close_btn.text = "Đóng cửa hàng"
	UITheme.style_button(_close_btn, UITheme.Kind.GHOST)
	_close_btn.custom_minimum_size.x = 192
	_close_btn.pressed.connect(queue_free)
	footer.add_child(_close_btn)

func _add_item_row(item_id: String, data: Dictionary):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_4)
	_items_container.add_child(row)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", UITheme.SP_1)
	row.add_child(info)

	info.add_child(UITheme.make_label(data["name"], UITheme.FS_LABEL, UITheme.TEXT))
	var desc_lbl = UITheme.make_label(data["desc"], UITheme.FS_BODY, UITheme.TEXT_MUTED)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc_lbl)

	var meta = HBoxContainer.new()
	meta.add_theme_constant_override("separation", UITheme.SP_3)
	info.add_child(meta)
	var owned_lbl = UITheme.make_label("", UITheme.FS_CAPTION, UITheme.TEXT_MUTED)
	meta.add_child(owned_lbl)
	var short_lbl = UITheme.make_label("", UITheme.FS_CAPTION, UITheme.DANGER_TEXT)
	meta.add_child(short_lbl)

	var buy_btn = Button.new()
	buy_btn.text = "Mua (%d Credits)" % data["price"]
	UITheme.style_button(buy_btn, UITheme.Kind.SECONDARY, UITheme.FS_BODY)
	buy_btn.custom_minimum_size.x = 176
	buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buy_btn.pressed.connect(_buy_item.bind(item_id))
	row.add_child(buy_btn)

	_rows[item_id] = {"owned": owned_lbl, "short": short_lbl, "buy": buy_btn}

# Cập nhật số dư, số đang có và trạng thái nút mua tại chỗ (không dựng lại nút nên không mất focus)
func _refresh():
	_credits_value.text = "%d Credits" % GameManager.credits
	for item_id in _rows:
		var price: int = GameManager.ITEM_CATALOG[item_id]["price"]
		var missing = price - GameManager.credits
		var ref: Dictionary = _rows[item_id]
		ref["owned"].text = "Đang có: %d" % GameManager.get_item_count(item_id)
		ref["short"].text = "Thiếu %d Credits" % missing if missing > 0 else ""
		ref["buy"].disabled = missing > 0

func _buy_item(item_id: String):
	var data: Dictionary = GameManager.ITEM_CATALOG[item_id]
	if GameManager.spend_credits(data["price"]):
		GameManager.add_item(item_id, 1)
		_feedback_label.text = "Đã mua %s" % data["name"]
		_refresh()
		_keep_focus(item_id)

# Nút vừa bấm có thể bị khóa do hết tiền: chuyển focus sang món còn mua được, hoặc nút Đóng
func _keep_focus(item_id: String):
	var btn: Button = _rows[item_id]["buy"]
	if not btn.disabled:
		btn.grab_focus()
	else:
		_focus_first_buyable()

func _focus_first_buyable():
	for item_id in _rows:
		var btn: Button = _rows[item_id]["buy"]
		if not btn.disabled:
			btn.call_deferred("grab_focus")
			return
	_close_btn.call_deferred("grab_focus")
