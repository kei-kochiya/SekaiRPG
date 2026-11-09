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
	"prime_minister": PrimeMinister,
	"recon_drone": ReconDrone,
	"sniper": Sniper,
	"cyborg_enforcer": CyborgEnforcer,
	"cyber_jammer": CyberJammer,
	"police": PoliceOfficer
}

# Mafuyu ở trận cuối phản chiếu chỉ số người chơi đã dồn vào Mafuyu đồng đội; không bao giờ yếu hơn bản cấp này.
# Đây là các "núm vặn" độ khó: tăng HP boss, giảm tốc độ để Ichika/Honami còn lượt hành động giữa hai đòn của cô ta.
const FINAL_BOSS_FLOOR_LEVEL = 25
const FINAL_BOSS_MIRROR = {"max_hp": 1.3, "atk": 1.0, "defense": 1.0, "res": 1.0, "spd": 0.85}

# Các trận mới của cốt truyện (đưa từ truyện vào): cố ý đặt khó, hằng số dưới đây là núm vặn để chỉnh.
# - Bài kiểm tra Khóa huấn luyện: Ena/Kanade đối thủ là bản sao đồng đội (kể cả điểm nâng cấp) nhân hệ số này.
const TRAINING_TRIAL_MIRROR = {"max_hp": 1.0, "atk": 0.72, "defense": 1.0, "res": 1.0, "spd": 0.8}
# - Ena hộ tống đoàn xe: cấp của đợt khủng bố đầu (đợt hai +ConvoyWavesScenario.WAVE_TWO_LEVEL_BONUS).
const OPS_ENA_LEVEL = 22
const OPS_ENA_COUNT = ConvoyWavesScenario.WAVE_SIZE

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
		GameLogger.error("BattleInitializer", "Không tìm thấy tệp JSON tại %s" % path)
		return {}
		
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {}

# ── Khởi Tạo Trận Đấu ──────────────────────────────────────────────────────

static func setup_battle() -> Dictionary:
	"""
	Thiết lập toàn bộ thông tin cho một trận đấu mới (Đội hình & Kịch bản).

	Returns:
		Dictionary: Chứa 'player_team', 'enemy_team', 'scenario'.
	"""
	var data := _build_battle()
	# Sandbox và luyện tập dùng bản sao mới nên không cần; còn lại là đội hình bền vững, có thể còn nằm ở 0 HP từ trận trước
	if not GameManager.is_sandbox and not GameManager.is_training_mode:
		_revive_downed(data["player_team"])
	return data

# Thành viên gục sau một trận thắng vẫn nằm ở 0 HP ngoài bản đồ (chỉ thua/luyện tập xong mới hồi máu). Trận cốt truyện
# nào cũng đưa họ về 50% HP lúc vào trận, để không có trận nào bắt đầu bằng một đội đã gục (thua ngay lượt 0).
static func _revive_downed(team: Array) -> void:
	for p in team:
		if p != null and p.current_hp <= 0:
			p.current_hp = maxi(1, int(p.max_hp * 0.5))

static func _build_battle() -> Dictionary:
	_ensure_data_loaded()
	
	if HoloSimManager and HoloSimManager.is_sim_active:
		return _setup_holosim_battle()

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
	
	# Trận Boss Bến Cảng và trận mở màn luôn là trận kịch bản (đăng ký ở _setup_scripted_battle): ở đây chỉ còn lính gác và Nhà kho
	if current_map == MapPaths.HARBOR:
		battle_key = "harbor_guards"
	elif current_map == MapPaths.WAREHOUSE:
		battle_key = "warehouse"
	
	if mission_battles.has(battle_key):
		return _setup_mission_battle(mission_battles[battle_key])
	
	print("[BattleInitializer] Cảnh báo: Không tìm thấy cấu hình trận đấu cho bản đồ ", current_map)
	return {"player_team": [], "enemy_team": [], "scenario": DefaultScenario.new()}

# ── Logic Thiết Lập Đội Hình ───────────────────────────────────────────────

static func _setup_mission_battle(cfg: Dictionary) -> Dictionary:
	"""
	Khởi tạo trận đấu dựa trên cấu hình nhiệm vụ.
	"""
	var p_team = []
	for p_name in cfg.get("player_party", []):
		var p = GameManager.get_party_member(p_name)
		if p: p_team.append(p)
	
	var lv := 1
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

	return {
		"player_team": p_team,
		"enemy_team": enemies,
		"scenario": DefaultScenario.new()
	}

