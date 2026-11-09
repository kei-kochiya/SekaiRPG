class_name MapUtils
extends RefCounted

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"
const PERSON_ROOT = "res://Assets/Person/"
const ROAD_ROOT = "res://Assets/Roads/"

static func place_tile(parent: Node2D, file: String, grid_pos: Vector2, has_collision: bool = false):
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = grid_pos * TILE_SIZE
	parent.add_child(sprite)
	
	if has_collision:
		var body = StaticBody2D.new()
		body.position = sprite.position
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		parent.add_child(body)

# Sàn phẳng phủ kín hình chữ nhật ô lưới [x1..x2] x [y1..y2] (không va chạm)
static func fill_floor(parent: Node2D, x1: int, y1: int, x2: int, y2: int):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			place_tile(parent, "floor.png", Vector2(x, y))

# Khung tường bao quanh hình chữ nhật ô lưới (có va chạm); thứ tự đặt giữ nguyên để thứ tự vẽ không đổi
static func draw_room_walls(parent: Node2D, x1: int, y1: int, x2: int, y2: int):
	for x in range(x1, x2 + 1):
		place_tile(parent, "horizontal_wall.png", Vector2(x, y1), true)
		place_tile(parent, "horizontal_wall.png", Vector2(x, y2), true)
	for y in range(y1, y2 + 1):
		place_tile(parent, "left_vertical_wall.png", Vector2(x1, y), true)
		place_tile(parent, "right_vertical_wall.png", Vector2(x2, y), true)
	place_tile(parent, "top_left_wall.png", Vector2(x1, y1), true)
	place_tile(parent, "top_right_wall.png", Vector2(x2, y1), true)
	place_tile(parent, "bottom_left_wall.png", Vector2(x1, y2), true)
	place_tile(parent, "bottom_right_wall.png", Vector2(x2, y2), true)

# Phá các node tại một ô (vd. tường) rồi trải sàn lên chỗ đó: mở lối đi qua tường
static func remove_wall_at(parent: Node2D, grid_pos: Vector2):
	var target_pos = grid_pos * TILE_SIZE
	for child in parent.get_children():
		if child is Node2D and child.position.distance_to(target_pos) < 1.0:
			child.queue_free()
	place_tile(parent, "floor.png", grid_pos)

static func place_road_asset(parent: Node2D, file: String, grid_pos: Vector2):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ROAD_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	parent.add_child(sprite)

const SPRITE_ROOT = "res://Assets/Sprites/"

static func get_character_sprite_path(c_name: String) -> String:
	var clean_name = c_name.strip_edges().to_lower()
	var path = SPRITE_ROOT + clean_name + ".svg"
	if ResourceLoader.exists(path):
		return path
	return ""

static func create_character_sprite(c_name: String, direction: String = "down") -> Sprite2D:
	var path = get_character_sprite_path(c_name)
	if path == "":
		return null
	var sprite = Sprite2D.new()
	sprite.texture = load(path)
	sprite.hframes = 3
	sprite.vframes = 4
	var row = 0
	match direction.to_lower():
		"down": row = 0
		"left": row = 1
		"right": row = 2
		"up": row = 3
	sprite.frame = row * 3 + 1
	sprite.position = Vector2(0, -16)
	return sprite

# Nhãn trong thế giới (tên NPC, tên khu, bảng hiệu): chữ >= FS_CAPTION, viền tối để đọc được trên mọi nền.
# Màu tối (Mafuyu, PrimeMinister...) được làm sáng lên vì viền INK_900 sẽ nuốt mất chữ tối.
# Nhãn được căn giữa quanh gốc node cha, mép trên cách gốc `y` px (âm = phía trên).
static func make_world_label(text: String, color: Color = UITheme.TEXT, y: float = -52.0) -> Label:
	var fg := color if color.get_luminance() >= 0.4 else color.lightened(0.55)
	var lbl := UITheme.make_label(text, UITheme.FS_CAPTION, fg)
	lbl.add_theme_color_override("font_outline_color", UITheme.INK_900)
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.position = Vector2(-lbl.get_minimum_size().x / 2.0, y)
	return lbl

