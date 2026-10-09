extends RefCounted

const DATA_PATH := "res://data/mml1_campaign.json"

var steps: Array = []
var steps_by_id: Dictionary = {}
var load_error: String = ""


func _init() -> void:
	reload()


func reload(path: String = DATA_PATH) -> bool:
	steps.clear()
	steps_by_id.clear()
	load_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		load_error = "Could not open campaign data: " + path
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		load_error = "Campaign data is not a JSON object."
		return false
	var source_steps = parsed.get("steps", [])
	if not source_steps is Array:
		load_error = "Campaign data has no steps array."
		return false
	for entry in source_steps:
		if not entry is Dictionary:
			continue
		var step: Dictionary = entry.duplicate(true)
		var number := int(step.get("step", 0))
		var id := String(step.get("id", ""))
		if number <= 0 or id.is_empty():
			continue
		steps.append(step)
		steps_by_id[id] = step
	steps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("step", 0)) < int(b.get("step", 0)))
	if steps.size() != 20:
		load_error = "Expected 20 MML1 campaign steps, found %d." % steps.size()
		return false
	return true


func get_step(number: int) -> Dictionary:
	for step in steps:
		if int(step.get("step", 0)) == number:
			return step.duplicate(true)
	return {}


func get_step_by_id(id: StringName) -> Dictionary:
	var key := String(id)
	if not steps_by_id.has(key):
		return {}
	return (steps_by_id[key] as Dictionary).duplicate(true)


func current(progression) -> Dictionary:
	if progression == null:
		return {}
	return get_step(int(progression.campaign_step))


func next(progression) -> Dictionary:
	if progression == null:
		return {}
	return get_step(int(progression.campaign_step) + 1)
