extends Node
class_name Entity

signal hp_changed(new_hp: int, max_hp: int)
signal died()
signal cooldown_updated(skill_name: String, turns_left: int)
signal status_changed(statuses: Array)
signal damage_received(amount: int, damage_type: String)

@export var entity_name: String = "Unknown"
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var atk: int = 10
@export var defense: int = 10
@export var res: int = 10
@export var spd: int = 10
@export var type: String = "None"
@export var skill_points: int = 0
@export var level: int = 1
@export var current_exp: int = 0
@export var next_level_exp: int = 100

# Battle context references (injected by Main.gd)
var allies: Array = []
var enemies: Array = []

# Skills list — override in subclasses, used by CommandMenu to build buttons
# Format: [{"name": "Skill Name", "method": "method_name", "cooldown_turns": 3, "initial_cooldown": 5, "once_per_battle": true}, ...]
var skills: Array = []

var active_statuses: Array = []
var cooldowns: Dictionary = {}
var stat_caps: Dictionary = {
	"max_hp": 2000,
	"atk": 500,
	"defense": 300,
	"spd": 250
}

# --- Core combat methods ---

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	
	hp_changed.emit(current_hp, max_hp)
	damage_received.emit(amount, damage_type)
	
	if current_hp == 0:
		died.emit()
		return true
	return false

func heal(amount: int):
	var actual = min(amount, max_hp - current_hp)
	if actual > 0:
		current_hp += actual
		hp_changed.emit(current_hp, max_hp)
		damage_received.emit(actual, "heal")

# --- Status helpers (emit signal so UI reacts) ---

func add_status(status: Dictionary):
	active_statuses.append(status)
	status_changed.emit(active_statuses.duplicate())

func remove_statuses(to_remove: Array):
	for s in to_remove:
		active_statuses.erase(s)
	if not to_remove.is_empty():
		status_changed.emit(active_statuses.duplicate())

# --- Skill availability (override in subclasses for special conditions) ---

func can_use_skill(skill_name: String) -> bool:
	return CooldownManager.is_skill_ready(self, skill_name)
