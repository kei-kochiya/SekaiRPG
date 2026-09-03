extends Node2D

func _ready():
	print("--- Running Mega-Update (Juice, Economy, HoloSim) Verification Tests ---")
	
	# Test 1: Critical Hit & Weakness Break
	var ichika = Ichika.new()
	var bot = TrainingBot.new()
	bot.max_break_gauge = 50
	bot.break_gauge = 50
	ichika.crit_rate = 1.0 # 100% crit for testing
	ichika.type = "Pure"
	bot.type = "Mysterious" # Pure is strong against Mysterious (1.25x)
	
	var res = DamageCalculator.calculate_damage_detailed(ichika, bot, 1.5)
	print("[Test 1.1] Damage detailed: dmg=", res["damage"], ", crit=", res["is_crit"], ", weakness=", res["is_weakness"], ", break=", res["is_break"])
	assert(res["is_crit"] == true, "Expected critical hit")
	assert(res["is_weakness"] == true, "Expected weakness hit")
	assert(res["is_break"] == true, "Expected break triggered on low gauge")
	
	# Test 2: Economy & Items
	var old_credits = GameManager.credits
	GameManager.add_credits(300)
	assert(GameManager.credits == old_credits + 300, "Expected credits added")
	var spent = GameManager.spend_credits(150)
	assert(spent == true, "Expected spend success")
	
	bot.current_hp = 20
	GameManager.add_item("potion", 2)
	var used = GameManager.use_item("potion", bot)
	assert(used == true, "Expected item use success")
	assert(bot.current_hp > 20, "Expected HP healed")
	print("[Test 2] Economy & Item use verified: Credits=", GameManager.credits, ", HP after heal=", bot.current_hp)
	
	# Test 3: Holo-Sim Roguelite State
	HoloSimManager.start_new_run()
	assert(HoloSimManager.is_sim_active == true, "Expected sim active")
	assert(HoloSimManager.current_floor == 1, "Expected floor 1")
	
	HoloSimManager.add_blessing("blessing_bleed")
	assert(HoloSimManager.has_blessing("blessing_bleed") == true, "Expected blessing active")
	
	var floor_info = HoloSimManager.get_floor_info(1)
	assert(floor_info["enemies"].size() > 0, "Expected floor enemies")
	
	var battle_data = BattleInitializer.setup_battle(null)
	assert(battle_data["enemy_team"].size() > 0, "Expected enemy team created")
	assert(battle_data["scenario"] is HoloSimScenario, "Expected HoloSimScenario")
	print("[Test 3] HoloSim battle setup verified: Floor=", HoloSimManager.current_floor, ", Enemies=", battle_data["enemy_team"].size())
	
	HoloSimManager.is_sim_active = false
	print("--- ALL MEGA-UPDATE TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
