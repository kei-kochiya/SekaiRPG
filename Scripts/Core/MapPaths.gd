class_name MapPaths
extends RefCounted

"""
MapPaths: đường dẫn các map (scene chơi được) và scene hệ thống, cùng tên hiển thị của map (dùng cho danh sách save).
Một nơi duy nhất thay cho hàng chục chuỗi "res://..." chép khắp mã nguồn.
"""

const PROLOGUE := "res://Maps/Prologue/PrologueMap.tscn"
const BASE := "res://Maps/Base/BaseMap.tscn"
const WAREHOUSE := "res://Maps/Warehouse/WarehouseMap.tscn"
const TRAINING := "res://Maps/Warehouse/TrainingWarehouseMap.tscn"
const CAFE := "res://Maps/Cafe/CafeMap.tscn"
const HARBOR := "res://Maps/Harbor/HarborMap.tscn"
const ALLEYWAY := "res://Maps/Alleyway/AlleywayMap.tscn"
const STREET := "res://Maps/Street/StreetMap.tscn"
const HONAMI_HOUSE := "res://Maps/HonamiHouse/HonamiHouseMap.tscn"
const CITY_OPS := "res://Maps/CityOperations/CityOperationsMap.tscn"
const HIGHWAY := "res://Maps/Highway/HighwayMap.tscn"
const BOUNTY := "res://Maps/Bounty/BountyMap.tscn"
const INTERROGATION := "res://Maps/Interrogation/InterrogationMap.tscn"

const BATTLE_SCENE := "res://Scripts/Battle/BattleScene.tscn"
const START_MENU := "res://UI/Menus/Start/StartMenu.tscn"
const SANDBOX_MENU := "res://UI/Menus/Sandbox/SandboxMenu.tscn"
const ENDING_CARD := "res://UI/Menus/Ending/EndingCard.tscn"

# Tên hiển thị của map (danh sách save, thông tin nhiệm vụ)
const NAMES := {
	PROLOGUE: "Hẻm vắng (Mở màn)",
	BASE: "Căn cứ Nightcord (Safehouse)",
	WAREHOUSE: "Nhà kho cũ",
	TRAINING: "Phòng tập Nhà kho",
	CAFE: "Quán Cafe",
	HARBOR: "Bến cảng thành phố",
	ALLEYWAY: "Hẻm nhỏ",
	STREET: "Ngã tư đường phố",
	HONAMI_HOUSE: "Phòng khám Honami",
	CITY_OPS: "Khu tác chiến phòng vệ",
	HIGHWAY: "Xa lộ đêm",
	BOUNTY: "Khu phố đêm (Tiền thưởng)",
	INTERROGATION: "Kho Cảnh sát Quốc tế"
}
