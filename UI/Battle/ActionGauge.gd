extends PanelContainer
class_name ActionGauge

"""
ActionGauge: dải thứ tự lượt nằm ngang ở giữa mép trên màn hình.

- Ô đầu tiên là thực thể đang hành động (viền vàng), các ô sau là lượt sắp tới.
- Màu vạch trên mỗi ô phân biệt phe ta (teal) và phe địch (san hô).
"""

const MAX_ENTRIES = 8
const CHIP_WIDTH = 104

var player_team: Array = []
var _row: HBoxContainer

func _ready():
	add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, Color.TRANSPARENT, UITheme.SP_2))
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", UITheme.SP_1)
	add_child(_row)

func set_player_team(team: Array):
	player_team = team

func refresh(timeline: Array, current_actor: Entity = null):
	for c in _row.get_children():
		c.queue_free()

	var entries: Array = []
	if current_actor:
		entries.append({"entity": current_actor, "is_current": true})
	for turn in timeline:
		entries.append({"entity": turn["entity"], "is_current": false})

	for i in range(mini(entries.size(), MAX_ENTRIES)):
		_row.add_child(_make_chip(entries[i]["entity"], entries[i]["is_current"]))

func _make_chip(entity: Entity, is_current: bool) -> PanelContainer:
	var faction := UITheme.PLAYER if player_team.has(entity) else UITheme.ENEMY
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(CHIP_WIDTH, 30)
	var sb: StyleBoxFlat
	if is_current:
		sb = UITheme.box(UITheme.INK_700, UITheme.ACCENT, UITheme.RADIUS_SM, UITheme.SP_2, 4, 2)
	else:
		sb = UITheme.box(UITheme.INK_900, faction, UITheme.RADIUS_SM, UITheme.SP_2, 4, 0)
		sb.border_width_top = 3
	chip.add_theme_stylebox_override("panel", sb)

	var label := UITheme.make_label(entity.entity_name, UITheme.FS_CAPTION, faction, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_font_override("font", UITheme.font_display_medium())
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chip.add_child(label)
	return chip
