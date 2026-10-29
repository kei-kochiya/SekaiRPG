extends Node2D

"""
BountyMap: khu phố đêm, nơi Ena (điều khiển được) nhận ba hợp đồng truy sát theo thứ tự.

Luồng được suy ra hoàn toàn từ cờ nên tải save vẫn tiếp tục đúng chỗ:
- Lần đầu vào: `bounty_intro`. Mỗi cánh cửa hợp đồng: `bounty_N_pre` rồi trận kịch bản `bounty_N`.
- Khi map nạp lại sau trận thắng (`bounty_N_done`), phát `bounty_N_post` đúng một lần (đếm bằng `bounty_posts_played`).
- Xong hợp đồng 3: Cảnh sát Quốc tế ập tới (`bounty_ambush_mid`), trận `bounty_ambush` (thua kịch bản, đặt `ena_captured`).
- Quay lại với `ena_captured`: `bounty_ambush_end` rồi chuyển sang InterrogationMap.
"""

const TILE_SIZE = 32
const MAP_PATH := "res://Maps/Bounty/BountyMap.tscn"
const NEXT_PATH := "res://Maps/Interrogation/InterrogationMap.tscn"
const ENA_COLOR := Color(0.72, 0.38, 0.16)
const POLICE_COLOR := Color(0.35, 0.5, 0.85)
const NIGHT := Color(0.5, 0.52, 0.72)

# Ba tòa nhà hợp đồng (theo lời thoại: chợ cá, xưởng tranh phố cổ, kho bến Đông): khung tường [x1, y1, x2, y2], ô cửa, hướng ra phố (+1 phía nam, -1 phía bắc)
const CONTRACTS := [
	{"box": [4, 3, 12, 7], "door": Vector2(8, 7), "out": 1, "name": "CHỢ CÁ", "neon": Color(0.95, 0.35, 0.55), "roof": Color(0.17, 0.14, 0.24)},
	{"box": [15, 15, 24, 19], "door": Vector2(19, 15), "out": -1, "name": "XƯỞNG TRANH", "neon": Color(0.35, 0.85, 0.95), "roof": Color(0.12, 0.2, 0.22)},
	{"box": [27, 3, 35, 7], "door": Vector2(31, 7), "out": 1, "name": "KHO BẾN ĐÔNG", "neon": Color(0.95, 0.75, 0.3), "roof": Color(0.24, 0.15, 0.15)},
]

var _busy := false
var _mod: CanvasModulate
var _light_tex: GradientTexture2D
var _hud_label: Label

signal _line_done

func _ready() -> void:
	AudioManager.play_music("map")

	var bg := ColorRect.new()
	bg.position = Vector2(-300, -300)
	bg.size = Vector2(1900, 1300)
	bg.color = Color(0.04, 0.05, 0.09)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_mod = CanvasModulate.new()
	_mod.color = NIGHT
	add_child(_mod)
	_light_tex = _make_light_tex()

	_build_district()
	if GameManager.get_flag("ena_captured"):
		_build_aftermath()
	else:
		_spawn_player()
	_build_hud()

	await ScreenFade.fade_in(1.0)
	_run_logic()

# ── Dựng khu phố ───────────────────────────────────────────────────────────

