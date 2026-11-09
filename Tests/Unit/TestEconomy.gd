extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho Hệ thống Kinh tế (Credits, Inventory, Item Usage, TreasureChest).
"""

func test_credits_management():
	var initial = GameManager.credits
	GameManager.add_credits(500)
	assert_eq(GameManager.credits, initial + 500, "GameManager.add_credits adds correctly")
	
	var spent = GameManager.spend_credits(200)
	assert_true(spent, "GameManager.spend_credits succeeds when sufficient")
	assert_eq(GameManager.credits, initial + 300, "GameManager.credits reduced after spend")
	
	var overspend = GameManager.spend_credits(999999)
	assert_false(overspend, "GameManager.spend_credits fails when insufficient")

func test_inventory_management():
	var bot = TrainingBot.new()
	bot.max_hp = 100
	bot.current_hp = 30
	
	# Potion
	GameManager.add_item("potion", 1)
	assert_gt(GameManager.get_item_count("potion"), 0, "Inventory tracks potion count")
	var used_potion = GameManager.use_item("potion", bot)
	assert_true(used_potion, "GameManager.use_item potion success")
	assert_gt(bot.current_hp, 30, "Potion heals target")
	
	# Energy Drink
	bot.action_gauge = 0.0
	GameManager.add_item("energy_drink", 1)
	var used_energy = GameManager.use_item("energy_drink", bot)
	assert_true(used_energy, "GameManager.use_item energy_drink success")
	assert_eq(bot.action_gauge, 10000.0, "Energy drink fills action gauge to 10000")
	
	# Bandage
	bot.add_status({"type": "Bleed", "duration": 2})
	bot.add_status({"type": "Poison", "duration": 2})
	assert_gt(bot.active_statuses.size(), 0, "Target has active statuses")
	GameManager.add_item("bandage", 1)
	var used_bandage = GameManager.use_item("bandage", bot)
	assert_true(used_bandage, "GameManager.use_item bandage success")
	assert_eq(bot.active_statuses.size(), 0, "Bandage cleanses all active debuffs")

# Rương thật trên map: thưởng đúng một lần, lần bấm sau chỉ báo rương rỗng; thân rương chặn người chơi (layer 2) mà không vướng vùng tương tác
func test_chest_node_pays_out_once_and_blocks_the_player():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var parent := Node2D.new()
	root.add_child(parent)
	MapUtils.place_chest(parent, "unit_test_chest_node", Vector2(3, 4), 200, "bandage", 2)
	var chest: TreasureChest = parent.get_child(0)
	assert_false(GameManager.is_chest_opened("unit_test_chest_node"), "Rương mới chưa mở")
	var credits_before: int = GameManager.credits
	var bandages_before: int = GameManager.inventory.get("bandage", 0)
	chest._on_interacted()
	_drain_dialogue()
	assert_eq(GameManager.credits, credits_before + 200, "Nhận 200 Credits")
	assert_eq(GameManager.inventory.get("bandage", 0), bandages_before + 2, "Nhận 2 băng gạc")
	assert_true(GameManager.is_chest_opened("unit_test_chest_node"), "Rương được ghi là đã mở")
	assert_true(GameManager.opened_chests.has("unit_test_chest_node"), "Mã rương nằm trong opened_chests")
	chest._on_interacted()
	_drain_dialogue()
	assert_eq(GameManager.credits, credits_before + 200, "Mở lần hai không thưởng thêm")
	assert_eq(GameManager.inventory.get("bandage", 0), bandages_before + 2, "Cũng không thêm vật phẩm")
	var bodies := chest.get_children().filter(func(n): return n is StaticBody2D)
	assert_eq(bodies.size(), 1, "Một thân va chạm")
	assert_eq((bodies[0] as StaticBody2D).collision_layer, 2, "Layer 2: chặn người chơi nhưng không chặn vùng tương tác")
	root.remove_child(parent)
	parent.free()
