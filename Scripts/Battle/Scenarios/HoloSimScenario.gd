extends BattleScenario
class_name HoloSimScenario

"""
Tóm tắt: HoloSimScenario quản lý vòng đời của một trận đấu trong chế độ Mô phỏng Roguelite (Holo-Sim).

Chức năng chính:
- Kích hoạt các hiệu ứng Phước Lành (Blessings) trong trận đấu: Phản đòn (Thorns), Hút máu khi giết địch, Kích nổ Bleed.
- Sau khi chiến thắng tầng: Hiển thị giao diện chọn 1 trong 3 Phước Lành (HoloBlessingSelectUI).
- Tự động chuyển tiếp giữa các tầng, xử lý trạm nghỉ ngơi (Floors 4 & 9) và trận Trùm Cuối (Floor 10).
"""

var _battle: Node
var _used_undying: bool = false

func on_start(battle: Node):
	_battle = battle
	AudioManager.play_music("boss")
	
	# Kết nối tín hiệu phản đòn nếu có blessing_thorn
	if HoloSimManager.has_blessing("blessing_thorn"):
		for p in battle.player_team:
			if p and not p.damage_received_detailed.is_connected(_on_player_damaged):
				p.damage_received_detailed.connect(_on_player_damaged.bind(p))
				
	# Phục hồi máu nếu nhân vật còn sống
	for p in battle.player_team:
		if p and p.current_hp > 0:
			p.current_hp = max(p.current_hp, int(p.max_hp * 0.3))

func _on_player_damaged(amt: int, _type: String, _is_crit: bool, _is_break: bool, player: Entity):
	if amt <= 0 or not HoloSimManager.has_blessing("blessing_thorn"): return
	var reflect_amt = int(amt * 0.35)
	if reflect_amt <= 0: return
	
	# Phản lại cho kẻ địch ngẫu nhiên còn sống
	var alive_enemies = _battle.enemy_team.filter(func(e): return e.current_hp > 0)
	if not alive_enemies.is_empty():
		var target = alive_enemies[randi() % alive_enemies.size()]
		target.take_damage(reflect_amt, "pure")
		print("[Blessing Thorns] Phản lại ", reflect_amt, " sát thương cho ", target.entity_name)

func on_entity_died(battle: Node, entity: Entity):
	# Nếu kẻ địch chết và có blessing_heal_kill
	if not entity.is_character and HoloSimManager.has_blessing("blessing_heal_kill"):
		for p in battle.player_team:
			if p and p.current_hp > 0:
				var heal_amt = int(p.max_hp * 0.25)
				p.heal(heal_amt)
				print("[Blessing Heal Kill] Hồi ", heal_amt, " HP cho ", p.entity_name)
				break

func get_victory_status(battle: Node) -> bool:
	return battle.enemy_team.all(func(e): return e.current_hp <= 0)

func check_battle_end(battle: Node) -> bool:
	var player_dead = battle.player_team.all(func(e): return e.current_hp <= 0)
	var enemy_dead = battle.enemy_team.all(func(e): return e.current_hp <= 0)
	
	# Xử lý blessing_undying
	if player_dead and HoloSimManager.has_blessing("blessing_undying") and not _used_undying:
		_used_undying = true
		for p in battle.player_team:
			if p:
				p.current_hp = int(p.max_hp * 0.4)
				p.hp_changed.emit(p.current_hp, p.max_hp)
				print("[Blessing Undying] Kích hoạt Dòng Máu Bất Tử! Hồi phục 40% HP cho ", p.entity_name)
		return false
		
	return player_dead or enemy_dead

func on_battle_completed(battle: Node, is_victory: bool):
	if is_victory:
		print("[HoloSim] Chiến thắng Tầng ", HoloSimManager.current_floor, "!")
		
		# Nếu đã vượt qua Tầng 10 (Boss cuối)
		if HoloSimManager.current_floor >= HoloSimManager.MAX_FLOORS:
			GameManager.add_credits(1000)
			HoloSimManager.is_sim_active = false
			DialogueManager.play_dialogue([
				{"text": "CHÚC MỪNG!\nBạn đã hoàn thành trọn vẹn 10 Tầng Mô Phỏng Holo-Sim!\nPhần thưởng: +1000 Credits!", "type": "narrator"}
			], func():
				await ScreenFade.fade_out(1.0)
				GameManager.get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
			)
			return
			
		# Tiến tầng và mở màn chọn Phước Lành
		HoloSimManager.advance_floor()
		
		# Kiểm tra tầng nghỉ ngơi (Floor 4 hoặc 9)
		if HoloSimManager.is_rest_floor(HoloSimManager.current_floor):
			for p in battle.player_team:
				if p: p.heal(int(p.max_hp * 0.5))
			GameManager.add_credits(150)
			DialogueManager.play_dialogue([
				{"text": "Bạn đã đến Trạm Nghỉ Ngơi (Tầng %d)!\nToàn đội hồi phục 50%% HP và nhận +150 Credits." % HoloSimManager.current_floor, "type": "narrator"}
			], func():
				_show_blessing_selection(battle)
			)
		else:
			_show_blessing_selection(battle)
	else:
		# Thất bại
		var reward = HoloSimManager.current_floor * 50
		GameManager.add_credits(reward)
		HoloSimManager.is_sim_active = false
		DialogueManager.play_dialogue([
			{"text": "Đội hình đã bị áp đảo tại Tầng %d.\nKết thúc lượt mô phỏng. Nhận an ủi: %d Credits." % [HoloSimManager.current_floor, reward], "type": "narrator"}
		], func():
			await ScreenFade.fade_out(1.0)
			GameManager.get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
		)

func _show_blessing_selection(battle: Node):
	var select_ui = HoloBlessingSelectUI.new()
	battle.add_child(select_ui)
	
	var options = HoloBlessing.get_random_blessings(3, HoloSimManager.active_blessings)
	select_ui.setup_options(options)
	
	select_ui.blessing_chosen.connect(func(b_id: String):
		HoloSimManager.add_blessing(b_id)
		# Chuyển sang trận đấu tiếp theo
		await ScreenFade.fade_out(0.6)
		GameManager.get_tree().change_scene_to_file("res://BattleSystem/BattleScene.tscn")
	)
