extends CanvasLayer
class_name ShopMenu

"""
Tóm tắt: ShopMenu quản lý giao diện mua sắm vật phẩm bằng Credits tại Safehouse.

Chức năng chính:
- Hiển thị số dư Credits hiện tại của người chơi.
- Liệt kê các vật phẩm tiêu hao kèm mô tả và giá bán.
- Xử lý giao dịch mua hàng qua GameManager.spend_credits và GameManager.add_item.
"""

var _panel: PanelContainer
var _credits_label: Label
var _items_container: VBoxContainer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	get_tree().paused = true
	_build_ui()

func _exit_tree():
	get_tree().paused = false

func _build_ui():
	# Nền làm mờ
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.04, 0.03, 0.02, 0.72)
	add_child(dimmer)
	
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(460, 380)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var ps = StyleBoxTexture.new()
	ps.texture = load("res://Assets/UI/panel_angular_brown.svg")
	ps.texture_margin_left = 20; ps.texture_margin_right = 20
	ps.texture_margin_top = 20; ps.texture_margin_bottom = 20
	ps.set_content_margin_all(22)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)
	
	# Tiêu đề
	var title = Label.new()
	title.text = "MÁY BÁN HÀNG TỰ ĐỘNG (SAFEHOUSE)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	vbox.add_child(title)
	
	# Hiển thị số dư Credits
	_credits_label = Label.new()
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits_label.add_theme_font_size_override("font_size", 14)
	_credits_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.45))
	vbox.add_child(_credits_label)
	_update_credits_display()
	
	vbox.add_child(HSeparator.new())
	
	# Danh sách hàng hóa
	_items_container = VBoxContainer.new()
	_items_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_items_container)
	_populate_shop_items()
	
	vbox.add_child(HSeparator.new())
	
	# Nút đóng
	var close_btn = Button.new()
	close_btn.text = "ĐÓNG CỬA HÀNG"
	close_btn.custom_minimum_size = Vector2(0, 36)
	
	var rb = StyleBoxTexture.new()
	rb.texture = load("res://Assets/UI/btn_angular_red.svg")
	rb.texture_margin_left = 8; rb.texture_margin_right = 8
	rb.texture_margin_top = 8; rb.texture_margin_bottom = 8
	close_btn.add_theme_stylebox_override("normal", rb)
	
	var rbh = StyleBoxTexture.new()
	rbh.texture = load("res://Assets/UI/btn_angular_red_hover.svg")
	rbh.texture_margin_left = 8; rbh.texture_margin_right = 8
	rbh.texture_margin_top = 8; rbh.texture_margin_bottom = 8
	close_btn.add_theme_stylebox_override("hover", rbh)
	close_btn.add_theme_stylebox_override("pressed", rbh)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	close_btn.add_theme_font_size_override("font_size", 13)
	
	close_btn.pressed.connect(queue_free)
	vbox.add_child(close_btn)

func _update_credits_display():
	_credits_label.text = "Số Dư: %d Credits" % GameManager.credits

func _populate_shop_items():
	for c in _items_container.get_children():
		c.queue_free()
		
	for item_id in GameManager.ITEM_CATALOG:
		var data = GameManager.ITEM_CATALOG[item_id]
		var card = PanelContainer.new()
		var card_style = StyleBoxFlat.new()
		card_style.bg_color = Color(0.16, 0.11, 0.08, 0.95)
		card_style.set_corner_radius_all(0)
		card_style.set_border_width_all(1)
		card_style.border_color = Color(0.42, 0.28, 0.18, 0.8)
		card_style.set_content_margin_all(8)
		card.add_theme_stylebox_override("panel", card_style)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		card.add_child(hbox)
		
		var desc_vbox = VBoxContainer.new()
		desc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(desc_vbox)
		
		var name_lbl = Label.new()
		var cur_owned = GameManager.get_item_count(item_id)
		name_lbl.text = "%s (Đang có: %d)" % [data["name"], cur_owned]
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		desc_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.7, 0.65))
		desc_vbox.add_child(desc_lbl)
		
		var buy_btn = Button.new()
		buy_btn.text = "Mua (%d C)" % data["price"]
		buy_btn.custom_minimum_size = Vector2(100, 32)
		buy_btn.disabled = (GameManager.credits < data["price"])
		
		var b_ns = StyleBoxTexture.new()
		b_ns.texture = load("res://Assets/UI/btn_angular_amber.svg")
		b_ns.texture_margin_left = 6; b_ns.texture_margin_right = 6
		b_ns.texture_margin_top = 6; b_ns.texture_margin_bottom = 6
		buy_btn.add_theme_stylebox_override("normal", b_ns)
		
		var b_hs = StyleBoxTexture.new()
		b_hs.texture = load("res://Assets/UI/btn_angular_amber_hover.svg")
		b_hs.texture_margin_left = 6; b_hs.texture_margin_right = 6
		b_hs.texture_margin_top = 6; b_hs.texture_margin_bottom = 6
		buy_btn.add_theme_stylebox_override("hover", b_hs)
		buy_btn.add_theme_stylebox_override("pressed", b_hs)
		
		var b_ds = StyleBoxTexture.new()
		b_ds.texture = load("res://Assets/UI/btn_angular_brown.svg")
		b_ds.texture_margin_left = 6; b_ds.texture_margin_right = 6
		b_ds.texture_margin_top = 6; b_ds.texture_margin_bottom = 6
		b_ds.modulate_color = Color(0.5, 0.45, 0.4, 0.5)
		buy_btn.add_theme_stylebox_override("disabled", b_ds)
		
		buy_btn.add_theme_color_override("font_color", Color(0.18, 0.12, 0.05))
		buy_btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.5, 0.45))
		buy_btn.add_theme_font_size_override("font_size", 12)
		
		buy_btn.pressed.connect(func(): _buy_item(item_id, data["price"]))
		hbox.add_child(buy_btn)
		
		_items_container.add_child(card)

func _buy_item(item_id: String, price: int):
	if GameManager.spend_credits(price):
		GameManager.add_item(item_id, 1)
		_update_credits_display()
		_populate_shop_items()
