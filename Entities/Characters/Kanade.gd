extends Entity
class_name Kanade

func _init():
	entity_name = "Kanade"
	max_hp = 70
	current_hp = 70
	atk = 180 # Kính vỡ DMG to
	defense = 30
	res = 5
	spd = 90
	type = "Cool"
	
	skills = [
		{"name": "Resonance", "method": "resonance", "cooldown_turns": 1},
		{"name": "Soundless Voice", "method": "soundless_voice", "cooldown_turns": 2},
		{"name": "Salvation Song", "method": "salvation_song", "initial_cooldown": 5, "once_per_battle": true},
	]

func resonance(target: Entity):
	print(entity_name, " ngân lên [Resonance]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	var scaled_dmg = int(dmg * 1.5)
	target.take_damage(scaled_dmg)

func soundless_voice(target: Entity):
	print(entity_name, " bóp nghẹt bằng [Soundless Voice]...")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	target.add_status({"type": "Stun", "duration": 1})

func salvation_song(target: Entity):
	print(entity_name, " cất tiếng hát [Salvation Song]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 3.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Stun", "duration": 2})
