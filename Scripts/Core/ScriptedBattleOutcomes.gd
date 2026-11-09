class_name ScriptedBattleOutcomes
extends RefCounted

"""
ScriptedBattleOutcomes: kết quả cốt truyện của từng trận kịch bản: cờ nào được ghi khi thắng/thua, trận nào luôn có kết cục
cố định, trận nào thua thì rút về căn cứ. Chỉ là dữ liệu và việc ghi cờ (thuần, không đổi scene) nên test được trực tiếp;
GameManager lo phần hồi máu và chuyển cảnh.
"""

# Các trận có kết cục cố định theo cốt truyện: cờ được ghi dù thắng hay thua (thua là chủ ý).
const FATED := {
	"bounty_ambush": "ena_captured",
	"mizuki_vs_ena_forced": "ena_killed",
	"mizuki_vs_kanade": "mizuki_killed",
	"ichika_vs_kanade_slow": "kanade_killed",
	"honami_spar": "honami_spar_done", # buổi thử phản xạ không thể thắng; cờ ghi dù kết quả ra sao
}

# Các trận chỉ ghi cờ khi thắng; thua thì map phát lại để đánh lại.
const WIN_FLAG := {
	"bounty_1": "bounty_1_done",
	"bounty_2": "bounty_2_done",
	"bounty_3": "bounty_3_done",
	"final_mafuyu": "final_mafuyu_defeated",
	"training_trial": "training_trial_won",
	"mizuki_police_2": "mizuki_police_done",
	"ops_kanade": "ops_kanade_done",
	"ops_ena": "ops_ena_done",
	"ops_ichika": "ops_ichika_done",
	"ops_honami": "ops_honami_done",
	"pm_boss": "pm_boss_defeated",
}

# Các trận cốt truyện khó của màn Tác chiến/Thủ Tướng: thua thì về căn cứ trước nhiệm vụ để luyện tập thêm
# (không đánh lại ngay tại chỗ). Tiến độ nhiệm vụ nằm trong cờ (ops_*_done) nên Mafuyu cho tiếp tục đúng chỗ.
const RETREAT_ON_LOSS := ["ops_kanade", "ops_ena", "ops_ichika", "ops_honami", "pm_boss"]

# Các trận cờ "xong" được ghi dù thắng hay thua (map đi tiếp theo cờ đó chứ không phát lại): thua cũng là câu chuyện tiếp diễn
const CONTINUES_ON_LOSS := ["ena_vs_mizuki", "ena_vs_thugs", "mizuki_vs_mafuyu", "street_survival"]

# Thua trận này thì câu chuyện vẫn đi tiếp (kết cục cố định hoặc cờ "xong" ghi dù thua), không rút lui cũng không đánh lại
static func continues_after_loss(id: String) -> bool:
	return FATED.has(id) or id in CONTINUES_ON_LOSS

# Thua trận kịch bản (hoặc trận có kết cục cố định) thì hồi đầy máu để lần sau không bắt đầu với đồng đội đã gục
static func heals_party(id: String, victory: bool) -> bool:
	return not victory or FATED.has(id)

static func retreats_to_base(id: String, victory: bool) -> bool:
	return not victory and id in RETREAT_ON_LOSS

# Ghi mọi cờ cốt truyện của một trận kịch bản vừa kết thúc.
static func apply(story: StoryState, id: String, victory: bool) -> void:
	# Map đọc hai cờ này để biết trận vừa rồi thắng hay thua (map cần phân biệt khi cờ riêng không đủ)
	story.set_flag("last_scripted_win", id if victory else "")
	story.set_flag("last_scripted_loss", "" if victory else id)
	
	if FATED.has(id):
		story.set_flag(FATED[id], true)
	elif victory and WIN_FLAG.has(id):
		story.set_flag(WIN_FLAG[id], true)
	
	match id:
		"mizuki_vs_mafuyu":
			story.set_flag("mizuki_vs_mafuyu_done", true)
		"ena_vs_mizuki":
			story.set_flag("ena_vs_mizuki_done", true)
			story.set_flag("ena_vs_mizuki_won", victory)
		"ena_vs_thugs":
			story.set_flag("ena_vs_thugs_done", true)
			story.set_flag("ena_vs_thugs_won", victory)
		"street_skirmish":
			# Chỉ tính xong khi thắng; thua thì StreetMap phát lại đoạn mở đầu để đánh lại
			if victory:
				story.set_flag("street_skirmish_done", true)
		"street_survival":
			story.set_flag("street_survival_done", true)
		"training_trial":
			# Thua bài kiểm tra: FinaleStage cho chuẩn bị thêm (luyện tập/nâng cấp) thay vì ép đánh lại ngay
			story.set_flag("training_trial_failed", not victory)
