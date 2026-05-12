extends Node2D

"""
AlleywayMap: Cánh đồng tối - Scene kết thúc nhiệm vụ Harbor.

Honami đợi trong ngõ hẻm ban đêm. Diễn ra monologue kết thúc của cô sau trận Boss.
Số wave hờn quyết định dùng hội thoại nào (harbor_wave <= 5 hay > 5).
Kết thúc chuyển về BaseMap_PostHarbor.
"""

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

var _map_root: Node2D
var _lighting: CanvasModulate

func _ready():
	# F6 Debug: If running directly, default to the first phase (Honami Monologue p1)
	if GameManager.story.harbor_wave <= 1:
		GameManager.story.harbor_wave = 5
		GameManager.story.set_flag("mafuyu_honami_talked", false)
		
	AudioManager.play_music("map")
	ScreenFade.fade_in(1.0)
	
	_lighting = CanvasModulate.new()
	_lighting.color = Color(0.1, 0.1, 0.15) # Dark Night
	add_child(_lighting)
	
	_map_root = Node2D.new()
	_map_root.position = Vector2(496, 100) # Centering on 1152x648 screen
	add_child(_map_root)
	
	_build_map()
	_spawn_honami()
	
	await get_tree().create_timer(1.0).timeout
	# Phần hội thoại: Honami tự lựa chọn kết thúc khác nhau tùy theo tiến độ câu chuyện.
	_play_sequence()

func _build_map():
	# Fill a large background area to ensure everything is black/dark
	for x in range(-15, 20):
		for y in range(-10, 25):
			_place_tile("floor.png", Vector2(x, y), false)
			
	# Walls
	for y in range(1, 15):
		_place_tile("left_vertical_wall.png", Vector2(0, y), true)
		_place_tile("right_vertical_wall.png", Vector2(4, y), true)
		
	# Top row corners and walls
	_place_tile("top_left_wall.png", Vector2(0, 0), true)
	_place_tile("horizontal_wall.png", Vector2(1, 0), true)
	_place_tile("door_1.png", Vector2(2, 0), true)
	_place_tile("horizontal_wall.png", Vector2(3, 0), true)
	_place_tile("top_right_wall.png", Vector2(4, 0), true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	_map_root.add_child(sprite)
	if has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		_map_root.add_child(body)

func _spawn_honami():
	var root = Node2D.new()
	root.position = Vector2(2 * TILE_SIZE, 8 * TILE_SIZE)
	
	var vis = ColorRect.new()
	vis.size = Vector2(16, 24)
	vis.position = Vector2(-8, -24)
	vis.color = Color(0.5, 0.35, 0.25) # Honami Brown
	root.add_child(vis)
	
	var lbl = Label.new()
	lbl.text = "Honami"
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -40)
	root.add_child(lbl)
	
	_map_root.add_child(root)

func _play_sequence():
	# harbor_wave <= 5: Honami monologue phần 1 (sau trận thắng boss lần đầu)
	# harbor_wave > 5:  Honami monologue phần 2 (sau của phần harbor tiếp theo)
	var key = "honami_alleyway"
	if GameManager.story.harbor_wave > 5:
		key = "honami_alleyway_p2"
		
	DialogueManager.play_dialogue(DialogueLoader.get_lines(key), func():
		await ScreenFade.fade_out(1.5)
		get_tree().change_scene_to_file("res://Scenes/BaseMap_PostHarbor.tscn")
	)
