extends Node2D

"""
BattleManager: Điều phối vòng lặp chiến đấu theo lượt (Turn-based).

Lớp này quản lý việc tạo đội hình, xây dựng giao diện người dùng (HUD), 
và vận hành dòng chảy của trận đấu thông qua hệ thống Timeline. 
Sử dụng coroutine (await) để quản lý các hành động bất đồng bộ.
"""

var player_team: Array = []
var enemy_team: Array = []
var all_entities: Array = []
var timeline: Array = []
var battle_over: bool = false

const BattleHUDClass = preload("res://UI/Battle/BattleHUD.gd")
const ScreenShakeClass = preload("res://UI/Effects/ScreenShake.gd")

var hud: Node
var shaker: Node

var is_harbor_boss_fight: bool = false
var harbor_boss_phase: int = 0
var is_scripting: bool = false
var turns_in_phase: int = 0

func _ready():
	"""
	Khởi tạo trạng thái ban đầu của trận đấu.
	
	Thiết lập đội hình, context thực thể, giao diện người dùng (HUD), 
	và bắt đầu dòng chảy trận đấu.
	"""
	ScreenFade.fade_in(0.5)
	
	var data = BattleInitializer.setup_battle(self)
	
	player_team = data["player_team"].filter(func(e): return e != null)
	enemy_team = data["enemy_team"].filter(func(e): return e != null)
	is_harbor_boss_fight = data["is_harbor_boss"]
	
	all_entities = player_team + enemy_team
	_refresh_team_context()
		
	for e in all_entities:
		for s in e.skills:
			if s.has("initial_cooldown"):
				e.cooldowns[s["method"]] = s["initial_cooldown"]
				
	hud = BattleHUDClass.new()
	add_child(hud)
	hud.setup(player_team, enemy_team)
	_setup_gauge_teams()
	
	shaker = ScreenShakeClass.new()
	add_child(shaker)
	
	for entity in all_entities:
		entity.died.connect(_on_entity_died.bind(entity))
	
	if GameManager.is_sandbox:
		_setup_sandbox_exit_button()
	
	if is_harbor_boss_fight:
		HarborBattleScript.run_intro(self, func(): run_battle())
	else:
		run_battle()

func _refresh_team_context():
	# Cập nhật tham chiếu đồng minh và kẻ thù cho từng thực thể.
	for e in player_team:
		e.allies = player_team
		e.enemies = enemy_team
	for e in enemy_team:
		e.allies = enemy_team
		e.enemies = player_team

func _setup_gauge_teams():
	# Thiết lập đội hình cho thanh hành động (Action Gauge).
	hud.action_gauge.set_player_team(player_team)

func _show_tutorial():
	# Hiển thị hướng dẫn chiến đấu cơ bản.
	await BattleTutorial.run_tutorial(self)

func run_battle():
	"""
	Hàm này vận hành vòng lặp chính của trận đấu cho đến khi kết thúc.
	- Tham số: Không có.
	- Return: Không có (Sử dụng await).
	"""
	_regenerate_timeline()
	
	print("=== TRẬN CHIẾN BẮT ĐẦU ===")
	
	while not battle_over:
		if timeline.is_empty():
			_regenerate_timeline()
			if timeline.is_empty():
				break
		
		var turn = timeline.pop_front()
		var actor = turn["entity"]
		
		if actor == null or actor.current_hp <= 0:
			continue
		
		if is_harbor_boss_fight:
			HarborBattleScript.check_transitions(self)
			if is_scripting:
				await get_tree().create_timer(0.5).timeout
				continue
		
		turns_in_phase += 1
		
		var is_player_turn = actor in player_team
		if not GameManager.is_tutorial:
			hud.show_turn_indicator(actor)
		
		_update_gauge_display(actor)
		
		var can_act = ProcessStatus.handle_turn_start(actor)
		CooldownManager.process_cooldowns(actor)
		
		if not can_act:
			await get_tree().create_timer(0.8).timeout
			continue
		
		if _check_battle_end():
			break
		
		if is_player_turn:
			await _player_turn(actor)
		else:
			await _ai_turn(actor)
		
		_update_gauge_display(actor)
		
		if is_harbor_boss_fight:
			HarborBattleScript.check_transitions(self)
		
		if _check_battle_end():
			break
		
		await get_tree().create_timer(0.4).timeout
	
	await get_tree().create_timer(2.0).timeout
	
	var is_victory = AIManager.get_alive_targets(enemy_team).is_empty()
	if is_harbor_boss_fight:
		var boss = _get_entity("Đội Trưởng")
		if boss == null or boss.current_hp <= 0:
			is_victory = true
	
	var enemy_count = enemy_team.size()
	
	if is_victory:
		if GameManager.current_map_file == "res://Scenes/HarborMap.tscn" and GameManager.harbor_route == "guards":
			GameManager.guards_defeated = true
			
	if is_victory and GameManager.prologue_phase == 0:
		GameManager.prologue_phase = 1
	
	if is_victory and is_harbor_boss_fight:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_victory"), func():
			GameManager.harbor_mission_done = true
			GameManager.finish_battle(is_victory, enemy_count)
		)
	else:
		GameManager.finish_battle(is_victory, enemy_count)

func _player_turn(actor: Entity):
	# Xử lý lượt đi của người chơi.
	if GameManager.is_tutorial:
		await _show_tutorial()

	hud.command_menu.show_for(actor, enemy_team)
	var result = await hud.command_menu.command_chosen
	var action: String = result[0]
	var target: Entity = result[1]
	_execute_action(actor, action, target)

