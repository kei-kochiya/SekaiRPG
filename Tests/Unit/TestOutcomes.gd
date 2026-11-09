extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra ba lớp được tách khỏi GameManager: ScriptedBattleOutcomes (cờ cốt truyện sau trận kịch bản),
EntityFactory (bảng tên → lớp thực thể dùng chung) và ItemCatalog (vật phẩm tiêu hao).
"""

func _story() -> StoryState:
	var s := StoryState.new()
	s.reset()
	return s

func test_win_flag_battles_set_their_flag_only_on_victory():
	for id in ScriptedBattleOutcomes.WIN_FLAG:
		var flag: String = ScriptedBattleOutcomes.WIN_FLAG[id]
		var won := _story()
		ScriptedBattleOutcomes.apply(won, id, true)
		assert_true(won.get_flag(flag), "%s: winning sets %s" % [id, flag])
		assert_eq(won.get_flag("last_scripted_win"), id, "%s: last_scripted_win" % id)
		assert_eq(won.get_flag("last_scripted_loss"), "", "%s: no loss recorded after a win" % id)
		var lost := _story()
		ScriptedBattleOutcomes.apply(lost, id, false)
		assert_false(lost.get_flag(flag), "%s: losing does not set %s (the map replays the fight)" % [id, flag])
		assert_eq(lost.get_flag("last_scripted_loss"), id, "%s: last_scripted_loss" % id)

func test_fated_battles_set_their_flag_win_or_lose():
	for id in ScriptedBattleOutcomes.FATED:
		for victory in [true, false]:
			var s := _story()
			ScriptedBattleOutcomes.apply(s, id, victory)
			assert_true(s.get_flag(ScriptedBattleOutcomes.FATED[id]), "%s (victory=%s) sets its fated flag" % [id, victory])
		assert_true(ScriptedBattleOutcomes.heals_party(id, true), "%s heals the party even after a win" % id)

func test_special_outcome_flags():
	var s := _story()
	ScriptedBattleOutcomes.apply(s, "ena_vs_mizuki", false)
	assert_true(s.get_flag("ena_vs_mizuki_done") and not s.get_flag("ena_vs_mizuki_won"), "ena_vs_mizuki records done and lost")
	ScriptedBattleOutcomes.apply(s, "ena_vs_thugs", true)
	assert_true(s.get_flag("ena_vs_thugs_done") and s.get_flag("ena_vs_thugs_won"), "ena_vs_thugs records done and won")
	var skirmish := _story()
	ScriptedBattleOutcomes.apply(skirmish, "street_skirmish", false)
	assert_false(skirmish.get_flag("street_skirmish_done"), "a lost skirmish is not done (the street replays it)")
	ScriptedBattleOutcomes.apply(skirmish, "street_skirmish", true)
	assert_true(skirmish.get_flag("street_skirmish_done"), "a won skirmish is done")
	var survival := _story()
	ScriptedBattleOutcomes.apply(survival, "street_survival", false)
	assert_true(survival.get_flag("street_survival_done"), "survival is done even when lost (Mafuyu rescues)")
	var harbor := _story()
	ScriptedBattleOutcomes.apply(harbor, "harbor_boss", true)
	assert_eq(harbor.get_flag("last_scripted_win"), "harbor_boss", "the boss win is recorded (the Harbor hand-off itself is GameManager's)")
	var trial := _story()
	ScriptedBattleOutcomes.apply(trial, "training_trial", false)
	assert_true(trial.get_flag("training_trial_failed"), "a lost trial is marked failed")
	ScriptedBattleOutcomes.apply(trial, "training_trial", true)
	assert_false(trial.get_flag("training_trial_failed"), "a won trial clears the failed mark")

func test_retreat_and_heal_rules():
	for id in ScriptedBattleOutcomes.RETREAT_ON_LOSS:
		assert_true(ScriptedBattleOutcomes.retreats_to_base(id, false), "%s: losing retreats to base" % id)
		assert_false(ScriptedBattleOutcomes.retreats_to_base(id, true), "%s: winning does not retreat" % id)
	assert_false(ScriptedBattleOutcomes.retreats_to_base("bounty_1", false), "bounty fights replay in place instead")
	assert_true(ScriptedBattleOutcomes.heals_party("bounty_1", false), "any loss heals the party")
	assert_false(ScriptedBattleOutcomes.heals_party("bounty_1", true), "a plain win does not")

func test_entity_factory_knows_every_listed_name():
	for n in EntityFactory.SANDBOX_CHARACTERS:
		var c := EntityFactory.create(n)
		assert_true(c != null and c.is_character, "%s is a playable character" % n)
		assert_eq(c.entity_name, n, "%s keeps its name" % n)
		c.free()
	for n in EntityFactory.SANDBOX_MONSTERS:
		var m := EntityFactory.create(n)
		assert_true(m != null and not m.is_character, "%s is a monster" % n)
		m.free()
	assert_true(EntityFactory.create("Không Có Ai") == null, "unknown names give null")
	for n in ["Thug", "Terrorist"]:
		var alias := EntityFactory.create(n)
		assert_true(alias != null, "Holo-Sim alias %s resolves" % n)
		alias.free()

func test_item_effects():
	var e := Ichika.new()
	e.current_hp = 10
	ItemCatalog.apply_effect("potion", e)
	assert_eq(e.current_hp, mini(10 + int(e.max_hp * 0.4), e.max_hp), "potion heals 40% of max HP")
	ItemCatalog.apply_effect("energy_drink", e)
	assert_eq(e.action_gauge, 10000.0, "energy drink fills the action gauge")
	e.add_status({"type": "Bleed", "duration": 3})
	assert_gt(e.active_statuses.size(), 0, "the bleed landed")
	ItemCatalog.apply_effect("bandage", e)
	assert_eq(e.active_statuses.size(), 0, "bandage clears every status")
	for id in GameManager.DEFAULT_INVENTORY:
		assert_true(ItemCatalog.ITEMS.has(id), "starting item %s exists in the catalog" % id)
	e.free()

# Hai bảng quái (tên hiển thị -> lớp ở EntityFactory, id kỹ thuật -> lớp ở BattleInitializer) từng được chép riêng và dễ lệch nhau
func test_entity_factory_monsters_are_known_to_the_battle_initializer():
	var known: Array = BattleInitializer.enemy_classes.values()
	for monster_name in EntityFactory.MONSTERS:
		assert_true(EntityFactory.MONSTERS[monster_name] in known, "%s có trong BattleInitializer.enemy_classes" % monster_name)

# Bảng kết cục chỉ chạy khi khóa khớp một id trong registry: gõ sai một id thì trận đó lặng lẽ mất cờ/quy tắc rút lui
func test_every_outcome_table_key_is_a_registered_battle():
	var ids: Array = BattleInitializer.scripted_battle_ids()
	var tables := {
		"FATED": ScriptedBattleOutcomes.FATED.keys(),
		"WIN_FLAG": ScriptedBattleOutcomes.WIN_FLAG.keys(),
		"RETREAT_ON_LOSS": ScriptedBattleOutcomes.RETREAT_ON_LOSS,
		"CONTINUES_ON_LOSS": ScriptedBattleOutcomes.CONTINUES_ON_LOSS,
	}
	for table_name in tables:
		assert_gt(tables[table_name].size(), 0, "%s không rỗng" % table_name)
		for id in tables[table_name]:
			assert_true(id in ids, "%s: '%s' là một id có trong registry" % [table_name, id])

