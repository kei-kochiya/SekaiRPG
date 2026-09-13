extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho DamageCalculator (tính toán sát thương, thuộc tính, chí mạng).
"""

func test_damage_normal_scaling():
	var attacker = Ichika.new()
	attacker.atk = 60
	attacker.crit_rate = 0.0
	attacker.type = "Pure"
	
	var defender = Guard.new()
	defender.defense = 20
	defender.res = 0
	defender.type = "Pure"
	
	# Case 1: Neutral hit
	var dmg = DamageCalculator.calculate_damage(attacker, defender, 1.0)
	assert_gt(dmg, 0, "Normal attack deals positive damage")
	assert_eq(dmg, 40, "Damage matches ATK - DEF formula (60 - 20 = 40)")

func test_damage_weakness_multiplier():
	var attacker = Ichika.new()
	attacker.atk = 60
	attacker.crit_rate = 0.0
	attacker.type = "Pure"
	
	var defender = Guard.new()
	defender.defense = 20
	defender.res = 0
	defender.type = "Mysterious" # Pure is strong against Mysterious (1.25x)
	
	# Case 2: Weakness hit
	var dmg = DamageCalculator.calculate_damage(attacker, defender, 1.0)
	assert_eq(dmg, 50, "Weakness attack deals 1.25x damage (40 * 1.25 = 50)")

func test_damage_high_defense_minimum_floor():
	var attacker = Ichika.new()
	attacker.atk = 50
	attacker.crit_rate = 0.0
	attacker.type = "Pure"
	
	var defender = Guard.new()
	defender.defense = 9999
	defender.res = 0
	defender.type = "Pure"
	
	# Case 3: Minimum damage floor guarantee
	var dmg = DamageCalculator.calculate_damage(attacker, defender, 1.0)
	assert_gt(dmg, 0, "Attacker still deals minimum non-zero chip damage against impenetrable defense")

func test_damage_critical_hit():
	var attacker = Ichika.new()
	attacker.atk = 60
	attacker.crit_rate = 1.0 # 100% crit
	attacker.crit_dmg = 2.0
	attacker.type = "Pure"
	
	var defender = Guard.new()
	defender.defense = 20
	defender.res = 0
	defender.type = "Pure"
	
	# Case 4: Critical hit
	var detailed = DamageCalculator.calculate_damage_detailed(attacker, defender, 1.0)
	assert_true(detailed["is_crit"], "Damage calculation flagged as critical hit")
	assert_eq(detailed["damage"], 80, "Critical hit applies 2.0x multiplier ((60 - 20) * 2.0 = 80)")
