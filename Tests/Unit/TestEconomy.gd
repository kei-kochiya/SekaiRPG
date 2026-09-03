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

func test_treasure_chests():
	var chest_id = "unit_test_chest_unique"
	assert_false(GameManager.is_chest_opened(chest_id), "New chest is not opened initially")
	
	GameManager.open_chest(chest_id)
	assert_true(GameManager.is_chest_opened(chest_id), "GameManager.open_chest marks chest opened")
	assert_true(GameManager.opened_chests.has(chest_id), "Chest ID recorded in opened_chests array")
