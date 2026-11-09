extends Node2D

"""
AlleywayMap: Cánh đồng tối - Scene kết thúc nhiệm vụ Harbor.

Honami đợi trong ngõ hẻm ban đêm. Diễn ra monologue kết thúc của cô sau trận Boss.
Cờ mafuyu_honami_talked quyết định dùng hội thoại nào (chưa/đã nói chuyện với Mafuyu về Honami).
Kết thúc chuyển về BaseMap_PostHarbor.
"""

const TILE_SIZE = 32

var _map_root: Node2D
var _lighting: CanvasModulate

func _ready():
	AudioManager.play_music("map")
	
	_lighting = CanvasModulate.new()
	_lighting.color = Color(0.1, 0.1, 0.15) # Dark Night
	add_child(_lighting)
	
	_map_root = Node2D.new()
	_map_root.position = Vector2(496, 100) # Centering on 1152x648 screen
	add_child(_map_root)
	
	_build_map()
	_spawn_honami()
	
	# Chờ màn hình sáng hẳn để Dialogue UI (Layer 100) không bị ScreenFade (Layer 200) che
	await ScreenFade.fade_in(1.0)
	# Phần hội thoại: Honami tự lựa chọn kết thúc khác nhau tùy theo tiến độ câu chuyện.
	_play_sequence()

func _build_map():
	# Fill a large background area to ensure everything is black/dark
	MapUtils.fill_floor(_map_root, -15, -10, 19, 24)
			
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
	MapUtils.place_tile(_map_root, file, grid_pos, has_collision)

func _spawn_honami():
	var root = Node2D.new()
	root.position = Vector2(2 * TILE_SIZE, 8 * TILE_SIZE)
	
	var char_sprite = MapUtils.create_character_sprite("Honami")
	if char_sprite:
		root.add_child(char_sprite)
	else:
		var vis = ColorRect.new()
		vis.size = Vector2(16, 24)
		vis.position = Vector2(-8, -24)
		vis.color = Color(0.5, 0.35, 0.25)
		root.add_child(vis)
	
	root.add_child(MapUtils.make_world_label("Honami"))
	
	_map_root.add_child(root)

# Chưa nói chuyện với Mafuyu: monologue phần 1 (sau trận thắng boss lần đầu); đã nói: phần 2 (cuộc gặp tiếp theo ở hẻm)
func _dialogue_key() -> String:
	return "honami_alleyway_p2" if GameManager.get_flag("mafuyu_honami_talked") else "honami_alleyway"

func _play_sequence():
	DialogueManager.play_dialogue(DialogueLoader.get_lines(_dialogue_key()), func():
		await GameManager.change_map(MapPaths.BASE, 1.5)
	)