# Đặt tên riêng cho các kẻ địch trong trận kịch bản (thẻ chiến đấu hiện tên thay vì tên loại quái).
static func _named(enemies: Array, names: Array) -> Array:
	for i in range(mini(enemies.size(), names.size())):
		enemies[i].entity_name = names[i]
	return enemies

# Dựng một kẻ địch theo id loại (xem enemy_classes) ở cấp `lv`; `p_name` (nếu có) thay tên mặc định của loại đó.
static func create_enemy(type_id: String, lv: int, p_name: String = "") -> Entity:
	var enemy_class = enemy_classes.get(type_id)
	if enemy_class == null:
		GameLogger.error("BattleInitializer", "Không tìm thấy Class cho loại kẻ địch: %s" % type_id)
		return null
	var e: Entity = enemy_class.new()
	if p_name != "":
		e.entity_name = p_name
	LevelManager.set_initial_level(e, lv)
	return e

static func _create_enemies(type_id: String, count: int, lv: int) -> Array:
	"""
	Tạo danh sách kẻ địch cùng loại; nhiều hơn một thì đánh số sau tên ("Khủng Bố 1", "Khủng Bố 2"...).
	"""
	var team = []
	for i in range(count):
		var e := create_enemy(type_id, lv)
		if e == null:
			return []
		if count > 1:
			e.entity_name += " " + str(i + 1)
		team.append(e)
	return team


# Bản sao luyện tập chỉ dựng lại chỉ số theo cấp; chép thêm điểm kỹ năng đã nâng để bản sao mạnh bằng nhân vật thật.
static func _mirror_upgrades(clone: Entity, source: Entity) -> void:
	clone.max_hp = source.max_hp
	clone.atk = source.atk
	clone.defense = source.defense
	clone.res = source.res
	clone.spd = source.spd
	clone.crit_rate = source.crit_rate
	clone.crit_dmg = source.crit_dmg
	clone.current_hp = clone.max_hp

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
			var clone_class = EntityFactory.CHARACTERS.get(p_name)
			if clone_class:
				var clone = clone_class.new()
				LevelManager.set_initial_level(clone, real_p.level)
				_mirror_upgrades(clone, real_p)
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
			var gone = not GameManager.is_member_alive_in_story(p_name) # đã chết trong cốt truyện
			if p_name not in GameManager.training_participants and p_name not in GameManager.training_used_opponents and not gone:
				candidates.append(p_name)
		candidates.shuffle()
		
		if not candidates.is_empty():
			var e_name = candidates.pop_back()
			GameManager.training_used_opponents.append(e_name)
			
			# Luôn dùng fresh instance cho đối thủ
			var enemy_class = EntityFactory.CHARACTERS.get(e_name)
			if enemy_class:
				var enemy = enemy_class.new()
				LevelManager.set_initial_level(enemy, target_lv)
				enemies.append(enemy)
	
	if enemies.is_empty():
		enemies = _create_enemies("target", 5, target_lv) # "Robot Huấn Luyện 1..5"

	GameManager.last_battle_max_lv = target_lv
	
	return {"player_team": player_team, "enemy_team": enemies, "scenario": DefaultScenario.new()}

# Bản sao của một thành viên (cùng cấp, chép cả điểm nâng cấp) để làm đối thủ trong trận kịch bản.
# `factors` nhân thêm lên từng chỉ số (độ khó); thiếu thành viên thật thì dựng bản cấp 25.
static func _mirror_party_member(p_name: String, factors: Dictionary = {}) -> Entity:
	var clone: Entity = EntityFactory.CHARACTERS[p_name].new()
	var source: Entity = GameManager.get_party_member(p_name)
	LevelManager.set_initial_level(clone, source.level if source else 25)
	if source:
		_mirror_upgrades(clone, source)
	for stat in factors:
		clone.set(stat, int(clone.get(stat) * factors[stat]))
	clone.current_hp = clone.max_hp
	return clone

