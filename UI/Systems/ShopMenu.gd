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
	layer = 100
	_build_ui()

func _build_ui():
	# Nền làm mờ
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.6)
	add_child(dimmer)
	
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(440, 360)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var ps = StyleBoxTexture.new()
	ps.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg")
	ps.texture_margin_left = 14; ps.texture_margin_right = 14
	ps.texture_margin_top = 14; ps.texture_margin_bottom = 14
	ps.set_content_margin_all(20)
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
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)
	
	# Hiển thị số dư Credits
	_credits_label = Label.new()
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credits_label.add_theme_font_size_override("font_size", 13)
	_credits_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
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
		card_style.bg_color = Color(0.12, 0.12, 0.15, 0.85)
		card_style.set_corner_radius_all(6)
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
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		desc_vbox.add_child(name_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		desc_vbox.add_child(desc_lbl)
		
		var buy_btn = Button.new()
		buy_btn.text = "Mua (%d C)" % data["price"]
		buy_btn.custom_minimum_size = Vector2(100, 32)
		buy_btn.disabled = (GameManager.credits < data["price"])
		buy_btn.pressed.connect(func(): _buy_item(item_id, data["price"]))
		hbox.add_child(buy_btn)
		
		_items_container.add_child(card)

func _buy_item(item_id: String, price: int):
	if GameManager.spend_credits(price):
		GameManager.add_item(item_id, 1)
		_update_credits_display()
		_populate_shop_items()
