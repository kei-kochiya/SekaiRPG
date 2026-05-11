extends CanvasLayer

"""
DialogueManager: Trình quản lý hệ thống đối thoại và cốt truyện toàn cục.

Lớp này đóng vai trò là một Autoload (Singleton), chịu trách nhiệm điều phối 
luồng hội thoại, hiển thị chân dung nhân vật (Portraits), quản lý lựa chọn 
và hiển thị lời dẫn (Narrator). Nó cũng quản lý việc khóa/mở khóa di chuyển 
của người chơi thông qua GameManager trong quá trình đối thoại.
"""

# ── Trạng thái (State) ───────────────────────────────────────────────────────
var current_dialogue: Array = []
var index: int   = 0
var active: bool = false
var _in_choice: bool = false
var _callback: Callable

signal choice_made(index: int)

# ── Các thành phần UI ────────────────────────────────────────────────────────
var _dialogue_box: PanelContainer
var _text_label: RichTextLabel
var _left_portrait: TextureRect
var _right_portrait: TextureRect
var _narrator_box: PanelContainer
var _narrator_label: RichTextLabel
var _choice_box: VBoxContainer
var _choice_panel: PanelContainer

# ── Khởi tạo (Setup) ─────────────────────────────────────────────────────────

func _ready() -> void:
	"""
	Thiết lập lớp hiển thị và khởi tạo giao diện người dùng.
	"""
	layer = 100
	visible = false
	_init_ui()

func _init_ui():
	"""
	Xây dựng cấu trúc cây Node giao diện cho hệ thống hội thoại một cách năng động.
	"""
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_narrator_box = PanelContainer.new()
	_narrator_box.set_anchors_preset(Control.PRESET_CENTER)
	_narrator_box.offset_left = -400
	_narrator_box.offset_right = 400
	_narrator_box.offset_top = -40
	_narrator_box.offset_bottom = 40
	_narrator_box.add_theme_stylebox_override("panel", _get_style("panel_brown_dark.svg", 12, 20))
	root.add_child(_narrator_box)
	
	_narrator_label = RichTextLabel.new()
	_narrator_label.bbcode_enabled = true
	_narrator_label.fit_content = true
	_narrator_label.add_theme_font_size_override("normal_font_size", 18)
	_narrator_box.add_child(_narrator_label)
	_narrator_box.visible = false

	var d_layer = Control.new()
	d_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	d_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(d_layer)

	_left_portrait = _create_portrait(Control.PRESET_BOTTOM_LEFT, 80, -456)
	_right_portrait = _create_portrait(Control.PRESET_BOTTOM_RIGHT, -336, -456)
	d_layer.add_child(_left_portrait)
	d_layer.add_child(_right_portrait)

	_dialogue_box = PanelContainer.new()
	_dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_box.offset_top = -200
	_dialogue_box.offset_bottom = -30
	_dialogue_box.offset_left = 100
	_dialogue_box.offset_right = -100
	_dialogue_box.add_theme_stylebox_override("panel", _get_style("panel_brown.svg", 12, 25))
	d_layer.add_child(_dialogue_box)

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = true
	_text_label.add_theme_font_size_override("normal_font_size", 20)
	_text_label.add_theme_color_override("default_color", Color(0.15, 0.08, 0.05))
	_dialogue_box.add_child(_text_label)

	_choice_panel = PanelContainer.new()
	_choice_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_choice_panel.offset_top = -390
	_choice_panel.offset_bottom = -215
	_choice_panel.offset_left = 200
	_choice_panel.offset_right = -200
	_choice_panel.add_theme_stylebox_override("panel", _get_style("panel_border_brown.svg", 32, 16))
	d_layer.add_child(_choice_panel)
	
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 8)
	_choice_panel.add_child(_choice_box)
	_choice_panel.visible = false

# ── API Công khai (Public API) ─────────────────────────────────────────────

func play_dialogue(lines: Array, on_complete: Callable = Callable()) -> void:
	"""
	Bắt đầu trình chiếu một chuỗi hội thoại mới.

	Args:
		lines (Array): Mảng các câu thoại đã được chuẩn hóa (từ DialogueLoader).
		on_complete (Callable): Hàm callback sẽ gọi khi kết thúc toàn bộ chuỗi thoại.
	"""
	if active or lines.is_empty(): 
		if on_complete.is_valid(): on_complete.call()
		return
	
	current_dialogue = lines
	_callback = on_complete
	index = 0
	active = true
	visible = true
	_clear_ui()
	GameManager.start_dialogue()
	_show_current_line()

func show_choice(options: Array):
	"""
	Hiển thị bảng lựa chọn cho người chơi.

	Args:
		options (Array): Danh sách các chuỗi văn bản đại diện cho các lựa chọn.
	"""
	active = false
	_clear_ui()
	visible = true
	_in_choice = true
	_choice_panel.visible = true
	GameManager.start_dialogue()
	
	for c in _choice_box.get_children(): c.queue_free()
	for i in options.size():
		var btn = Button.new()
		btn.text = options[i]
		btn.add_theme_stylebox_override("normal", _get_style("button_brown.svg", 10, 10))
		btn.add_theme_stylebox_override("hover", _get_style("button_grey.svg", 10, 10))
		btn.add_theme_stylebox_override("focus", _get_style("button_grey.svg", 10, 10))
		btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_on_choice_selected.bind(i))
		_choice_box.add_child(btn)
	
	if _choice_box.get_child_count() > 0:
		_choice_box.get_child(0).grab_focus()

