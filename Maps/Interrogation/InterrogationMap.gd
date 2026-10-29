extends Node2D

"""
InterrogationMap: kho của Cảnh sát Quốc tế (phòng thẩm vấn + sân sau). Giai đoạn suy ra từ cờ: A = Ena bị tra tấn (cảnh quay),
B = Mizuki dọn hai toán cảnh sát rồi bị ép đấu Ena, C = sân sau: Ichika đối mặt Kanade. Không khớp giai đoạn nào (cờ mặc định
trong test) thì chỉ dựng phòng như cảnh A, không chạy logic.
"""

const TILE_SIZE = 32
const MAP_PATH := "res://Maps/Interrogation/InterrogationMap.tscn"
const BASE_PATH := "res://Maps/Base/BaseMap.tscn"
const COLORS := {
	"Mafuyu": Color(0.4, 0.3, 0.5), "Ena": Color(0.72, 0.38, 0.16), "Kanade": Color(0.8, 0.8, 0.9),
	"Mizuki": Color(0.85, 0.65, 0.8), "Ichika": Color(0.29, 0.62, 0.62),
}
const POLICE := Color(0.35, 0.5, 0.85)
const CHAIR := Vector2(16, 9)
const DOOR := Vector2(16, 17)
const TABLE := Vector2(8, 5) # bàn có máy tính bảng của đại úy
const CELL := Vector2(25.5, 5.6) # góc phòng giam nơi Ena nằm
# Hai toán cảnh sát giai đoạn B: tâm toán + vị trí từng người (toán 2: người cuối là đại úy, đứng chắn cửa phòng giam)
const GROUPS := {
	1: [Vector2(12, 14.3), [Vector2(11, 14), Vector2(13.2, 14.6)]],
	2: [Vector2(24, 10.8), [Vector2(22.6, 10.5), Vector2(25.6, 10.5), Vector2(24.1, 11.6)]],
}

enum Phase { NONE, A, B, C }

var _phase: int = Phase.NONE
var _busy := false
var _armed := false # chỉ cho cảnh sát tự kích hoạt sau khi map đã ổn định (tránh nổ trận ngay khi nạp)
var _mod: CanvasModulate
var _light_tex: GradientTexture2D
var _screen: ColorRect
var _npcs: Dictionary = {}

signal _line_done

func _ready() -> void:
	_phase = _pick_phase()
	_sync_police_wins()
	AudioManager.play_music("map" if _phase == Phase.NONE else "night")
	_rect(Vector2(-400, -400), Vector2(2000, 1500), Color(0.03, 0.03, 0.05))
	_mod = CanvasModulate.new()
	_mod.color = Color(0.55, 0.58, 0.82) if _phase == Phase.C else Color(0.55, 0.55, 0.7)
	add_child(_mod)
	if _phase == Phase.C:
		_build_yard()
		_cast_c()
	else:
		_build_room()
		if _phase == Phase.B:
			_cast_b()
		else:
			_cast_a()
	_build_hud()
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _pick_phase() -> int:
	if GameManager.get_flag("kanade_unmasked") and not GameManager.get_flag("honami_rescue_done"):
		return Phase.C
	if GameManager.get_flag("ena_kill_ordered") and not GameManager.get_flag("kanade_unmasked"):
		return Phase.B
	if GameManager.get_flag("ena_captured") and not GameManager.get_flag("interrogation_seen"):
		return Phase.A
	return Phase.NONE

# Thắng mizuki_police_1 chỉ để lại last_scripted_win (GameManager ghi); đổi thành bộ đếm bền để sống qua các trận sau và save/load
func _sync_police_wins() -> void:
	var wins := int(GameManager.get_flag("mizuki_police_wins", 0))
	if GameManager.get_flag("last_scripted_win", "") == "mizuki_police_1":
		wins = maxi(wins, 1)
	if GameManager.get_flag("mizuki_police_done"):
		wins = maxi(wins, 2)
	GameManager.set_flag("mizuki_police_wins", wins)

# ── Dựng phòng thẩm vấn và sân sau ─────────────────────────────────────────

