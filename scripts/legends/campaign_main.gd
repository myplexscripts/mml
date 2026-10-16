extends "res://scripts/legends/main.gd"

const CampaignWorld = preload("res://scripts/legends/campaign_world.gd")
const CampaignActor = preload("res://scripts/legends/actor.gd")
const CampaignState = preload("res://scripts/legends/state.gd")

const STAGE_AREAS := {
	1:"ocean_tower", 2:"cardon", 3:"apple_market", 4:"downtown", 5:"bonne",
	6:"city_hall", 7:"yass_plains", 8:"cardon_approach", 9:"cardon_subgate",
	10:"uptown", 11:"lake_jyun", 12:"lake_subgate", 13:"flutter_restart",
	14:"clozer_subgate", 15:"flutter_deck", 16:"main_gate", 17:"old_city",
	18:"subcity", 19:"central_gate", 20:"kattelox_departure"
}

const STAGE_NAMES := {
	1:"OCEAN TOWER", 2:"CARDON FOREST", 3:"APPLE MARKET / PORTAL 1", 4:"DOWNTOWN KATTELOX",
	5:"FELDYNAUGHT", 6:"CITY HALL", 7:"YASS PLAINS / CLOZER WOODS", 8:"CARDON SUB-GATE APPROACH",
	9:"CARDON SUB-GATE", 10:"UPTOWN", 11:"LAKE JYUN", 12:"LAKE SUB-GATE",
	13:"FLUTTER RESTART", 14:"CLOZER SUB-GATE", 15:"FLUTTER AIR BATTLE", 16:"MAIN GATE",
	17:"OLD CITY / BRUNO", 18:"THREE SUB-CITIES", 19:"CENTRAL GATE", 20:"KATTELOX DEPARTURE"
}

var pending_step: int = 0


static func entry_for_step(step: int) -> Dictionary:
	var safe_step := clampi(step, 1, 20)
	var area_name := String(STAGE_AREAS.get(safe_step, "ocean_tower"))
	var spawn := Vector3(0,0,10)
	if safe_step == 1: spawn = Vector3(0,0,11)
	elif safe_step == 2: spawn = Vector3(-3,0,0)
	elif safe_step == 3: spawn = Vector3(-14,0,0)
	elif safe_step == 4: spawn = Vector3(-15,0,0)
	elif safe_step == 5: spawn = Vector3(0,0,6.5)
	elif safe_step == 6: spawn = Vector3(0,0,11)
	return {"area":area_name, "depth":safe_step, "spawn":spawn}


static func stage_name(step: int) -> String:
	return String(STAGE_NAMES.get(clampi(step,1,20), "KATTELOX"))


func build_area(target: String, level: int, spawn: Vector3) -> void:
	enemies.clear()
	npcs.clear()
	effects.clear()
	interaction = {}
	combo = 0
	combo_time = 0
	if is_instance_valid(world): world.free()
	area = target
	depth = level
	run_score = 0
	world = CampaignWorld.new()
	world.game = self
	world.area = target
	world.depth = level
	add_child(world)
	move_child(world,0)
	player = CampaignActor.new()
	player.game = self
	player.role = "player"
	player.kind = "megaman"
	player.position = spawn + Vector3.UP * .1
	world.add_child(player)
	if target == "apple_market" and state.campaign_step >= 4:
		world.interact("Downtown gate",Vector3(0,0,-5.2),"downtown_gate")
		world.sign_at("DOWNTOWN",Vector3(0,2.2,-5.8))
	if target == "downtown" and state.campaign_step == 4 and not state.story_flag(&"barrell_found_downtown"):
		spawn_npc("Barrell","barrell",Vector3(-8,0,1.5))
	camera_focus = spawn
	audio.track(_track_for_area(target))


func _track_for_area(target: String) -> String:
	if target == "bonne": return "feldynaught_theme"
	if target in ["ocean_tower","portal1","cardon_subgate","lake_subgate","clozer_subgate","main_gate","subcity","central_gate"]: return "kattelox_ruins"
	if target in ["cardon","yass_plains","cardon_approach","lake_jyun"]: return "flutter_theme"
	return "town"


