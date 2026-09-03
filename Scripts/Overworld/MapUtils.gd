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

static func place_road_asset(parent: Node2D, file: String, grid_pos: Vector2):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ROAD_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	parent.add_child(sprite)

const SPRITE_ROOT = "res://Art/Sprites/"

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

static func create_dummy_char(parent: Node2D, p_name: String, grid_pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = grid_pos * TILE_SIZE
	
	if p_name.begins_with("Khủng Bố") or p_name.begins_with("Terrorist"):
		var sprite = Sprite2D.new()
		sprite.texture = load(PERSON_ROOT + "terrorist.png")
		sprite.scale = Vector2(2, 2)
		sprite.position = Vector2(0, -6)
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
	
	var lbl = Label.new()
	lbl.text = p_name
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -42)
	root.add_child(lbl)
	
	parent.add_child(root)

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
	sprite.scale = Vector2(4, 4)
	sprite.position = Vector2(0, -12)
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
