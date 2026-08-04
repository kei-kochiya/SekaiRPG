extends Node

"""
Tóm tắt: GameManager là bộ não trung tâm (Autoload) quản lý toàn bộ vòng đời của trò chơi.

Chức năng chính:
- Lưu trữ và cung cấp đối tượng đội hình (Party).
- Quản lý bộ đệm trạng thái cốt truyện thông qua StoryState (cờ sự kiện, tiến độ map).
- Xử lý hệ thống lưu và tải game (Save/Load) qua JSON.
- Điều phối các chế độ chơi đặc biệt: Sandbox, Training, Scripted Battle.
- Xử lý luồng sau khi trận chiến kết thúc (tính exp, kích hoạt sự kiện, chuyển cảnh).
- Quản lý tùy chọn cài đặt hệ thống (Volume, Battle Speed, Skip Battle).
- Cung cấp các hàm hỗ trợ chung (filter, entity factory).
"""

# ── Tham chiếu đến các Manager thành phần ──────────────────────────────────
var story: StoryState = StoryState.new()

# ── Biến Quản Lý Trạng Thái ────────────────────────────────────────────────

var current_map_file: String = "res://Maps/Prologue/PrologueMap.tscn"
var last_player_position: Vector2 = Vector2.ZERO

var is_training_mode: bool = false
var training_participants: Array = []
var training_used_opponents: Array = []
var last_battle_max_lv: int = 1

var is_in_dialogue: bool = false
var is_tutorial: bool = false
var is_sandbox: bool = false
var is_scripted_battle: bool = false
var scripted_battle_id: String = ""
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []

var available_sandbox_chars = ["Ichika", "Kanade", "Mafuyu", "Ena", "Mizuki", "Honami"]
var available_sandbox_monsters = ["Lính Cảng", "Kidnapper", "Target", "Nhân Viên Kho", "Đội Trưởng (BOSS)"]

var battle_speed: float = 1.2
var master_volume: float = 1.0:
	set(v):
		master_volume = clamp(v, 0.0, 1.0)
		if AudioManager: AudioManager.update_volume(master_volume)

var skip_battle_unlocked: bool = false
var skip_battle_enabled: bool = false

# ── Đội Hình (Party) ───────────────────────────────────────────────────────
var party: Dictionary = {}

# Khởi tạo đội hình
func _ready():
	_init_party()

func _init_party():
	"""
	Khởi tạo các đối tượng nhân vật chính và cấp độ ban đầu cho đội hình.
	
	Args: Không có
	Returns: Không có
	"""
	party["Ichika"] = Ichika.new()
	party["Kanade"] = Kanade.new()
	party["Mafuyu"] = Mafuyu.new()
	party["Ena"] = Ena.new()
	party["Mizuki"] = Mizuki.new()
	party["Honami"] = Honami.new()
	
	LevelManager.set_initial_level(party["Ichika"], 1)
	LevelManager.set_initial_level(party["Kanade"], 5)
	LevelManager.set_initial_level(party["Mafuyu"], 25)
	LevelManager.set_initial_level(party["Ena"], 20)
	LevelManager.set_initial_level(party["Mizuki"], 25)
	LevelManager.set_initial_level(party["Honami"], 25)

# ── Hàm Hỗ Trợ Dữ Liệu (Engine/Filter) ─────────────────────────────────────
func get_skill_target_type(entity: Entity, action_name: String) -> String:
	if action_name == "attack": return "enemy"
	for s in entity.skills:
		if s["method"] == action_name:
			return s.get("target", "enemy")
	return "enemy"

func get_alive_targets(team: Array) -> Array:
	var alive_units = []
	for unit in team:
		if unit.current_hp > 0:
			alive_units.append(unit)
	return alive_units

func create_sandbox_entity(e_name: String) -> Entity:
	match e_name:
		"Ichika": return Ichika.new()
		"Kanade": return Kanade.new()
		"Mafuyu": return Mafuyu.new()
		"Ena": return Ena.new()
		"Mizuki": return Mizuki.new()
		"Honami": return Honami.new()
		"Lính Cảng":
			var g = Entity.new()
			g.entity_name = "Lính Cảng"
			g.max_hp = 250; g.current_hp = 250; g.atk = 75; g.defense = 40; g.spd = 95; g.type = "Hard"
			return g
		"Kidnapper":
			var k = Entity.new()
			k.entity_name = "Kidnapper"
			k.max_hp = 80; k.current_hp = 80; k.atk = 40; k.defense = 20; k.spd = 80; k.type = "None"
			k.skills = [{"name": "Shank", "method": "basic_attack", "cooldown_turns": 1}]
			return k
		"Target":
			var t = Entity.new()
			t.entity_name = "Target"
			t.max_hp = 100; t.current_hp = 100; t.atk = 45; t.defense = 25; t.spd = 90; t.type = "None"
			return t
		"Nhân Viên Kho":
			var w = WarehouseWorker.new()
			return w
		"Đội Trưởng (BOSS)":
			var b = Entity.new()
			b.entity_name = "Đội Trưởng"
			b.max_hp = 3500; b.current_hp = 3500; b.atk = 240; b.defense = 130; b.spd = 110; b.type = "Hard"
			b.skills = [{"name": "Execution", "method": "basic_attack", "cooldown_turns": 1}]
			return b
	return Entity.new()