func start_new() -> void:
	state = CampaignState.new()
	state.set_campaign_step(1)
	state.set_story_flag(&"blue_refractor_acquired")
	mode = "game"
	mouse_aim = false
	var entry := entry_for_step(1)
	build_area(entry.area, entry.depth, entry.spawn)
	ui.clear_overlay()
	dialogue("Roll",[
		"MegaMan! We have the blue refractor. Now we need to get out of Ocean Tower before this place comes down around us.",
		"Move with WASD or the left stick. Fire the Buster with left click, J or controller X. Hold right click or the right trigger to charge a shot.",
		"Use K or the left shoulder button to lock onto nearby Reaverbots. E, F or Space investigates caches and exits. Follow the mechanical passages toward the rooftop."
	])
	state.save_game()


func continue_game() -> void:
	if not state.load_game():
		toast("The save could not be read.")
		return
	mode = "game"
	var entry := entry_for_step(state.campaign_step)
	build_area(entry.area, entry.depth, entry.spawn)
	ui.clear_overlay()
	toast("%s / campaign step %d of 20" % [stage_name(state.campaign_step), state.campaign_step])
	audio.refresh()


func _process(delta: float) -> void:
	super._process(delta)
	if active(): _campaign_tick()


func _campaign_tick() -> void:
	if area != "ocean_tower": return
	if not state.story_flag(&"ocean_move_lesson") and player.position.z < 8:
		state.set_story_flag(&"ocean_move_lesson")
		toast("Roll: Good. Keep moving north through the tower.")
	elif not state.story_flag(&"ocean_buster_lesson") and player.position.z < 4:
		state.set_story_flag(&"ocean_buster_lesson")
		toast("Roll: Reaverbots ahead. Use the Buster and keep your distance.")
	elif not state.story_flag(&"ocean_elevation_lesson") and player.position.z < -3:
		state.set_story_flag(&"ocean_elevation_lesson")
		toast("Roll: Take the stepped service deck. The rooftop route is above us.")


func if_entered() -> void:
	if not area in CampaignWorld.CUSTOM_AREAS:
		super.if_entered()
		return
	var key := StringName("entered_campaign_step_%d" % state.campaign_step)
	if state.story_flag(key): return
	state.set_story_flag(key)
	state.save_game()
	toast("%s / step %d of 20" % [stage_name(state.campaign_step), state.campaign_step])


func execute_interaction(item: Dictionary) -> void:
	match String(item.action):
		"ocean_cache":
			if state.story_flag(&"ocean_side_cache_opened"):
				toast("The side cache is empty.")
				return
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.defeated and enemy.position.distance_to(item.pos) < 5:
					toast("The wrong-turn chamber is still guarded.")
					return
			state.set_story_flag(&"ocean_side_cache_opened")
			state.zenny += 180
			state.shards += 1
			state.save_game()
			audio.effect("item")
			dialogue("Roll",["Nice find. That's not our escape route, but the refractor shard and Zenny will come in handy."])
		"ocean_exit":
			if not state.story_flag(&"hanmuru_defeated"):
				toast("The rooftop barrier is still active. Defeat the one-armed guardian first.")
				return
			state.set_story_flag(&"ocean_tower_cleared")
			state.set_campaign_step(2)
			state.save_game()
			dialogue("Roll",["That's the way out! I'm bringing the Flutter around. Get ready to jump aboard!"],"cardon_crash")
		"to_market":
			if state.campaign_step == 2:
				state.set_campaign_step(3)
				state.save_game()
			travel("apple_market",3,Vector3(-14,0,0))
		"to_cardon": travel("cardon",2,Vector3(15,0,0))
		"to_portal1":
			if state.story_flag(&"junk_store_owner_rescued"):
				travel("portal1",3,Vector3(-14,0,9))
			else:
				dialogue("Roll",["The Junk Store owner's supposed to be down there. We should find him before we do anything else."],"portal1_enter")
		"junk_store":
			if not state.story_flag(&"junk_store_owner_rescued"):
				dialogue("Resident",["The Junk Store is closed. The owner went into Portal 1 and hasn't come back yet."])
			else: open_shop()
		"downtown_gate": travel("downtown",4,Vector3(-15,0,0))
		"city_hall_gate":
			if state.campaign_step < 6:
				toast("City Hall is not part of the current objective yet.")
			else: travel("city_hall",6,Vector3(0,0,11))
		"stage_complete": _complete_generic_stage()
		_: super.execute_interaction(item)


