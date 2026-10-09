extends RefCounted

const SAVE_PATH := "user://flutterbound_v1.json"
const SAVE_VERSION := 2
const CAMPAIGN_FIRST_STEP := 1
const CAMPAIGN_LAST_STEP := 20
const SAVE_KEYS := [
	"camera_zoom", "health", "energy", "zenny", "scrap", "shards", "bottles",
	"score", "best_run", "repair", "parts", "quest_started", "tron_defeated",
	"completed", "power", "rapid", "armour", "grenade", "weapon_plans", "relics",
	"claimed", "deepest", "music", "sound", "reduced_motion"
]

var camera_zoom: float = 1.0
var health: int = 100
var energy: float = 100.0
var zenny: int = 250
var scrap: int = 0
var shards: int = 0
var bottles: int = 3
var score: int = 0
var best_run: int = 0
var repair: int = 0
var parts: Array = []
var quest_started: bool = false
var tron_defeated: bool = false
var completed: bool = false
var power: int = 0
var rapid: int = 0
var armour: int = 0
var grenade: bool = false
var weapon_plans: bool = false
var relics: int = 0
var claimed: Array = []
var deepest: int = 4
var music: bool = true
var sound: bool = true
var reduced_motion: bool = false

# MML1-wide story state. The legacy vertical-slice fields above remain while
# current gameplay is migrated so existing saves and mechanics keep working.
var campaign_step: int = CAMPAIGN_FIRST_STEP
var story_flags: Dictionary = {}
var story_counters: Dictionary = {}
var story_objectives: Dictionary = {}


func max_health() -> int:
	return 100 + armour * 25


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func story_flag(name: StringName) -> bool:
	return bool(story_flags.get(String(name), false))


func set_story_flag(name: StringName, value: bool = true) -> bool:
	var key := String(name)
	var previous := bool(story_flags.get(key, false))
	if previous == value:
		return false
	story_flags[key] = value
	return true


func story_counter(name: StringName, default_value: int = 0) -> int:
	return int(story_counters.get(String(name), default_value))


func set_story_counter(name: StringName, value: int) -> bool:
	var key := String(name)
	if story_counters.has(key) and int(story_counters[key]) == value:
		return false
	story_counters[key] = value
	return true


func increment_story_counter(name: StringName, amount: int = 1) -> int:
	var value := story_counter(name) + amount
	set_story_counter(name, value)
	return value


func register_story_objective(objective_id: StringName, required: int = 1) -> void:
	var key := String(objective_id)
	var target := maxi(1, required)
	if story_objectives.has(key):
		var existing: Dictionary = story_objectives[key]
		existing["required"] = target
		existing["current"] = mini(int(existing.get("current", 0)), target)
		existing["complete"] = int(existing["current"]) >= target
		story_objectives[key] = existing
		return
	story_objectives[key] = {"current": 0, "required": target, "complete": false}


func report_story_objective(objective_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var key := String(objective_id)
	if not story_objectives.has(key):
		register_story_objective(StringName(key))
	var objective: Dictionary = story_objectives[key]
	if bool(objective.get("complete", false)):
		return false
	var required := maxi(1, int(objective.get("required", 1)))
	var current := mini(required, int(objective.get("current", 0)) + amount)
	objective["current"] = current
	objective["required"] = required
	objective["complete"] = current >= required
	story_objectives[key] = objective
	return true


func story_objective_progress(objective_id: StringName) -> int:
	var objective: Dictionary = story_objectives.get(String(objective_id), {})
	return int(objective.get("current", 0))


func story_objective_required(objective_id: StringName) -> int:
	var objective: Dictionary = story_objectives.get(String(objective_id), {})
	return int(objective.get("required", 0))


func story_objective_complete(objective_id: StringName) -> bool:
	var objective: Dictionary = story_objectives.get(String(objective_id), {})
	return bool(objective.get("complete", false))


func set_campaign_step(step: int) -> bool:
	var next_step := clampi(step, CAMPAIGN_FIRST_STEP, CAMPAIGN_LAST_STEP)
	if campaign_step == next_step:
		return false
	campaign_step = next_step
	return true


func advance_campaign(expected_step: int = -1) -> bool:
	if expected_step >= 0 and campaign_step != expected_step:
		return false
	if campaign_step >= CAMPAIGN_LAST_STEP:
		return false
	return set_campaign_step(campaign_step + 1)


func progression_data() -> Dictionary:
	return {
		"campaign_step": campaign_step,
		"flags": story_flags.duplicate(true),
		"counters": story_counters.duplicate(true),
		"objectives": story_objectives.duplicate(true),
	}


func to_data() -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"progression": progression_data(),
	}
	for key in SAVE_KEYS:
		data[key] = get(key)
	return data


