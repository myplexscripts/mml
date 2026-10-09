extends RefCounted

const Progression = preload("res://scripts/legends/progression.gd")
const SAVE_PATH := "user://flutterbound_v1.json"
const SAVE_VERSION := 2
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

# New MML1-wide story state. The legacy fields above remain while the current
# vertical slice is migrated so old saves and existing gameplay keep working.
var progression = Progression.new()


func max_health() -> int:
	return 100 + armour * 25


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func story_flag(name: StringName) -> bool:
	return progression.has_flag(name)


func set_story_flag(name: StringName, value: bool = true) -> bool:
	return progression.set_flag(name, value)


func story_counter(name: StringName, default_value: int = 0) -> int:
	return progression.get_counter(name, default_value)


func set_story_counter(name: StringName, value: int) -> bool:
	return progression.set_counter(name, value)


func to_data() -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"progression": progression.to_data(),
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
		progression.load_data(data.get("progression", {}))
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


func _migrate_v1_progression() -> void:
	progression.reset()
	progression.set_flag(&"legacy_vertical_slice_save")
	progression.set_counter(&"flutter_repair_stage", repair)
	if quest_started:
		progression.set_flag(&"flutter_repair_started")
	if tron_defeated:
		progression.set_flag(&"feldynaught_defeated")
	if completed:
		progression.set_flag(&"flutter_restored")
