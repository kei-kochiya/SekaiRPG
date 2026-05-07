extends Entity
class_name Ichika

func _init():
	entity_name = "Ichika"
	max_hp = 150
	current_hp = 150
	atk = 150
	defense = 80
	res = 20
	spd = 100
	type = "Cool"
	is_character = true
	
	skills = [
		{"name": "Metal Cut", "method": "metal_cut", "cooldown_turns": 1},
		{"name": "Bleeding Edge", "method": "bleeding_edge", "cooldown_turns": 2},
		{"name": "Shadow Blade", "method": "shadow_blade", "initial_cooldown": 5, "once_per_battle": true},
	]

# Override: Shadow Blade blocked when HP <= 1
func can_use_skill(skill_name: String) -> bool:
	if not CooldownManager.is_skill_ready(self, skill_name):
		return false
	if skill_name == "shadow_blade" and current_hp <= 1:
		return false
	return true

# 1. Metal Cut: Standard damage (DEF + RES apply normally)
func metal_cut(target: Entity):
	print(entity_name, " sử dụng [Metal Cut]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)

# 2. Bleeding Edge: Effect based (Bleed)
func bleeding_edge(target: Entity):
	print(entity_name, " sử dụng [Bleeding Edge]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	target.add_status({"type": "Bleed", "duration": 3})

# 3. Shadow Blade: ATK×3 ignoring DEF+RES, costs 15% max HP (can't kill self)
func shadow_blade(target: Entity):
	if current_hp <= 1:
		print(entity_name, " không đủ sinh lực để dùng [Shadow Blade]!")
		return
	
	print(entity_name, " giải phóng [Shadow Blade] cực hạn!")
	var massive_dmg = self.atk * 3
	var self_dmg = int(self.max_hp * 0.15)
	
	# Clamp: self-damage can only reduce HP to 1, never kill
	self_dmg = min(self_dmg, current_hp - 1)
	
	target.take_damage(massive_dmg, "pure")
	self.take_damage(self_dmg, "pure")