func talk_to(person: String) -> void:
	if person == "Junk Store Owner":
		if area == "portal1" and not state.story_flag(&"junk_store_owner_rescued"):
			for enemy in enemies:
				if is_instance_valid(enemy) and not enemy.defeated:
					toast("Clear the Reaverbots before approaching the trapped Digger.")
					return
			state.set_story_flag(&"junk_store_owner_rescued")
			state.set_story_flag(&"support_car_unlocked")
			state.set_story_flag(&"mine_parts_kit_unlocked")
			state.set_campaign_step(4)
			state.save_game()
			dialogue("Junk Store Owner",["You came all the way down here for me? Thanks, kid. I thought those Reaverbots had me cornered for good.","Come back to the shop. I'll make sure you and Roll have what you need to get started."],"portal_rescue_return")
		else: open_shop()
		return
	if person == "Roll" and area == "cardon":
		dialogue("Roll",["The Flutter took a hard hit. I can repair her, but we need tools and parts from town first.","Apple Market is east of the crash site. Barrell and Data will stay with the ship while we look for help."])
		return
	if person == "Barrell" and area == "downtown" and state.campaign_step == 4:
		state.set_story_flag(&"barrell_found_downtown")
		state.save_game()
		dialogue("Barrell",["MegaMan! Good, you found me. The pirates have been making trouble downtown.","That young woman with the Servbots has been watching the city. Keep your guard up."])
		return
	if person == "Tron" and area == "downtown" and state.campaign_step <= 5:
		if not state.story_flag(&"barrell_found_downtown"):
			dialogue("Tron",["Looking for someone? Maybe you should finish your little errand before bothering me."])
			return
		state.set_campaign_step(5)
		state.save_game()
		dialogue("Tron",["So you're MegaMan Volnutt. You're the Digger who's been getting in our way?","Servbots! Bring out the Feldynaught! Let's see what that Buster can do!"],"feldynaught_start")
		return
	super.talk_to(person)


func enemy_defeated(enemy) -> void:
	if enemy.boss and area == "bonne":
		enemies.erase(enemy)
		combo = mini(9,combo+1)
		combo_time = 5
		var points := 1200
		state.score += points
		run_score += points
		floating(enemy.position+Vector3.UP*2.8,"+%d"%points,Color("ffe2a0"))
		explosion(enemy.position+Vector3.UP*.7)
		audio.effect("explosion",.7)
		state.zenny += 480
		state.scrap += 6
		state.shards += 3
		state.set_story_flag(&"feldynaught_defeated")
		state.set_campaign_step(6)
		state.save_game()
		for other in enemies:
			if is_instance_valid(other): other.queue_free()
		enemies.clear()
		dialogue("Tron",["My beautiful Feldynaught! Do you know how long that took to build?!","This isn't over, MegaMan!"],"feldynaught_return")
		return

	super.enemy_defeated(enemy)
	if not enemy.boss: return
	if area == "ocean_tower":
		state.set_story_flag(&"hanmuru_defeated")
		state.save_game()
		toast("Roll: The guardian is down. The rooftop barrier just dropped!")
	elif area == "city_hall":
		state.set_story_flag(&"bon_bonne_defeated")
		state.set_campaign_step(7)
		state.save_game()
		for other in enemies:
			if is_instance_valid(other): other.queue_free()
		enemies.clear()
		dialogue("Amelia",["You protected City Hall and drove the pirates back. Kattelox owes you a great deal.","I'm granting you a Class B Digger's licence. We need your help against the pirates in the north."],"cityhall_clear")
	elif area in CampaignWorld.CUSTOM_AREAS:
		state.set_story_flag(StringName("campaign_boss_%d_defeated" % state.campaign_step))
		state.save_game()
		toast("The area's main Reaverbot is down. Finish the mission objective.")