func _ai_turn(actor: Entity):
	# Xử lý lượt đi của AI đối thủ (Đã làm chậm để người chơi kịp quan sát).
	await get_tree().create_timer(1.2).timeout
	
	var decision = AIManager.pick_action(actor, actor.enemies, actor.allies, timeline)
	var action: String = decision["action"]
	var target: Entity = decision["target"]
	
	if target == null:
		return
	
	_execute_action(actor, action, target)

func _execute_action(actor: Entity, action: String, target: Entity):
	"""
	Hàm này thực thi hành động tấn công hoặc kỹ năng lên mục tiêu.
	- actor: Thực thể ra chiêu (Entity).
	- action: Tên phương thức kỹ năng (String).
	- target: Thực thể chịu đòn (Entity).
	- Return: Không có.
	"""
	if action == "attack":
		var dmg = DamageCalculator.calculate_damage(actor, target)
		target.take_damage(dmg)
		return
	
	if actor.has_method(action):
		var cd_turns = 0
		var once_per_battle = false
		for s in actor.skills:
			if s["method"] == action:
				cd_turns = s.get("cooldown_turns", 0)
				once_per_battle = s.get("once_per_battle", false)
				break
		
		var is_shadow_blade = (action == "shadow_blade")
		
		actor.call(action, target)
		
		if once_per_battle:
			CooldownManager.set_cooldown(actor, action, 99)
		elif cd_turns > 0:
			CooldownManager.set_cooldown(actor, action, cd_turns)
		
		if is_shadow_blade and actor.current_hp > 0:
			await shaker.hitstop(0.1)
			shaker.shake(8.0, 0.3)
	else:
		print("[Warning] ", actor.entity_name, " không có skill: ", action)
	
	_regenerate_timeline()

func _regenerate_timeline():
	# Tái tạo lại danh sách thứ tự lượt đi (Timeline).
	var alive = AIManager.get_alive_targets(all_entities)
	timeline = TurnCalculator.get_timeline(alive, 20)
	_update_gauge_display()

func _update_gauge_display(current_actor: Entity = null):
	# Cập nhật hiển thị của thanh hành động (Action Gauge).
	hud.action_gauge.refresh(timeline.slice(0, 10), current_actor)

func _purge_dead_from_timeline(dead_entity: Entity):
	# Loại bỏ các lượt dự kiến của một thực thể đã bị hạ gục.
	timeline = TurnCalculator.remove_dead_from_timeline(timeline, dead_entity)

func _get_entity(e_name: String) -> Entity:
	# Tìm kiếm thực thể trong trận đấu theo tên.
	for entity in all_entities:
		if entity.entity_name == e_name:
			return entity
	return null

func _on_entity_died(entity: Entity):
	"""
	Hàm xử lý logic khi một thực thể trong trận đấu bị hạ gục.
	- entity: Thực thể vừa chết (Entity).
	- Return: Không có.
	"""
	print(">>> ", entity.entity_name, " đã bị hạ gục! <<<")
	_purge_dead_from_timeline(entity)
	
	if not entity.is_character:
		var exp_reward = LevelManager.get_exp_reward(entity.level)
		for p in player_team:
			LevelManager.gain_exp(p, exp_reward)
	
	if is_harbor_boss_fight:
		HarborBattleScript.check_transitions(self)

func _check_battle_end() -> bool:
	"""
	Hàm kiểm tra xem trận đấu đã kết thúc hay chưa và kết quả thắng/thua.
	- Return: True nếu trận đấu kết thúc, False nếu tiếp tục (bool).
	"""
	if is_scripting: return false
	
	var is_boss_dead = false
	if is_harbor_boss_fight:
		var boss = _get_entity("Đội Trưởng")
		var dead = (boss == null or boss.current_hp <= 0)
		
		if dead:
			if harbor_boss_phase < 3:
				HarborBattleScript.check_transitions(self)
				return false
			else:
				is_boss_dead = true
	
	if (not is_harbor_boss_fight and AIManager.get_alive_targets(enemy_team).is_empty()) or is_boss_dead:
		hud.show_victory()
		battle_over = true
		return true
	
	if AIManager.get_alive_targets(player_team).is_empty():
		if GameManager.is_scripted_battle:
			battle_over = true
			return true
			
		if is_harbor_boss_fight and harbor_boss_phase == 1:
			HarborBattleScript.handle_loss(self)
			return false
		
		hud.show_defeat()
		battle_over = true
		return true
	return false

func _setup_sandbox_exit_button():
	# Tạo nút X ở góc phải màn hình để thoát Sandbox
	var cl = CanvasLayer.new()
	add_child(cl)
	
	# Control node làm vật chứa để dùng anchors
	var ctrl = Control.new()
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cl.add_child(ctrl)
	
	var btn = TextureButton.new()
	var tex = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey_close.svg")
	btn.texture_normal = tex
	
	# Đặt vào góc trên bên phải
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	btn.position = Vector2(-70, 20) # Cách lề phải 70px, lề trên 20px
	btn.scale = Vector2(0.8, 0.8)
	ctrl.add_child(btn)
	
	btn.pressed.connect(func():
		print("[Sandbox] Kết thúc trận đấu sớm.")
		GameManager.is_sandbox = false
		get_tree().change_scene_to_file("res://Scenes/SandboxMenu.tscn")
	)

func _names(team: Array) -> String:
	# Chuyển đổi danh sách thực thể thành chuỗi tên (dùng cho debug).
	var n = []
	for e in team:
		n.append(e.entity_name)
	return ", ".join(n)
