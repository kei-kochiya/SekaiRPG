extends CanvasLayer

"""
BattleHUD: Lớp điều phối giao diện chính trong trận chiến.

Lớp này quản lý việc xây dựng và cập nhật các thành phần UI cốt lõi: 
- Thanh hành động (Action Gauge).
- Danh sách thẻ nhân vật (Character Cards) phe ta và phe địch.
- Menu lệnh chiến đấu (Command Menu).
- Các banner thông báo lượt đi, thắng lợi và thất bại.
"""

var player_team: Array
var enemy_team: Array

# ── Tham chiếu Component ───────────────────────────────────────────────────
const ActionGaugeClass = preload("res://UI/Battle/ActionGauge.gd")
const CharacterCardClass = preload("res://UI/Battle/CharacterCard.gd")
const CommandMenuClass = preload("res://UI/Battle/CommandMenu.gd")
const EntityDetailPanelClass = preload("res://UI/Popups/EntityDetailPanel.gd")

var card_container: VBoxContainer
var enemy_container: VBoxContainer
var action_gauge: Node
var command_menu: Node
var _info_panel: Node

# ── Cấu hình UI ─────────────────────────────────────────────────────────────

func setup(players: Array, enemies: Array):
	"""
	Khởi tạo dữ liệu và xây dựng toàn bộ cây Node giao diện.

	- players: Danh sách các thực thể phe người chơi (Array).
	- enemies: Danh sách các thực thể phe đối phương (Array).
	"""
	player_team = players
	enemy_team = enemies
	layer = 10
	_build_ui()

func _build_ui():
	"""
	Xây dựng cấu trúc giao diện theo bố cục định sẵn.
	
	Bố cục bao gồm: Gauge ở góc trên, thẻ nhân vật hai bên cánh, 
	và Menu lệnh được căn giữa phía dưới.
	"""
	for child in get_children():
		child.queue_free()

	action_gauge = ActionGaugeClass.new()
	add_child(action_gauge)
	
	card_container = VBoxContainer.new()
	card_container.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	card_container.offset_left = 60
	card_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	card_container.add_theme_constant_override("separation", 15)
	add_child(card_container)
	
	for p in player_team:
		var card = CharacterCardClass.new()
		card_container.add_child(card)
		card.setup(p, true)
		
	enemy_container = VBoxContainer.new()
	enemy_container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	enemy_container.offset_right = -60
	enemy_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	enemy_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	enemy_container.add_theme_constant_override("separation", 15)
	add_child(enemy_container)
	
	for e in enemy_team:
		var card = CharacterCardClass.new()
		enemy_container.add_child(card)
		card.setup(e, false)
		
	command_menu = CommandMenuClass.new()
	command_menu.set_anchors_preset(Control.PRESET_CENTER)
	command_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	command_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	command_menu.offset_top = 350
	add_child(command_menu)
	
	var info_btn = Button.new()
	info_btn.text = "📊 CHI TIẾT"
	info_btn.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_btn.offset_left = 140
	info_btn.offset_top = 10
	info_btn.pressed.connect(_on_info_pressed)
	add_child(info_btn)
	
	_info_panel = EntityDetailPanelClass.new()
	add_child(_info_panel)

# ── Logic Điều khiển ───────────────────────────────────────────────────────

func _on_info_pressed():
	"""Mở bảng thông số chi tiết của toàn bộ thực thể trên sân."""
	_info_panel.show_entities(player_team, enemy_team)

func show_turn_indicator(entity: Entity):
	"""
	Hiển thị thông báo khi đến lượt của một thực thể cụ thể.

	Args:
		entity (Entity): Thực thể vừa bắt đầu lượt.
	"""
	var banner = _create_banner("ĐẾN LƯỢT: " + entity.entity_name.to_upper(), 
		Color(0.2, 0.8, 1.0) if entity.is_character else Color(1.0, 0.4, 0.3))
	add_child(banner)
	
	banner.position.y -= 250
	
	var tw = create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.3)
	tw.tween_interval(0.7)
	tw.tween_property(banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(banner.queue_free)

func show_victory():
	"""Hiển thị banner thông báo chiến thắng."""
	var banner = _create_banner("CHIẾN THẮNG!", Color(1, 0.9, 0.2))
	add_child(banner)
	banner.position.y -= 100
	var tw = create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.5)

func show_defeat():
	"""Hiển thị banner thông báo thất bại."""
	var banner = _create_banner("THẤT BẠI...", Color(0.6, 0.2, 0.2))
	add_child(banner)
	banner.position.y -= 100
	var tw = create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.5)

# ── Helpers ────────────────────────────────────────────────────────────────

func _create_banner(txt: String, color: Color) -> PanelContainer:
	"""
	Khởi tạo một dải banner thông báo chuẩn hóa.
	
	Sử dụng texture 'banner_modern' dẹt và cố định kích thước 280x42 
	để đảm bảo tính thẩm mỹ.

	Args:
		txt (String): Nội dung chữ hiển thị trên banner.
		color (Color): Màu sắc của phông chữ.
		
	Returns:
		PanelContainer: Đối tượng banner đã được cấu hình.
	"""
	var p = PanelContainer.new()
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	p.custom_minimum_size = Vector2(280, 42)
	p.modulate.a = 0
	
	var sb = StyleBoxTexture.new()
	sb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/banner_modern.svg")
	
	sb.texture_margin_left = 20
	sb.texture_margin_right = 20
	sb.texture_margin_top = 4
	sb.texture_margin_bottom = 4
	
	p.add_theme_stylebox_override("panel", sb)
	
	var l = Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	
	return p
