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

var scenario: BattleScenario
var is_scripting: bool = false

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
	scenario = data["scenario"]
	
	all_entities = player_team + enemy_team
	_refresh_team_context()
		
	for e in all_entities:
		for s in e.skills:
			if s.has("initial_cooldown"):
				e.cooldowns[s["method"]] = s["initial_cooldown"]
				
	hud = BattleHUDClass.new()
	add_child(hud)
	hud.setup(player_team, enemy_team)
	hud.skip_requested.connect(_on_skip_requested)
	_setup_gauge_teams()
	
	shaker = ScreenShakeClass.new()
	add_child(shaker)
	
	for entity in all_entities:
		entity.died.connect(_on_entity_died.bind(entity))
	
	if GameManager.is_sandbox:
		_setup_sandbox_exit_button()
	
	if scenario:
		scenario.on_start(self)
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
		var av_passed = turn["tick"]
		
		if actor == null or actor.current_hp <= 0:
			continue
			
		# Cập nhật thanh hành động cho tất cả thực thể dựa trên thời gian (AV) đã trôi qua
		for e in all_entities:
			if e.current_hp > 0:
				e.action_gauge += e.spd * av_passed
		
		# Reset thanh hành động của người vừa đến lượt (về 0 hoặc trừ đi 10000 để giữ phần dư)
		actor.action_gauge = max(0.0, actor.action_gauge - 10000.0)
		
		if scenario:
			scenario.on_turn_start(self, actor)
			if is_scripting:
				await get_tree().create_timer(0.5, false).timeout
				continue
		
		var is_player_turn = actor in player_team
		if not GameManager.is_tutorial:
			hud.show_turn_indicator(actor)
		
		_update_gauge_display(actor)
		
		var can_act = ProcessStatus.handle_turn_start(actor)
		CooldownManager.process_cooldowns(actor)
		
		if not can_act:
			await get_tree().create_timer(0.8, false).timeout
			continue
		
		if _check_battle_end():
			break
		
		if is_player_turn:
			await _player_turn(actor)
		else:
			await _ai_turn(actor)
		
		if scenario:
			scenario.on_turn_end(self, actor)
		
		if _check_battle_end():
			break
		
		await get_tree().create_timer(0.4, false).timeout
	
	await get_tree().create_timer(2.0, false).timeout
	
	var is_victory = scenario.get_victory_status(self)
	scenario.on_battle_completed(self, is_victory)

func _player_turn(actor: Entity):
	# Xử lý lượt đi của người chơi.
	if GameManager.is_tutorial:
		await _show_tutorial()

	hud.command_menu.show_for(actor, enemy_team)
	var result = await hud.command_menu.command_chosen
	if battle_over or result[0] == "cancel": return
	var action: String = result[0]
	var target: Entity = result[1]
	_execute_action(actor, action, target)

func _on_skip_requested():
	if battle_over: return
	print("[Skip] Người chơi kích hoạt bỏ qua trận đấu.")
	battle_over = true
	
	if hud.command_menu.visible:
		hud.command_menu.cancel()
		
	for e in enemy_team:
		if e.current_hp > 0:
			e.take_damage(99999, "pure")
	hud.show_victory()

func _ai_turn(actor: Entity):
	# Xử lý lượt đi của AI đối thủ (Đã làm chậm để người chơi kịp quan sát).
	await get_tree().create_timer(GameManager.battle_speed, false).timeout
	
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
	var had_bleed = (target != null and target.get_status_count("Bleed") > 0)
	
	if action == "attack":
		var dmg = DamageCalculator.calculate_damage(actor, target)
		target.take_damage(dmg)
	elif actor.has_method(action):
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
	
	# [Synergy]: Ichika & Mafuyu Bleed refresh
	# Khi đánh bất kỳ chiêu nào (bao gồm đánh thường, trừ Skill 3) lên ĐỊCH đang có Bleed, tự động reset duration và thêm 1 stack.
	if actor.entity_name in ["Ichika", "Mafuyu"] and action != "shadow_strike" and action != "lost_world":
		if target and target in actor.enemies and had_bleed:
			target.refresh_status_duration("Bleed", 3)
			target.add_status({"type": "Bleed", "duration": 3})
			print("[Synergy] ", actor.entity_name, " duy trì và tăng cường vết thương (Bleed refresh +1 stack)!")
	
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
	
	if scenario:
		scenario.on_entity_died(self, entity)

func _check_battle_end() -> bool:
	"""
	Hàm kiểm tra xem trận đấu đã kết thúc hay chưa và kết quả thắng/thua.
	- Return: True nếu trận đấu kết thúc, False nếu tiếp tục (bool).
	"""
	if scenario:
		return scenario.check_battle_end(self)
	
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
		get_tree().change_scene_to_file("res://Menus/Sandbox/SandboxMenu.tscn")
	)

func _names(team: Array) -> String:
	# Chuyển đổi danh sách thực thể thành chuỗi tên (dùng cho debug).
	var n = []
	for e in team:
		n.append(e.entity_name)
	return ", ".join(n)