func _build_district() -> void:
	# Vỉa hè và mặt đường (đường chạy xuyên hai đầu map, hai đầu bị chặn vô hình)
	for x in range(2, 38):
		for y in range(2, 20):
			if y < 10 or y > 12:
				_tile("floor.png", Vector2(x, y))
	for x in range(0, 40):
		_road("Road_Edge_Horizontal_Up.png", Vector2(x, 10))
		_road("Road_Plain.png", Vector2(x, 11))
		_road("Road_Edge_Horizontal_Down.png", Vector2(x, 12))
	for y in range(10, 13):
		_block(Vector2(0, y))
		_block(Vector2(39, y))
	# Vạch qua đường ngay trước cửa mỗi tòa nhà
	for c in CONTRACTS:
		var dx: float = c["door"].x
		_road("Crosswalk_Horizontal_Up.png", Vector2(dx, 10))
		_road("Crosswalk_Horizontal_Middle.png", Vector2(dx, 11))
		_road("Crosswalk_Horizontal_Down.png", Vector2(dx, 12))

	# Tường bao khu phố (chừa đường chạy ở hai đầu)
	for x in range(2, 38):
		_tile("horizontal_wall.png", Vector2(x, 1), true)
		_tile("horizontal_wall.png", Vector2(x, 20), true)
	for y in range(2, 20):
		if y < 10 or y > 12:
			_tile("left_vertical_wall.png", Vector2(1, y), true)
			_tile("right_vertical_wall.png", Vector2(38, y), true)
	_tile("top_left_wall.png", Vector2(1, 1), true)
	_tile("top_right_wall.png", Vector2(38, 1), true)
	_tile("bottom_left_wall.png", Vector2(1, 20), true)
	_tile("bottom_right_wall.png", Vector2(38, 20), true)

	for i in CONTRACTS.size():
		_build_building(i)
	_build_street_props()

func _build_building(i: int) -> void:
	var c: Dictionary = CONTRACTS[i]
	var b: Array = c["box"]
	var door: Vector2 = c["door"]
	var out: int = c["out"]
	var neon: Color = c["neon"]
	var x1: int = b[0]
	var y1: int = b[1]
	var x2: int = b[2]
	var y2: int = b[3]

	# Mái nhà (vẽ trước tường để viền tường đè lên)
	_rect(Vector2(x1 * TILE_SIZE + 16, y1 * TILE_SIZE + 16), Vector2((x2 - x1 - 1) * TILE_SIZE, (y2 - y1 - 1) * TILE_SIZE), c["roof"])
	for vx in [x1 + 2, x2 - 2]:
		var vp := Vector2(vx * TILE_SIZE - 14, (y1 + 1 if out > 0 else y2 - 1) * TILE_SIZE - 14)
		_rect(vp, Vector2(28, 28), Color(0.3, 0.33, 0.4))
		_rect(vp + Vector2(5, 5), Vector2(18, 18), Color(0.13, 0.15, 0.19))

	for x in range(x1 + 1, x2):
		_wall("horizontal_wall.png", Vector2(x, y1), door)
		_wall("horizontal_wall.png", Vector2(x, y2), door)
	for y in range(y1 + 1, y2):
		_wall("left_vertical_wall.png", Vector2(x1, y), door)
		_wall("right_vertical_wall.png", Vector2(x2, y), door)
	_tile("top_left_wall.png", Vector2(x1, y1), true)
	_tile("top_right_wall.png", Vector2(x2, y1), true)
	_tile("bottom_left_wall.png", Vector2(x1, y2), true)
	_tile("bottom_right_wall.png", Vector2(x2, y2), true)
	_tile("door_1.png", door, true)

	# Bảng hiệu neon, vệt sáng và đèn trước cửa
	var door_px := door * TILE_SIZE
	_rect(Vector2(door_px.x - 40, door_px.y - out * 20 - 2), Vector2(80, 4), neon)
	_rect(Vector2(door_px.x - 30, door_px.y + (16 if out > 0 else -26)), Vector2(60, 10), Color(neon.r, neon.g, neon.b, 0.4))
	_light(door_px + Vector2(0, out * 28), neon, 0.9, 140.0)
	var done := _done_count()
	var sign_text := "HỢP ĐỒNG %d\n%s" % [i + 1, c["name"]]
	var sign_color := neon
	if i < done:
		sign_text += " (XONG)"
		sign_color = UITheme.TEXT_DISABLED
	var board := UITheme.make_label(sign_text, UITheme.FS_CAPTION, sign_color, HORIZONTAL_ALIGNMENT_CENTER)
	board.add_theme_color_override("font_outline_color", UITheme.INK_900)
	board.add_theme_constant_override("outline_size", 4)
	board.position = Vector2(door_px.x - board.get_minimum_size().x / 2.0, door_px.y + (-70 if out > 0 else 28))
	add_child(board)
	if i == done:
		# Hợp đồng kế tiếp: biển nhấp nháy + dấu mục tiêu để mũi tên dẫn đường chỉ tới
		var tw := board.create_tween().set_loops()
		tw.tween_property(board, "modulate:a", 0.35, 0.6)
		tw.tween_property(board, "modulate:a", 1.0, 0.6)
		_marker(door_px + Vector2(0, out * 52))

	var prompt := "Hợp đồng %d (chưa tới lượt)" % (i + 1)
	if i < done:
		prompt = "Hợp đồng %d (đã xong)" % (i + 1)
	elif i == done:
		prompt = "Nhấn ENTER để nhận hợp đồng %d" % (i + 1)
	_zone(door_px + Vector2(0, out * 40), Vector2(96, 56), prompt, _on_door.bind(i + 1))

