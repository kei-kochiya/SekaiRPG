extends Entity
class_name Honami

func _init():
	entity_name = "Honami"
	max_hp = 400
	current_hp = 400
	atk = 110
	defense = 120
	res = 40
	spd = 95
	type = "Pure"
	is_character = true
	
	skills = [
		{"name": "Gentle Strike", "method": "gentle_strike", "cooldown_turns": 1},
		{"name": "Cleansing Breeze", "method": "cleansing_breeze", "cooldown_turns": 2},
		{"name": "Healing Harmony", "method": "healing_harmony", "cooldown_turns": 3},
	]

# Honami is invincible in this scripted encounter
func take_damage(amount: int, damage_type: String = "physical") -> bool:
	damage_received.emit(0, damage_type)
	return false

func gentle_strike(target: Entity):
	print(entity_name, " sử dụng [Gentle Strike]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)

func cleansing_breeze(target: Entity):
	print(entity_name, " sử dụng [Cleansing Breeze]!")
	# Heals the target (usually the boss in this scenario)
	target.heal(60)
	if not target.active_statuses.is_empty():
		var status = target.active_statuses.pick_random()
		target.remove_statuses([status])

func healing_harmony(_target: Entity):
	print(entity_name, " sử dụng [Healing Harmony]!")
	for ally in allies:
		ally.heal(50)
