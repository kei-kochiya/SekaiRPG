extends PanelContainer
class_name CommandMenu

"""
CommandMenu: Menu điều khiển hành động của nhân vật trong trận đấu.

Lớp này quản lý quy trình chọn lệnh cho người chơi, bao gồm:
1. Chọn hành động (Tấn công thường hoặc Kỹ năng).
2. Chọn mục tiêu (Kẻ địch hoặc Đồng minh tùy theo loại kỹ năng).
Tích hợp hệ thống Tooltip nhanh để hiển thị mô tả kỹ năng và nút 'i' để xem 
thông số chi tiết thông qua SkillDetailPopup.
"""

signal command_chosen(action: String, target: Entity)

var current_entity: Entity
var enemy_team: Array
var chosen_action: String = ""

# ── Tham chiếu UI ──────────────────────────────────────────────────────────
const SkillDetailPopupClass = preload("res://UI/Popups/SkillDetailPopup.gd")

var action_container: VBoxContainer
var target_container: VBoxContainer
var title_label: Label
var _tooltip: PanelContainer
var _skill_detail_popup: Node

func _ready():
	"""
	Khởi tạo cấu trúc menu và các thành phần hỗ trợ hiển thị thông tin.
	"""
	visible = false
	_build_shell()
	
	_skill_detail_popup = SkillDetailPopupClass.new()
	add_child(_skill_detail_popup)

func _build_shell():
	"""Xây dựng khung giao diện chính cho menu lệnh."""
	var ps = StyleBoxTexture.new()
	ps.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg")
	ps.texture_margin_left = 12; ps.texture_margin_right = 12
	ps.texture_margin_top = 12; ps.texture_margin_bottom = 12
	ps.set_content_margin_all(16)
	add_theme_stylebox_override("panel", ps)
	
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	
	var title_row = HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 6)
	root.add_child(title_row)
	
	var info_btn = TextureButton.new()
	info_btn.texture_normal = load("res://Assets/kenney_ui-pack-adventure/Vector/minimap_icon_exclamation_white.svg")
	info_btn.ignore_texture_size = true
	info_btn.custom_minimum_size = Vector2(20, 20)
	info_btn.flip_v = true
	info_btn.modulate = Color(0.7, 0.7, 0.7)
	info_btn.pressed.connect(func(): if current_entity: _skill_detail_popup.display_entity_skills(current_entity))
	title_row.add_child(info_btn)
	
	title_label = Label.new()
	title_label.text = "LỆNH CHIẾN ĐẤU"
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	title_row.add_child(title_label)
	
	action_container = VBoxContainer.new()
	action_container.add_theme_constant_override("separation", 4)
	root.add_child(action_container)
	
	target_container = VBoxContainer.new()
	target_container.add_theme_constant_override("separation", 4)
	target_container.visible = false
	root.add_child(target_container)


# ── API Công khai ──────────────────────────────────────────────────────────

func show_for(entity: Entity, enemies: Array):
	"""
	Hiển thị menu và liệt kê các hành động khả dụng cho thực thể chỉ định.

	Args:
		entity (Entity): Nhân vật đang thực hiện lượt.
		enemies (Array): Danh sách kẻ địch trên sân.
	"""
	current_entity = entity
	enemy_team = enemies
	chosen_action = ""
	
	title_label.text = entity.entity_name.to_upper()
	
	_clear(action_container)
	_clear(target_container)
	action_container.visible = true
	target_container.visible = false
	
	action_container.add_child(_make_btn("TẤN CÔNG", "attack", true))
	
	for skill in entity.skills:
		var skill_ready = entity.can_use_skill(skill["method"])
		var cd = entity.cooldowns.get(skill["method"], 0)
		var label = skill["name"]
		
		if cd >= 99: label += " [Hết lượt]"
		elif cd > 0: label += " (Hồi: %d)" % cd
			
		var btn = _make_btn(label, skill["method"], skill_ready)
		action_container.add_child(btn)
	
	visible = true


# ── Logic Nội bộ ───────────────────────────────────────────────────────────

func _on_action_picked(action_name: String):
	"""Xử lý sự kiện khi người chơi chọn một hành động cụ thể."""
	chosen_action = action_name
	action_container.visible = false
	
	var target_type = "enemy"
	if action_name != "attack":
		for s in current_entity.skills:
			if s["method"] == action_name:
				target_type = s.get("target", "enemy")
				break
	
	if target_type == "all_allies" or target_type == "all_enemies" or target_type == "self":
		visible = false
		command_chosen.emit(chosen_action, current_entity)
	else:
		_show_targets(target_type)

func _show_targets(target_type: String = "enemy"):
	"""Hiển thị danh sách các mục tiêu hợp lệ để người chơi lựa chọn."""
	_clear(target_container)
	target_container.visible = true
	
	var header = Label.new()
	header.text = "CHỌN MỤC TIÊU"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_container.add_child(header)
	
	var team = enemy_team if target_type == "enemy" else current_entity.allies
	var alive = AIManager.get_alive_targets(team)
	for member in alive:
		var label = "%s  HP %d/%d" % [member.entity_name, member.current_hp, member.max_hp]
		var btn = _make_btn(label, "", true)
		btn.pressed.connect(_on_target_picked.bind(member))
		target_container.add_child(btn)

func _on_target_picked(target: Entity):
	"""Xác nhận mục tiêu cuối cùng và phát tín hiệu hoàn thành lệnh."""
	visible = false
	command_chosen.emit(chosen_action, target)

func _make_btn(label: String, action_name: String, enabled: bool) -> Button:
	"""Khởi tạo một nút bấm trong menu với phong cách Kenney."""
	var btn = Button.new()
	btn.text = label
	btn.disabled = not enabled
	btn.custom_minimum_size = Vector2(220, 32)
	
	var ns = StyleBoxTexture.new()
	ns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	ns.texture_margin_left = 10; ns.texture_margin_right = 10
	ns.texture_margin_top = 10; ns.texture_margin_bottom = 14
	ns.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", ns)
	
	var hs = StyleBoxTexture.new()
	hs.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg")
	hs.texture_margin_left = 10; hs.texture_margin_right = 10
	hs.texture_margin_top = 10; hs.texture_margin_bottom = 14
	hs.set_content_margin_all(6)
	btn.add_theme_stylebox_override("hover", hs)
	
	var ds = StyleBoxTexture.new()
	ds.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg")
	ds.texture_margin_left = 10; ds.texture_margin_right = 10
	ds.texture_margin_top = 10; ds.texture_margin_bottom = 14
	ds.modulate_color = Color(0.5, 0.5, 0.5, 0.6)
	ds.set_content_margin_all(6)
	btn.add_theme_stylebox_override("disabled", ds)
	
	btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	btn.add_theme_font_size_override("font_size", 14)
	
	if action_name != "":
		btn.pressed.connect(_on_action_picked.bind(action_name))
	
	return btn

func _clear(container: Container):
	"""Xóa sạch các Node con trong một Container chỉ định."""
	for c in container.get_children(): c.queue_free()
