extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra vùng tương tác ngoài map. Khi nhiều vùng chồng lên nhau (NPC đứng sát bệ cửa hàng/Holo-Sim),
chỉ vùng gần người chơi nhất được hiện gợi ý và nhận phím ENTER.
"""

func _zone(pos: Vector2, parent: Node) -> InteractableZone:
	var zone := InteractableZone.new()
	zone.position = pos
	var col := CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	zone.add_child(col)
	parent.add_child(zone)
	return zone

func _press_enter(zone: InteractableZone) -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	zone._unhandled_input(ev)

func test_only_the_nearest_overlapping_zone_reacts():
	GameManager.end_dialogue()
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var holder := Node2D.new()
	root.add_child(holder)
	var player := Node2D.new()
	player.name = "OverworldPlayer"
	holder.add_child(player)
	var shop := _zone(Vector2(0, 0), holder)
	var npc := _zone(Vector2(60, 0), holder)
	var fired := {"shop": 0, "npc": 0}
	shop.interacted.connect(func(): fired["shop"] += 1)
	npc.interacted.connect(func(): fired["npc"] += 1)

	player.position = Vector2(45, 0) # gần NPC hơn bệ cửa hàng
	shop._on_body_entered(player)
	assert_true(shop.prompt_label.visible, "Đứng một mình trong vùng thì vùng đó hiện gợi ý")
	npc._on_body_entered(player)
	assert_true(npc.prompt_label.visible, "Vùng gần nhất hiện gợi ý")
	assert_false(shop.prompt_label.visible, "Vùng xa hơn bị ẩn gợi ý dù người chơi vẫn đứng trong")
	_press_enter(shop)
	_press_enter(npc)
	assert_eq(fired, {"shop": 0, "npc": 1}, "Chỉ vùng gần nhất nhận phím ENTER")

	player.position = Vector2(10, 0) # đi sát bệ cửa hàng: vùng thắng đổi chủ
	shop._process(0.0)
	npc._process(0.0)
	assert_true(shop.prompt_label.visible, "Bệ cửa hàng gần hơn nên giờ nó hiện gợi ý")
	assert_false(npc.prompt_label.visible, "NPC bị ẩn gợi ý")
	_press_enter(npc)
	_press_enter(shop)
	assert_eq(fired, {"shop": 1, "npc": 1}, "Phím ENTER chuyển sang bệ cửa hàng")

	shop._on_body_exited(player) # rời vùng gần nhất: vùng còn lại hiện lại ngay
	assert_true(npc.prompt_label.visible, "Ra khỏi vùng thắng thì vùng còn lại hiện gợi ý")
	_press_enter(shop)
	assert_eq(fired["shop"], 1, "Vùng đã rời không nhận phím")

	npc._on_body_exited(player)
	root.remove_child(holder)
	holder.free()
	assert_eq(InteractableZone._inside.size(), 0, "Không còn vùng nào bị giữ lại trong danh sách")

func test_a_freed_zone_leaves_the_arbitration_list():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var holder := Node2D.new()
	root.add_child(holder)
	var player := Node2D.new()
	player.name = "OverworldPlayer"
	holder.add_child(player)
	var a := _zone(Vector2(0, 0), holder)
	var b := _zone(Vector2(20, 0), holder)
	player.position = Vector2(5, 0)
	a._on_body_entered(player)
	b._on_body_entered(player)
	assert_eq(InteractableZone._inside.size(), 2, "Hai vùng cùng chứa người chơi")
	holder.remove_child(a) # NPC dựng lại giữa chừng (BaseMap._spawn_npcs)
	a.free()
	assert_eq(InteractableZone._inside.size(), 1, "Vùng bị gỡ rời danh sách")
	assert_true(b.prompt_label.visible, "Vùng còn lại hiện gợi ý ngay")
	root.remove_child(holder)
	holder.free()
	assert_eq(InteractableZone._inside.size(), 0, "Danh sách sạch sau khi dọn")

# ── MapUtils: vật cản và tấm lát ───────────────────────────────────────────

func test_blocks_and_tiled_rectangles_cover_the_expected_cells():
	var parent := Node2D.new()
	var block := MapUtils.add_block(parent, Vector2(3, 4))
	assert_eq(block.position, Vector2(3, 4) * MapUtils.TILE_SIZE, "Vật cản đặt đúng ô lưới")
	assert_eq(((block.get_child(0) as CollisionShape2D).shape as RectangleShape2D).size, Vector2(32, 32), "Vật cản vừa một ô")

	var before := parent.get_child_count()
	MapUtils.place_tile(parent, "horizontal_wall.png", Vector2(1, 1), true)
	assert_eq(parent.get_child_count(), before + 2, "Ô tường có va chạm = sprite + một vật cản")
	assert_eq((parent.get_child(parent.get_child_count() - 1) as Node2D).position, Vector2(32, 32), "Vật cản của ô tường nằm đúng ô")

	var area := Node2D.new()
	MapUtils.fill_tiles(area, "water_body.png", 2, 3, 11, 5, true) # 10 x 3 ô
	assert_eq(area.get_child_count(), 2, "Cả hình chữ nhật chỉ còn một sprite và một vật cản")
	var tiles: Sprite2D = area.get_child(0)
	assert_eq(tiles.region_rect.size, tiles.texture.get_size() * Vector2(10, 3), "Sprite lát đủ 10 x 3 ô")
	assert_eq(tiles.position, Vector2(2, 3) * 32 - Vector2(16, 16), "Sprite bắt đầu ở góc trên trái của ô (2, 3)")
	var wall: StaticBody2D = area.get_child(1)
	assert_eq(wall.position, Vector2(2 + 11, 3 + 5) * 32 / 2.0, "Vật cản phủ chính giữa vùng")
	assert_eq(((wall.get_child(0) as CollisionShape2D).shape as RectangleShape2D).size, Vector2(10, 3) * 32, "Vật cản phủ cả vùng")

	var floor_only := Node2D.new()
	MapUtils.fill_floor(floor_only, 0, 0, 4, 4)
	assert_eq(floor_only.get_child_count(), 1, "Sàn không có va chạm: chỉ một sprite")
	parent.free()
	area.free()
	floor_only.free()

func test_zone_and_player_factories():
	var parent := Node2D.new()
	var round_zone := MapUtils.circle_zone(40, "Nói chuyện", Vector2(64, 96))
	var box_zone := MapUtils.rect_zone(Vector2(64, 32), "", Vector2(5, 6))
	parent.add_child(round_zone)
	parent.add_child(box_zone)
	assert_eq(round_zone.prompt_text, "Nói chuyện", "Gợi ý được đặt")
	assert_eq(round_zone.position, Vector2(64, 96), "Vị trí được đặt")
	assert_eq(((round_zone.get_child(0) as CollisionShape2D).shape as CircleShape2D).radius, 40.0, "Bán kính vùng tròn")
	assert_eq(box_zone.prompt_text, "Press ENTER", "Không truyền gợi ý thì giữ gợi ý mặc định")
	assert_eq(((box_zone.get_child(0) as CollisionShape2D).shape as RectangleShape2D).size, Vector2(64, 32), "Kích thước vùng chữ nhật")

	GameManager.reset_game()
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	root.add_child(parent)
	GameManager.last_player_position = Vector2.ZERO
	var fresh := MapUtils.spawn_player(parent, Vector2(320, 576))
	assert_eq(fresh.position, Vector2(320, 576), "Không có vị trí lưu: xuất hiện ở vị trí mặc định")
	GameManager.last_player_position = Vector2(128, 160)
	var resumed := MapUtils.spawn_player(parent, Vector2(320, 576))
	assert_eq(resumed.global_position, Vector2(128, 160), "Có vị trí lưu (vào lại map sau trận): OverworldPlayer tự nạp lại")
	root.remove_child(parent)
	parent.free()
	GameManager.reset_game()

# Camera cố định dùng chung: mặc định căn giữa (15, 10) zoom 1.5; Thẩm vấn truyền tâm/zoom riêng
func test_fixed_camera_defaults_and_overrides():
	var parent := Node2D.new()
	var plain := MapUtils.add_fixed_camera(parent)
	assert_eq(plain.position, Vector2(15, 10) * MapUtils.TILE_SIZE, "Tâm mặc định (15, 10)")
	assert_eq(plain.zoom, Vector2(1.5, 1.5), "Zoom mặc định 1.5")
	var custom := MapUtils.add_fixed_camera(parent, Vector2(16, 10), 1.4)
	assert_eq(custom.position, Vector2(16, 10) * MapUtils.TILE_SIZE, "Tâm tùy chọn")
	assert_eq(custom.zoom, Vector2(1.4, 1.4), "Zoom tùy chọn")
	assert_eq(parent.get_child_count(), 2, "Mỗi lời gọi thêm đúng một camera")
	parent.free()

# Đèn dùng chung của StoryMap: texture dựng một lần rồi dùng lại; bán kính px = texture_scale * 64
func test_story_map_lights_share_one_texture_and_honour_the_parent():
	var map := StoryMap.new()
	var other := Node2D.new()
	map.add_child(other)
	map._light(Vector2(10, 20), Color(1, 0.8, 0.5), 0.7, 128.0)
	map._light(Vector2(30, 40), Color.WHITE, 1.0, 64.0, other)
	var on_map := map.get_children().filter(func(c): return c is PointLight2D)
	var on_other := other.get_children().filter(func(c): return c is PointLight2D)
	assert_eq(on_map.size(), 1, "Không truyền parent: đèn gắn vào map")
	assert_eq(on_other.size(), 1, "Có parent: đèn gắn vào parent")
	assert_eq((on_map[0] as PointLight2D).texture_scale, 2.0, "Bán kính 128px = scale 2")
	assert_eq((on_other[0] as PointLight2D).texture_scale, 1.0, "Bán kính 64px = scale 1")
	assert_eq((on_map[0] as PointLight2D).position, Vector2(10, 20), "Vị trí đèn")
	assert_eq((on_map[0] as PointLight2D).texture, (on_other[0] as PointLight2D).texture, "Hai đèn dùng chung một texture")
	map.free()

