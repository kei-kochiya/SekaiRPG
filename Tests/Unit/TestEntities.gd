extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho Thực thể (Entities: Characters & Enemies).
"""

func test_character_skills():
	var chars = [Ichika.new(), Kanade.new(), Mafuyu.new(), Ena.new(), Mizuki.new(), Honami.new()]
	for c in chars:
		assert_gt(c.skills.size(), 0, "%s has at least 1 skill" % c.entity_name)
		assert_gt(c.max_hp, 0, "%s has positive Max HP" % c.entity_name)
		assert_gt(c.atk, 0, "%s has positive ATK" % c.entity_name)
		assert_gt(c.spd, 0, "%s has positive SPD" % c.entity_name)

func test_character_passives():
	# Test Honami Harbor Immunity
	var honami = Honami.new()
	honami.is_harbor = true
	honami.max_hp = 200
	honami.current_hp = 200
	honami.take_damage(50, "physical")
	assert_eq(honami.current_hp, 200, "Honami takes 0 damage when is_harbor is active")
	
	honami.is_harbor = false
	honami.take_damage(50, "physical")
	assert_lt(honami.current_hp, 200, "Honami takes damage when is_harbor is false")

func test_enemy_classes():
	var enemies = [
		Guard.new(),
		Kidnapper.new(),
		Thug.new(),
		WarehouseWorker.new(),
		Terrorist.new(),
		Captain.new(),
		PrimeMinister.new(),
		TrainingBot.new()
	]
	
	for e in enemies:
		assert_false(e.is_character, "%s is flagged as enemy (!is_character)" % e.entity_name)
		assert_gt(e.max_hp, 0, "%s has positive Max HP" % e.entity_name)
		assert_gt(e.atk, 0, "%s has positive ATK" % e.entity_name)
		
	# Prime minister unique boss skills
	var pm = PrimeMinister.new()
	assert_true(pm.has_method("snipe_order"), "PrimeMinister has snipe_order skill")
	assert_true(pm.has_method("lock_power"), "PrimeMinister has lock_power skill")