func save_game() -> bool:
	# Browser persistence is already a transactional IndexedDB operation. Closing
	# the final filename lets Godot sync the changed data; renaming after close
	# could leave its persisted filename one save behind.
	var browser: bool = OS.has_feature("web")
	var destination: String = SAVE_PATH if browser else SAVE_PATH + ".tmp"
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(to_data()))
	file.close()
	return true if browser else DirAccess.rename_absolute(destination, SAVE_PATH) == OK


func load_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return false
	var version := int(data.get("version", 0))
	if version not in [1, SAVE_VERSION]:
		return false

	for key in SAVE_KEYS:
		if not data.has(key):
			continue
		var current = get(key)
		if current is Array:
			if data[key] is Array:
				set(key, data[key])
		elif typeof(current) == TYPE_BOOL:
			if typeof(data[key]) == TYPE_BOOL:
				set(key, data[key])
		elif typeof(current) in [TYPE_INT, TYPE_FLOAT]:
			set(key, data[key])

	if version >= 2 and data.get("progression", {}) is Dictionary:
		_load_progression(data.get("progression", {}))
	else:
		_migrate_v1_progression()

	camera_zoom = clampf(camera_zoom, .8, 1.6)
	repair = clampi(repair, 0, 3)
	power = clampi(power, 0, 3)
	rapid = clampi(rapid, 0, 3)
	armour = clampi(armour, 0, 3)
	health = clampi(health, 1, max_health())
	energy = clampf(energy, 0, 100)
	zenny = maxi(0, zenny)
	scrap = maxi(0, scrap)
	shards = maxi(0, shards)
	bottles = maxi(0, bottles)
	deepest = clampi(deepest, 4, 15)
	return true


func _reset_progression() -> void:
	campaign_step = CAMPAIGN_FIRST_STEP
	story_flags.clear()
	story_counters.clear()
	story_objectives.clear()


func _load_progression(data: Dictionary) -> void:
	_reset_progression()
	campaign_step = clampi(int(data.get("campaign_step", CAMPAIGN_FIRST_STEP)), CAMPAIGN_FIRST_STEP, CAMPAIGN_LAST_STEP)
	var saved_flags = data.get("flags", {})
	if saved_flags is Dictionary:
		for key in saved_flags:
			if typeof(saved_flags[key]) == TYPE_BOOL:
				story_flags[String(key)] = bool(saved_flags[key])
	var saved_counters = data.get("counters", {})
	if saved_counters is Dictionary:
		for key in saved_counters:
			if typeof(saved_counters[key]) in [TYPE_INT, TYPE_FLOAT]:
				story_counters[String(key)] = int(saved_counters[key])
	var saved_objectives = data.get("objectives", {})
	if saved_objectives is Dictionary:
		for key in saved_objectives:
			if not saved_objectives[key] is Dictionary:
				continue
			var saved: Dictionary = saved_objectives[key]
			var required := maxi(1, int(saved.get("required", 1)))
			var current := clampi(int(saved.get("current", 0)), 0, required)
			story_objectives[String(key)] = {
				"current": current,
				"required": required,
				"complete": current >= required,
			}


func _migrate_v1_progression() -> void:
	_reset_progression()
	set_story_flag(&"legacy_vertical_slice_save")
	set_story_counter(&"flutter_repair_stage", repair)
	if quest_started:
		set_story_flag(&"flutter_repair_started")
	if tron_defeated:
		set_story_flag(&"feldynaught_defeated")
	if completed:
		set_story_flag(&"flutter_restored")