# ── Kết nối StoryState (Flags & Variables) ─────────────────────────────────
var flags: Dictionary:
	get: return story.flags
var warehouse_wave: int:
	get: return story.warehouse_wave
	set(v): story.warehouse_wave = v
var harbor_wave: int:
	get: return story.harbor_wave
	set(v): story.harbor_wave = v
var enemies_defeated: int:
	get: return story.enemies_defeated
	set(v): story.enemies_defeated = v
var harbor_guards_defeated: int:
	get: return story.harbor_guards_defeated
	set(v): story.harbor_guards_defeated = v
var harbor_route: String:
	get: return story.harbor_route
	set(v): story.harbor_route = v

# Thiết lập một cờ trạng thái
func set_flag(id: String, value: Variant):
	story.set_flag(id, value)

# Lấy giá trị của một cờ trạng thái
func get_flag(id: String, default: Variant = false) -> Variant:
	return story.get_flag(id, default)

var prologue_phase: int:
	get: return story.get_flag("prologue_phase", 0)
	set(v): story.set_flag("prologue_phase", v)
var harbor_mission_done: bool:
	get: return story.get_flag("harbor_mission_done", false)
	set(v): story.set_flag("harbor_mission_done", v)
var harbor_mission_unlocked: bool:
	get: return story.get_flag("harbor_mission_unlocked", false)
	set(v): story.set_flag("harbor_mission_unlocked", v)
var intro_quest_done: bool:
	get: return story.get_flag("intro_quest_done", false)
	set(v): story.set_flag("intro_quest_done", v)
var safehouse_intro_done: bool:
	get: return story.get_flag("safehouse_intro_done", false)
	set(v): story.set_flag("safehouse_intro_done", v)
var npcs_greeted: Array:
	get: return story.get_flag("npcs_greeted", [])
	set(v): story.set_flag("npcs_greeted", v)
var warehouse_mission_accepted: bool:
	get: return story.get_flag("warehouse_mission_accepted", false)
	set(v): story.set_flag("warehouse_mission_accepted", v)
var talked_to_mafuyu_training: bool:
	get: return story.get_flag("talked_to_mafuyu_training", false)
	set(v): story.set_flag("talked_to_mafuyu_training", v)
var accepted_harbor_mission: bool:
	get: return story.get_flag("accepted_harbor_mission", false)
	set(v): story.set_flag("accepted_harbor_mission", v)
var harbor_intro_done: bool:
	get: return story.get_flag("harbor_intro_done", false)
	set(v): story.set_flag("harbor_intro_done", v)
var upgrade_tutorial_done: bool:
	get: return story.get_flag("upgrade_tutorial_done", false)
	set(v): story.set_flag("upgrade_tutorial_done", v)
var guards_defeated: bool:
	get: return story.get_flag("guards_defeated", false)
	set(v): story.set_flag("guards_defeated", v)
var training_ichika_done: bool:
	get: return story.get_flag("training_ichika_done", false)
	set(v): story.set_flag("training_ichika_done", v)
var training_kanade_done: bool:
	get: return story.get_flag("training_kanade_done", false)
	set(v): story.set_flag("training_kanade_done", v)
var harbor_meeting_p1_done: bool:
	get: return story.get_flag("harbor_meeting_p1_done", false)
	set(v): story.set_flag("harbor_meeting_p1_done", v)
var mafuyu_honami_talked: bool:
	get: return story.get_flag("mafuyu_honami_talked", false)
	set(v): story.set_flag("mafuyu_honami_talked", v)
var mizuki_control_phase: bool:
	get: return story.get_flag("mizuki_control_phase", false)
	set(v): story.set_flag("mizuki_control_phase", v)
var harbor_mizuki_snack_done: bool:
	get: return story.get_flag("harbor_mizuki_snack_done", false)
	set(v): story.set_flag("harbor_mizuki_snack_done", v)

# ── Tiện Ích Trò Chơi ──────────────────────────────────────────────────────
func get_party_member(m_name: String) -> Entity:
	return party.get(m_name)

# Bắt đầu trạng thái hội thoại
func start_dialogue():
	is_in_dialogue = true

# Kết thúc trạng thái hội thoại
func end_dialogue():
	is_in_dialogue = false

# ── Hệ Thống Lưu/Tải (Save/Load) ───────────────────────────────────────────
const SAVE_PATH = "user://sekai_save.json"

func save_game(path: String = SAVE_PATH):
	SaveManager.save_game(path)

func get_current_save_path() -> String:
	return SaveManager.get_current_save_path()

func load_game(path: String = SAVE_PATH) -> bool:
	return SaveManager.load_game(path)

func has_save(path: String = SAVE_PATH) -> bool:
	return SaveManager.has_save(path)

func get_save_files() -> Array:
	return SaveManager.get_save_files()

