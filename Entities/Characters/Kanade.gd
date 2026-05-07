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
	type = "Happy"
	is_character = true
	
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

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	# 20% Deflect chance
	if randf() < 0.20:
		print("[DEFLECT] Kanade bẻ cong đường tấn công!")
		var halved_dmg = int(amount * 0.5)
		
		# Try to find an ally to transfer to (don't transfer to self)
		var alive_allies = allies.filter(func(a): return a != self and a.current_hp > 0)
		if not alive_allies.is_empty():
			var transfer_target = alive_allies[randi() % alive_allies.size()]
			print("Sát thương bị chuyển hướng sang ", transfer_target.entity_name)
			transfer_target.take_damage(halved_dmg, damage_type)
			# Kanade takes 0, but we emit signal for feedback (e.g. "0" floating text)
			return super.take_damage(0, damage_type)
		else:
			# No allies to transfer, Kanade takes halved damage
			return super.take_damage(halved_dmg, damage_type)
	
	# Normal case
	return super.take_damage(amount, damage_type)
