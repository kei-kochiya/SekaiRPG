extends Control

"""
SaveLoadMenu: Giao diện Lưu & Tải game của SekaiRPG, dạng hộp thoại modal phủ lên StartMenu hoặc PauseMenu.

Chức năng:
- Liệt kê file save trong `user://saves/` kèm siêu dữ liệu: Tên Quest (QuestRegistry), Tên Map, Ngày giờ lưu.
- Từ màn hình tiêu đề chỉ cho Tải và Xóa; Lưu mới / Ghi đè chỉ có khi đang chơi (tránh ghi đè save thật bằng trạng thái mặc định).
- Xóa và Ghi đè đều qua hộp thoại xác nhận; lỗi lưu/tải hiện ngay trong hộp thoại.
- Báo PauseMenu qua push_modal/pop_modal để ESC đóng hộp thoại này thay vì mở menu tạm dừng bên dưới.
"""

const PANEL_WIDTH = 760
const LIST_HEIGHT = 320
const DIALOG_WIDTH = 460

var slot_container: VBoxContainer
var new_save_edit: LineEdit
var is_in_game_mode: bool = false

var _panel: PanelContainer
var _status_label: Label
var _new_save_btn: Button
var _close_btn: Button
var _confirm_layer: Control = null
var _confirm_origin: Control = null
var _prev_focus: Control = null
var _busy: bool = false
var _modal := ModalScope.new()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_prev_focus = get_viewport().gui_get_focus_owner()
	_check_mode()
	_build_ui()
	_refresh_slots()
	_modal.enter()
	_focus_default()

func _exit_tree():
	_modal.exit()

func _check_mode():
	# Từ StartMenu chưa có trạng thái game thật nên không cho Lưu mới / Ghi đè
	var cur_scene = get_tree().current_scene
	is_in_game_mode = not (cur_scene != null and cur_scene.name == "StartMenu")

func _input(event):
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if _busy:
		return
	if _confirm_layer != null:
		_close_confirmation()
	else:
		_on_back_pressed()

# ── Xây dựng Giao diện ─────────────────────────────────────────────────────

func _build_ui():
	for c in get_children():
		c.queue_free()

	_panel = _add_shell(self, 0.85, PANEL_WIDTH, UITheme.INK_600, UITheme.ACCENT)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_3)
	_panel.add_child(vbox)

	var title = Label.new()
	title.text = "Lưu / Tải game" if is_in_game_mode else "Tải game"
	UITheme.style_title(title, UITheme.FS_TITLE, UITheme.ACCENT)
	vbox.add_child(title)

	var hint = "Lưu tiến trình hiện tại hoặc tải lại một file đã lưu." if is_in_game_mode else "Chọn một file đã lưu để tiếp tục."
	vbox.add_child(UITheme.make_label(hint, UITheme.FS_BODY, UITheme.TEXT_MUTED))

	if is_in_game_mode:
		var new_save_box = HBoxContainer.new()
		new_save_box.add_theme_constant_override("separation", UITheme.SP_2)
		vbox.add_child(new_save_box)

		new_save_edit = LineEdit.new()
		new_save_edit.placeholder_text = "Nhập tên file lưu mới..."
		new_save_edit.max_length = 40
		new_save_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		new_save_edit.custom_minimum_size.y = UITheme.MIN_TOUCH
		new_save_edit.add_theme_font_size_override("font_size", UITheme.FS_LABEL)
		new_save_edit.text_submitted.connect(func(_t): _on_create_new_save())
		new_save_box.add_child(new_save_edit)

		_new_save_btn = UITheme.make_button("Lưu mới", UITheme.Kind.PRIMARY, UITheme.FS_LABEL, _on_create_new_save)
		_new_save_btn.custom_minimum_size.x = 128
		new_save_box.add_child(_new_save_btn)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = LIST_HEIGHT
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	vbox.add_child(scroll)

	slot_container = VBoxContainer.new()
	slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_container.add_theme_constant_override("separation", UITheme.SP_2)
	scroll.add_child(slot_container)

	vbox.add_child(HSeparator.new())
	
	# Hàng cuối: thông báo trạng thái bên trái, nút đóng bên phải
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", UITheme.SP_4)
	vbox.add_child(footer)

	_status_label = UITheme.make_label("", UITheme.FS_BODY, UITheme.TEXT_MUTED)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_status_label)

	_close_btn = UITheme.make_button("Đóng", UITheme.Kind.GHOST, UITheme.FS_LABEL, _on_back_pressed)
	_close_btn.custom_minimum_size.x = 128
	footer.add_child(_close_btn)

