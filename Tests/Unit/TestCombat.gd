extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho hệ thống Chiến đấu (trạng thái, AI, chí mạng, hồi chiêu, phản đòn). Công thức sát thương: TestDamageCalculator; thứ tự lượt: TestTurnOrder.
"""

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

# Kanade bẻ hướng 20% đòn: cờ chí mạng phải đi theo phần sát thương sang đồng đội, Kanade chỉ hiện số 0 thường
func test_kanade_deflect_moves_the_crit_flag_to_whoever_takes_the_damage():
	var kanade := Kanade.new()
	var ichika := Ichika.new()
	kanade.allies = [kanade, ichika]
	var k_events: Array = []
	var i_events: Array = []
	kanade.damage_received_detailed.connect(func(amount, _t, crit, _b): k_events.append([amount, crit]))
	ichika.damage_received_detailed.connect(func(amount, _t, crit, _b): i_events.append([amount, crit]))
	var deflected := 0
	var direct := 0
	for i in 300:
		kanade.current_hp = kanade.max_hp
		ichika.current_hp = ichika.max_hp
		k_events.clear()
		i_events.clear()
		kanade.set_meta("was_crit", true)
		kanade.take_damage(100)
		if i_events.is_empty():
			direct += 1
			assert_eq(k_events, [[100, true]], "Không bẻ hướng: Kanade nhận đòn chí mạng")
		else:
			deflected += 1
			assert_eq(k_events, [[0, false]], "Bẻ hướng: Kanade chỉ hiện số 0 thường")
			assert_eq(i_events, [[50, true]], "Bẻ hướng: đồng đội nhận nửa sát thương kèm cờ chí mạng")
	assert_gt(deflected, 0, "Trong 300 lần phải có lần bẻ hướng (xác suất 20%)")
	assert_gt(direct, 0, "Và có lần không bẻ hướng")
	kanade.free()
	ichika.free()
