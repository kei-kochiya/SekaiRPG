extends Node
class_name BattleInitializer

"""
Tóm tắt: BattleInitializer khởi tạo dữ liệu và đội hình cho các trận đấu.

Chức năng chính:
- Load dữ liệu trận đấu (Mission Battles) từ tệp JSON.
- Xây dựng đội hình phe ta và phe địch dựa trên tiến trình cốt truyện, map hiện tại hoặc chế độ Sandbox/Training.
- Tự động scale level của kẻ địch cho phù hợp (`_setup_mission_battle`, `_setup_training_battle`).
- Chọn kịch bản (Scenario) đặc biệt cho các trận đấu cốt truyện quan trọng.
"""

# ── Cấu Hình & Biến ────────────────────────────────────────────────────────


# Ánh xạ ID kẻ địch sang các Class tương ứng
static var enemy_classes = {
	"kidnapper": Kidnapper,
	"thug": Thug,
	"guard": Guard,
	"harbor_boss": Captain,
	"target": TrainingBot,
	"warehouse_worker": WarehouseWorker,
	"terrorist": Terrorist,
	"prime_minister": PrimeMinister
}

static var mission_battles: Dictionary = {}

# ── Dữ Liệu Tệp ────────────────────────────────────────────────────────────

static func _ensure_data_loaded():
	"""
	Đảm bảo các tệp cấu hình trận đấu được tải vào bộ nhớ.
	"""
	if mission_battles.is_empty():
		mission_battles = _load_json("res://Data/battles/mission_battles.json")

static func _load_json(path: String) -> Dictionary:
	"""
	Tải và giải mã tệp JSON.
	"""
	if not FileAccess.file_exists(path):
		print("[BattleInitializer] Lỗi: Không tìm thấy tệp JSON tại ", path)
		return {}
		
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {}

# ── Khởi Tạo Trận Đấu ──────────────────────────────────────────────────────

static func setup_battle(_main: Node) -> Dictionary:
	"""
	Thiết lập toàn bộ thông tin cho một trận đấu mới (Đội hình & Kịch bản).
	
	Args:
		_main (Node): Tham chiếu tới Scene trận đấu.
	Returns: 
		Dictionary: Chứa 'player_team', 'enemy_team', 'scenario'.
	"""
	_ensure_data_loaded()
	
	if GameManager.is_sandbox:
		return {
			"player_team": GameManager.sandbox_player_team,
			"enemy_team": GameManager.sandbox_enemy_team,
			"scenario": DefaultScenario.new()
		}
	
	if GameManager.is_training_mode:
		return _setup_training_battle()
		
	if GameManager.is_scripted_battle:
		return _setup_scripted_battle(GameManager.scripted_battle_id)
	
	var current_map = GameManager.current_map_file
	var battle_key = ""
	
	if current_map == "res://Maps/Harbor/HarborMap.tscn":
		if GameManager.harbor_route == "boss" or GameManager.harbor_wave > 3:
			battle_key = "harbor_boss"
		else:
			battle_key = "harbor_guards"
	elif current_map == "res://Maps/Warehouse/WarehouseMap.tscn":
		battle_key = "warehouse"
	elif GameManager.prologue_phase == 0:
		battle_key = "prologue"
	
	if mission_battles.has(battle_key):
		return _setup_mission_battle(mission_battles[battle_key], battle_key)
	
	print("[BattleInitializer] Cảnh báo: Không tìm thấy cấu hình trận đấu cho bản đồ ", current_map)
	return {"player_team": [], "enemy_team": [], "scenario": DefaultScenario.new()}

# ── Logic Thiết Lập Đội Hình ───────────────────────────────────────────────

static func _setup_mission_battle(cfg: Dictionary, battle_key: String = "") -> Dictionary:
	"""
	Khởi tạo trận đấu dựa trên cấu hình nhiệm vụ.
	"""
	var p_team = []
	for p_name in cfg.get("player_party", []):
		var p = GameManager.get_party_member(p_name)
		if p: p_team.append(p)
	
	var lv = cfg.get("level_val", 1)
	if cfg.has("level_key"):
		var key = cfg["level_key"]
		if key == "warehouse_wave": lv = clamp(GameManager.warehouse_wave * 3, 3, 15)
		elif key == "harbor_guards": lv = 5 + GameManager.harbor_wave
	
	var e_type = cfg.get("enemy_type", "")
	var count = cfg.get("enemy_count", 1)
	var enemies = _create_enemies(e_type, count, lv)
	
	for p in p_team:
		var min_hp = int(p.max_hp * 0.5)
		if p.current_hp < min_hp: p.current_hp = min_hp

	var scenario = DefaultScenario.new()
	if battle_key == "harbor_boss":
		scenario = HarborBossScenario.new()
	elif battle_key == "prologue":
		scenario = PrologueScenario.new()

	return {
		"player_team": p_team,
		"enemy_team": enemies,
		"scenario": scenario
	}

static func _create_enemies(type_id: String, count: int, lv: int) -> Array:
	"""
	Tạo danh sách kẻ địch bằng cách khởi tạo các Class tương ứng.
	"""
	var team = []
	var enemy_class = enemy_classes.get(type_id)
	
	if enemy_class == null:
		print("[BattleInitializer] Lỗi: Không tìm thấy Class cho loại kẻ địch: ", type_id)
		return []
	
	for i in range(count):
		var e = enemy_class.new()
		if count > 1: e.entity_name += " " + str(i + 1)
		
		LevelManager.set_initial_level(e, lv)
		team.append(e)
	return team

