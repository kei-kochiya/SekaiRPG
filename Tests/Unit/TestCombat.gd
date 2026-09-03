extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho hệ thống Chiến đấu (DamageCalculator, TurnCalculator, ProcessStatus, AIManager).
"""

func test_damage_calculator_raw():
	var attacker = Ichika.new()
	attacker.atk = 50
	var defender = Guard.new()
	defender.defense = 20
	
	var dmg = DamageCalculator.calculate_damage(attacker, defender, 1.0)
	assert_gt(dmg, 0, "Damage is positive")
	
	# Test minimum damage guarantee
	defender.defense = 9999
	var min_dmg = DamageCalculator.calculate_damage(attacker, defender, 1.0)
	assert_gt(min_dmg, 0, "Damage satisfies minimum threshold even against huge defense")

func test_damage_calculator_type_chart():
	var ichika = Ichika.new()
	ichika.atk = 40
	ichika.crit_rate = 0.0 # Tắt random crit để kiểm tra chính xác hệ số nguyên tố
	ichika.type = "Pure"
	
	var bot = TrainingBot.new()
	bot.type = "Mysterious" # Pure is effective against Mysterious (1.25x)
	bot.defense = 10
	
	var dmg_strong = DamageCalculator.calculate_damage(ichika, bot, 1.0)
	
	bot.type = "Pure" # Same element (neutral)
	var dmg_neutral = DamageCalculator.calculate_damage(ichika, bot, 1.0)
	assert_gt(dmg_strong, dmg_neutral, "Type advantage yields higher damage")

func test_damage_calculator_crit_and_break():
	var ichika = Ichika.new()
	ichika.atk = 60
	ichika.crit_rate = 1.0 # Guarantee crit
	ichika.crit_dmg = 2.0
	ichika.type = "Pure"
	
	var bot = TrainingBot.new()
	bot.type = "Mysterious"
	bot.max_break_gauge = 40
	bot.break_gauge = 40
	
	var detailed = DamageCalculator.calculate_damage_detailed(ichika, bot, 1.0)
	assert_true(detailed["is_crit"], "calculate_damage_detailed correctly identifies critical hit")
	assert_true(detailed["is_weakness"], "calculate_damage_detailed identifies weakness hit")
	assert_true(detailed["is_break"], "calculate_damage_detailed triggers break on depleted gauge")

func test_turn_calculator():
	var av_fast = TurnCalculator.get_action_value(120)
	var av_slow = TurnCalculator.get_action_value(60)
	assert_gt(av_slow, av_fast, "Higher speed results in lower (faster) Action Value")

func test_process_status():
	var entity = TrainingBot.new()
	entity.max_hp = 100
	entity.current_hp = 100
	
	# Test Bleed
	entity.add_status({"type": "Bleed", "duration": 2})
	entity.add_status({"type": "Bleed", "duration": 2})
	assert_eq(entity.get_status_count("Bleed"), 2, "Bleed applied with correct stacks")
	
	var can_act = ProcessStatus.handle_turn_start(entity)
	assert_true(can_act, "Bleed allows entity to act")
	assert_lt(entity.current_hp, 100, "Bleed deals damage at turn start")
	
	# Test Stun
	entity.add_status({"type": "Stun", "duration": 1})
	var can_act_stun = ProcessStatus.handle_turn_start(entity)
	assert_false(can_act_stun, "Stun prevents entity from acting")

func test_ai_manager():
	var enemy = Guard.new()
	var ally = TrainingBot.new()
	var enemies = [ally]
	var allies = [enemy]
	var timeline = [{"entity": enemy, "av": 100.0}, {"entity": ally, "av": 120.0}]
	
	var decision = AIManager.pick_action(enemy, enemies, allies, timeline)
	assert_true(decision.has("action"), "AIManager decision has action")
	assert_true(decision.has("target"), "AIManager decision has target")
	assert_eq(decision["target"], ally, "AIManager selects valid target")
