extends "res://scripts/legends/campaign_main.gd"

const CampaignMissile = preload("res://scripts/legends/campaign_missile.gd")

var support_fire_timer: float = 0.0
var lake_missile_timer: float = 0.0
var lake_boat_integrity: int = 100
var lake_warning_level: int = 0


func build_area(target: String, level: int, spawn: Vector3) -> void:
	super.build_area(target, level, spawn)
	if target == "lake_jyun":
		lake_boat_integrity = 100
		lake_missile_timer = 1.8
		lake_warning_level = 0
	if target == "cardon_approach":
		support_fire_timer = .65


func _campaign_tick() -> void:
	super._campaign_tick()
	var delta := get_process_delta_time()
	if area == "cardon_approach": _support_car_tick(delta)
	elif area == "lake_jyun": _lake_battle_tick(delta)


func _support_car_tick(delta: float) -> void:
	support_fire_timer -= delta
	if support_fire_timer > 0.0: return
	support_fire_timer = 1.25
	var support_position := Vector3(-12, .9, 5)
	var target = nearest_enemy(support_position, 18.0)
	if target == null: return
	var direction := support_position.direction_to(target.position + Vector3.UP * .8)
	shoot(support_position, direction * 10.5, false, 13)
	spark(support_position, Color("ffe6ad"), .15, .18)
	if not state.story_flag(&"support_car_first_shot"):
		state.set_story_flag(&"support_car_first_shot")
		toast("Roll: I'll cover you from the support car. Push through to the Sub-Gate!")


func _lake_battle_tick(delta: float) -> void:
	if state.story_flag(&"balcon_defeated"): return
	var boss = null
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.defeated and enemy.kind == "balcon":
			boss = enemy
			break
	if boss == null: return
	lake_missile_timer -= delta
	if lake_missile_timer <= 0.0:
		lake_missile_timer = .95 if boss.health < boss.max_health / 2 else 1.35
		spawn_lake_missile(boss.position + Vector3.UP * 1.2)


func spawn_lake_missile(at: Vector3) -> void:
	var missile = CampaignMissile.new()
	missile.game = self
	missile.position = at
	missile.target = Vector3(randf_range(-3.2,3.2), .25, randf_range(-2.5,7.5))
	missile.velocity = at.direction_to(missile.target) * 2.0
	world.add_child(missile)


func lake_missile_hit(at: Vector3) -> void:
	lake_boat_integrity = maxi(0, lake_boat_integrity - 12)
	explosion(at)
	audio.effect("explosion", .85)
	if lake_boat_integrity <= 0:
		state.health = 0
		toast("Roll: The boat can't take any more hits!")
		call_deferred("knock_out")
		return
	var next_warning := 1 if lake_boat_integrity <= 70 else 0
	if lake_boat_integrity <= 40: next_warning = 2
	if lake_boat_integrity <= 20: next_warning = 3
	if next_warning > lake_warning_level:
		lake_warning_level = next_warning
		toast("Roll: Boat integrity %d%%. Shoot down those incoming missiles!" % lake_boat_integrity)


func lake_missile_intercepted(at: Vector3) -> void:
	explosion(at)
	audio.effect("hit", 1.25)
	state.score += 35
	floating(at + Vector3.UP * .4, "+35", Color("ffe7a5"))