func _build_room() -> void:
	for x in range(5, 28):
		for y in range(4, 17):
			_tile("floor.png", Vector2(x, y))
	_rect(CHAIR * TILE_SIZE + Vector2(-112, -112), Vector2(224, 224), Color(0.1, 0.11, 0.16, 0.6)) # vệt sàn quanh ghế
	for i in range(7):
		_rect(Vector2((13 + i) * TILE_SIZE + 4, 16 * TILE_SIZE - 6), Vector2(14, 8), Color(0.85, 0.7, 0.15, 0.7)) # vạch cảnh báo
	_rect(Vector2(23 * TILE_SIZE - 16, 4 * TILE_SIZE - 16), Vector2(5 * TILE_SIZE, 4 * TILE_SIZE), Color(0.06, 0.06, 0.08, 0.45)) # sàn phòng giam
	_ring(4, 3, 28, 17, DOOR)
	_tile("door_1.png", DOOR, true)
	_light(CELL * TILE_SIZE, Color(0.8, 0.85, 1.0), 0.55, 130.0)
	# Phòng giam góc đông bắc: tường trái và tường dưới, chừa cửa ở x = 24
	for y in range(4, 8):
		_tile("left_vertical_wall.png", Vector2(22, y), true)
	_tile("bottom_left_wall.png", Vector2(22, 8), true)
	for x in [23, 25, 26, 27]:
		_tile("horizontal_wall.png", Vector2(x, 8), true)
	# Giá kệ tường bắc, thùng hàng các góc, bàn thẩm vấn với máy tính bảng, cốc nước và giấy tờ
	_rect(Vector2(12 * TILE_SIZE, 4 * TILE_SIZE - 14), Vector2(9 * TILE_SIZE, 24), Color(0.22, 0.25, 0.3))
	for i in range(9):
		_rect(Vector2((12 + i) * TILE_SIZE + 5, 4 * TILE_SIZE - 10), Vector2(22, 14), [Color(0.5, 0.36, 0.2), Color(0.3, 0.38, 0.5), Color(0.4, 0.4, 0.42)][i % 3])
	for g in [Vector2(5, 14), Vector2(5, 15), Vector2(6, 15), Vector2(5, 16), Vector2(27, 14), Vector2(27, 15), Vector2(26, 16), Vector2(27, 16), Vector2(5, 8)]:
		_crate(g)
	for i in range(3):
		_indoor("table_horizontal_%d.png" % (i + 1), TABLE + Vector2(i - 1, 0))
	var t := TABLE * TILE_SIZE
	_rect(t + Vector2(-22, -26), Vector2(18, 12), Color(0.85, 0.85, 0.8))
	_rect(t + Vector2(24, -24), Vector2(8, 10), Color(0.7, 0.85, 0.95))
	_rect(t + Vector2(-8, -30), Vector2(30, 20), Color(0.12, 0.14, 0.18))
	_screen = _rect(t + Vector2(-6, -28), Vector2(26, 16), Color(0.25, 0.85, 1.0))
	_screen.modulate.a = 0.55
	_light(t + Vector2(8, -14), Color(0.4, 0.9, 1.0), 0.6, 120.0)
	# Bóng đèn trần đung đưa trên ghế thẩm vấn, đèn khung cửa
	var lamp := Node2D.new()
	lamp.position = CHAIR * TILE_SIZE + Vector2(0, -112)
	add_child(lamp)
	_rect(Vector2(-1, 0), Vector2(2, 40), Color(0.1, 0.1, 0.12), lamp)
	_rect(Vector2(-14, 40), Vector2(28, 8), Color(0.9, 0.92, 1.0), lamp)
	_light(Vector2(0, 92), Color(0.85, 0.9, 1.0), 1.1, 230.0, lamp)
	var sway := lamp.create_tween().set_loops()
	sway.tween_property(lamp, "rotation", 0.12, 1.3).set_trans(Tween.TRANS_SINE)
	sway.tween_property(lamp, "rotation", -0.12, 1.3).set_trans(Tween.TRANS_SINE)
	_light(DOOR * TILE_SIZE + Vector2(0, -30), Color(1.0, 0.8, 0.5), 0.7, 130.0)
	_indoor("chair_facing_right.png", CHAIR, false)