# Dựng một nhân vật đứng yên (sprite hoặc khối màu 16x24, kèm nhãn tên) tại ô lưới và trả về node gốc của nó.
# `sprite_file` (trong PERSON_ROOT): nhân vật chưa có sprite riêng (cảnh sát...) thì thay khối màu bằng SVG này nếu có.
static func create_dummy_char(parent: Node2D, p_name: String, grid_pos: Vector2, color: Color, sprite_file: String = "") -> Node2D:
	var root = Node2D.new()
	root.position = grid_pos * TILE_SIZE
	
	if p_name.begins_with("Khủng Bố") or p_name.begins_with("Terrorist"):
		var sprite = Sprite2D.new()
		sprite.texture = load(PERSON_ROOT + "terrorist.svg")
		sprite.scale = Vector2(1, 1)
		sprite.position = Vector2(0, -16)
		root.add_child(sprite)
	else:
		var char_sprite = create_character_sprite(p_name)
		if char_sprite:
			root.add_child(char_sprite)
		else:
			var vis = ColorRect.new()
			vis.size = Vector2(16, 24)
			vis.position = Vector2(-8, -24)
			vis.color = color
			root.add_child(vis)
	
	root.add_child(make_world_label(p_name, color))
	
	if sprite_file != "" and ResourceLoader.exists(PERSON_ROOT + sprite_file) and root.get_child(0) is ColorRect:
		root.get_child(0).queue_free()
		var sp := Sprite2D.new()
		sp.texture = load(PERSON_ROOT + sprite_file)
		sp.position = Vector2(0, -16)
		root.add_child(sp)
		root.move_child(sp, 0)
	
	parent.add_child(root)
	return root

static func create_visual_npc(parent: Node2D, npc_name: String, pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = pos
	var char_sprite = create_character_sprite(npc_name)
	if char_sprite:
		root.add_child(char_sprite)
	else:
		var vis = ColorRect.new()
		vis.size = Vector2(16, 24)
		vis.position = Vector2(-8, -24)
		vis.color = color
		root.add_child(vis)
	root.z_index = 2
	parent.add_child(root)

static func create_enemy_npc(parent: Node2D, pos: Vector2, sprite_file: String):
	var root = Node2D.new()
	root.position = pos
	var sprite = Sprite2D.new()
	sprite.texture = load(PERSON_ROOT + sprite_file)
	sprite.scale = Vector2(1, 1)
	sprite.position = Vector2(0, -16)
	root.add_child(sprite)
	root.z_index = 2
	parent.add_child(root)

static func draw_corner_walls(parent: Node2D):
	# Top-Left Block (Sidewalk góc Trên-Trái: X ∈ [3, 13], Y ∈ [3, 8])
	for x in range(4, 13):
		place_tile(parent, "horizontal_wall.png", Vector2(x, 8))
	for y in range(4, 8):
		place_tile(parent, "right_vertical_wall.png", Vector2(13, y))
	place_tile(parent, "top_left_wall.png", Vector2(3, 3))
	place_tile(parent, "top_right_wall.png", Vector2(13, 3))
	place_tile(parent, "bottom_left_wall.png", Vector2(3, 8))
	place_tile(parent, "bottom_right_wall.png", Vector2(13, 8))

	# Top-Right Block (Sidewalk góc Trên-Phải: X ∈ [17, 27], Y ∈ [3, 8])
	for x in range(18, 27):
		place_tile(parent, "horizontal_wall.png", Vector2(x, 8))
	for y in range(4, 8):
		place_tile(parent, "left_vertical_wall.png", Vector2(17, y))
	place_tile(parent, "top_left_wall.png", Vector2(17, 3))
	place_tile(parent, "top_right_wall.png", Vector2(27, 3))
	place_tile(parent, "bottom_left_wall.png", Vector2(17, 8))
	place_tile(parent, "bottom_right_wall.png", Vector2(27, 8))

	# Bottom-Left Block (Sidewalk góc Dưới-Trái: X ∈ [3, 13], Y ∈ [12, 17])
	for x in range(4, 13):
		place_tile(parent, "horizontal_wall.png", Vector2(x, 12))
	for y in range(13, 17):
		place_tile(parent, "right_vertical_wall.png", Vector2(13, y))
	place_tile(parent, "top_left_wall.png", Vector2(3, 12))
	place_tile(parent, "top_right_wall.png", Vector2(13, 12))
	place_tile(parent, "bottom_left_wall.png", Vector2(3, 17))
	place_tile(parent, "bottom_right_wall.png", Vector2(13, 17))

	# Bottom-Right Block (Sidewalk góc Dưới-Phải: X ∈ [17, 27], Y ∈ [12, 17])
	for x in range(18, 27):
		place_tile(parent, "horizontal_wall.png", Vector2(x, 12))
	for y in range(13, 17):
		place_tile(parent, "left_vertical_wall.png", Vector2(17, y))
	place_tile(parent, "top_left_wall.png", Vector2(17, 12))
	place_tile(parent, "top_right_wall.png", Vector2(27, 12))
	place_tile(parent, "bottom_left_wall.png", Vector2(17, 17))
	place_tile(parent, "bottom_right_wall.png", Vector2(27, 17))

static func place_chest(parent: Node2D, chest_id: String, grid_pos: Vector2, credits: int = 150, item: String = "potion", count: int = 1):
	var chest = TreasureChest.new()
	chest.chest_id = chest_id
	chest.position = grid_pos * TILE_SIZE
	chest.reward_credits = credits
	chest.reward_item = item
	chest.reward_item_count = count
	parent.add_child(chest)
