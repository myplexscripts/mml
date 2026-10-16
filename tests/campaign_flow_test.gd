extends SceneTree

var passed := 0
var failed := 0

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("CHECK: " + message)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var Campaign = load("res://scripts/legends/campaign_main.gd")
	var State = load("res://scripts/legends/state.gd")
	check(Campaign != null, "campaign controller loads")
	check(State != null, "state loads")
	if Campaign != null:
		for step in range(1,21):
			var entry: Dictionary = Campaign.entry_for_step(step)
			check(not String(entry.get("area","")).is_empty(), "step %d has an area" % step)
			check(int(entry.get("depth",0)) == step, "step %d keeps canonical step number" % step)
			check(not Campaign.stage_name(step).is_empty(), "step %d has a display name" % step)
		check(String(Campaign.entry_for_step(1).area) == "ocean_tower", "campaign begins at Ocean Tower")
		check(String(Campaign.entry_for_step(20).area) == "kattelox_departure", "campaign ends at Kattelox departure")
	if State != null:
		var state = State.new()
		state.set_campaign_step(1)
		state.set_story_flag(&"blue_refractor_acquired")
		check(state.story_flag(&"blue_refractor_acquired"), "opening refractor state is persisted")
		state.set_campaign_step(20)
		check(state.campaign_step == 20, "state accepts final campaign step")
	print("CAMPAIGN CHECKS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
