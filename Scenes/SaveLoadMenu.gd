extends Control

"""
SaveLoadMenu: Giao diện quản lý các ô lưu game (Save Slots).

Tự động liệt kê các file .json trong thư mục user:// và cho phép người chơi Load hoặc xóa.
Nút 'Lưu Game Mới' chỉ hiện khi đang trong game (không phải từ Main Menu).
"""

var slot_container: VBoxContainer
var title_label: Label

func _ready():
	# Thiết lập giao diện cơ bản bằng code
	_setup_ui()
	_refresh_slots()
	ScreenFade.fade_in(0.5)

func _setup_ui():
	# Hình nền mờ (Overlay)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 400)
	center.add_child(panel)
	
	# Style cho Panel
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	sb.border_width_left = 2
	sb.border_width_right = 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.3, 0.5, 1.0)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# Tiêu đề
	title_label = Label.new()
	title_label.text = "HỆ THỐNG LƯU TRỮ"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title_label)
	
	# Scroll Area cho danh sách Slot
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	slot_container = VBoxContainer.new()
	slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(slot_container)
	
	# Nút bấm chức năng dưới cùng
	var h_actions = HBoxContainer.new()
	h_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(h_actions)
	
	var save_btn = Button.new()
	save_btn.text = "Lưu Game Mới"
	save_btn.custom_minimum_size = Vector2(150, 40)
	h_actions.add_child(save_btn)
	save_btn.pressed.connect(_on_save_new_pressed)
	
	# Chỉ hiển thị nút Lưu nếu không phải đang ở Main Menu (Overlay)
	if get_parent() != null and get_parent().name == "StartMenu":
		save_btn.visible = false
	
	var back_btn = Button.new()
	back_btn.text = "Quay lại"
	back_btn.custom_minimum_size = Vector2(150, 40)
	h_actions.add_child(back_btn)
	back_btn.pressed.connect(_on_back_pressed)

func _refresh_slots():
	# Xóa danh sách cũ
	for child in slot_container.get_children():
		child.queue_free()
	
	var save_files = GameManager.get_save_files()
	
	if save_files.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "(Chưa có dữ liệu lưu trữ)"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		slot_container.add_child(empty_lbl)
		return
		
	for path in save_files:
		_create_slot_ui(path)

func _create_slot_ui(path: String):
	var h_box = HBoxContainer.new()
	slot_container.add_child(h_box)
	
	var file_name = path.get_file()
	
	var btn_load = Button.new()
	btn_load.text = "LOAD: " + file_name
	btn_load.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_load.alignment = HORIZONTAL_ALIGNMENT_LEFT
	h_box.add_child(btn_load)
	btn_load.pressed.connect(func(): _on_load_pressed(path))
	
	var btn_delete = Button.new()
	btn_delete.text = "X"
	btn_delete.custom_minimum_size = Vector2(40, 0)
	btn_delete.modulate = Color(1, 0.4, 0.4)
	h_box.add_child(btn_delete)
	btn_delete.pressed.connect(func(): _on_delete_pressed(path))

func _on_load_pressed(path: String):
	print("Đang tải dữ liệu từ: ", path)
	await ScreenFade.fade_out(0.5)
	GameManager.load_game(path)

func _on_save_new_pressed():
	var new_path = GameManager.get_current_save_path()
	print("Đang lưu game vào: ", new_path)
	GameManager.save_game(new_path)
	_refresh_slots()

func _on_delete_pressed(path: String):
	# Xóa file (Sử dụng DirAccess)
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(path.get_file())
		print("Đã xóa file: ", path)
		_refresh_slots()

func _on_back_pressed():
	# Kiểm tra nếu Menu này đang là Overlay (được add_child vào scene khác)
	if get_parent() != get_tree().root:
		self.queue_free()
		return
		
	# Nếu là một scene độc lập, quay về StartMenu
	# (Bạn có thể điều chỉnh để quay về Map nếu đang trong trận)
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")
