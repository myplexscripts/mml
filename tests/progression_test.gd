extends SceneTree

var passed: int = 0
var failed: int = 0


func _init() -> void:
	call_deferred("run")


func check(ok: bool, text: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("CHECK: " + text)


func run() -> void:
	var State = load("res://scripts/legends/state.gd")
	var progress = State.new()

	check(progress.campaign_step == 1, "campaign starts at Ocean Tower")
	check(progress.set_story_flag(&"ocean_tower_cleared"), "new story flag changes state")
	check(progress.story_flag(&"ocean_tower_cleared"), "story flag can be queried")
	check(not progress.set_story_flag(&"ocean_tower_cleared"), "setting same flag is idempotent")
	check(progress.increment_story_counter(&"starter_keys") == 1, "story counter increments")

	progress.register_story_objective(&"collect_cardon_starter_keys", 3)
	progress.report_story_objective(&"collect_cardon_starter_keys", 2)
	check(progress.story_objective_progress(&"collect_cardon_starter_keys") == 2, "objective tracks partial progress")
	check(not progress.story_objective_complete(&"collect_cardon_starter_keys"), "partial objective remains active")
	progress.report_story_objective(&"collect_cardon_starter_keys")
	check(progress.story_objective_complete(&"collect_cardon_starter_keys"), "objective completes at requirement")
	check(progress.story_objective_progress(&"collect_cardon_starter_keys") == 3, "objective progress clamps to requirement")

	check(progress.advance_campaign(1), "campaign advances from expected step")
	check(progress.campaign_step == 2, "campaign is now Cardon crash")
	check(not progress.advance_campaign(1), "stale event cannot double-advance campaign")

	var saved: Dictionary = progress.progression_data()
	var restored = State.new()
	restored._load_progression(saved)
	check(restored.campaign_step == 2, "campaign step survives round trip")
	check(restored.story_flag(&"ocean_tower_cleared"), "flags survive round trip")
	check(restored.story_counter(&"starter_keys") == 1, "counters survive round trip")
	check(restored.story_objective_complete(&"collect_cardon_starter_keys"), "objectives survive round trip")

	var campaign_file := FileAccess.open("res://data/mml1_campaign.json", FileAccess.READ)
	check(campaign_file != null, "canonical campaign data exists")
	if campaign_file:
		var campaign = JSON.parse_string(campaign_file.get_as_text())
		check(campaign is Dictionary, "campaign data is valid JSON")
		if campaign is Dictionary:
			var steps: Array = campaign.get("steps", [])
			check(steps.size() == 20, "campaign contains all twenty reference-bible steps")
			if steps.size() == 20:
				check(String(steps[0].get("id", "")) == "ocean_tower_escape", "campaign begins at Ocean Tower")
				check(String(steps[19].get("id", "")) == "kattelox_departure", "campaign ends with Kattelox departure")

	var state = State.new()
	state.set_story_flag(&"junk_store_owner_rescued")
	state.set_story_counter(&"subcity_keys", 2)
	state.set_campaign_step(3)
	var state_data: Dictionary = state.to_data()
	check(int(state_data.get("version", 0)) == 2, "save schema upgraded to version two")
	check(state_data.get("progression", {}) is Dictionary, "save includes progression payload")
	check(state.story_flag(&"junk_store_owner_rescued"), "state exposes story flag API")
	check(state.story_counter(&"subcity_keys") == 2, "state exposes story counter API")

	print("PROGRESSION CHECKS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
