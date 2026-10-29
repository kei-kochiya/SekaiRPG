extends "res://Tests/Unit/BaseTest.gd"


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
		TrainingBot.new(),
		ReconDrone.new(),
		Sniper.new(),
		CyborgEnforcer.new(),
		CyberJammer.new()
	]
	
	var valid_elements = ["Cool", "Happy", "Cute", "Mysterious", "Pure"]
	
	for e in enemies:
		assert_false(e.is_character, "%s is flagged as enemy (!is_character)" % e.entity_name)
		assert_gt(e.max_hp, 0, "%s has positive Max HP" % e.entity_name)
		assert_gt(e.atk, 0, "%s has positive ATK" % e.entity_name)
		assert_ne(e.type, "None", "%s must have a defined element type" % e.entity_name)
		assert_true(valid_elements.has(e.type), "%s has valid element (%s)" % [e.entity_name, e.type])
		assert_gt(e.max_break_gauge, 0, "%s has positive Break Gauge" % e.entity_name)
		
	# Special enemy skills
	var pm = PrimeMinister.new()
	assert_true(pm.has_method("snipe_order"), "PrimeMinister has snipe_order skill")
	assert_true(pm.has_method("lock_power"), "PrimeMinister has lock_power skill")
	
	var drone = ReconDrone.new()
	assert_true(drone.has_method("emp_shock"), "ReconDrone has emp_shock skill")
	assert_true(drone.has_method("scan_weakness"), "ReconDrone has scan_weakness skill")
	
	var sniper = Sniper.new()
	assert_true(sniper.has_method("headshot"), "Sniper has headshot skill")
	assert_true(sniper.has_method("smoke_screen"), "Sniper has smoke_screen skill")
	
	var cyborg = CyborgEnforcer.new()
	assert_true(cyborg.has_method("shield_slam"), "CyborgEnforcer has shield_slam skill")
	assert_true(cyborg.has_method("barrier_boost"), "CyborgEnforcer has barrier_boost skill")
	
	var jammer = CyberJammer.new()
	assert_true(jammer.has_method("system_hack"), "CyberJammer has system_hack skill")
	assert_true(jammer.has_method("overclock_ally"), "CyberJammer has overclock_ally skill")

func test_enemy_skills_apply_no_ghost_statuses():
	# Slow/Buff từng được gắn nhưng không có hiệu lực; chỉ còn Bleed, Poison, Stun là hiệu ứng thật.
	var ichika = Ichika.new()
	var worker = WarehouseWorker.new()
	worker.enemies = [ichika]
	for i in range(30):
		worker.throw_box(ichika)
	assert_eq(ichika.active_statuses.size(), 0, "Ném Thùng Hàng chỉ gây sát thương")
	
	var drone = ReconDrone.new()
	var base_def = ichika.defense
	drone.scan_weakness(ichika)
	assert_eq(ichika.active_statuses.size(), 0, "Quét Điểm Yếu không gắn trạng thái ảo")
	assert_eq(ichika.defense, base_def - 25, "Quét Điểm Yếu vẫn giảm 25 DEF")
	ichika.clear_temp_mods()
	assert_eq(ichika.defense, base_def, "DEF được hoàn trả sau trận")
	
	for status_name in UITheme.STATUS_INFO:
		assert_true(status_name in ["Bleed", "Poison", "Stun"], "Chỉ còn hiệu ứng có thật: " + status_name)