func _build_street_props() -> void:
	# Xe đỗ ven đường (có va chạm)
	var cars := [["Green_Car_Facing_Right_1.png", Vector2(13, 10)], ["Green_Car_Facing_Right_2.png", Vector2(14, 10)],
		["Red_Car_Facing_Left_1.png", Vector2(26, 12)], ["Red_Car_Facing_Left_2.png", Vector2(27, 12)],
		["Green_Car_Facing_Left_1.png", Vector2(35, 10)], ["Green_Car_Facing_Left_2.png", Vector2(36, 10)]]
	for car in cars:
		_road(car[0], car[1])
		_block(car[1])
	# Ao nước phía tây nam
	var pond := [["top_left_water.png", "upper_horizontal_water.png", "top_right_water.png"],
		["left_vertical_water.png", "water_body.png", "right_vertical_water.png"],
		["bottom_left_water.png", "lower_horizontal_water.png", "bottom_right_water.png"]]
	for row in pond.size():
		for col in pond[row].size():
			_tile(pond[row][col], Vector2(4 + col, 16 + row), true)
	# Quán nước vỉa hè phía đông nam
	_tile("dining_table.png", Vector2(31, 17), true)
	_tile("dining_seat.png", Vector2(30, 17))
	_tile("dining_seat.png", Vector2(32, 17))
	_tile("dining_table.png", Vector2(34, 17), true)
	_tile("dining_seat.png", Vector2(34, 18))
	for t in [Vector2(2, 8), Vector2(14, 8), Vector2(25, 9), Vector2(37, 8), Vector2(2, 14), Vector2(13, 14), Vector2(26, 14), Vector2(37, 14)]:
		_tile("tree.png", t, true)
	for g in [Vector2(6, 9), Vector2(16, 9), Vector2(24, 9), Vector2(34, 9), Vector2(11, 13), Vector2(28, 13), Vector2(36, 13), Vector2(3, 13)]:
		_lamp(g)

func _lamp(g: Vector2) -> void:
	var p := g * TILE_SIZE
	_rect(p + Vector2(-2, -26), Vector2(4, 26), Color(0.25, 0.27, 0.33))
	_rect(p + Vector2(-8, -30), Vector2(16, 6), Color(1.0, 0.86, 0.5))
	_light(p + Vector2(0, -22), Color(1.0, 0.8, 0.5), 0.85, 150.0)

func _marker(pos: Vector2) -> void:
	var m := Node2D.new()
	m.position = pos
	m.add_to_group("objectives")
	var d := Polygon2D.new()
	d.polygon = PackedVector2Array([Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)])
	d.color = Color(1.0, 0.3, 0.3)
	m.add_child(d)
	add_child(m)
	var tw := m.create_tween().set_loops()
	tw.tween_property(d, "scale", Vector2(1.5, 1.5), 0.5)
	tw.tween_property(d, "scale", Vector2(1, 1), 0.5)

