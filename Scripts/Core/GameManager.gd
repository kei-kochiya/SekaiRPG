extends Node

"""
Tóm tắt: GameManager là bộ não trung tâm (Autoload) quản lý toàn bộ vòng đời của trò chơi.

Chức năng chính:
- Lưu trữ và cung cấp đối tượng đội hình (Party).
- Quản lý bộ đệm trạng thái cốt truyện thông qua StoryState (cờ sự kiện, tiến độ map).
- Xử lý hệ thống lưu và tải game (Save/Load) qua JSON (lỗi gần nhất nằm trong last_save_error / last_load_error).
- Điều phối các chế độ chơi đặc biệt: Sandbox, Training, Scripted Battle.
- Xử lý luồng sau khi trận chiến kết thúc (tính exp, kích hoạt sự kiện, chuyển cảnh).
- Quản lý tùy chọn cài đặt hệ thống (Volume, Battle Speed, Skip Battle).
- Cung cấp các hàm hỗ trợ chung (filter, entity factory).
"""

# ── Tham chiếu đến các Manager thành phần ──────────────────────────────────
var story: StoryState = StoryState.new()

# ── Biến Quản Lý Trạng Thái ────────────────────────────────────────────────

var current_map_file: String = MapPaths.PROLOGUE
var last_player_position: Vector2 = Vector2.ZERO

var is_training_mode: bool = false
var training_participants: Array = []
var training_used_opponents: Array = []
# EXP kiếm được trong trận luyện tập hiện tại. Trận luyện tập đánh bằng bản sao nhân vật nên EXP phải chuyển về nhân vật thật.
var training_exp_earned: int = 0
var last_battle_max_lv: int = 1

# Thông báo lỗi của lần Lưu/Tải gần nhất ("" nếu thành công) để UI hiển thị cho người chơi
var last_save_error: String = ""
var last_load_error: String = ""

var is_in_dialogue: bool = false
var is_tutorial: bool = false
var is_sandbox: bool = false
var is_scripted_battle: bool = false
var scripted_battle_id: String = ""
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []

# battle_speed là số giây chờ giữa các nhịp trong trận (nhỏ hơn = nhanh hơn)
const BATTLE_SPEED_FAST := 0.6
const BATTLE_SPEED_NORMAL := 1.2
var battle_speed: float = BATTLE_SPEED_NORMAL
var master_volume: float = 1.0:
	set(v):
		master_volume = clamp(v, 0.0, 1.0)
		if AudioManager: AudioManager.update_volume(master_volume)

var skip_battle_unlocked: bool = false
var skip_battle_enabled: bool = false

# Tắt rung màn hình và dừng hình (hit-stop) khi đánh trúng; người chơi dễ say hoặc nhạy với chuyển động dùng tuỳ chọn này.
var reduce_motion: bool = false

# ── Kinh Tế & Túi Đồ (Economy & Inventory) ─────────────────────────────────
const DEFAULT_CREDITS := 200
const DEFAULT_INVENTORY := {
	"potion": 2,
	"energy_drink": 1,
	"bandage": 1
}

var credits: int = DEFAULT_CREDITS
var inventory: Dictionary = DEFAULT_INVENTORY.duplicate()
var opened_chests: Array = []

func add_credits(amt: int):
	credits = max(0, credits + amt)

func spend_credits(amt: int) -> bool:
	if credits >= amt:
		credits -= amt
		return true
	return false

func add_item(item_id: String, count: int = 1):
	inventory[item_id] = inventory.get(item_id, 0) + count

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func use_item(item_id: String, target: Entity) -> bool:
	if get_item_count(item_id) <= 0 or target == null:
		return false
	inventory[item_id] -= 1
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
		
	ItemCatalog.apply_effect(item_id, target)
	return true

func is_chest_opened(chest_id: String) -> bool:
	return opened_chests.has(chest_id)

func open_chest(chest_id: String):
	if not opened_chests.has(chest_id):
		opened_chests.append(chest_id)

# ── Đội Hình (Party) ───────────────────────────────────────────────────────
var party: Dictionary = {}

# Khởi tạo đội hình & Bộ đếm tự động lưu
func _ready():
	_init_party()
	_setup_autosave_timer()
	# Hoãn một nhịp: setter master_volume gọi AudioManager, autoload này có thể khởi tạo sau GameManager
	load_settings.call_deferred()

# Tùy chọn của người chơi nằm ngoài file save (xem GameSettings)
func load_settings():
	GameSettings.load_into(self)

func save_settings():
	GameSettings.save_from(self)

var _autosave_timer: Timer
# Tắt hẳn tự động lưu (công cụ chạy thử tự động đặt false để không ghi đè autosave thật của người chơi)
var autosave_enabled: bool = true

