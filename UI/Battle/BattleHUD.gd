extends CanvasLayer

"""
Tóm tắt: BattleHUD là lớp điều phối giao diện chính trong trận chiến.

Chức năng chính:
- Quản lý việc xây dựng và cập nhật các thành phần UI cốt lõi như: Thanh hành động (Action Gauge), Thẻ nhân vật (Character Cards) và Menu lệnh (Command Menu).
- Cung cấp các hàm hiển thị thông báo trận đấu: Đến lượt (Turn Indicator), Chiến thắng (Victory), Thất bại (Defeat).
- Kết nối các nút chức năng phụ như 'Bỏ qua trận đấu' (Skip) và 'Chi tiết chỉ số' (Info).
"""

var player_team: Array
var enemy_team: Array

# ── Tham Chiếu Component ───────────────────────────────────────────────────
const ActionGaugeClass = preload("res://UI/Battle/ActionGauge.gd")
const CharacterCardClass = preload("res://UI/Battle/CharacterCard.gd")
const CommandMenuClass = preload("res://UI/Battle/CommandMenu.gd")
const EntityDetailPanelClass = preload("res://UI/Popups/EntityDetailPanel.gd")

signal skip_requested()

const SIDE_MARGIN = 24
const TOP_MARGIN = 16

var card_container: VBoxContainer
var enemy_container: VBoxContainer
var action_gauge: Node
var command_menu: Node
var _info_panel: Node
var _cards: Dictionary = {}
var _turn_banner: PanelContainer
# Main đặt false cho trận có kịch bản cốt truyện (boss, sinh tồn...) để không thể bỏ qua bằng nút Skip.
var allow_skip: bool = true

