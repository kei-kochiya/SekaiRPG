extends Entity
class_name Mafuyu

func _init():
	entity_name = "Mafuyu"
	max_hp = 450
	current_hp = 450
	atk = 250
	defense = 135
	res = 20
	spd = 150
	type = "Mysterious"
	is_character = true
	
	skills = [
		{"name": "Shadow Strike", "method": "shadow_strike", "cooldown_turns": 1, "target": "enemy"},
		{"name": "Empty Words", "method": "empty_words", "cooldown_turns": 2, "target": "enemy"},
		{"name": "Lost World", "method": "lost_world", "initial_cooldown": 5, "once_per_battle": true, "target": "all_enemies"},
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

# 3. Lost World: Ultimate (AoE)
func lost_world(_target: Entity):
	print(entity_name, " kéo tất cả vào [Lost World]!")
	for e in enemies:
		if e.current_hp > 0:
			var multiplier = TypeChart.get_multiplier(self.type, e.type)
			var massive_dmg = int(self.atk * 2.5 * multiplier)
			e.take_damage(massive_dmg, "pure")
			e.add_status({"type": "Bleed", "duration": 4})