func dialogue_done(after: String) -> void:
	match after:
		"cardon_crash":
			resume_game()
			var entry := entry_for_step(2)
			travel(entry.area,entry.depth,entry.spawn)
		"portal1_enter":
			resume_game()
			travel("portal1",3,Vector3(-14,0,9))
		"portal_rescue_return":
			resume_game()
			travel("apple_market",4,Vector3(10,0,3.5))
		"feldynaught_start":
			resume_game()
			travel("bonne",5,Vector3(0,0,6.5))
		"feldynaught_return":
			resume_game()
			travel("city_hall",6,Vector3(0,0,11))
		"cityhall_clear":
			resume_game()
			_advance_to_step(7)
		"advance_campaign":
			resume_game()
			if pending_step > 0:
				var next := pending_step
				pending_step = 0
				_advance_to_step(next)
		_: super.dialogue_done(after)


func _advance_to_step(step: int) -> void:
	state.set_campaign_step(step)
	state.save_game()
	var entry := entry_for_step(step)
	travel(entry.area,entry.depth,entry.spawn)


func _complete_generic_stage() -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.defeated:
			toast("The mission area is not clear yet.")
			return
	var step: int = int(state.campaign_step)
	state.set_story_flag(StringName("campaign_step_%d_complete" % step))
	if step >= 20:
		state.set_story_flag(&"campaign_complete")
		state.save_game()
		ui.summary("KATTELOX DEPARTURE",[
			"The Main Gate crisis is over.",
			"Kattelox is safe, and the Flutter is ready to leave the island.",
			"MML1 campaign route complete."
		])
		return
	pending_step = step + 1
	state.save_game()
	dialogue("Roll",[_stage_result(step)],"advance_campaign")


func _stage_result(step: int) -> String:
	var results := {
		7:"The northern route is open and Amelia has authorised the next dig. We're heading back toward Cardon Forest.",
		8:"We've reached the Cardon Sub-Gate approach. The gate is accessible now.",
		9:"The Yellow Refractor is ours. That gives us the power source we needed for the next repair.",
		10:"Wily's boat is ready. We can cross Lake Jyun and reach the next Sub-Gate.",
		11:"We made it across the lake. The Lake Sub-Gate is directly ahead.",
		12:"We recovered the Red Refractor. The Flutter's engines should finally be able to start again.",
		13:"The Flutter is flying again. We can reach Clozer Woods from the air now.",
		14:"The generator is restored and the ID cards opened the path to the Main Gate.",
		15:"The Bonne air attack is finished. We're still flying, and the Main Gate is waiting below.",
		16:"The Main Gate control panel is active. Three Sub-City portals have appeared around Kattelox.",
		17:"Bruno is down. The Bonnes are beaten for now, but the Sub-City keys are still out there.",
		18:"Watcher, Sleeper and Dreamer are complete. We have the keys for the Central Gate.",
		19:"Juno is stopped and Data shut down Eden. Kattelox is safe. Time to say goodbye."
	}
	return String(results.get(step,"The route ahead is open."))


func knock_out() -> void:
	if mode != "game": return
	var loss := int(state.zenny*.08)
	state.zenny -= loss
	state.health = state.max_health()
	state.energy = 100
	var entry := entry_for_step(state.campaign_step)
	build_area(entry.area,entry.depth,entry.spawn)
	state.save_game()
	dialogue("Roll",["Data got you back on your feet. We lost %d Zenny, but the campaign progress is safe."%loss])


func objective() -> String:
	var step: int = int(state.campaign_step)
	match step:
		1:
			if not state.story_flag(&"hanmuru_defeated"): return "Escape Ocean Tower / defeat the rooftop guardian"
			return "Use the rooftop exit"
		2: return "Reach Apple Market and find repair help"
		3:
			if not state.story_flag(&"junk_store_owner_rescued"): return "Enter Portal 1 and rescue the Junk Store owner"
			return "Return to the Junk Store"
		4:
			if not state.story_flag(&"barrell_found_downtown"): return "Find Barrell in Downtown Kattelox"
			return "Confront Tron downtown"
		5: return "Defeat Tron's Feldynaught"
		6: return "Defend City Hall and defeat Bon Bonne"
		20: return "Say farewell and depart Kattelox"
		_: return "Complete the %s mission" % stage_name(step).capitalize()


func location() -> String:
	if area == "portal1": return "PORTAL 1"
	if area in CampaignWorld.CUSTOM_AREAS: return stage_name(state.campaign_step)
	return super.location()
