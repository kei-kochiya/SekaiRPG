class_name EntityFactory
extends RefCounted

"""
EntityFactory: bảng DUY NHẤT từ TÊN HIỂN THỊ → lớp thực thể (nhân vật và quái) dùng cho Sandbox, Holo-Sim và các trận bản sao.
Trước đây bảng này bị chép ở GameManager (Sandbox), BattleInitializer (bản sao) và HoloSim (match).
Bảng id kỹ thuật → lớp quái (dữ liệu trận, kịch bản) là BattleInitializer.enemy_classes; TestOutcomes giữ hai bảng khớp nhau.
"""

# Nhân vật chơi được: tên → lớp
static var CHARACTERS := {
	"Ichika": Ichika,
	"Kanade": Kanade,
	"Mafuyu": Mafuyu,
	"Ena": Ena,
	"Mizuki": Mizuki,
	"Honami": Honami,
}

# Quái theo tên hiển thị (Sandbox, Holo-Sim). "Thug"/"Terrorist" là tên tiếng Anh Holo-Sim vẫn dùng.
static var MONSTERS := {
	"Lính Cảng": Guard,
	"Kidnapper": Kidnapper,
	"Giang Hồ": Thug,
	"Thug": Thug,
	"Target": TrainingBot,
	"Nhân Viên Kho": WarehouseWorker,
	"Khủng Bố": Terrorist,
	"Terrorist": Terrorist,
	"Drone Trinh Sát": ReconDrone,
	"Xạ Thủ Bắn Tỉa": Sniper,
	"Vệ Binh Cơ Giới": CyborgEnforcer,
	"Chuyên Viên Nhiễu Sóng": CyberJammer,
	"Đội Trưởng (BOSS)": Captain,
	"Thủ Tướng (FINAL BOSS)": PrimeMinister,
}

# Danh sách (có thứ tự) hiện trong Sandbox
const SANDBOX_CHARACTERS := ["Ichika", "Kanade", "Mafuyu", "Ena", "Mizuki", "Honami"]
const SANDBOX_MONSTERS := [
	"Lính Cảng", "Kidnapper", "Giang Hồ", "Target", "Nhân Viên Kho",
	"Khủng Bố", "Drone Trinh Sát", "Xạ Thủ Bắn Tỉa", "Vệ Binh Cơ Giới",
	"Chuyên Viên Nhiễu Sóng", "Đội Trưởng (BOSS)", "Thủ Tướng (FINAL BOSS)",
]

# Dựng mới một thực thể theo tên; null nếu không biết tên đó.
static func create(entity_name: String) -> Entity:
	var entity_class = CHARACTERS.get(entity_name, MONSTERS.get(entity_name))
	return entity_class.new() if entity_class else null
