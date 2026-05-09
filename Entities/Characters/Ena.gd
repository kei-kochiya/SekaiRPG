extends Entity
class_name Ena

func _init():
	entity_name = "Ena"
	max_hp = 150
	current_hp = 150
	atk = 80
	defense = 90
	res = 12
	spd = 115
	type = "Happy"
	is_character = true
	
	skills = [
		{"name": "Brush Stroke", "method": "brush_stroke", "cooldown_turns": 1, "target": "enemy"},
		{"name": "Toxic Criticism", "method": "toxic_criticism", "cooldown_turns": 2, "target": "enemy"},
		{"name": "Masterpiece", "method": "masterpiece", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy"},
	]

func brush_stroke(target: Entity):
	print(entity_name, " vung [Brush Stroke]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)

func toxic_criticism(target: Entity):
	print(entity_name, " tung ra [Toxic Criticism]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	target.add_status({"type": "Poison", "duration": 3, "percent": 0.15})

func masterpiece(target: Entity):
	print(entity_name, " hoàn thành [Masterpiece]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 2.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Poison", "duration": 4, "percent": 0.2})
	
	# Heal ally with lowest absolute HP
	var lowest_ally = null
	var lowest_hp = 999999
	for ally in allies:
		if ally.current_hp > 0 and ally.current_hp < lowest_hp:
			lowest_hp = ally.current_hp
			lowest_ally = ally
			
	if lowest_ally != null:
		var heal_amount = int(self.atk * 1.5)
		print(entity_name, " hồi phục cho ", lowest_ally.entity_name)
		lowest_ally.heal(heal_amount)