# Sân sau: tường sau nhà kho với cổng sau, thùng phuy rỉ sét (có cốc mì ly), xe máy cũ, ánh trăng
func _build_yard() -> void:
	for x in range(5, 28):
		for y in range(5, 17):
			_tile("floor.png", Vector2(x, y))
	for g in [Vector2(5, 5), Vector2(27, 5), Vector2(5, 16), Vector2(27, 16), Vector2(5, 10), Vector2(27, 11)]:
		_tile("tree.png", g, true)
	_rect(Vector2(5 * TILE_SIZE - 16, 5 * TILE_SIZE - 16), Vector2(23 * TILE_SIZE, 12 * TILE_SIZE), Color(0.4, 0.41, 0.46, 0.45)) # ánh trăng phủ nền
	_rect(Vector2(15 * TILE_SIZE + 8, 5 * TILE_SIZE - 16), Vector2(80, 6 * TILE_SIZE), Color(0.55, 0.55, 0.58, 0.25)) # lối mòn từ cổng sau
	_ring(4, 3, 28, 17)
	for x in range(5, 28):
		if x != 16:
			_tile("horizontal_wall.png", Vector2(x, 4), true)
	_tile("door_1.png", Vector2(16, 4), true)
	for g in [Vector2(7, 6), Vector2(8, 6), Vector2(7, 15), Vector2(8, 15), Vector2(8, 14)]:
		_crate(g)
	for b in [Vector2(24.6, 7.4), Vector2(25.8, 7.9), Vector2(24.8, 8.7), Vector2(10, 7)]:
		_disc(b * TILE_SIZE, 13.0, Color(0.42, 0.2, 0.11))
		_disc(b * TILE_SIZE, 10.0, Color(0.55, 0.3, 0.16))
		_block(b.round()) # chặn đi xuyên thùng phuy
	var cup := Vector2(24.6, 7.4) * TILE_SIZE # cốc mì ly Kanade đặt trên thùng phuy
	_rect(cup + Vector2(-5, -12), Vector2(10, 12), Color(0.95, 0.92, 0.85))
	_rect(cup + Vector2(-5, -8), Vector2(10, 4), Color(0.9, 0.45, 0.15))
	_light(cup + Vector2(0, -8), Color(1.0, 0.8, 0.5), 0.5, 60.0)
	var bike := Vector2(20.4, 14.9) * TILE_SIZE # xe máy cũ
	for dx in [-24, 24]:
		_disc(bike + Vector2(dx, 0), 9.0, Color(0.08, 0.08, 0.1))
	_rect(bike + Vector2(-22, -10), Vector2(44, 6), Color(0.3, 0.32, 0.38))
	_rect(bike + Vector2(-8, -16), Vector2(18, 6), Color(0.15, 0.12, 0.1))
	_light(Vector2(16, 5.3) * TILE_SIZE, Color(1.0, 0.8, 0.5), 0.9, 190.0)
	_light(Vector2(16, 10.5) * TILE_SIZE, Color(0.6, 0.7, 1.0), 0.65, 520.0)

# ── Nhân vật ───────────────────────────────────────────────────────────────

func _cast_a() -> void:
	_person("Ena", CHAIR)
	for g in [Vector2(12.5, 8), Vector2(19.5, 8), Vector2(12.5, 11.4), Vector2(19.5, 11.4)]:
		_police(g)
	_police(Vector2(16, 11.6), true)
	if _phase == Phase.NONE:
		_police(Vector2(14, 15))
		_police(Vector2(18, 15))
	for y in [-14, -7]: # dây trói Ena vào ghế
		_rect(CHAIR * TILE_SIZE + Vector2(-11, y), Vector2(22, 3), Color(0.45, 0.27, 0.1))
	_fixed_camera()

func _cast_b() -> void:
	var g := GameManager
	var killed: bool = g.get_flag("ena_killed")
	var arrived: bool = g.get_flag("warehouse_arrival_done")
	var start := Vector2(16, 15)
	if killed:
		start = Vector2(18.4, 11.4)
	else:
		var saved: Vector2 = g.last_player_position / TILE_SIZE # chỉ nhận vị trí lưu lúc vào trận nếu nằm trong phòng
		if saved.x > 5.0 and saved.x < 27.0 and saved.y > 4.0 and saved.y < 16.0:
			start = saved
	var ena := _person("Ena", Vector2(16, 11.6) if killed else (start + Vector2(-0.95, 0.2) if arrived else CELL))
	if killed or not arrived:
		_lay_down(ena) # nằm co ro trong phòng giam, hoặc đã gục sau trận cưỡng ép
	for n in GROUPS:
		if int(g.get_flag("mizuki_police_wins", 0)) < n:
			for i in GROUPS[n][1].size():
				_police(GROUPS[n][1][i], n == 2 and i == 2)
			_group_trigger(n, GROUPS[n][0])
	if arrived:
		_person("Mafuyu", Vector2(16, 13.6))
		_person("Ichika", Vector2(14, 14))
		if not g.get_flag("kanade_fled"):
			_person("Kanade", Vector2(18, 14))
	_spawn_player("Mizuki", start, "up")

