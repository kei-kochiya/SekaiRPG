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

func test_bleed_can_kill_at_turn_start():
	var entity = Ichika.new()
	entity.current_hp = 1
	entity.add_status({"type": "Bleed", "duration": 2})
	
	var can_act = ProcessStatus.handle_turn_start(entity)
	assert_true(entity.current_hp <= 0, "Bleed kills an entity at 1 HP")
	assert_false(can_act, "Dead entity cannot act")

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

func test_dead_entity_does_not_die_twice():
	var bot = TrainingBot.new()
	var died_count = [0]
	bot.died.connect(func(): died_count[0] += 1)
	bot.take_damage(99999)
	bot.take_damage(50)
	assert_eq(died_count[0], 1, "died is emitted only once, no matter how many hits land on the corpse")

func test_temp_mods_round_trip():
	var ichika = Ichika.new()
	var base_spd = ichika.spd
	var base_def = ichika.defense
	ichika.add_temp_mod("spd", 40)
	ichika.add_temp_mod("spd", 40)
	ichika.add_temp_mod("defense", -99999)
	assert_eq(ichika.spd, base_spd + 80, "Temp speed mods stack during the battle")
	assert_eq(ichika.defense, 0, "Defense never goes negative")
	ichika.clear_temp_mods()
	assert_eq(ichika.spd, base_spd, "Speed is restored after the battle")
	assert_eq(ichika.defense, base_def, "Defense is restored by the real amount that was removed")

func test_poison_reapply_upgrades_strength():
	var bot = TrainingBot.new()
	bot.add_status({"type": "Poison", "duration": 2, "percent": 0.05})
	bot.add_status({"type": "Poison", "duration": 3, "percent": 0.2})
	assert_eq(bot.get_status_count("Poison"), 1, "Poison does not stack")
	assert_eq(bot.active_statuses[0]["percent"], 0.2, "A stronger poison replaces the weaker strength")
	assert_eq(bot.active_statuses[0]["duration"], 3, "Duration is refreshed")

func test_reset_battle_state_clears_leftovers():
	var ichika = Ichika.new()
	ichika.cooldowns["shadow_strike"] = 5
	ichika.add_status({"type": "Stun", "duration": 2})
	ichika.action_gauge = 9000.0
	ichika.skills_disabled = true
	ichika.reset_battle_state()
	assert_true(ichika.cooldowns.is_empty(), "Cooldowns cleared")
	assert_eq(ichika.active_statuses.size(), 0, "Statuses cleared")
	assert_eq(ichika.action_gauge, 0.0, "Action gauge cleared")
	assert_false(ichika.skills_disabled, "Skills re-enabled")

func test_locked_cooldown_does_not_tick_down():
	var mafuyu = Mafuyu.new()
	CooldownManager.set_cooldown(mafuyu, "lost_world", CooldownManager.LOCKED_FOR_BATTLE)
	CooldownManager.set_cooldown(mafuyu, "numb_blade", 2)
	CooldownManager.process_cooldowns(mafuyu)
	assert_eq(mafuyu.cooldowns["lost_world"], CooldownManager.LOCKED_FOR_BATTLE, "Once-per-battle skill stays locked")
	assert_eq(mafuyu.cooldowns["numb_blade"], 1, "Normal cooldowns still count down")

func test_crit_flag_reaches_take_damage():
	var ichika = Ichika.new()
	ichika.crit_rate = 1.0
	var bot = TrainingBot.new()
	var seen = []
	bot.damage_received_detailed.connect(func(_amt, _type, is_crit, _is_break): seen.append(is_crit))
	var dmg = DamageCalculator.calculate_damage(ichika, bot, 1.0)
	bot.take_damage(dmg)
	assert_eq(seen.size(), 1, "One damage event")
	assert_true(seen[0], "Critical hits are reported to listeners")
