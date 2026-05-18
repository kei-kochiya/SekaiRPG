extends CanvasLayer

"""
DialogueManager: Trình điều phối (Controller) hệ thống đối thoại.

Lớp này quản lý luồng dữ liệu hội thoại, theo dõi chỉ số dòng thoại hiện tại 
và xử lý các sự kiện đầu vào. Toàn bộ phần hiển thị được giao cho DialogueUI.
"""

# ── Trạng thái (State) ───────────────────────────────────────────────────────
var current_dialogue: Array = []
var index: int   = 0
var active: bool = false
var _in_choice: bool = false
var _callback: Callable

signal choice_made(index: int)

# ── Thành phần hiển thị ──────────────────────────────────────────────────────
var _ui: DialogueUI

func _ready() -> void:
	layer = 100
	visible = false
	
	_ui = DialogueUI.new()
	add_child(_ui)
	_ui.choice_selected.connect(_on_choice_selected)
	_ui.get_node("DialogueLayer/Clicker").pressed.connect(_on_clicker_pressed)

# ── API Công khai ──────────────────────────────────────────────────────────

func play_dialogue(lines: Array, on_complete: Callable = Callable()) -> void:
	if active or lines.is_empty(): 
		if on_complete.is_valid(): on_complete.call()
		return
	
	current_dialogue = lines
	_callback = on_complete
	index = 0
	active = true
	visible = true
	_ui.clear()
	GameManager.start_dialogue()
	_show_current_line()

func show_choice(options: Array):
	active = false
	_ui.clear()
	visible = true
	_in_choice = true
	GameManager.start_dialogue()
	_ui.display_choices(options)

# ── Điều phối dòng chảy ─────────────────────────────────────────────────────

func _input(event: InputEvent):
	if _in_choice or not active: return
	
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()

func _on_clicker_pressed():
	if _in_choice or not active: return
	_advance_dialogue()

func _advance_dialogue():
	index += 1
	if index < current_dialogue.size():
		_show_current_line()
	else:
		_finish()

func _show_current_line():
	if index < current_dialogue.size():
		_ui.display_line(current_dialogue[index])

func _on_choice_selected(idx: int):
	_in_choice = false
	if not active:
		visible = false
		GameManager.end_dialogue()
	choice_made.emit(idx)

func _finish():
	active = false
	visible = false
	_ui.clear()
	GameManager.end_dialogue()
	if _callback.is_valid(): _callback.call()
