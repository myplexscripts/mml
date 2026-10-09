extends RefCounted

signal flag_changed(flag: String, value: bool)
signal counter_changed(counter: String, value: int)
signal objective_progressed(objective_id: String, current: int, required: int)
signal objective_completed(objective_id: String)
signal campaign_step_changed(step: int)

const CAMPAIGN_FIRST_STEP := 1
const CAMPAIGN_LAST_STEP := 20

var campaign_step: int = CAMPAIGN_FIRST_STEP
var flags: Dictionary = {}
var counters: Dictionary = {}
var objectives: Dictionary = {}


func reset() -> void:
	campaign_step = CAMPAIGN_FIRST_STEP
	flags.clear()
	counters.clear()
	objectives.clear()


func has_flag(flag: StringName) -> bool:
	return bool(flags.get(String(flag), false))


func set_flag(flag: StringName, value: bool = true) -> bool:
	var key := String(flag)
	var previous := bool(flags.get(key, false))
	if previous == value:
		return false
	flags[key] = value
	flag_changed.emit(key, value)
	return true


func clear_flag(flag: StringName) -> bool:
	return set_flag(flag, false)


func get_counter(counter: StringName, default_value: int = 0) -> int:
	return int(counters.get(String(counter), default_value))


func set_counter(counter: StringName, value: int) -> bool:
	var key := String(counter)
	if counters.has(key) and int(counters[key]) == value:
		return false
	counters[key] = value
	counter_changed.emit(key, value)
	return true


func increment_counter(counter: StringName, amount: int = 1) -> int:
	var value := get_counter(counter) + amount
	set_counter(counter, value)
	return value


func register_objective(objective_id: StringName, required: int = 1) -> void:
	var key := String(objective_id)
	var target := maxi(1, required)
	if objectives.has(key):
		var existing: Dictionary = objectives[key]
		existing["required"] = target
		existing["current"] = mini(int(existing.get("current", 0)), target)
		existing["complete"] = int(existing["current"]) >= target
		objectives[key] = existing
		return
	objectives[key] = {"current": 0, "required": target, "complete": false}


func report_objective(objective_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	var key := String(objective_id)
	if not objectives.has(key):
		register_objective(key)
	var objective: Dictionary = objectives[key]
	if bool(objective.get("complete", false)):
		return false
	var required := maxi(1, int(objective.get("required", 1)))
	var current := mini(required, int(objective.get("current", 0)) + amount)
	objective["current"] = current
	objective["required"] = required
	objective["complete"] = current >= required
	objectives[key] = objective
	objective_progressed.emit(key, current, required)
	if bool(objective["complete"]):
		objective_completed.emit(key)
	return true


func objective_progress(objective_id: StringName) -> int:
	var objective: Dictionary = objectives.get(String(objective_id), {})
	return int(objective.get("current", 0))


func objective_required(objective_id: StringName) -> int:
	var objective: Dictionary = objectives.get(String(objective_id), {})
	return int(objective.get("required", 0))


func is_objective_complete(objective_id: StringName) -> bool:
	var objective: Dictionary = objectives.get(String(objective_id), {})
	return bool(objective.get("complete", false))


func set_campaign_step(step: int) -> bool:
	var next_step := clampi(step, CAMPAIGN_FIRST_STEP, CAMPAIGN_LAST_STEP)
	if campaign_step == next_step:
		return false
	campaign_step = next_step
	campaign_step_changed.emit(campaign_step)
	return true


func advance_campaign(expected_step: int = -1) -> bool:
	if expected_step >= 0 and campaign_step != expected_step:
		return false
	if campaign_step >= CAMPAIGN_LAST_STEP:
		return false
	return set_campaign_step(campaign_step + 1)


func to_data() -> Dictionary:
	return {
		"campaign_step": campaign_step,
		"flags": flags.duplicate(true),
		"counters": counters.duplicate(true),
		"objectives": objectives.duplicate(true),
	}


func load_data(data: Dictionary) -> void:
	reset()
	campaign_step = clampi(int(data.get("campaign_step", CAMPAIGN_FIRST_STEP)), CAMPAIGN_FIRST_STEP, CAMPAIGN_LAST_STEP)
	var saved_flags = data.get("flags", {})
	if saved_flags is Dictionary:
		for key in saved_flags:
			if typeof(saved_flags[key]) == TYPE_BOOL:
				flags[String(key)] = bool(saved_flags[key])
	var saved_counters = data.get("counters", {})
	if saved_counters is Dictionary:
		for key in saved_counters:
			if typeof(saved_counters[key]) in [TYPE_INT, TYPE_FLOAT]:
				counters[String(key)] = int(saved_counters[key])
	var saved_objectives = data.get("objectives", {})
	if saved_objectives is Dictionary:
		for key in saved_objectives:
			if not saved_objectives[key] is Dictionary:
				continue
			var saved: Dictionary = saved_objectives[key]
			var required := maxi(1, int(saved.get("required", 1)))
			var current := clampi(int(saved.get("current", 0)), 0, required)
			objectives[String(key)] = {
				"current": current,
				"required": required,
				"complete": current >= required,
			}