func _cast_c() -> void:
	var g := GameManager
	_person("Mafuyu", Vector2(8.5, 9))
	var mizuki := _person("Mizuki", Vector2(11.5, 10.5))
	var kanade := _person("Kanade", Vector2(22.5, 10.5))
	if g.get_flag("mizuki_killed"):
		mizuki.position = Vector2(17, 10.8) * TILE_SIZE
		_lay_down(mizuki)
		kanade.position = Vector2(19.8, 10.5) * TILE_SIZE
	else:
		mizuki.modulate = Color(0.75, 0.75, 0.85) # bị từ trường điều khiển, đứng như người rỗng
	if g.get_flag("kanade_killed"):
		_lay_down(kanade)
	else:
		_debris(kanade)
	_spawn_player("Ichika", Vector2(8, 12.5), "right")
	_fixed_camera() # tạo sau người chơi nên thành camera hiện hành

func _fixed_camera() -> void:
	var cam := Camera2D.new()
	cam.position = Vector2(16, 10) * TILE_SIZE
	cam.zoom = Vector2(1.4, 1.4)
	add_child(cam)
	cam.make_current()

# Mảnh kim loại lơ lửng quanh Kanade (từ trường)
func _debris(node: Node2D) -> void:
	for i in range(6):
		var shard := _rect(Vector2(cos(TAU * i / 6.0) * 26.0, sin(TAU * i / 6.0) * 14.0 - 22.0), Vector2(4, 4) if i % 2 == 0 else Vector2(6, 3), Color(0.7, 0.75, 0.85), node)
		var tw := shard.create_tween().set_loops()
		tw.tween_property(shard, "position:y", shard.position.y - 5.0, 0.7 + 0.1 * i).set_trans(Tween.TRANS_SINE)
		tw.tween_property(shard, "position:y", shard.position.y + 5.0, 0.7 + 0.1 * i).set_trans(Tween.TRANS_SINE)

func _spawn_player(char_name: String, grid_pos: Vector2, facing: String) -> void:
	var p := OverworldPlayer.new()
	p.name = "OverworldPlayer"
	p.character_color = COLORS[char_name]
	p.set_facing(facing)
	add_child(p)
	p.character_name = char_name
	p.global_position = grid_pos * TILE_SIZE # OverworldPlayer tự nạp last_player_position nên đặt lại sau add_child
	for c in p.get_children():
		if c is Camera2D:
			c.zoom = Vector2(1.5, 1.5)
			c.limit_left = 48 # quanh khu vực (4..28, 3..17) cộng lề
			c.limit_top = 16
			c.limit_right = 976
			c.limit_bottom = 624

func _person(p_name: String, grid_pos: Vector2) -> Node2D:
	return _npc(p_name, grid_pos, COLORS.get(p_name, POLICE))

func _police(grid_pos: Vector2, captain: bool = false) -> void:
	_npc("Đại Úy Cảnh Sát" if captain else "Cảnh Sát", grid_pos, POLICE, "captain.svg" if captain else "police.svg")

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
	for c in node.get_children():
		if c is Label and color.get_luminance() < 0.4:
			c.add_theme_color_override("font_color", color.lightened(0.55)) # nhãn tối (Mafuyu) khó đọc trên nền đêm
	if not _npcs.has(p_name):
		_npcs[p_name] = node
	return node

# Nằm xuống (xoay sprite 90 độ) cho người đã gục, hoặc đứng dậy
func _lay_down(n: Node2D, lying: bool = true) -> void:
	var body = n.get_child(0)
	body.rotation = PI / 2.0 if lying else 0.0
	body.position = Vector2(2, -8) if lying else Vector2(0, -16)

# Vùng tiếp cận toán cảnh sát: bước vào là xông (hoặc nhấn ENTER khi đứng gần)
func _group_trigger(n: int, center: Vector2) -> void:
	var pos := center * TILE_SIZE
	var zone := _zone(pos, 72.0, "Nhấn ENTER để xông vào toán cảnh sát", func(): _on_group(n))
	zone.body_entered.connect(func(body):
		if body.name == "OverworldPlayer":
			_on_group(n)
	)
	if n == int(GameManager.get_flag("mizuki_police_wins", 0)) + 1: # toán kế tiếp là mục tiêu của mũi tên dẫn đường
		var m := Node2D.new()
		m.position = pos
		m.add_to_group("objectives")
		add_child(m)