# ── Nhân vật, HUD ──────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var p := OverworldPlayer.new()
	p.name = "OverworldPlayer"
	p.character_color = ENA_COLOR
	p.set_facing("right")
	add_child(p)
	p.character_name = "Ena"
	p.global_position = _saved_pos(Vector2(3, 11)) # OverworldPlayer tự nạp last_player_position nên đặt lại sau add_child
	for c in p.get_children():
		if c is Camera2D:
			c.zoom = Vector2(1.35, 1.35)
			c.limit_left = -32
			c.limit_top = -32
			c.limit_right = 40 * TILE_SIZE
			c.limit_bottom = 22 * TILE_SIZE

# Vị trí lưu lúc vào trận, chỉ nhận khi nằm trên đường/vỉa hè (tránh vị trí cũ của map khác làm Ena kẹt vào tường)
func _saved_pos(default: Vector2) -> Vector2:
	var g := GameManager.last_player_position / TILE_SIZE
	if g.x >= 2.0 and g.x <= 37.0 and g.y >= 8.0 and g.y <= 14.6:
		return GameManager.last_player_position
	return default * TILE_SIZE

func _build_hud() -> void:
	var hud := QuestHUDBuilder.build(self)
	_hud_label = hud["label"]
	hud["panel"].visible = not GameManager.get_flag("ena_captured")
	var n := _done_count()
	if n >= 3:
		_hud_label.text = "TIỀN THƯỞNG: Hợp đồng 3/3 đã xong\nMục tiêu: Rời khỏi khu phố trước khi có ai phát hiện."
	else:
		_hud_label.text = "TIỀN THƯỞNG: Hợp đồng %d/3 đã xong\nMục tiêu: cửa có biển nhấp nháy, nhấn ENTER." % n

# Sau trận phục kích: Ena gục giữa vòng vây Cảnh sát Quốc tế, camera cố định
func _build_aftermath() -> void:
	var center := _saved_pos(Vector2(31, 8.6))
	var cam := Camera2D.new()
	cam.position = center
	cam.zoom = Vector2(1.7, 1.7)
	add_child(cam)
	var ena := _npc("Ena", center / TILE_SIZE, ENA_COLOR)
	var body = ena.get_child(0)
	body.rotation = PI / 2.0
	body.position = Vector2(2, -8)
	_police_ring(center, false)
	_siren()