func _setup_autosave_timer():
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = 300.0 # 5 phút
	_autosave_timer.autostart = true
	_autosave_timer.one_shot = false
	_autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	add_child(_autosave_timer)

func _on_autosave_timer_timeout():
	if autosave_enabled and _can_autosave():
		auto_save()

# Scene gốc không phải màn chơi: không lưu, không tạm dừng bằng ESC, không hiện phím ảo. Tên node gốc của cảnh trận là BATTLE_SCENE_NAME.
const MENU_SCENES := ["StartMenu", "SandboxMenu", "EndingCard"]
const BATTLE_SCENE_NAME := "BattleRoot"

func _can_autosave() -> bool:
	return not is_in_dialogue and can_save_now()

# Lưu được khi đang ở Overworld bình thường: không Sandbox/trận/luyện tập/Holo-Sim, có người chơi đang di chuyển
# (cảnh tự chạy khóa người chơi, lúc đó cờ cốt truyện mới đặt dở nên không lưu).
func can_save_now() -> bool:
	if is_sandbox or is_scripted_battle or is_training_mode or HoloSimManager.is_sim_active:
		return false
	var cur_scene = get_tree().current_scene
	if cur_scene == null or cur_scene.name == BATTLE_SCENE_NAME or cur_scene.name in MENU_SCENES:
		return false
	var player = cur_scene.find_child("OverworldPlayer", true, false)
	return player != null and player.is_physics_processing()

func restart_autosave_timer():
	if _autosave_timer and autosave_enabled:
		_autosave_timer.start()

func _init_party():
	"""
	Khởi tạo các đối tượng nhân vật chính và cấp độ ban đầu cho đội hình.
	
	Args: Không có
	Returns: Không có
	"""
	# Đội hình cũ (New Game / tải lại) không còn ai giữ: giải phóng để không rò rỉ node mồ côi
	for old in party.values():
		if is_instance_valid(old):
			old.queue_free()
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

# ── Kết nối StoryState (Flags & Variables) ─────────────────────────────────
var warehouse_wave: int:
	get: return story.warehouse_wave
	set(v): story.warehouse_wave = v
var harbor_wave: int:
	get: return story.harbor_wave
	set(v): story.harbor_wave = v
# Wave của chế độ luyện tập (tách biệt với warehouse_wave của cốt truyện)
var training_wave: int:
	get: return story.training_wave
	set(v): story.training_wave = v
var enemies_defeated: int:
	get: return story.enemies_defeated
	set(v): story.enemies_defeated = v
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

# ── Tiện Ích Trò Chơi ──────────────────────────────────────────────────────
func get_party_member(m_name: String) -> Entity:
	return party.get(m_name)

# Thành viên còn sống trong cốt truyện? (Hồi kết 2 giết dần các thành viên Nightcord cũ.)
# Chỉ ảnh hưởng NPC trong map, danh sách luyện tập và đối thủ luyện tập; Sandbox và Holo-Sim vẫn dùng đủ mọi người.
func is_member_alive_in_story(m_name: String) -> bool:
	match m_name:
		"Ena": return not story.get_flag("ena_killed")
		"Mizuki": return not story.get_flag("mizuki_killed")
		"Kanade": return not story.get_flag("kanade_killed")
		"Mafuyu": return not story.get_flag("final_mafuyu_defeated")
	return true

# Bắt đầu trạng thái hội thoại
func start_dialogue():
	is_in_dialogue = true

# Kết thúc trạng thái hội thoại
func end_dialogue():
	is_in_dialogue = false

# ── Hệ Thống Lưu/Tải (Save/Load) ───────────────────────────────────────────

func save_game(path_or_name: String = SaveManager.QUICK_SAVE_PATH) -> bool:
	last_save_error = ""
	var cur_scene = get_tree().current_scene
	if cur_scene:
		var player = cur_scene.find_child("OverworldPlayer", true, false)
		if player:
			last_player_position = player.global_position
		# current_map_file chỉ được ghi khi rời map (store_map_state) nên có thể đã cũ
		# (vd: quay về Base từ Cafe/HonamiHouse). Luôn lấy map thật đang chạy khi lưu.
		var scene_path: String = cur_scene.scene_file_path
		if scene_path.begins_with("res://Maps/"):
			current_map_file = scene_path
	var ok := SaveManager.save_game(path_or_name)
	if not ok:
		last_save_error = SaveManager.last_error
	return ok

func quick_save() -> bool:
	return save_game(SaveManager.QUICK_SAVE_PATH)

