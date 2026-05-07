extends Entity
class_name Mafuyu

func _init():
	entity_name = "Mafuyu"
	max_hp = 250
	current_hp = 250
	atk = 130
	defense = 80
	res = 15
	spd = 125
	type = "Mysterious"
	
	skills = [
		{"name": "Shadow Strike", "method": "shadow_strike", "cooldown_turns": 1},
		{"name": "Empty Words", "method": "empty_words", "cooldown_turns": 2},
		{"name": "Lost World", "method": "lost_world", "initial_cooldown": 5, "once_per_battle": true},
	]

# 1. Shadow Strike: Generic damage
func shadow_strike(target: Entity):
	print(entity_name, " sử dụng [Shadow Strike]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)

# 2. Empty Words: Effect based (Bleed)
func empty_words(target: Entity):
	print(entity_name, " mấp máy [Empty Words]...")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	target.add_status({"type": "Bleed", "duration": 3})

# 3. Lost World: Ultimate
func lost_world(target: Entity):
	print(entity_name, " kéo tất cả vào [Lost World]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 2.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Bleed", "duration": 4})