static func build_final_mafuyu() -> Entity:
	"""
	Mafuyu ở trận cuối: sao chép chỉ số (kể cả mọi điểm nâng cấp) của Mafuyu đồng đội nhân hệ số FINAL_BOSS_MIRROR.
	Nâng cấp cho Mafuyu suốt game cuối cùng sẽ quay lại cắn chính người chơi; luyện tập Ichika/Honami thì không giới hạn.
	"""
	var boss = Mafuyu.new()
	boss.entity_name = "Mafuyu"
	var floor_ref = Mafuyu.new()
	LevelManager.set_initial_level(floor_ref, FINAL_BOSS_FLOOR_LEVEL)
	var ally = GameManager.get_party_member("Mafuyu")
	
	boss.level = maxi(floor_ref.level, ally.level if ally else 1)
	for stat in FINAL_BOSS_MIRROR:
		# Lấy chỉ số cao hơn giữa bản sàn và Mafuyu đồng đội (đã nâng cấp), rồi mới áp hệ số độ khó
		var base_value = maxi(floor_ref.get(stat), ally.get(stat) if ally else 0)
		boss.set(stat, int(base_value * FINAL_BOSS_MIRROR[stat]))
	if ally:
		boss.crit_rate = maxf(boss.crit_rate, ally.crit_rate)
		boss.crit_dmg = maxf(boss.crit_dmg, ally.crit_dmg)
	boss.current_hp = boss.max_hp
	floor_ref.free()
	return boss

static func _party(names: Array) -> Array:
	"""Các thành viên thật (bền vững) theo tên; thiếu ai thì chỗ đó là null và Main.gd sẽ lọc bỏ."""
	return names.map(func(n): return GameManager.get_party_member(n))

static func _battle(party_names: Array, enemies: Array, scenario: BattleScenario) -> Dictionary:
	return {"player_team": _party(party_names), "enemy_team": enemies, "scenario": scenario}

# Kẻ địch là nhân vật chính (cùng class với thành viên), dựng mới ở cấp cho trước
static func _character_enemy(char_name: String, lv: int) -> Entity:
	var e: Entity = EntityFactory.CHARACTERS[char_name].new()
	LevelManager.set_initial_level(e, lv)
	return e

# Cấp của thành viên thật, hoặc `fallback` nếu thiếu (dùng cho các bản sao đối đầu đồng đội)
static func _party_level(char_name: String, fallback: int) -> int:
	var member: Entity = GameManager.get_party_member(char_name)
	return member.level if member else fallback

# Bảng id -> hàm dựng của mọi trận kịch bản (tách ra để test liệt kê được các id và kiểm tra nơi gọi dùng đúng id)
static func _scripted_registry() -> Dictionary:
	return {
		"mizuki_vs_mafuyu": func():
			var mafuyu := _character_enemy("Mafuyu", 100)
			mafuyu.entity_name = "Mafuyu (BOSS)"
			return _battle(["Mizuki"], [mafuyu], ScriptedBattleScenario.new()),
		"ena_vs_mizuki": func():
			return _battle(["Ena"], [_character_enemy("Mizuki", _party_level("Mizuki", 25))], ScriptedBattleScenario.new()),
		"ena_vs_thugs": func():
			return _battle(["Ena"], _create_enemies("thug", 3, 25), ScriptedBattleScenario.new()),
		"harbor_boss": func():
			return _battle(["Ichika", "Ena"], [create_enemy("harbor_boss", 25)], HarborBossScenario.new()),
		"prologue": func():
			return _battle(["Ichika"], _create_enemies("kidnapper", 3, 1), PrologueScenario.new()),
		"ops_kanade": func():
			return _battle(["Kanade"], _create_enemies("terrorist", 2, 35), ScriptedBattleScenario.new()),
		"ops_ichika": func():
			return _battle(["Ichika"], _create_enemies("terrorist", 2, 35), ScriptedBattleScenario.new()),
		"ops_honami": func():
			return _battle(["Honami"], _create_enemies("terrorist", 3, 35), ScriptedBattleScenario.new()),
		"pm_boss": func():
			return _battle(["Mafuyu", "Ena", "Mizuki"], [create_enemy("prime_minister", 50)], PrimeMinisterBossScenario.new()),
		"bounty_1": func():
			# Chủ nợ chợ cá và tay chân của hắn
			return _battle(["Ena"], _named(_create_enemies("warehouse_worker", 2, 22), ["Chủ Nợ", "Tay Chân"]), ScriptedBattleScenario.new()),
		"bounty_2": func():
			# Họa sĩ làm tranh giả và bảo vệ xưởng
			return _battle(["Ena"], _named(_create_enemies("terrorist", 2, 22), ["Họa Sĩ Giả", "Bảo Vệ Xưởng"]), ScriptedBattleScenario.new()),
		"bounty_3": func():
			# Chủ kho bến Đông: ngồi một mình, không vệ sĩ (đúng như lời thoại)
			return _battle(["Ena"], _named(_create_enemies("guard", 1, 27), ["Chủ Kho"]), ScriptedBattleScenario.new()),
		"bounty_ambush": func():
			return _battle(["Ena"], _create_enemies("police", 4, 27), ForcedLossScenario.new()),
		"mizuki_police_1": func():
			return _battle(["Mizuki"], _create_enemies("police", 2, 20), ScriptedBattleScenario.new()),
		"mizuki_police_2": func():
			return _battle(["Mizuki"], _create_enemies("police", 3, 22), ScriptedBattleScenario.new()),
		"mizuki_vs_ena_forced": func():
			var ena_enemy := _character_enemy("Ena", _party_level("Ena", 20))
			ena_enemy.current_hp = int(ena_enemy.max_hp * 0.4) # đã bị tra tấn nhiều ngày
			return _battle(["Mizuki"], [ena_enemy], ForcedDuelScenario.new()),
		"mizuki_vs_kanade": func():
			return _battle(["Mizuki", "Ichika"], [_character_enemy("Kanade", 100)], FrozenAllyScenario.new()),
		"ichika_vs_kanade_slow": func():
			return _battle(["Ichika"], [_character_enemy("Kanade", 60)], SlowStrikeScenario.new()),
		"final_mafuyu": func():
			return _battle(["Ichika", "Honami"], [build_final_mafuyu()], DefaultScenario.new()),
		"training_trial": func():
			# Khóa huấn luyện sinh tử, ngày thứ bảy: Ichika một mình trước Ena và Kanade
			return _battle(["Ichika"], [_mirror_party_member("Ena", TRAINING_TRIAL_MIRROR), _mirror_party_member("Kanade", TRAINING_TRIAL_MIRROR)], TrainingTrialScenario.new()),
		"ops_ena": func():
			# Tác chiến cầu vịnh Tokyo: Ena hộ tống đoàn xe chở bom, hai đợt khủng bố
			return _battle(["Ena"], _create_enemies("terrorist", OPS_ENA_COUNT, OPS_ENA_LEVEL), ConvoyWavesScenario.new()),
		"honami_spar": func():
			# Buổi thử phản xạ ở phòng khám: Honami chỉ đỡ đòn
			return _battle(["Ichika"], [_mirror_party_member("Honami")], SparringScenario.new()),
		"street_skirmish": func():
			return _battle(["Ichika", "Mizuki"], _create_enemies("terrorist", 3, 20), DefaultScenario.new()),
		"street_survival": func():
			return _battle(["Ichika", "Mizuki"], _create_enemies("terrorist", 3, 20), StreetSurvivalScenario.new()),
	}