func _on_choice_selected(idx: int):
	"""Xử lý sự kiện khi một lựa chọn được người chơi nhấn vào."""
	_choice_panel.visible = false
	_in_choice = false
	if not active:
		visible = false
		GameManager.end_dialogue()
	choice_made.emit(idx)

# ── Điều phối dòng chảy (Flow Control) ──────────────────────────────────────

func _unhandled_input(event: InputEvent):
	"""Xử lý phím tắt để chuyển sang câu thoại tiếp theo."""
	if _in_choice or not active: return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		index += 1
		if index < current_dialogue.size():
			_show_current_line()
		else:
			_finish()

func _finish():
	"""Dọn dẹp và kết thúc trạng thái hội thoại."""
	active = false
	visible = false
	_clear_ui()
	GameManager.end_dialogue()
	if _callback.is_valid(): _callback.call()

func _show_current_line():
	"""Hiển thị dữ liệu của câu thoại hiện tại lên các thành phần UI tương ứng."""
	var line = current_dialogue[index]
	var type = line.get("type", "dialogue")
	var text = line.get("text", "")
	var speaker_name = line.get("name", "")
	var speaker_side = line.get("speaker", "left")
	var color = line.get("color", Color.WHITE)

	_narrator_box.visible = (type == "narrator")
	_dialogue_box.visible = (type != "narrator")
	_left_portrait.visible = (type != "narrator")
	_right_portrait.visible = (type != "narrator")

	if type == "narrator":
		_narrator_label.text = "[center][color=#ddddcc]%s[/color][/center]" % text
	else:
		var final_text = "[i]%s[/i]" % text if type == "action" else text

		_text_label.text = "[color=#%s]%s:[/color]\n\n%s" % [color.to_html(false), speaker_name, final_text]
		_update_portraits(speaker_name, speaker_side)

func _update_portraits(character_name: String, side: String):
	"""Cập nhật Texture và hiệu ứng hình ảnh cho các chân dung nhân vật."""
	var path = "res://Art/Portraits/%s.png" % character_name.to_lower()
	var tex = load(path) if ResourceLoader.exists(path) else null
	
	if side == "left":
		if _right_portrait.texture == tex: _right_portrait.texture = null
		_left_portrait.texture = tex
	else:
		if _left_portrait.texture == tex: _left_portrait.texture = null
		_right_portrait.texture = tex
	
	var tw = create_tween().set_parallel(true)
	var focus_l = (side == "left")
	tw.tween_property(_left_portrait, "modulate", Color(1,1,1,1) if focus_l else Color(0.4,0.4,0.4,1), 0.2)
	tw.tween_property(_left_portrait, "scale", Vector2(1.05, 1.05) if focus_l else Vector2(0.9, 0.9), 0.2)
	tw.tween_property(_right_portrait, "modulate", Color(1,1,1,1) if not focus_l else Color(0.4,0.4,0.4,1), 0.2)
	tw.tween_property(_right_portrait, "scale", Vector2(1.05, 1.05) if not focus_l else Vector2(0.9, 0.9), 0.2)

# ── Phương thức tiện ích (Helpers) ──────────────────────────────────────────

func _clear_ui():
	"""Xóa trắng nội dung hiển thị của hội thoại và chân dung."""
	_left_portrait.texture = null
	_right_portrait.texture = null
	_text_label.text = ""
	_narrator_label.text = ""
	_narrator_box.visible = false
	_dialogue_box.visible = false
	_choice_panel.visible = false

func _get_style(tex: String, margin: int, padding: int) -> StyleBoxTexture:
	"""
	Tạo StyleBoxTexture với các thông số margin và padding tùy chỉnh.
	
	Args:
		tex (String): Tên file texture trong thư mục Assets.
		margin (int): Khoảng cách biên của texture.
		padding (int): Khoảng cách nội dung bên trong.
		
	Returns:
		StyleBoxTexture: Đối tượng StyleBox đã được cấu hình.
	"""
	var s = StyleBoxTexture.new()
	s.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/" + tex)
	s.texture_margin_left = margin
	s.texture_margin_right = margin
	s.texture_margin_top = margin
	s.texture_margin_bottom = margin
	s.set_content_margin_all(padding)
	return s

func _create_portrait(preset: int, x: int, y: int) -> TextureRect:
	"""Khởi tạo một TextureRect dành cho chân dung nhân vật."""
	var t = TextureRect.new()
	t.custom_minimum_size = Vector2(256, 256)
	t.set_anchors_preset(preset)
	t.offset_left = x
	t.offset_right = x + 256
	t.offset_top = y
	t.offset_bottom = y + 256
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.pivot_offset = Vector2(128, 256)
	return t
