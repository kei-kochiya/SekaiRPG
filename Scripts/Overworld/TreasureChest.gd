extends Node2D
class_name TreasureChest

"""
Tóm tắt: TreasureChest quản lý rương kho báu tương tác trong Overworld.

Chức năng chính:
- Hiển thị Sprite trạng thái đóng/mở dựa theo dữ liệu đã lưu trong GameManager.opened_chests.
- Khởi tạo vùng tương tác InteractableZone và vật cản StaticBody2D.
- Khi người chơi mở: Phát âm thanh, cộng tiền/vật phẩm, đổi hình ảnh rương mở và hiển thị thông báo.
"""

@export var chest_id: String = "chest_01"
@export var reward_credits: int = 150
@export var reward_item: String = "potion"
@export var reward_item_count: int = 1

var _sprite: Sprite2D
var _zone: InteractableZone

const CLOSED_PATH = "res://Assets/Sprites/chest_closed.svg"
const OPEN_PATH = "res://Assets/Sprites/chest_open.svg"

func _ready():
	z_index = 2
	_setup_visual()
	_setup_collision()
	_setup_interactable()
	_update_state()

func _setup_visual():
	_sprite = Sprite2D.new()
	var tex = load(CLOSED_PATH)
	if tex: _sprite.texture = tex
	_sprite.position = Vector2(0, -10)
	_sprite.scale = Vector2(0.8, 0.8)
	add_child(_sprite)

func _setup_collision():
	var body = StaticBody2D.new()
	body.collision_layer = 2
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(24, 20)
	col.shape = rect
	col.position = Vector2(0, -6)
	body.add_child(col)
	add_child(body)

func _setup_interactable():
	_zone = InteractableZone.new()
	_zone.prompt_text = "Mở rương"
	var col = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 38.0
	col.shape = circle
	_zone.add_child(col)
	_zone.interacted.connect(_on_interacted)
	add_child(_zone)

func _update_state():
	var is_open = GameManager.is_chest_opened(chest_id)
	var path = OPEN_PATH if is_open else CLOSED_PATH
	var tex = load(path)
	if tex: _sprite.texture = tex
	_zone.prompt_text = "Rương trống" if is_open else "Mở rương"

func _on_interacted():
	if GameManager.is_chest_opened(chest_id):
		DialogueManager.play_dialogue([{"text": "Rương này đã được mở rỗng.", "type": "narrator"}])
		return
		
	# Mở rương thành công
	GameManager.open_chest(chest_id)
	var o_tex = load(OPEN_PATH)
	if o_tex: _sprite.texture = o_tex
	_zone.prompt_text = "Rương trống"
	
	GameManager.add_credits(reward_credits)
	if reward_item != "" and reward_item_count > 0:
		GameManager.add_item(reward_item, reward_item_count)
		
	var item_name = GameManager.ITEM_CATALOG.get(reward_item, {}).get("name", reward_item)
	var msg = "Bạn đã mở rương kho báu!\nNhận được: %d Credits" % reward_credits
	if reward_item != "" and reward_item_count > 0:
		msg += " và %d %s" % [reward_item_count, item_name]
	msg += "."
	
	DialogueManager.play_dialogue([{"text": msg, "type": "narrator"}])
