extends VBoxContainer
class_name ActionGauge

"""
ActionGauge: Hiển thị danh sách thứ tự hành động (Timeline) trong trận đấu.

Thành phần này trực quan hóa danh sách các lượt đánh sắp tới, sử dụng màu sắc 
để phân biệt giữa phe người chơi và phe địch. Đặc biệt, nó sử dụng cơ chế 
so sánh đối tượng (Object-based) để xác định chính xác danh tính thực thể, 
ngay cả khi có các nhân vật trùng tên trên sân.
"""

const PLAYER_COLOR = Color(0.0, 0.8, 0.8)
const ENEMY_COLOR  = Color(1.0, 0.3, 0.3)

# Danh sách các thực thể phe ta (Dùng để so sánh Object)
var player_team: Array = []

func _ready():
	add_theme_constant_override("separation", 2)
	custom_minimum_size = Vector2(140, 0)

func set_player_team(team: Array):
	"""
	Thiết lập danh sách thực thể phe người chơi để phục vụ việc tô màu.

	Args:
		team (Array): Mảng các thực thể Entity thuộc phe ta.
	"""
	player_team = team

func refresh(timeline: Array, current_actor: Entity = null):
	"""
	Cập nhật và vẽ lại toàn bộ danh sách thứ tự lượt.

	Args:
		timeline (Array): Mảng các Dictionary chứa thông tin lượt (entity, tick).
		current_actor (Entity): Thực thể đang thực hiện lượt hiện tại.
	"""
	for c in get_children():
		c.queue_free()
	
	var header = Label.new()
	header.text = "THỨ TỰ LƯỢT"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)
	
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	add_child(sep)
	
	# Chuẩn bị danh sách hiển thị (bao gồm lượt hiện tại nếu có)
	var display_list = []
	if current_actor:
		display_list.append({"entity": current_actor, "is_current": true})
	
	for turn in timeline:
		display_list.append({"entity": turn["entity"], "is_current": false})
	
	# Giới hạn hiển thị 10 lượt
	for i in range(min(display_list.size(), 10)):
		var data = display_list[i]
		var entity = data["entity"]
		var is_current = data["is_current"]
		var entry_name = entity.entity_name
		
		var is_player = player_team.has(entity)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		
		var num = Label.new()
		num.text = "NOW" if is_current else "%d." % i
		num.add_theme_font_size_override("font_size", 9 if is_current else 11)
		num.add_theme_color_override("font_color", Color(1, 0.8, 0.2) if is_current else Color(0.35, 0.35, 0.35))
		num.custom_minimum_size = Vector2(22, 0)
		row.add_child(num)
		
		var icon = TextureRect.new()
		icon.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/round_grey.svg")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.custom_minimum_size = Vector2(16, 16)
		icon.modulate = PLAYER_COLOR if is_player else ENEMY_COLOR
		row.add_child(icon)
		
		var lbl = Label.new()
		lbl.text = entry_name
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color",
			PLAYER_COLOR if is_player else ENEMY_COLOR)
		
		if is_current:
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_outline_color", Color.BLACK)
			lbl.add_theme_constant_override("outline_size", 2)
			
		row.add_child(lbl)
		add_child(row)
