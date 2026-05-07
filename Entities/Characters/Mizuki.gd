extends Entity
class_name Mizuki

func _init():
	entity_name = "Mizuki"
	max_hp = 170
	current_hp = 170
	atk = 120
	defense = 60
	res = 8
	spd = 125
	type = "Cute"
	is_character = true
	
	skills = [
		{"name": "Ribbon Bind", "method": "ribbon_bind", "cooldown_turns": 1},
		{"name": "Bitter Secret", "method": "bitter_secret", "cooldown_turns": 2},
		{"name": "Lonely Marionette", "method": "lonely_marionette", "initial_cooldown": 5, "once_per_battle": true},
	]

func ribbon_bind(target: Entity):
	print(entity_name, " trói chặt bằng [Ribbon Bind]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)

func bitter_secret(target: Entity):
	print(entity_name, " thì thầm [Bitter Secret]...")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	target.add_status({"type": "Poison", "duration": 3, "percent": 0.15})

func lonely_marionette(target: Entity):
	print(entity_name, " giật dây [Lonely Marionette]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 2.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Poison", "duration": 4, "percent": 0.2})