# ── Quản Lý Chuyển Cảnh & Trận Chiến ───────────────────────────────────────
# Thiết lập lại toàn bộ trạng thái để bắt đầu trò chơi mới
func reset_game():
	story.reset()
	last_player_position = Vector2.ZERO
	current_map_file = "res://Maps/Prologue/PrologueMap.tscn"
	is_sandbox = false
	is_tutorial = false
	is_scripted_battle = false
	_init_party()

# Ghi nhớ bản đồ và vị trí hiện tại
func store_map_state(map_path: String, player_pos: Vector2):
	current_map_file = map_path
	last_player_position = player_pos

# Đặt lại bộ đếm nhiệm vụ
func reset_mission_stats():
	story.enemies_defeated = 0

func full_heal_party():
	for key in party.keys():
		var entity = party[key]
		if entity:
			entity.hp = entity.max_hp
			if entity.has_method("clear_all_debuffs"):
				entity.clear_all_debuffs()

# Chuyển cảnh đến trận chiến
func trigger_battle():
	AudioManager.play_music("battle")
	get_tree().change_scene_to_file("res://BattleSystem/BattleScene.tscn")

func finish_battle(victory: bool, count: int = 1):
	"""
	Xử lý logic kết quả sau trận đấu (Exp, Cốt truyện, Chuyển cảnh).
	
	Args:
		victory (bool): Cờ báo thắng hay thua.
		count (int): Số lượng địch bị hạ.
	Returns: Không có
	"""
	if is_sandbox:
		get_tree().change_scene_to_file("res://Menus/Sandbox/SandboxMenu.tscn")
		return

	if is_scripted_battle:
		_handle_scripted_battle_finish(victory)
		return

	if not victory and is_training_mode:
		# Thua training: thưởng EXP an ủi, hồi máu, rồi về base
		var bonus_exp = int(last_battle_max_lv * 50)
		for p_name in training_participants:
			var entity = get_party_member(p_name)
			if entity: LevelManager.gain_exp(entity, bonus_exp)
		is_training_mode = false
		full_heal_party()
		current_map_file = "res://Maps/Base/BaseMap.tscn"
		last_player_position = Vector2.ZERO
		get_tree().change_scene_to_file(current_map_file)
		return

	if victory:
		_apply_victory_rewards(count)
	else:
		full_heal_party()
		reset_mission_stats()
		current_map_file = "res://Maps/Base/BaseMap.tscn"
		last_player_position = Vector2.ZERO
			
	if story.get_flag("harbor_boss_defeated") and current_map_file == "res://Maps/Harbor/HarborMap.tscn":
		await get_tree().create_timer(1.5, false).timeout 
		await ScreenFade.fade_out(0.8)
		last_player_position = Vector2.ZERO
		get_tree().change_scene_to_file("res://Maps/Alleyway/AlleywayMap.tscn")
	else:
		get_tree().change_scene_to_file(current_map_file)

func _handle_scripted_battle_finish(victory: bool):
	if scripted_battle_id == "harbor_boss":
		is_scripted_battle = false
		scripted_battle_id = ""
		if victory:
			story.set_flag("harbor_boss_defeated", true)
			await get_tree().create_timer(1.5, false).timeout
			await ScreenFade.fade_out(0.8)
			last_player_position = Vector2.ZERO
			get_tree().change_scene_to_file("res://Maps/Alleyway/AlleywayMap.tscn")
		else:
			get_tree().change_scene_to_file("res://Maps/Harbor/HarborMap.tscn")
		return
	elif scripted_battle_id == "mizuki_vs_mafuyu":
		story.set_flag("mizuki_vs_mafuyu_done", true)
	elif scripted_battle_id == "ena_vs_mizuki":
		story.set_flag("ena_vs_mizuki_done", true)
		story.set_flag("ena_vs_mizuki_won", victory)
	elif scripted_battle_id == "ena_vs_thugs":
		story.set_flag("ena_vs_thugs_done", true)
		story.set_flag("ena_vs_thugs_won", victory)
	elif scripted_battle_id == "street_skirmish":
		story.set_flag("street_skirmish_done", true)
		story.set_flag("street_skirmish_won", victory)
	elif scripted_battle_id == "street_survival":
		story.set_flag("street_survival_done", true)
		story.set_flag("street_survival_won", victory)
	elif scripted_battle_id == "ops_kanade":
		if victory: story.set_flag("ops_kanade_done", true)
	elif scripted_battle_id == "ops_ichika":
		if victory: story.set_flag("ops_ichika_done", true)
	elif scripted_battle_id == "ops_honami":
		if victory: story.set_flag("ops_honami_done", true)
	elif scripted_battle_id == "pm_boss":
		if victory: story.set_flag("pm_boss_defeated", true)
	
	is_scripted_battle = false
	scripted_battle_id = ""
	get_tree().change_scene_to_file(current_map_file)

func _apply_victory_rewards(count: int):
	story.enemies_defeated += count
	if current_map_file.contains("Warehouse"): story.warehouse_wave += 1
	if current_map_file == "res://Maps/Harbor/HarborMap.tscn":
		story.harbor_wave += 1
		if story.harbor_wave > 4 or harbor_route == "boss":
			story.set_flag("harbor_boss_defeated", true)
