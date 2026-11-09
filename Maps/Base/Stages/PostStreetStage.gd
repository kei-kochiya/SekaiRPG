extends LobbyStage
class_name PostStreetStage

func on_stage_start():
	map.set_player("Ichika")

	if GameManager.get_flag("post_street_trained_once"):
		_cutscene_active = true
		_play_honami_invasion()

func handle_npc_interaction(npc_name: String):
	if npc_name == "Mafuyu":
		DialogueManager.play_dialogue([say("Mafuyu", "Cô cần gì? Muốn tập luyện thêm à?")], func():
			_show_training_menu()
		)
	elif npc_name == "Kanade":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade_post"), func():
			open_upgrade_ui()
		)
	elif npc_name == "Ena":
		DialogueManager.play_dialogue([say("Ena", "Chị còn đau lưng lắm, đừng rủ chị tập luyện.")])
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue([say("Mizuki", "Mới đi dạo có chút xíu mà mệt muốn đứt hơi. Tội nghiệp Mafuyu phải cõng tôi về.")])

# Lần luyện tập đầu tiên ở sảnh là điều kiện để Honami xông vào ở lần vào Base kế tiếp
func _show_training_menu():
	offer_training(TRAINEES, false, func():
		GameManager.set_flag("post_street_trained_once", true)
	)

func _play_honami_invasion():
	# Phát âm thanh báo động (Chưa có hàm play_sound nên tạm tắt)
	# AudioManager.play_sound("res://Assets/Audio/SFX/alert.wav")

	# Spawn Honami ở cửa chính
	map.spawn_dummy("Honami", Vector2(24, 21), Color(0.5, 0.35, 0.25))

	DialogueManager.play_dialogue(DialogueLoader.get_lines("base_honami_invasion"), func():
		GameManager.set_flag("honami_house_unlocked", true)
		GameManager.set_flag("post_street_trained_once", false) # Reset flag for safety

		# Đưa người chơi sang nhà Honami
		await GameManager.change_map(MapPaths.HONAMI_HOUSE, 1.5)
	)

func get_quest_text() -> String:
	return "MỤC TIÊU: Nói chuyện với Mafuyu để luyện tập (Unlock: Mafuyu, Mizuki)."
