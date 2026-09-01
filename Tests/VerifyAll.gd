extends Node

const QuestRegistryClass = preload("res://Quests/QuestRegistry.gd")

func _ready():
	print("--- Running Antigravity Verification Tests ---")
	
	# Test 1: QuestRegistry
	var quests = QuestRegistryClass.get_all_quests()
	print("[Test 1] Quests loaded: ", quests.size())
	assert(quests.size() == 10, "Expected 10 quests loaded")
	for q in quests:
		print("  - ", q.quest_id, ": ", q.quest_name, " (Arc: ", q.arc_name, ")")
		assert(ResourceLoader.exists(q.linked_map_scene), "Linked map scene must exist: " + q.linked_map_scene)
	
	# Test 2: Quest Progression Detection
	GameManager.story.reset()
	var current_q = QuestRegistryClass.get_current_quest()
	print("[Test 2] Initial Quest: ", current_q.quest_id)
	assert(current_q.quest_id == "quest_01_prologue", "Initial quest should be prologue")
	
	GameManager.story.set_flag("prologue_phase", 1)
	current_q = QuestRegistryClass.get_current_quest()
	print("[Test 2.1] Post Prologue Quest: ", current_q.quest_id)
	assert(current_q.quest_id == "quest_02_safehouse_intro", "Expected safehouse intro quest")
	
	# Test 3: ProcessStatus DoT Dead Entity Check
	var test_ent = Ichika.new()
	test_ent.current_hp = 1
	test_ent.add_status({"type": "Bleed", "duration": 2})
	var can_act = ProcessStatus.handle_turn_start(test_ent)
	print("[Test 3] ProcessStatus Bleed death check: HP=", test_ent.current_hp, ", can_act=", can_act)
	assert(test_ent.current_hp <= 0, "Entity should be dead from Bleed")
	assert(can_act == false, "Dead entity should not be able to act")
	
	# Test 4: AIManager Target Check
	var honami = Honami.new()
	var bot1 = TrainingBot.new()
	var bot2 = TrainingBot.new()
	var timeline = [{"entity": bot1, "tick": 10}, {"entity": honami, "tick": 12}]
	var decision = AIManager.pick_action(honami, [bot1, bot2], [honami], timeline)
	print("[Test 4] AIManager decision: ", decision["action"], " target: ", decision["target"].entity_name)
	
	# Test 5: Prime Minister Skills
	var pm = PrimeMinister.new()
	pm.enemies = [bot1, bot2]
	pm.snipe_order()
	pm.lock_power()
	print("[Test 5] Prime Minister skills executed successfully")
	
	print("--- ALL VERIFICATION TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