static var character_classes = {
	"Ichika": Ichika,
	"Kanade": Kanade,
	"Mafuyu": Mafuyu,
	"Ena": Ena,
	"Mizuki": Mizuki,
	"Honami": Honami
}

static func _setup_training_battle() -> Dictionary:
	"""
	Thiết lập trận đấu luyện tập.
	Dùng bản sao (clone) của party member để HP không bị ảnh hưởng sau training.
	"""
	var player_team = []
	var total_lv = 0
	var p_count = 0
	
	for p_name in GameManager.training_participants:
		var real_p = GameManager.get_party_member(p_name)
		if real_p:
			# Tạo bản sao (fresh instance) cùng class, cùng level — HP luôn đầy
			var clone_class = character_classes.get(p_name)
			if clone_class:
				var clone = clone_class.new()
				LevelManager.set_initial_level(clone, real_p.level)
				player_team.append(clone)
				total_lv += real_p.level
				p_count += 1
	
	var mean_lv = int(float(total_lv) / max(p_count, 1))
	var target_lv = clamp(mean_lv + randi_range(-3, 3), 1, 100)
	
	var enemies = []
	
	# Random chance to fight party members
	if randf() < 0.7:
		var pool = ["Mafuyu", "Ena", "Mizuki", "Kanade", "Ichika", "Honami"]
		var candidates = []
		for p_name in pool:
			if p_name not in GameManager.training_participants and p_name not in GameManager.training_used_opponents:
				candidates.append(p_name)
		candidates.shuffle()
		
		if not candidates.is_empty():
			var e_name = candidates.pop_back()
			GameManager.training_used_opponents.append(e_name)
			
			# Luôn dùng fresh instance cho đối thủ
			var enemy_class = character_classes.get(e_name)
			if enemy_class:
				var enemy = enemy_class.new()
				LevelManager.set_initial_level(enemy, target_lv)
				enemies.append(enemy)
	
	if enemies.is_empty():
		enemies = _create_enemies("target", 5, target_lv)
		for e in enemies: e.entity_name = "Training Bot " + e.entity_name.split(" ")[1]

	GameManager.last_battle_max_lv = target_lv
	
	return {"player_team": player_team, "enemy_team": enemies, "scenario": DefaultScenario.new()}

static func _setup_scripted_battle(battle_id: String) -> Dictionary:
	"""
	Khởi tạo các trận đấu theo kịch bản cốt truyện.
	"""
	var registry = {
		"mizuki_vs_mafuyu": func():
			var mizuki = GameManager.get_party_member("Mizuki")
			var mafuyu = Mafuyu.new()
			mafuyu.entity_name = "Mafuyu (BOSS)"
			LevelManager.set_initial_level(mafuyu, 100)
			return {
				"player_team": [mizuki],
				"enemy_team": [mafuyu],
				"scenario": ScriptedBattleScenario.new()
			},
		"ena_vs_mizuki": func():
			return {
				"player_team": [GameManager.get_party_member("Ena")],
				"enemy_team": [GameManager.get_party_member("Mizuki")],
				"scenario": ScriptedBattleScenario.new()
			},
		"ena_vs_thugs": func():
			return {
				"player_team": [GameManager.get_party_member("Ena")],
				"enemy_team": _create_enemies("thug", 3, 25),
				"scenario": ScriptedBattleScenario.new()
			},
		"harbor_boss": func():
			var boss = Captain.new()
			LevelManager.set_initial_level(boss, 25)
			return {
				"player_team": [GameManager.get_party_member("Ichika"), GameManager.get_party_member("Ena")],
				"enemy_team": [boss],
				"scenario": HarborBossScenario.new()
			},
		"prologue": func():
			var kidnappers = _create_enemies("kidnapper", 3, 1)
			return {
				"player_team": [GameManager.get_party_member("Ichika")],
				"enemy_team": kidnappers,
				"scenario": PrologueScenario.new()
			},
		"ops_kanade": func():
			return {
				"player_team": [GameManager.get_party_member("Kanade")],
				"enemy_team": _create_enemies("terrorist", 2, 35),
				"scenario": ScriptedBattleScenario.new()
			},
		"ops_ichika": func():
			return {
				"player_team": [GameManager.get_party_member("Ichika")],
				"enemy_team": _create_enemies("terrorist", 2, 35),
				"scenario": ScriptedBattleScenario.new()
			},
		"ops_honami": func():
			return {
				"player_team": [GameManager.get_party_member("Honami")],
				"enemy_team": _create_enemies("terrorist", 3, 35),
				"scenario": ScriptedBattleScenario.new()
			},
		"pm_boss": func():
			var pm = PrimeMinister.new()
			LevelManager.set_initial_level(pm, 50)
			return {
				"player_team": [GameManager.get_party_member("Mafuyu"), GameManager.get_party_member("Ena"), GameManager.get_party_member("Mizuki")],
				"enemy_team": [pm],
				"scenario": PrimeMinisterBossScenario.new()
			},
		"street_skirmish": func():
			return {
				"player_team": [GameManager.get_party_member("Ichika"), GameManager.get_party_member("Mizuki")],
				"enemy_team": _create_enemies("terrorist", 3, 25),
				"scenario": DefaultScenario.new()
			},
		"street_survival": func():
			return {
				"player_team": [GameManager.get_party_member("Ichika"), GameManager.get_party_member("Mizuki")],
				"enemy_team": _create_enemies("terrorist", 3, 25),
				"scenario": StreetSurvivalScenario.new()
			}
	}
	
	if registry.has(battle_id):
		return registry[battle_id].call()
	
	return {"player_team": [], "enemy_team": [], "scenario": DefaultScenario.new()}