# ── Xây Dựng UI ────────────────────────────────────────────────────────────

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
	Bố cục: thanh thứ tự lượt ở giữa mép trên, thẻ phe ta bên trái, thẻ phe địch bên phải,
	menu lệnh ở giữa mép dưới. Mỗi vùng có chỗ riêng nên không chồng lên nhau.
	"""
	for child in get_children():
		child.queue_free()
	_cards.clear()

	_build_backdrop()

	action_gauge = ActionGaugeClass.new()
	action_gauge.set_anchors_preset(Control.PRESET_CENTER_TOP)
	action_gauge.grow_horizontal = Control.GROW_DIRECTION_BOTH
	action_gauge.offset_top = TOP_MARGIN
	add_child(action_gauge)

	card_container = _build_column(true)
	for p in player_team:
		_add_card(card_container, p, true)

	enemy_container = _build_column(false)
	for e in enemy_team:
		_add_card(enemy_container, e, false)

	command_menu = CommandMenuClass.new()
	command_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	command_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	command_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	command_menu.offset_bottom = -SIDE_MARGIN
	add_child(command_menu)

	_turn_banner = _create_banner("", UITheme.PLAYER)
	_turn_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_turn_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_turn_banner.offset_top = TOP_MARGIN + 52
	_turn_banner.modulate.a = 0.0
	add_child(_turn_banner)

	var info_btn = Button.new()
	info_btn.text = "Chi tiết"
	UITheme.style_button(info_btn, UITheme.Kind.SECONDARY, UITheme.FS_BODY)
	info_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	info_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
	info_btn.offset_left = SIDE_MARGIN
	info_btn.offset_bottom = -SIDE_MARGIN
	info_btn.pressed.connect(_on_info_pressed)
	add_child(info_btn)

	# Nút Skip Battle (Chỉ hiện khi Option bật và không phải kịch bản/boss/hướng dẫn)
	if allow_skip and GameManager.skip_battle_enabled and not GameManager.is_scripted_battle and not GameManager.is_tutorial:
		var skip_btn = Button.new()
		skip_btn.text = "Bỏ qua trận đấu"
		UITheme.style_button(skip_btn, UITheme.Kind.SECONDARY, UITheme.FS_BODY)
		skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		skip_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		skip_btn.grow_vertical = Control.GROW_DIRECTION_BEGIN
		skip_btn.offset_right = -SIDE_MARGIN
		skip_btn.offset_bottom = -SIDE_MARGIN
		skip_btn.pressed.connect(func(): skip_requested.emit())
		add_child(skip_btn)

	_info_panel = EntityDetailPanelClass.new()
	add_child(_info_panel)

	# Lớp trên cùng cho số sát thương nổi: CharacterCard tìm nó theo nhóm "ui_overlay"
	var overlay := Control.new()
	overlay.name = "UIOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_to_group("ui_overlay")
	add_child(overlay)

func _build_backdrop():
	"""Nền tối có vignette nhẹ thay cho màu xám mặc định của engine."""
	var back := CanvasLayer.new()
	back.layer = -1
	back.add_child(UITheme.backdrop())
	add_child(back)

func _build_column(left: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UITheme.SP_2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	if left:
		column.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		column.offset_left = SIDE_MARGIN
	else:
		column.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		column.offset_right = -SIDE_MARGIN
	column.offset_top = TOP_MARGIN + 52
	column.offset_bottom = -SIDE_MARGIN
	column.custom_minimum_size.x = CharacterCard.CARD_WIDTH
	if left:
		column.offset_right = SIDE_MARGIN + CharacterCard.CARD_WIDTH
	else:
		column.offset_left = -SIDE_MARGIN - CharacterCard.CARD_WIDTH
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	return column

func _add_card(column: VBoxContainer, entity: Entity, is_player: bool):
	var card = CharacterCardClass.new()
	column.add_child(card)
	card.setup(entity, is_player)
	_cards[entity] = card

# ── Logic Điều Khiển ───────────────────────────────────────────────────────

func _on_info_pressed():
	"""Mở bảng thông số chi tiết của toàn bộ thực thể trên sân."""
	_info_panel.show_entities(player_team, enemy_team)

func show_turn_indicator(entity: Entity):
	"""Đánh dấu thẻ của thực thể đang tới lượt và hiện banner thông báo ngắn."""
	for e in _cards:
		if is_instance_valid(_cards[e]):
			_cards[e].set_active(e == entity)
	
	var color: Color = UITheme.PLAYER if entity.is_character else UITheme.ENEMY
	_turn_banner.get_child(0).text = "Lượt của " + entity.entity_name
	_turn_banner.get_child(0).add_theme_color_override("font_color", color)
	
	var tw = create_tween()
	tw.tween_property(_turn_banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(0.8)
	tw.tween_property(_turn_banner, "modulate:a", 0.0, 0.3)

func show_announcement(text: String, color: Color = UITheme.ACCENT):
	"""Banner thông báo ngắn của kịch bản (vd. pha cứu viện), hiện dưới banner lượt."""
	var banner = _create_banner(text, color)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = TOP_MARGIN + 52 + 60
	banner.modulate.a = 0.0
	add_child(banner)
	var tw = create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.5)
	tw.tween_property(banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(banner.queue_free)

func show_victory():
	"""Hiển thị banner thông báo chiến thắng."""
	_show_result("CHIẾN THẮNG", UITheme.ACCENT)

func show_defeat():
	"""Hiển thị banner thông báo thất bại."""
	var defeat_msg: String
	if GameManager.is_sandbox:
		defeat_msg = "THẤT BẠI
Đang quay lại Sandbox..."
	elif HoloSimManager and HoloSimManager.is_sim_active:
		defeat_msg = "KẾT THÚC MÔ PHỎNG"
	elif GameManager.is_training_mode:
		defeat_msg = "HOÀN THÀNH HUẤN LUYỆN"
	else:
		defeat_msg = "THẤT BẠI
Đang rút lui về Safehouse..."
	_show_result(defeat_msg, UITheme.DANGER_TEXT)

func _show_result(text: String, color: Color):
	var banner = _create_banner(text, color, UITheme.FS_TITLE)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner.custom_minimum_size = Vector2(440, 96)
	banner.modulate.a = 0.0
	add_child(banner)
	create_tween().tween_property(banner, "modulate:a", 1.0, 0.4)

# ── Helpers ────────────────────────────────────────────────────────────────

func _create_banner(txt: String, color: Color, font_size: int = UITheme.FS_HEADING) -> PanelContainer:
	"""Banner thông báo phẳng, dùng chung cho thông báo lượt và kết quả trận."""
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, color, UITheme.SP_3))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l = UITheme.make_label(txt, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", UITheme.font_display())
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p