func _police_ring(center: Vector2, animate: bool) -> void:
	var offsets := [Vector2(-76, 8), Vector2(76, 8), Vector2(-40, 64), Vector2(40, 64), Vector2(-124, 72), Vector2(124, 72)]
	for o in offsets:
		var target: Vector2 = center + o
		var cop := _npc("Cảnh Sát", target / TILE_SIZE, POLICE_COLOR, "police.svg")
		if animate:
			cop.position = target + Vector2(signf(o.x if o.x != 0.0 else 1.0) * 460.0, 80)
			var tw := cop.create_tween()
			tw.tween_property(cop, "position", target, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# Đèn còi cảnh sát: ánh sáng chuyển đỏ - xanh liên tục
func _siren() -> void:
	var tw := create_tween().set_loops()
	tw.tween_property(_mod, "color", Color(0.85, 0.42, 0.5), 0.5)
	tw.tween_property(_mod, "color", Color(0.42, 0.52, 1.0), 0.5)

# ── Logic cốt truyện ───────────────────────────────────────────────────────

func _done_count() -> int:
	var n := 0
	for i in range(1, 4):
		if GameManager.get_flag("bounty_%d_done" % i):
			n = i
		else:
			break
	return n

func _run_logic() -> void:
	_busy = true
	if GameManager.get_flag("ena_captured"):
		await _say("bounty_ambush_end")
		await _go(NEXT_PATH)
		return
	if not GameManager.get_flag("bounty_intro_done"):
		await _say("bounty_intro")
		GameManager.set_flag("bounty_intro_done", true)
	# Hậu cảnh của hợp đồng vừa thắng: mỗi đoạn chỉ phát một lần (đếm bằng cờ để sống qua save/load)
	var done := _done_count()
	var posts := int(GameManager.get_flag("bounty_posts_played", 0))
	while posts < done:
		posts += 1
		await _say("bounty_%d_post" % posts)
		GameManager.set_flag("bounty_posts_played", posts)
	if done >= 3:
		await _ambush()
		return
	_busy = false

func _on_door(n: int) -> void:
	if _busy:
		return
	_busy = true
	var done := _done_count()
	if n <= done:
		await _narrate("Hợp đồng %d đã xong. Không còn gì đáng để quay lại ở đây." % n)
		_busy = false
	elif n > done + 1:
		await _narrate("Chưa tới lượt. Theo danh sách, phải xử lý xong hợp đồng %d trước." % (done + 1))
		_busy = false
	else:
		await _say("bounty_%d_pre" % n)
		await _start_battle("bounty_%d" % n)

func _ambush() -> void:
	var p := get_node_or_null("OverworldPlayer") as Node2D
	var center: Vector2 = p.global_position if p else Vector2(31, 8.6) * TILE_SIZE
	GameManager.start_dialogue() # khóa Ena trong lúc cảnh sát áp sát
	_siren()
	_police_ring(center, true)
	await get_tree().create_timer(1.3).timeout
	GameManager.end_dialogue()
	await _say("bounty_ambush_mid")
	await _start_battle("bounty_ambush")

func _start_battle(id: String) -> void:
	var p := get_node_or_null("OverworldPlayer") as Node2D
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = id
	GameManager.store_map_state(MAP_PATH, p.global_position if p else Vector2.ZERO)
	await ScreenFade.fade_out(1.0)
	GameManager.trigger_battle()

func _go(path: String) -> void:
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state(path, Vector2.ZERO)
	get_tree().change_scene_to_file(path)

# Phát một đoạn hội thoại và chờ xong; khóa thiếu (mảng rỗng) thì chạy tiếp ngay
func _say(key: String) -> void:
	await _play(DialogueLoader.get_lines(key))

func _narrate(text: String) -> void:
	await _play([{"text": text, "type": "narrator"}])

func _play(lines: Array) -> void:
	if lines.is_empty():
		return
	var state := {"done": false}
	DialogueManager.play_dialogue(lines, func():
		state["done"] = true
		_line_done.emit()
	)
	if not state["done"]:
		await _line_done

# ── Tiện ích dựng cảnh ─────────────────────────────────────────────────────

func _npc(p_name: String, grid_pos: Vector2, color: Color, sprite_file: String = "") -> Node2D:
	MapUtils.create_dummy_char(self, p_name, grid_pos, color)
	var node := get_child(get_child_count() - 1) as Node2D
	# Nhân vật chưa có sprite riêng (cảnh sát...) thì thay khối màu bằng SVG nếu đã nhập vào project
	if sprite_file != "" and ResourceLoader.exists(MapUtils.PERSON_ROOT + sprite_file) and node.get_child(0) is ColorRect:
		node.get_child(0).queue_free()
		var sp := Sprite2D.new()
		sp.texture = load(MapUtils.PERSON_ROOT + sprite_file)
		sp.position = Vector2(0, -16)
		node.add_child(sp)
		node.move_child(sp, 0)
	return node

func _tile(file: String, g: Vector2, collide: bool = false) -> void:
	MapUtils.place_tile(self, file, g, collide)

func _wall(file: String, g: Vector2, skip: Vector2) -> void:
	if g != skip:
		_tile(file, g, true)

func _road(file: String, g: Vector2) -> void:
	MapUtils.place_road_asset(self, file, g)

func _block(g: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = g * TILE_SIZE
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r

func _zone(pos: Vector2, size: Vector2, prompt: String, action: Callable) -> void:
	var zone := InteractableZone.new()
	zone.position = pos
	zone.prompt_text = prompt
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	zone.add_child(col)
	zone.interacted.connect(action)
	add_child(zone)

func _make_light_tex() -> GradientTexture2D:
	var tex := GradientTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.set_color(0, Color.WHITE)
	grad.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = grad
	return tex

func _light(pos: Vector2, color: Color, energy: float, radius: float) -> void:
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.texture_scale = radius / 64.0
	l.color = color
	l.energy = energy
	l.position = pos
	add_child(l)