func execute_interaction(item: Dictionary) -> void:
	var action := String(item.action)
	match action:
		"yass_exit":
			if not state.story_flag(&"marlwolf_defeated"):
				toast("Marlwolf is still controlling the excavation.")
				return
			state.set_campaign_step(8)
			state.save_game()
			travel("cardon_approach",8,Vector3(-16,0,0))
		"cardon_assault_finish":
			if _living_enemy_count() > 0:
				toast("Roll: The approach isn't clear yet!")
				return
			state.set_story_flag(&"cardon_approach_cleared")
			state.set_campaign_step(9)
			state.save_game()
			travel("cardon_subgate",9,Vector3(0,0,12))
		"cardon_key_1", "cardon_key_2", "cardon_key_3":
			_take_starter_key(action, &"cardon_starter_keys", "Cardon")
		"spring_set":
			state.set_story_flag(&"spring_set_found")
			state.set_story_flag(&"jump_springs_unlocked")
			state.save_game()
			audio.effect("item")
			dialogue("Roll",["A Spring Set! I can turn these into Jump Springs. They'll help with raised ruin routes later on."])
		"grenade_kit":
			state.set_story_flag(&"grenade_kit_found")
			state.weapon_plans = true
			state.save_game()
			audio.effect("item")
			dialogue("Roll",["This is a Grenade Kit. I can use it as the basis for the Grenade Arm at the workshop."])
		"yellow_refractor":
			if state.story_counter(&"cardon_starter_keys") < 3:
				toast("Three Starter Keys are required to drop the refractor barrier.")
				return
			if state.story_flag(&"yellow_refractor_acquired"): return
			state.set_story_flag(&"yellow_refractor_acquired")
			state.set_story_flag(&"cardon_subgate_cleared")
			state.set_campaign_step(10)
			state.save_game()
			audio.effect("item")
			dialogue("Roll",["We got the Yellow Refractor. This one isn't for the Flutter. It should have enough output to help me get Wily's remaining boat running."],"midgame_uptown")
		"repair_wily_boat":
			if not state.story_flag(&"yellow_refractor_acquired"):
				toast("Roll: We need a stronger refractor before I can repair this boat.")
				return
			if state.story_flag(&"wily_boat_repaired"):
				travel("lake_jyun",11,Vector3(0,0,7))
				return
			state.set_story_flag(&"wily_boat_repaired")
			state.set_campaign_step(11)
			state.save_game()
			dialogue("Roll",["That did it. Wily's boat is running again.","Lake Jyun is the only route to the next Sub-Gate. Stay on the deck and watch the sky. The Bonnes know we're coming."],"midgame_lake")
		"lake_key_1", "lake_key_2", "lake_key_3":
			_take_starter_key(action, &"lake_starter_keys", "Lake Jyun")
		"red_refractor":
			if state.story_counter(&"lake_starter_keys") < 3:
				toast("The Red Refractor is still sealed behind the Starter Key lock.")
				return
			state.set_story_flag(&"red_refractor_acquired")
			state.save_game()
			audio.effect("item")
			dialogue("Roll",["That's it, MegaMan. The Red Refractor has enough power to restart the Flutter's engines.","Wait... the pedestal behind you just moved."],"midgame_garudoriten")
		"lake_exit_locked":
			toast("Garudoriten is blocking the return route. Its eye opens after it attacks.")
		"lake_exit":
			if not state.story_flag(&"garudoriten_defeated"):
				toast("The return route is blocked.")
				return
			state.set_campaign_step(13)
			state.save_game()
			travel("flutter_restart",13,Vector3(0,0,7))
		"restart_flutter":
			if not state.story_flag(&"red_refractor_acquired"):
				toast("The main engine still needs the Red Refractor.")
				return
			if state.story_flag(&"flutter_flight_unlocked"): return
			state.set_story_flag(&"flutter_flight_unlocked")
			state.set_story_flag(&"flutter_engine_restarted")
			state.set_campaign_step(14)
			state.save_game()
			dialogue("Roll",["Engine pressure is stable. The Flutter can fly again!","That means we can finally reach the elevated entrance to the Clozer Woods Sub-Gate."],"midgame_clozer")
		"clozer_generator":
			if state.story_flag(&"clozer_generator_on"):
				toast("The Sub-Gate generator is online.")
				return
			state.set_story_flag(&"clozer_generator_on")
			state.save_game()
			dialogue("Roll",["Power is back. The ID-card readers and central control system should be online now.","Watch the elevator chamber. Something big just woke up down there."],"midgame_refresh_clozer")
		"clozer_id_1", "clozer_id_2", "clozer_id_3":
			if not state.story_flag(&"clozer_generator_on"):
				toast("The ID-card reader has no power.")
				return
			if state.story_flag(StringName(action)): return
			state.set_story_flag(StringName(action))
			var count := state.increment_story_counter(&"clozer_id_cards")
			state.save_game()
			audio.effect("item")
			toast("ID Card recovered / %d of 3" % count)
			call_deferred("_refresh_current_area")
		"clozer_control":
			if not state.story_flag(&"clozer_generator_on"):
				toast("Restore the generator before using the control system.")
				return
			if state.story_counter(&"clozer_id_cards") < 3:
				toast("The control system requires all three ID Cards.")
				return
			if not state.story_flag(&"karumuna_defeated"):
				toast("Karumuna Bash is still controlling the elevator chamber.")
				return
			state.set_story_flag(&"guidance_unit_acquired")
			state.set_story_flag(&"main_gate_open")
			state.set_campaign_step(15)
			state.save_game()
			dialogue("Roll",["The Guidance Unit is responding. The Main Gate has opened beneath Kattelox.","We're heading back to the Flutter... and the Bonnes are already in the air."],"midgame_to_airbattle")
		_:
			super.execute_interaction(item)