func auto_save() -> bool:
	print("[GameManager] Tự động lưu game định kỳ...")
	return save_game(SaveManager.AUTOSAVE_PATH)

# Trả về false (và điền last_load_error) nếu file không đọc được/hỏng; khi đó trạng thái game KHÔNG bị thay đổi.
func load_game(path_or_name: String = "") -> bool:
	last_load_error = ""
	var ok := SaveManager.load_game(path_or_name)
	if not ok:
		last_load_error = SaveManager.last_error
	else:
		restart_autosave_timer()
	return ok

func has_save() -> bool:
	return SaveManager.has_save()

# ── Quản Lý Chuyển Cảnh & Trận Chiến ───────────────────────────────────────
# Thiết lập lại toàn bộ trạng thái để bắt đầu trò chơi mới
func reset_game():
	story.reset()
	last_player_position = Vector2.ZERO
	current_map_file = MapPaths.PROLOGUE
	last_load_error = ""
	last_save_error = ""
	last_battle_max_lv = 1
	HoloSimManager.high_score_floor = 0
	credits = DEFAULT_CREDITS
	inventory = DEFAULT_INVENTORY.duplicate()
	opened_chests = []
	clear_transient_state()
	_init_party()
	restart_autosave_timer()

# Xóa các trạng thái tạm của phiên chơi (luyện tập, trận kịch bản, sandbox, hội thoại, Holo-Sim)
# để chúng không rò sang game mới / game vừa tải. Gọi từ reset_game() và khi tải save thành công.
func clear_transient_state():
	is_training_mode = false
	training_participants = []
	training_used_opponents = []
	training_exp_earned = 0
	story.training_wave = 0
	is_scripted_battle = false
	scripted_battle_id = ""
	is_sandbox = false
	sandbox_player_team = []
	sandbox_enemy_team = []
	is_in_dialogue = false
	is_tutorial = false
	if HoloSimManager:
		HoloSimManager.is_sim_active = false
	DialogueManager.reset() # hội thoại/lựa chọn đang mở của lượt chơi trước (thoát về menu giữa cảnh) không được sang phiên mới

# Bắt đầu một phiên luyện tập (dùng bộ đếm training_wave riêng, không đụng warehouse_wave của cốt truyện)
func begin_training(participants: Array):
	is_training_mode = true
	story.training_wave = 1
	training_participants = participants.duplicate()
	training_used_opponents = []
	training_exp_earned = 0

# Kết thúc phiên luyện tập (hoàn thành, thua hoặc bỏ dở)
func end_training():
	is_training_mode = false
	story.training_wave = 0
	training_participants = []
	training_used_opponents = []
	training_exp_earned = 0

# Chuyển EXP của trận luyện tập vừa thắng cho các nhân vật thật tham gia (rồi xóa bộ đếm)
func grant_training_exp() -> void:
	var amount := training_exp_earned
	training_exp_earned = 0
	if amount <= 0:
		return
	for p_name in training_participants:
		var entity = get_party_member(p_name)
		if entity:
			LevelManager.gain_exp(entity, amount)

# Bắt đầu một trận kịch bản: ghi nhớ map để quay lại sau trận (kèm vị trí người chơi), tùy chọn fade-out rồi vào BattleScene.
# Kết quả trận do _handle_scripted_battle_finish xử lý (xem ScriptedBattleOutcomes).
# Chạy trên autoload nên sống lâu hơn map: nếu scene đã đổi trong lúc fade (thoát về menu/tải game) thì hủy trận.
func start_scripted_battle(id: String, return_map: String, player_pos: Vector2 = Vector2.ZERO, fade: float = 0.0) -> void:
	if _in_menu_scene():
		return
	var scene := get_tree().current_scene
	is_scripted_battle = true
	scripted_battle_id = id
	store_map_state(return_map, player_pos)
	if fade > 0.0:
		await ScreenFade.fade_out(fade)
		if get_tree().current_scene != scene:
			is_scripted_battle = false
			scripted_battle_id = ""
			return
	trigger_battle()

# Người chơi vừa thoát về menu: lời gọi đến muộn từ timer/coroutine của map cũ phải bỏ qua, không kéo menu sang map đó
func _in_menu_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.name in MENU_SCENES

# Sang một map khác: fade-out, ghi nhớ map đích rồi đổi scene. Chạy trên autoload nên không chết theo map đang bị đóng;
# nếu scene đã đổi trong lúc fade (người chơi tải game/thoát về menu) thì bỏ qua, không kéo scene mới đi chỗ khác.
func change_map(path: String, fade: float = 1.0, player_pos: Vector2 = Vector2.ZERO) -> void:
	if _in_menu_scene():
		return
	var scene := get_tree().current_scene
	if fade > 0.0:
		await ScreenFade.fade_out(fade)
		if get_tree().current_scene != scene:
			return
	store_map_state(path, player_pos)
	get_tree().change_scene_to_file(path)

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
			entity.current_hp = entity.max_hp
			if entity.has_method("clear_all_debuffs"):
				entity.clear_all_debuffs()