# Lớp mờ + khung giữa màn hình dùng chung cho hộp thoại chính và hộp xác nhận (chỉ khác độ mờ, độ rộng, viền, vạch màu)
func _add_shell(parent: Control, dim_alpha: float, width: int, border: Color, accent: Color) -> PanelContainer:
	parent.add_child(UITheme.dim_layer(dim_alpha))

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)

	var shell = PanelContainer.new()
	shell.custom_minimum_size.x = width
	shell.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, border, accent, UITheme.SP_6))
	center.add_child(shell)
	return shell

func _set_status(msg: String, color: Color = UITheme.TEXT_MUTED):
	if _status_label == null:
		return
	_status_label.text = msg
	_status_label.add_theme_color_override("font_color", color)

# ── Cập nhật Danh sách Slots ───────────────────────────────────────────────

# `focus_kind`/`focus_path`: nút cần giữ focus sau khi dựng lại danh sách (rỗng = không đổi focus)
func _refresh_slots(focus_kind: String = "", focus_path: String = ""):
	UITheme.clear_children(slot_container)

	var slots = SaveManager.get_all_save_slots()
	if slots.is_empty():
		var empty_hint = "Chưa có file lưu nào. Nhập tên và bấm Lưu mới để tạo file đầu tiên." if is_in_game_mode else "Chưa có file lưu nào trong hệ thống."
		var empty_lbl = UITheme.make_label(empty_hint, UITheme.FS_LABEL, UITheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.custom_minimum_size.y = LIST_HEIGHT / 2
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_container.add_child(empty_lbl)
	else:
		for i in range(slots.size()):
			if i > 0:
				slot_container.add_child(HSeparator.new())
			_create_slot_row(slots[i], i == 0)

	if focus_kind != "":
		call_deferred("_restore_focus", focus_kind, focus_path)

func _create_slot_row(data: Dictionary, is_first: bool):
	var full_path: String = data.get("path", "")
	var file_name: String = data.get("file_name", "save.json")
	var is_auto = (file_name == "autosave.json")
	var is_quick = (file_name == "quicksave.json")

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_4)
	slot_container.add_child(row)

	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", UITheme.SP_1)
	row.add_child(info)

	# Hàng 1: tên file (+ nhãn Tự động/Lưu nhanh) và thời gian
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", UITheme.SP_2)
	info.add_child(header)

	var name_lbl = UITheme.make_label(file_name.get_basename(), UITheme.FS_LABEL, UITheme.TEXT)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(name_lbl)

	if is_auto:
		header.add_child(UITheme.chip("Tự động", UITheme.ACCENT))
	elif is_quick:
		header.add_child(UITheme.chip("Lưu nhanh", UITheme.ACCENT))
	header.add_child(UITheme.make_label(data.get("timestamp", ""), UITheme.FS_CAPTION, UITheme.TEXT_MUTED))

	# Hàng 2-3: Nhiệm vụ & Bản đồ
	var quest_name: String = data.get("quest_name", "Nhiệm vụ chưa xác định")
	var map_name: String = data.get("map_name", "Bản đồ chưa xác định")
	info.add_child(_make_meta_label("Nhiệm vụ: " + quest_name))
	info.add_child(_make_meta_label("Địa điểm: " + map_name))

	# Cụm nút: từ StartMenu thì nút Tải của file mới nhất là hành động chính
	var actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation", UITheme.SP_2)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(actions)

	var load_kind = UITheme.Kind.PRIMARY if (is_first and not is_in_game_mode) else UITheme.Kind.SECONDARY
	var btn_load = UITheme.make_button("Tải game", load_kind, UITheme.FS_BODY, func(): _on_load_save(full_path))
	_tag_button(btn_load, "load", full_path)
	actions.add_child(btn_load)

	if is_in_game_mode:
		var btn_overwrite = UITheme.make_button("Ghi đè", UITheme.Kind.SECONDARY, UITheme.FS_BODY, func(): _confirm_overwrite(full_path))
		_tag_button(btn_overwrite, "overwrite", full_path)
		actions.add_child(btn_overwrite)

	var btn_del = UITheme.make_button("Xóa", UITheme.Kind.GHOST, UITheme.FS_BODY, func(): _confirm_delete(full_path))
	UITheme.tint_button_text(btn_del, UITheme.DANGER_TEXT)
	_tag_button(btn_del, "delete", full_path)
	actions.add_child(btn_del)