static func scripted_battle_ids() -> Array:
	return _scripted_registry().keys()

static func _setup_scripted_battle(battle_id: String) -> Dictionary:
	"""
	Khởi tạo các trận đấu theo kịch bản cốt truyện.
	"""
	var registry := _scripted_registry()
	if registry.has(battle_id):
		return registry[battle_id].call()
	
	GameLogger.error("BattleInitializer", "Trận kịch bản không có trong bảng: %s" % battle_id)
	return {"player_team": [], "enemy_team": [], "scenario": DefaultScenario.new()}

static func _setup_holosim_battle() -> Dictionary:
	"""Thiết lập đội hình và quái vật cho từng tầng trong chế độ Mô Phỏng Holo-Sim."""
	var info = HoloSimManager.get_floor_info(HoloSimManager.current_floor)
	var p_team = []
	for p_name in ["Ichika", "Kanade", "Mafuyu"]:
		var p = GameManager.get_party_member(p_name)
		if p: p_team.append(p)
		
	HoloSimManager.apply_blessings_to_team(p_team)
	# Còn sống thì vào tầng với ít nhất 30% máu (làm ở đây, trước khi dựng HUD, để thẻ nhân vật hiện đúng số máu)
	for p in p_team:
		if p.current_hp > 0:
			p.current_hp = maxi(p.current_hp, int(p.max_hp * 0.3))
	
	var e_team = []
	var enemies = info.get("enemies", ["Lính Cảng"])
	var levels = info.get("enemy_levels", [10])
	for i in range(enemies.size()):
		var e_type = enemies[i]
		var e_lv = levels[i] if i < levels.size() else 10
		var inst: Entity = EntityFactory.create(e_type)
		if inst == null:
			inst = Guard.new() # tên lạ trong bảng tầng: dùng lính gác mặc định
		LevelManager.set_initial_level(inst, e_lv)
		e_team.append(inst)
		
	var scenario = HoloSimScenario.new()
	return {
		"player_team": p_team,
		"enemy_team": e_team,
		"scenario": scenario
	}
