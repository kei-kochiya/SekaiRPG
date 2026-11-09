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

# Các suite chạy trước (TestMaps dựng map có fade_in) có thể để ScreenFade.busy kẹt ở true vì runner chạy đồng bộ, không có frame để tween xong;
# InteractableZone bỏ qua phím khi đang fade nên bài này tự đặt lại rồi trả về như cũ.
var _was_busy := false

func before_each() -> void:
	super.before_each()
	_was_busy = ScreenFade.busy
	ScreenFade.busy = false
	GameManager.end_dialogue() # _refresh_targets bỏ qua khi đang hội thoại

func after_each() -> void:
	ScreenFade.busy = _was_busy
	super.after_each()

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