func _make_meta_label(text: String) -> Label:
	var lbl = UITheme.make_label(text, UITheme.FS_BODY, UITheme.TEXT_MUTED)
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return lbl

func _tag_button(btn: Button, kind: String, path: String):
	btn.set_meta("slot_kind", kind)
	btn.set_meta("slot_path", path)

# ── Focus ──────────────────────────────────────────────────────────────────

func _focus_default():
	if is_in_game_mode and new_save_edit != null:
		# Trên điện thoại, focus vào ô nhập sẽ bật bàn phím ảo nên dừng ở nút Lưu mới
		var target: Control = _new_save_btn if OS.has_feature("mobile") else new_save_edit
		UITheme.focus_later(target)
		return
	_focus_first_slot_or_close()

func _focus_first_slot_or_close():
	for c in slot_container.find_children("*", "Button", true, false):
		if not c.disabled:
			UITheme.focus_later(c)
			return
	UITheme.focus_later(_close_btn)

func _restore_focus(kind: String, path: String):
	for c in slot_container.find_children("*", "Button", true, false):
		if c.get_meta("slot_kind", "") == kind and c.get_meta("slot_path", "") == path and not c.disabled:
			c.grab_focus()
			return
	_focus_first_slot_or_close()

# ── Xử Lý Hành Động ────────────────────────────────────────────────────────

func _on_create_new_save():
	if new_save_edit == null or _busy:
		return
	var fname = new_save_edit.text.strip_edges()
	if fname == "":
		var dt = Time.get_datetime_dict_from_system()
		fname = "save_%02d%02d_%02d%02d" % [dt["day"], dt["month"], dt["hour"], dt["minute"]]

	# Trùng tên một slot đã có: phải xác nhận ghi đè như nút "Ghi đè", không lặng lẽ thay mất file cũ
	var existing := SaveManager.slot_path_for_name(fname)
	if existing != "" and FileAccess.file_exists(existing):
		_confirm_overwrite(existing)
		return

	if GameManager.save_game(fname):
		new_save_edit.text = ""
		_set_status("Đã lưu file \"%s\"." % fname, UITheme.SUCCESS)
		_refresh_slots()
	else:
		_set_status(_save_error_text(), UITheme.DANGER_TEXT)

func _save_error_text() -> String:
	var err := GameManager.last_save_error
	if err != "":
		return err
	return "Không thể lưu game. Tên file không hợp lệ hoặc không ghi được."

func _on_load_save(path: String):
	if _busy:
		return
	_busy = true
	print("[SaveLoadMenu] Đang tải game từ: ", path)
	_set_status("Đang tải game...", UITheme.TEXT_MUTED)
	await ScreenFade.fade_out(0.5)
	if not is_inside_tree():
		return
	if not GameManager.load_game(path):
		ScreenFade.fade_in(0.3)
		var err := GameManager.last_load_error
		_set_status(err if err != "" else "Không thể tải file save.", UITheme.DANGER_TEXT)
		_busy = false
		return
	# Tải thành công: nếu mở từ PauseMenu thì ẩn nó và bỏ pause để cảnh mới chạy được
	PauseMenu.visible = false
	get_tree().paused = false
	queue_free()

