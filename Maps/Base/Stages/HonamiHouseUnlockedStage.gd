extends LobbyStage
class_name HonamiHouseUnlockedStage

func on_stage_start():
	map.set_player("Ichika")
		
	if not GameManager.get_flag("honami_unlocked_intro_done"):
		lock_scene()
		map.place_player(Vector2(24, 20))
		
		DialogueManager.play_dialogue([
			say("Mafuyu", "Cô về rồi à. Có vẻ ả bác sĩ đó không làm khó dễ gì cô nhỉ."),
			say("Ichika", "Dạ vâng! Chị ấy tốt bụng lắm, còn chỉ cho em mấy chiêu phòng thân nữa!"),
			say("Mafuyu", "Cô ta... tốt bụng? Chắc là chỉ đối với những người ngây ngô như cô thôi."),
			say("Mafuyu", "Thôi bỏ đi. Từ giờ cô được phép tự do đi lại giữa hai bên.")
		], func():
			GameManager.set_flag("honami_unlocked_intro_done", true)
			unlock_scene()
			map._refresh_quest_label()
		)
	elif GameManager.get_flag("finale_retreated"):
		# Vừa thua một trận của màn Tác chiến/Thủ Tướng: giải thích vì sao đang ở căn cứ
		GameManager.set_flag("finale_retreated", false)
		DialogueManager.play_dialogue([
			{"text": "Cả đội gục ngã và phải rút về căn cứ. Luyện tập thêm với Mafuyu, khi sẵn sàng thì nói chuyện với cô ấy để quay lại nhiệm vụ.", "type": "narrator"}
		])

func handle_npc_interaction(npc_name: String):
	if npc_name == "Mafuyu":
		if not GameManager.get_flag("pm_arc_started"):
			DialogueManager.play_dialogue([say("Mafuyu", "Cô tìm được thông tin gì rồi?")], func():
				_show_mafuyu_menu()
			)
		else:
			DialogueManager.play_dialogue([say("Mafuyu", "Đừng để ả lôi kéo cô quá đà.")], func():
				_show_resume_menu()
			)
	elif npc_name == "Kanade":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade_post"), func():
			open_upgrade_ui()
		)
	elif npc_name == "Ena":
		DialogueManager.play_dialogue([say("Ena", "Bác sĩ gì mà tay vịn cứng như thép... Đau điếng cả người.")])
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue([say("Mizuki", "Bà bác sĩ đó cũng bảnh đấy chứ, ha ha!")])

func _show_mafuyu_menu():
	var idx: int = await DialogueManager.ask(["[Báo cáo Intel]", "[Tập luyện]", "[Hủy]"])
	if idx == 0:
		_start_finale_arc()
	elif idx == 1:
		offer_training(TRAINEES)

# Sau khi đã bắt đầu màn Tác chiến/Thủ Tướng (kể cả khi thua và bị đưa về căn cứ): tiếp tục nhiệm vụ hoặc luyện tập thêm
func _show_resume_menu():
	var idx: int = await DialogueManager.ask(["[Tiếp tục nhiệm vụ]", "[Tập luyện]", "[Hủy]"])
	if idx == 0:
		_resume_finale_arc()
	elif idx == 1:
		offer_training(TRAINEES)

# Bản đồ Tác chiến tự chọn trận chưa xong tiếp theo (theo cờ ops_*_done), xong hết thì sang Xa lộ đánh Thủ Tướng
func _resume_finale_arc():
	await GameManager.change_map(MapPaths.CITY_OPS, 1.0)

func _start_finale_arc():
	GameManager.set_flag("pm_arc_started", true)
	DialogueManager.play_dialogue(DialogueLoader.get_lines("pm_plot_reveal"), func():
		await GameManager.change_map(MapPaths.CITY_OPS, 1.0)
	)

func get_quest_text() -> String:
	if GameManager.get_flag("pm_arc_started"):
		return "MỤC TIÊU: Nói chuyện với Mafuyu để tiếp tục nhiệm vụ (hoặc luyện tập thêm trước khi quay lại)."
	return "MỤC TIÊU: Bạn đã được phép đi lại tự do. Luyện tập qua lại giữa Nightcord và nhà Honami.\nKhi sẵn sàng, nói chuyện với Mafuyu và chọn [Báo cáo Intel]."