func _build_hud() -> void:
	var hud := QuestHUDBuilder.build(self)
	var wins := int(GameManager.get_flag("mizuki_police_wins", 0))
	hud["panel"].visible = _phase == Phase.B and not GameManager.get_flag("mizuki_police_done")
	hud["label"].text = "THANH TRỪNG: Toán cảnh sát đã hạ %d/2\nMục tiêu: %s (mũi tên chỉ hướng), đi thẳng vào chúng hoặc nhấn ENTER." % [wins, "Dọn hai tên gác hành lang gần cửa" if wins < 1 else "Hạ toán canh phòng giam ở góc đông bắc"]

# ── Logic cốt truyện ───────────────────────────────────────────────────────

func _run_logic() -> void:
	match _phase:
		Phase.A:
			await _run_a()
		Phase.B:
			await _run_b()
		Phase.C:
			await _run_c()

func _run_a() -> void:
	_busy = true
	await _say("interrogation_torture_1")
	await _beat()
	await _say("interrogation_torture_2")
	GameManager.set_flag("interrogation_seen", true)
	await _go(BASE_PATH)

func _run_b() -> void:
	_busy = true
	var g := GameManager
	if g.get_flag("ena_killed"):
		if not g.get_flag("kanade_fled"):
			await _say("forced_duel_post")
			g.set_flag("kanade_fled", true)
			await _walk(_npcs.get("Kanade"), DOOR + Vector2(0, -0.2), 2.0, true)
		await _walk(_npcs.get("Mafuyu"), TABLE + Vector2(0, 2), 2.4)
		if _screen:
			_screen.modulate.a = 1.0
		await _say("kanade_dossier")
		g.set_flag("kanade_unmasked", true)
		await _go(MAP_PATH) # nạp lại map: giai đoạn C ở sân sau
		return
	if not g.get_flag("warehouse_arrival_done"):
		if g.get_flag("mizuki_police_done"):
			await _say("mizuki_police_done")
			var p := get_node("OverworldPlayer") as Node2D
			_lay_down(_npcs["Ena"], false) # Mizuki dìu Ena dậy rồi Mafuyu cùng hai người nữa bước vào
			await _walk(_npcs["Ena"], p.position / TILE_SIZE + Vector2(-0.95, 0.2), 1.6)
			var spots := {"Mafuyu": Vector2(16, 13.6), "Ichika": Vector2(14, 14), "Kanade": Vector2(18, 14)}
			for n in spots:
				_walk(_person(n, DOOR + Vector2(0, -0.4)), spots[n], 1.6)
				await get_tree().create_timer(0.5).timeout
			await get_tree().create_timer(1.0).timeout
			await _say("warehouse_mafuyu_arrive")
			g.set_flag("warehouse_arrival_done", true)
		else:
			if not g.get_flag("warehouse_mizuki_arrive_seen"):
				await _say("warehouse_mizuki_arrive")
				g.set_flag("warehouse_mizuki_arrive_seen", true)
			_busy = false
			_armed = true
			return
	await _say("forced_duel_pre")
	await _battle("mizuki_vs_ena_forced")

func _run_c() -> void:
	_busy = true
	var g := GameManager
	if g.get_flag("kanade_killed"):
		await _say("kanade_death")
		await _go(BASE_PATH)
	elif g.get_flag("mizuki_killed"):
		if not g.get_flag("kanade_slow_pre_seen"):
			await _say("mizuki_dies")
			await _say("kanade_slow_pre")
			g.set_flag("kanade_slow_pre_seen", true)
		await _battle("ichika_vs_kanade_slow")
	else:
		if not g.get_flag("kanade_confront_seen"):
			await _say("kanade_confront_pre")
			g.set_flag("kanade_confront_seen", true)
		await _battle("mizuki_vs_kanade")

func _on_group(n: int) -> void:
	if _busy or not _armed:
		return
	_busy = true
	if n == 2 and int(GameManager.get_flag("mizuki_police_wins", 0)) < 1:
		await _narrate("Hai tên gác hành lang còn đứng ngay sau lưng cô. Xử lý chúng trước khi tiến vào phòng giam.")
		_busy = false
		return
	await _say("mizuki_police_%d_pre" % n)
	await _battle("mizuki_police_%d" % n)