func _confirm_overwrite(path: String):
	_show_confirmation(
		"Xác nhận ghi đè",
		"Bạn có chắc chắn muốn ghi đè lên file:\n[" + path.get_file() + "] không?",
		"Ghi đè",
		func():
			if GameManager.save_game(path):
				_set_status("Đã ghi đè file \"%s\"." % path.get_file(), UITheme.SUCCESS)
			else:
				_set_status(_save_error_text(), UITheme.DANGER_TEXT)
			_refresh_slots("overwrite", path)
	)

func _confirm_delete(path: String):
	_show_confirmation(
		"Xác nhận xóa file",
		"Bạn có chắc chắn muốn xóa vĩnh viễn file:\n[" + path.get_file() + "] không?",
		"Xóa vĩnh viễn",
		func():
			if SaveManager.delete_save(path):
				_set_status("Đã xóa file \"%s\"." % path.get_file(), UITheme.TEXT_MUTED)
			else:
				_set_status("Không thể xóa file \"%s\"." % path.get_file(), UITheme.DANGER_TEXT)
			_refresh_slots("load", "")
	)

# Hộp thoại xác nhận nằm trên một lớp mờ riêng; trong lúc mở, các nút phía sau không nhận focus bàn phím.
func _show_confirmation(title_text: String, msg_text: String, confirm_text: String, on_confirm: Callable):
	if _confirm_layer != null:
		_close_confirmation(false)
	_confirm_origin = get_viewport().gui_get_focus_owner()
	_set_background_focusable(false)

	_confirm_layer = Control.new()
	_confirm_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_confirm_layer)

	var dialog = _add_shell(_confirm_layer, 0.7, DIALOG_WIDTH, UITheme.INK_500, UITheme.DANGER)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_4)
	dialog.add_child(vbox)

	vbox.add_child(UITheme.make_label(title_text, UITheme.FS_HEADING, UITheme.TEXT))
	var m_lbl = UITheme.make_label(msg_text, UITheme.FS_LABEL, UITheme.TEXT)
	m_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(m_lbl)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", UITheme.SP_2)
	vbox.add_child(hbox)

	var btn_no = UITheme.make_button("Hủy", UITheme.Kind.GHOST, UITheme.FS_LABEL, func(): _close_confirmation())
	btn_no.custom_minimum_size.x = 112
	hbox.add_child(btn_no)

	var btn_yes = UITheme.make_button(confirm_text, UITheme.Kind.DANGER, UITheme.FS_LABEL, func():
		_close_confirmation(false)
		on_confirm.call()
	)
	hbox.add_child(btn_yes)

	# Mặc định focus vào Hủy để tránh lỡ tay xóa/ghi đè
	UITheme.focus_later(btn_no)

func _close_confirmation(restore_focus: bool = true):
	if _confirm_layer == null:
		return
	_confirm_layer.queue_free()
	_confirm_layer = null
	_set_background_focusable(true)
	if restore_focus and is_instance_valid(_confirm_origin):
		UITheme.focus_later(_confirm_origin)
	_confirm_origin = null

func _set_background_focusable(on: bool):
	for c in _panel.find_children("*", "Control", true, false):
		if on:
			if c.has_meta("focus_backup"):
				c.focus_mode = c.get_meta("focus_backup")
				c.remove_meta("focus_backup")
		elif c.focus_mode != Control.FOCUS_NONE:
			c.set_meta("focus_backup", c.focus_mode)
			c.focus_mode = Control.FOCUS_NONE

func _on_back_pressed():
	if _busy:
		return
	if get_parent() != get_tree().root:
		# Trả focus về nút đã mở hộp thoại này (Tải game / Lưu-Tải game)
		if is_instance_valid(_prev_focus) and _prev_focus.is_inside_tree():
			UITheme.focus_later(_prev_focus)
		queue_free()
		return
	get_tree().change_scene_to_file(MapPaths.START_MENU)
