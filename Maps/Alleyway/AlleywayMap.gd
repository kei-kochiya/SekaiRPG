extends Node2D

"""
AlleywayMap: Con hẻm tối - Scene kết thúc nhiệm vụ Harbor.

Honami đợi trong ngõ hẻm ban đêm. Diễn ra monologue kết thúc của cô sau trận Boss.
Cờ mafuyu_honami_talked quyết định dùng hội thoại nào (chưa/đã nói chuyện với Mafuyu về Honami).
Kết thúc: về BaseMap (Stage PostHarbor).
"""

const TILE_SIZE = MapUtils.TILE_SIZE

var _map_root: Node2D
var _lighting: CanvasModulate

func _ready():
	AudioManager.play_music("map")
	
	_lighting = CanvasModulate.new()
	_lighting.color = Color(0.1, 0.1, 0.15) # Dark Night
	add_child(_lighting)
	
	_map_root = Node2D.new()
	_map_root.position = Vector2(496, 100)
	add_child(_map_root)
	# Hành lang rộng 5 ô, cao 15 ô: đặt camera giữa nó để luôn nằm giữa màn hình ở mọi cỡ cửa sổ (trước đây dàn theo khung 1152x648)
	MapUtils.add_fixed_camera(self, (_map_root.position + Vector2(2, 7) * TILE_SIZE) / TILE_SIZE, 1.0)
	
	_build_map()
	_spawn_honami()
	
	# Chờ màn hình sáng hẳn để Dialogue UI (Layer 100) không bị ScreenFade (Layer 200) che
	await ScreenFade.fade_in(1.0)
	# Phần hội thoại: Honami tự lựa chọn kết thúc khác nhau tùy theo tiến độ câu chuyện.
	_play_sequence()

func _build_map():
	# Fill a large background area to ensure everything is black/dark
	MapUtils.fill_floor(_map_root, -30, -20, 34, 34) # phủ kín khung nhìn của camera giữa hành lang, kể cả cửa sổ rộng
			
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
	
	MapUtils.add_character_body(root, "Honami", Color(0.5, 0.35, 0.25))
	
	root.add_child(MapUtils.make_world_label("Honami"))
	
	_map_root.add_child(root)

# Chưa nói chuyện với Mafuyu: monologue phần 1 (sau trận thắng boss lần đầu); đã nói: phần 2 (cuộc gặp tiếp theo ở hẻm)
func _dialogue_key() -> String:
	return "honami_alleyway_p2" if GameManager.get_flag("mafuyu_honami_talked") else "honami_alleyway"

func _play_sequence():
	DialogueManager.play_dialogue(DialogueLoader.get_lines(_dialogue_key()), func():
		await GameManager.change_map(MapPaths.BASE, 1.5)
	)