# Chuyển cảnh đến trận chiến
func trigger_battle():
	AudioManager.play_music("battle")
	get_tree().change_scene_to_file(MapPaths.BATTLE_SCENE)

func finish_battle(victory: bool, count: int = 1):
	"""
	Xử lý logic kết quả sau trận đấu (Exp, Cốt truyện, Chuyển cảnh).
	
	Args:
		victory (bool): Cờ báo thắng hay thua.
		count (int): Số lượng địch bị hạ.
	Returns: Không có
	"""
	if is_sandbox:
		get_tree().change_scene_to_file(MapPaths.SANDBOX_MENU)
		return

	if is_scripted_battle:
		_handle_scripted_battle_finish(victory)
		return

	if not victory and is_training_mode:
		# Thua training: thưởng EXP an ủi, hồi máu, rồi về base
		var bonus_exp = int(last_battle_max_lv * 50)
		training_exp_earned = 0
		for p_name in training_participants:
			var entity = get_party_member(p_name)
			if entity: LevelManager.gain_exp(entity, bonus_exp)
		end_training()
		full_heal_party()
		_set_base_as_current_map()
		get_tree().change_scene_to_file(current_map_file)
		return

	if victory:
		_apply_victory_rewards(count)
	else:
		full_heal_party()
		reset_mission_stats()
		_set_base_as_current_map()
		# Thua trận nhiệm vụ: về căn cứ, mở lại luyện tập cho người chơi cày thêm rồi quay lại
		reset_training_progress()
			
	get_tree().change_scene_to_file(current_map_file)

const TRAINING_DONE_FLAGS = [
	"training_ichika_done", "training_kanade_done", "training_ena_done",
	"training_mizuki_done", "training_mafuyu_done", "training_honami_done",
]

# Mở lại các lượt luyện tập đã hoàn thành. Menu của Mafuyu ở giai đoạn đầu ẩn người đã tập xong, nên sau một trận thua
# phải xóa cờ thì người chơi mới tập thêm được.
func reset_training_progress() -> void:
	for flag in TRAINING_DONE_FLAGS:
		story.set_flag(flag, false)

func _retreat_to_base() -> void:
	reset_training_progress()
	story.set_flag("finale_retreated", true)
	_set_base_as_current_map()

# Đặt căn cứ làm map hiện tại (người chơi xuất hiện ở vị trí mặc định)
func _set_base_as_current_map() -> void:
	current_map_file = MapPaths.BASE
	last_player_position = Vector2.ZERO

func _handle_scripted_battle_finish(victory: bool):
	var id := scripted_battle_id
	# Thua trận kịch bản: hồi đầy máu để lần đánh lại không bắt đầu với đồng đội đã gục
	if ScriptedBattleOutcomes.heals_party(id, victory):
		full_heal_party()
	ScriptedBattleOutcomes.apply(story, id, victory)
	
	if id == "harbor_boss":
		# Boss Bến Cảng có đường chuyển cảnh riêng: thắng thì sang hẻm sau trận, thua thì về lại bến cảng
		is_scripted_battle = false
		scripted_battle_id = ""
		if victory:
			var scene := get_tree().current_scene
			await get_tree().create_timer(1.5, false).timeout
			if get_tree().current_scene != scene:
				return # người chơi đã thoát về menu trong lúc chờ
			await change_map(MapPaths.ALLEYWAY, 0.8)
		else:
			get_tree().change_scene_to_file(MapPaths.HARBOR)
		return
	
	if ScriptedBattleOutcomes.retreats_to_base(id, victory):
		_retreat_to_base()
	
	is_scripted_battle = false
	scripted_battle_id = ""
	get_tree().change_scene_to_file(current_map_file)

func _apply_victory_rewards(count: int):
	story.enemies_defeated += count
	if is_training_mode:
		# Luyện tập dùng bộ đếm riêng, không làm tiến trình Nhà kho của cốt truyện
		story.training_wave += 1
		grant_training_exp()
	elif current_map_file == MapPaths.WAREHOUSE:
		story.warehouse_wave += 1
	if current_map_file == MapPaths.HARBOR:
		# Trận Boss Bến Cảng luôn là trận kịch bản (xử lý ở _handle_scripted_battle_finish) nên ở đây chỉ đếm wave lính gác
		story.harbor_wave += 1