# Nhịp hình ảnh giữa hai đoạn tra tấn: chớp sáng, tối màn hình, thời gian trôi, Ena gục hẳn
func _beat() -> void:
	var old := _mod.color
	var tw := create_tween()
	tw.tween_property(_mod, "color", Color(1.8, 1.8, 1.9), 0.06)
	tw.tween_property(_mod, "color", old, 0.5)
	await tw.finished
	await ScreenFade.fade_out(0.7)
	_npcs["Ena"].get_child(0).rotation = 0.3
	_mod.color = Color(0.3, 0.28, 0.4)
	await get_tree().create_timer(0.8).timeout
	await ScreenFade.fade_in(0.9)

# Đi tới ô lưới (nhân vật có thể không còn trong map thì bỏ qua); `free_after` để xóa sau khi tới (Kanade bỏ đi)
func _walk(node: Node2D, grid: Vector2, secs: float, free_after: bool = false) -> void:
	if node == null:
		return
	var tw := node.create_tween()
	tw.tween_property(node, "position", grid * TILE_SIZE, secs).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if free_after:
		node.queue_free()

func _battle(id: String) -> void:
	_busy = true
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

func _ring(x1: int, y1: int, x2: int, y2: int, skip: Vector2 = Vector2(-99, -99)) -> void:
	for x in range(x1 + 1, x2):
		for y in [y1, y2]:
			if Vector2(x, y) != skip:
				_tile("horizontal_wall.png", Vector2(x, y), true)
	for y in range(y1 + 1, y2):
		_tile("left_vertical_wall.png", Vector2(x1, y), true)
		_tile("right_vertical_wall.png", Vector2(x2, y), true)
	_tile("top_left_wall.png", Vector2(x1, y1), true)
	_tile("top_right_wall.png", Vector2(x2, y1), true)
	_tile("bottom_left_wall.png", Vector2(x1, y2), true)
	_tile("bottom_right_wall.png", Vector2(x2, y2), true)

func _tile(file: String, g: Vector2, collide: bool = false) -> void:
	MapUtils.place_tile(self, file, g, collide)

func _indoor(file: String, g: Vector2, collide: bool = true) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://Assets/Indoors/" + file)
	sp.scale = Vector2(4, 4)
	sp.position = g * TILE_SIZE
	add_child(sp)
	if collide:
		_block(g)

func _crate(g: Vector2) -> void:
	var p := g * TILE_SIZE - Vector2(14, 14)
	_rect(p, Vector2(28, 28), Color(0.36, 0.25, 0.14))
	_rect(p + Vector2(3, 3), Vector2(22, 22), Color(0.52, 0.37, 0.21))
	_rect(p + Vector2(3, 12), Vector2(22, 3), Color(0.33, 0.23, 0.13))
	_rect(p + Vector2(12, 3), Vector2(3, 22), Color(0.33, 0.23, 0.13))
	_block(g)

func _block(g: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = g * TILE_SIZE
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE_SIZE, TILE_SIZE)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node = null) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(r)
	return r

func _disc(pos: Vector2, radius: float, color: Color) -> void:
	var d := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(14):
		pts.append(Vector2(cos(TAU * i / 14.0), sin(TAU * i / 14.0)) * radius)
	d.polygon = pts
	d.position = pos
	d.color = color
	add_child(d)

func _zone(pos: Vector2, radius: float, prompt: String, action: Callable) -> InteractableZone:
	var zone := InteractableZone.new()
	zone.position = pos
	zone.prompt_text = prompt
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	zone.add_child(col)
	zone.interacted.connect(action)
	add_child(zone)
	return zone

# Đèn điểm dùng texture gradient tròn tự tạo (không thêm tài nguyên nhị phân)
func _light(pos: Vector2, color: Color, energy: float, radius: float, parent: Node = null) -> void:
	if _light_tex == null:
		_light_tex = GradientTexture2D.new()
		_light_tex.width = 128
		_light_tex.height = 128
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
		_light_tex.gradient = Gradient.new()
		_light_tex.gradient.set_color(0, Color.WHITE)
		_light_tex.gradient.set_color(1, Color(1, 1, 1, 0))
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.texture_scale = radius / 64.0
	l.color = color
	l.energy = energy
	l.position = pos
	(parent if parent else self).add_child(l)
