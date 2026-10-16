extends SceneTree

var game
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("run")

func ticks(count: int = 3) -> void:
	for i in range(count): await physics_frame

func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		push_error("MIDGAME: " + message)

func has_action(action: String) -> bool:
	for item in game.world.interactables:
		if String(item.get("action", "")) == action: return true
	return false

func has_enemy(kind: String) -> bool:
	for enemy in game.enemies:
		if is_instance_valid(enemy) and String(enemy.kind) == kind: return true
	return false

func run() -> void:
	var Midgame = load("res://scripts/legends/midgame_campaign.gd")
	check(Midgame != null, "midgame controller loads")
	if Midgame == null:
		print("MIDGAME CHECKS: %d passed, %d failed" % [passed, failed])
		quit(1)
		return
	game = Midgame.new()
	root.add_child(game)
	await ticks(3)
	game.mode = "game"

	game.state.set_campaign_step(7)
	game.build_area("yass_plains",7,Vector3(0,0,11))
	await ticks(4)
	check(has_enemy("marlwolf"), "Yass Plains contains Marlwolf")
	check(has_action("yass_exit"), "Yass Plains has the excavation exit")

	game.state.set_campaign_step(8)
	game.build_area("cardon_approach",8,Vector3(-16,0,0))
	await ticks(4)
	check(game.npcs.any(func(n): return n.person == "Roll"), "Roll accompanies the support-car assault")
	check(has_action("cardon_assault_finish"), "support-car route reaches the Sub-Gate")

	game.state.set_campaign_step(9)
	game.build_area("cardon_subgate",9,Vector3(0,0,12))
	await ticks(4)
	check(has_action("cardon_key_1") and has_action("cardon_key_2") and has_action("cardon_key_3"), "Cardon Sub-Gate exposes three Starter Keys")
	check(not has_action("yellow_refractor"), "Yellow Refractor remains sealed before all three keys")
	for name in ["cardon_key_1","cardon_key_2","cardon_key_3"]: game.state.set_story_flag(StringName(name))
	game.state.set_story_counter(&"cardon_starter_keys",3)
	game.build_area("cardon_subgate",9,Vector3(0,0,2))
	await ticks(4)
	check(has_action("yellow_refractor"), "three Cardon keys expose the Yellow Refractor")

	game.state.set_story_flag(&"yellow_refractor_acquired")
	game.state.set_campaign_step(10)
	game.build_area("uptown",10,Vector3(0,0,10))
	await ticks(4)
	check(has_action("repair_wily_boat"), "Uptown contains Wily's boat repair objective")

	game.state.set_campaign_step(11)
	game.build_area("lake_jyun",11,Vector3(0,0,7))
	await ticks(4)
	check(has_enemy("balcon"), "Lake Jyun contains Balcon Gelede")
	check(game.lake_boat_integrity == 100, "boat battle starts at full integrity")

	game.state.set_campaign_step(12)
	game.state.story_flags.erase("red_refractor_acquired")
	game.state.story_flags.erase("garudoriten_defeated")
	game.state.set_story_counter(&"lake_starter_keys",3)
	for name in ["lake_key_1","lake_key_2","lake_key_3"]: game.state.set_story_flag(StringName(name))
	game.build_area("lake_subgate",12,Vector3(0,0,10))
	await ticks(4)
	check(has_action("red_refractor"), "Lake Sub-Gate exposes the Red Refractor after three keys")
	game.state.set_story_flag(&"red_refractor_acquired")
	game.build_area("lake_subgate",12,Vector3(0,0,-10))
	await ticks(4)
	check(has_enemy("garudoriten"), "Garudoriten appears only on the return route")
	check(has_action("lake_exit_locked"), "Garudoriten blocks the Sub-Gate exit")

	game.state.set_campaign_step(13)
	game.build_area("flutter_restart",13,Vector3(0,0,7))
	await ticks(4)
	check(has_action("restart_flutter"), "Flutter engine room accepts the Red Refractor")

	game.state.set_campaign_step(14)
	game.state.story_flags.erase("clozer_generator_on")
	game.state.story_flags.erase("karumuna_defeated")
	game.state.set_story_counter(&"clozer_id_cards",0)
	game.build_area("clozer_subgate",14,Vector3(0,0,11))
	await ticks(4)
	check(has_action("clozer_generator"), "Clozer Sub-Gate begins with generator dependency")
	check(not has_action("clozer_id_1"), "ID cards remain inactive before generator power")
	game.state.set_story_flag(&"clozer_generator_on")
	game.build_area("clozer_subgate",14,Vector3(-13,0,-6))
	await ticks(4)
	check(has_enemy("karumuna"), "powering Clozer wakes Karumuna Bash")
	check(has_action("clozer_id_1") and has_action("clozer_id_2") and has_action("clozer_id_3"), "generator enables all three ID-card routes")
	game.state.set_story_flag(&"karumuna_defeated")
	for name in ["clozer_id_1","clozer_id_2","clozer_id_3"]: game.state.set_story_flag(StringName(name))
	game.state.set_story_counter(&"clozer_id_cards",3)
	game.build_area("clozer_subgate",14,Vector3(0,0,8))
	await ticks(4)
	check(has_action("clozer_control"), "completed Clozer state retains the Main Gate console")

	print("MIDGAME CHECKS: %d passed, %d failed" % [passed, failed])
	game.audio.shutdown()
	game.queue_free()
	game = null
	await ticks(8)
	quit(1 if failed else 0)