func _take_starter_key(flag_name: String, counter_name: StringName, label: String) -> void:
	var flag := StringName(flag_name)
	if state.story_flag(flag): return
	state.set_story_flag(flag)
	var count := state.increment_story_counter(counter_name)
	state.save_game()
	audio.effect("item")
	toast("%s Starter Key / %d of 3" % [label, count])
	call_deferred("_refresh_current_area")


func _refresh_current_area() -> void:
	if not active(): return
	var at := player.position
	build_area(area, depth, at)


func _living_enemy_count() -> int:
	var total := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.defeated: total += 1
	return total


func enemy_defeated(enemy) -> void:
	var kind := String(enemy.kind)
	super.enemy_defeated(enemy)
	match kind:
		"marlwolf":
			state.set_story_flag(&"marlwolf_defeated")
			state.set_story_flag(&"class_a_licence")
			state.save_game()
			dialogue("Roll",["Marlwolf is down! Amelia just transmitted the Class A licence.","The pirates were digging toward the Cardon Sub-Gate. Let's follow their route while it's open."])
		"balcon":
			state.set_story_flag(&"balcon_defeated")
			state.set_story_flag(&"lake_crossing_complete")
			state.set_campaign_step(12)
			state.save_game()
			_clear_lake_missiles()
			dialogue("Roll",["Balcon Gelede is going down. The boat survived!","I can see the Lake Sub-Gate landing ahead. Get ready to disembark."],"midgame_lake_subgate")
		"garudoriten":
			state.set_story_flag(&"garudoriten_defeated")
			state.set_story_flag(&"lake_subgate_cleared")
			state.save_game()
			dialogue("Roll",["Garudoriten is finished. Bring the Red Refractor home. The Flutter finally has a chance to fly again."],"midgame_refresh_lake")
		"karumuna":
			state.set_story_flag(&"karumuna_defeated")
			state.save_game()
			dialogue("Roll",["Karumuna Bash is down. Finish collecting the ID Cards, then return to the main control console."])


func _clear_lake_missiles() -> void:
	if not is_instance_valid(world): return
	for child in world.get_children():
		if child is StaticBody3D and child.get_script() == CampaignMissile:
			child.queue_free()


func dialogue_done(after: String) -> void:
	match after:
		"midgame_uptown":
			resume_game();travel("uptown",10,Vector3(0,0,10))
		"midgame_lake":
			resume_game();travel("lake_jyun",11,Vector3(0,0,7))
		"midgame_lake_subgate":
			resume_game();travel("lake_subgate",12,Vector3(0,0,12))
		"midgame_garudoriten":
			resume_game();build_area("lake_subgate",12,Vector3(0,0,-10))
		"midgame_refresh_lake":
			resume_game();build_area("lake_subgate",12,Vector3(0,0,4))
		"midgame_clozer":
			resume_game();travel("clozer_subgate",14,Vector3(0,0,11))
		"midgame_refresh_clozer":
			resume_game();build_area("clozer_subgate",14,Vector3(-13,0,-6))
		"midgame_to_airbattle":
			resume_game();travel("flutter_deck",15,Vector3(0,0,7))
		_:
			super.dialogue_done(after)


func objective() -> String:
	match int(state.campaign_step):
		7:
			return "Defeat Marlwolf / attack the rear hatch" if not state.story_flag(&"marlwolf_defeated") else "Follow the pirate excavation route"
		8:
			return "Fight beside Roll's support car and reach the Cardon Sub-Gate"
		9:
			var count := state.story_counter(&"cardon_starter_keys")
			return "Recover Cardon Starter Keys / %d of 3" % count if count < 3 else "Recover the Yellow Refractor"
		10:
			return "Help Roll repair Wily's boat with the Yellow Refractor"
		11:
			return "Protect Wily's boat / intercept missiles / defeat Balcon Gelede"
		12:
			if not state.story_flag(&"red_refractor_acquired"): return "Recover Lake Starter Keys and the Red Refractor / %d of 3 keys" % state.story_counter(&"lake_starter_keys")
			if not state.story_flag(&"garudoriten_defeated"): return "Defeat Garudoriten / strike the eye after it attacks"
			return "Return to the Flutter with the Red Refractor"
		13:
			return "Install the Red Refractor and restart the Flutter"
		14:
			if not state.story_flag(&"clozer_generator_on"): return "Restore power to the Clozer Sub-Gate"
			if not state.story_flag(&"karumuna_defeated"): return "Defeat Karumuna Bash in the elevator chamber"
			if state.story_counter(&"clozer_id_cards") < 3: return "Recover all three ID Cards / %d of 3" % state.story_counter(&"clozer_id_cards")
			return "Activate the Main Gate control console"
		_:
			return super.objective()
