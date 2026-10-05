extends Node2D
## Kattelox Days: an authored, completable adventure with a persistent life loop.
const Catalog = preload("res://scripts/catalog.gd")
const Grenade = preload("res://scripts/grenade.gd")
const State = preload("res://scripts/state.gd")
const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Pickup = preload("res://scripts/pickup.gd")
const NPC = preload("res://scripts/npc.gd")
const Audio = preload("res://scripts/audio.gd")
const UI = preload("res://scripts/ui.gd")
var state = State.new()
var mode: String = "title"
var area: String = "surface"
var floor_number: int = 1
var tool: int = 0
var world
var player
var camera: Camera2D
var audio
var ui
var enemies: Array = []
var npcs: Array = []
var effects: Array = []
var combo: int = 0
var combo_time: float = 0.0
var dig_score: int = 0
var dig_kills: int = 0
var shake: float = 0.0
var clock: float = 0.0
var notice: String = ""
var notice_time: float = 0.0
var pending: Dictionary = {}
var fade: float = 0.0
var fading_in: bool = false
var save_clock: float = 0.0
var interaction: Dictionary = {}
var boss_rewarded: bool = false
var last_sell: int = 0
var visited: Dictionary = {}
var effect_layer: Node2D

func _ready() -> void:
	configure_inputs()
	get_tree().auto_accept_quit=false
	camera=Camera2D.new()
	camera.position=Vector2(410,730)
	add_child(camera)
	effect_layer=Node2D.new();effect_layer.z_index=40
	effect_layer.draw.connect(draw_effects);add_child(effect_layer)
	audio=Audio.new();audio.game=self;add_child(audio)
	ui=UI.new();ui.game=self;add_child(ui)
	build_area("surface",1,Vector2(350,781))
	audio.track("town")
	ui.title_screen()

func configure_inputs() -> void:
	var keys := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E,KEY_F,KEY_SPACE],"fire":[KEY_J],"dash":[KEY_SHIFT],"lock":[KEY_K],"heal":[KEY_Q],"pause_game":[KEY_ESCAPE],"map":[KEY_M],"inventory":[KEY_TAB],"sleep":[KEY_R],"tool_next":[KEY_T],"special":[KEY_L],"seed_menu":[KEY_C]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var event:=InputEventKey.new();event.physical_keycode=key
			InputMap.action_add_event(action,event)
	var buttons := {"interact":JOY_BUTTON_A,"fire":JOY_BUTTON_X,"dash":JOY_BUTTON_RIGHT_SHOULDER,"lock":JOY_BUTTON_LEFT_SHOULDER,"pause_game":JOY_BUTTON_START,"heal":JOY_BUTTON_Y,"special":JOY_BUTTON_B}
	for action in buttons:
		var event:=InputEventJoypadButton.new();event.button_index=buttons[action]
		InputMap.action_add_event(action,event)
	for action in ["move_left","move_right","move_up","move_down"]:
		var event:=InputEventJoypadMotion.new()
		event.axis=JOY_AXIS_LEFT_X if action in ["move_left","move_right"] else JOY_AXIS_LEFT_Y
		event.axis_value=-1.0 if action in ["move_left","move_up"] else 1.0
		InputMap.action_add_event(action,event)
	for pair in [["fire",MOUSE_BUTTON_LEFT],["lock",MOUSE_BUTTON_RIGHT]]:
		var event:=InputEventMouseButton.new();event.button_index=pair[1]
		InputMap.action_add_event(pair[0],event)

func active() -> bool:
	return mode=="game" and is_instance_valid(player)

func _process(delta: float) -> void:
	clock+=delta
	if notice_time>0: notice_time-=delta
	if not pending.is_empty():
		fade=minf(1,fade+delta*4)
		if fade>=1:
			var target:=pending.duplicate();pending.clear()
			build_area(target.area,target.floor,target.spawn)
			fading_in=true
	elif fading_in:
		fade=maxf(0,fade-delta*4)
		if fade<=0:
			fading_in=false;mode="game";ui.clear_overlay()
			if area=="ruins": radio("Roll","I've got your signal. Watch the red eyes, and come home in one piece!")
	if active():
		state.minutes=minf(1439,state.minutes+delta*1.8)
		save_clock+=delta
		combo_time=maxf(0,combo_time-delta)
		if combo_time<=0: combo=0
		if state.minutes>=1439: knock_out(true)
		if save_clock>45: save_clock=0;state.save_game()
		interaction=find_interaction()
		visited[Vector2i(player.position/32)]=true
		update_effects(delta)
	if is_instance_valid(player):
		var desired: Vector2=player.global_position
		if mode=="title": desired=Vector2(420+sin(clock*0.09)*45,710)
		desired.x=clampf(desired.x,320,maxf(320,world.size.x-320))
		desired.y=clampf(desired.y,180,maxf(180,world.size.y-180))
		if area=="bonne": desired=Vector2(320,240)
		camera.position=camera.position.lerp(desired,1-exp(-delta*8))
		shake=maxf(0,shake-delta*16)
		camera.offset=Vector2(randf_range(-shake,shake),randf_range(-shake,shake)) if not state.reduced_motion and active() else Vector2.ZERO
	ui.refresh(delta)
	effect_layer.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.echo: return
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_F11:
		var full:=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("pause_game"):
		if mode=="game": ui.pause_screen("Status")
		elif mode in ["pause","menu","fishing","summary"]: ui.cancel_overlay()
		elif mode=="dialogue": ui.advance_dialogue()
		get_viewport().set_input_as_handled();return
	if event.is_action_pressed("interact"):
		if mode=="game": interact()
		elif mode=="dialogue": ui.advance_dialogue()
		elif mode=="fishing": ui.fish_press()
		elif mode in ["menu","summary","title","pause"]:
			var focused:=get_viewport().gui_get_focus_owner()
			if focused is Button: focused.pressed.emit()
		get_viewport().set_input_as_handled();return
	if not active(): return
	if event.is_action_pressed("map"): ui.pause_screen("Map")
	elif event.is_action_pressed("seed_menu"): open_seeds()
	elif event.is_action_pressed("inventory"): ui.pause_screen("Equipment")
	elif event.is_action_pressed("sleep"):
		if area=="cabin" or area=="surface" and player.position.distance_to(Vector2(310,771))<115: open_home()
		else: toast("Sleep aboard the Flutter. Find its door beside Roll.")
	elif event.is_action_pressed("tool_next"): tool=(tool+1)%4
	elif event is InputEventKey and event.pressed:
		if event.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4]: tool=event.physical_keycode-KEY_1

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if mode!="title": state.save_game()
		call_deferred("quit_game")
	elif what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode=="game" and is_instance_valid(ui): ui.pause_screen("Status")

func quit_game() -> void:
	mode="transition"
	audio.shutdown()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func start_new() -> void:
	state=State.new();tool=0;mode="game"
	build_area("surface",1,Vector2(350,781));ui.clear_overlay()
	dialogue("Roll",["MegaMan! You're finally awake. The Flutter made it to Kattelox, but her engine didn't.","We'll make this island our home while I fix her. Come see me for the repair list. Data can save our progress, and the garden beside the ship is ours to use.","The northern ruins have the parts we need. Let's get you moving first!"])
	state.save_game()

func continue_game() -> void:
	if not state.load_game(): toast("The save could not be read. Start a new adventure.");return
	mode="game";build_area("surface",1,Vector2(350,781));ui.clear_overlay()
	toast("Welcome back to Kattelox. Day %d."%state.day);audio.refresh()

func build_area(destination: String, depth: int, spawn: Vector2) -> void:
	enemies.clear();npcs.clear();effects.clear();visited.clear()
	if is_instance_valid(world): world.free()
	area=destination;floor_number=depth
	if area in ["ruins","bonne"]: tool=0
	world=World.new();world.game=self;world.area=destination;world.floor_number=depth
	add_child(world);move_child(world,0)
	player=Player.new();player.game=self;player.position=spawn
	world.entities.add_child(player)
	if area=="surface":
		for entry in [["Roll","roll"],["Data","data"],["Barrell","barrell"],["Amelia","amelia"],["Junk Shop Man","junkman"]]: spawn_npc(entry[0],entry[1],npc_destination(entry[0]))
		if state.repair>=2: spawn_npc("Tron","tron",Vector2(800,566))
		if is_instance_valid(audio): audio.track("town")
	elif area=="bonne": audio.track("boss")
	elif area in ["shop","museum","cafe","hall"]:
		audio.track("town")
	elif area=="cabin":
		spawn_npc("Data","data",Vector2(254,307))
		spawn_npc("Barrell","barrell",Vector2(205,218))
		audio.track("town")
	else:
		tool=0
		dig_score=0;dig_kills=0;boss_rewarded=false;audio.track("ruins")
	camera.position=Vector2(clampf(spawn.x,320,maxf(320,world.size.x-320)),clampf(spawn.y,180,maxf(180,world.size.y-180)))
	if area=="bonne": camera.position=Vector2(320,240)
	interaction={}

func travel(destination: String, depth: int = 1, spawn: Vector2 = Vector2(350,781)) -> void:
	mode="transition";ui.clear_overlay()
	pending={"area":destination,"floor":depth,"spawn":spawn};fade=0
	audio.effect("door");state.save_game()

func spawn_npc(person: String, art: String, at: Vector2) -> void:
	var npc=NPC.new();npc.game=self;npc.person=person;npc.art=art;npc.position=at
	world.entities.add_child(npc);npcs.append(npc)

func spawn_enemy(kind: String, at: Vector2, hp: int = 30, is_boss: bool = false) -> void:
	var enemy=Enemy.new();enemy.game=self;enemy.kind=kind;enemy.health=hp;enemy.boss=is_boss
	enemy.reward=240 if is_boss else 28+floor_number*8
	enemy.score_value=1000 if is_boss else 100+floor_number*25
	enemy.position=at;world.entities.add_child(enemy);enemies.append(enemy)

func shoot(at: Vector2, velocity: Vector2, hostile: bool, damage: int) -> void:
	var shot=Projectile.new();shot.game=self;shot.position=at;shot.speed=velocity;shot.hostile=hostile;shot.damage=damage
	shot.life=2.8 if hostile else 1.05+state.power*0.18
	world.entities.add_child(shot)

func nearest_enemy(at: Vector2, distance: float):
	var target=null
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.defeated: continue
		var d: float=enemy.position.distance_to(at)
		if d<distance and line_clear(at,enemy.position): distance=d;target=enemy
	return target

func line_clear(from: Vector2, to: Vector2) -> bool:
	var query:=PhysicsRayQueryParameters2D.create(from,to,1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func enemy_defeated(enemy) -> void:
	enemies.erase(enemy);combo=mini(8,combo+1);combo_time=5
	var points: int=enemy.score_value*(1+int(combo/3))
	dig_score+=points;dig_kills+=1;state.score+=points;state.enemies_today+=1
	floating(enemy.position+Vector2(0,-50),"+%d"%points,Color("ffe2a0"))
	for i in range(3): drop(enemy.position,"zenny",int(enemy.reward/3),Vector2(randf_range(-55,55),randf_range(-30,30)))
	drop(enemy.position,"scrap",3 if enemy.boss else 1,Vector2(15,-30))
	if enemy.boss: drop(enemy.position,"relic",1,Vector2(-15,-25))
	boss_rewarded=boss_rewarded or enemy.boss
	burst(enemy.position+Vector2(0,-20),Color("f6b779"),22,110)
	shake=6 if enemy.boss else 2;audio.effect("explosion",0.7 if enemy.boss else 1.1)
	if area=="bonne" and enemy.boss: call_deferred("win_bonne")
	elif enemy.boss:
		radio("Roll","The guardian's signal is gone! The cache is safe to open.")
		state.best_dig=maxi(state.best_dig,dig_score)

func drop(at: Vector2, kind: String, amount: int, motion: Vector2) -> void:
	var item=Pickup.new();item.game=self;item.position=at;item.kind=kind;item.amount=amount;item.motion=motion
	world.entities.add_child(item)

func win_bonne() -> void:
	state.tron_defeated=true;state.items.scrap+=9;state.items.relic+=1;state.zenny+=540
	for enemy in enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	enemies.clear()
	dialogue("Tron",["My beautiful machine! Do you have any idea how long that took to build?!","Fine. Take the core Refractor. But you owe me a rematch, MegaMan!"],"bonne_return")
	state.save_game()

func npc_destination(person: String) -> Vector2:
	if area in ["shop","museum","cafe","hall"]: return Vector2(430,290) if person=="Barrell" else Vector2(320,218)
	if area=="cabin": return Vector2(254,307) if person=="Data" else Vector2(205,218)
	var hour: float=state.minutes/60
	match person:
		"Roll": return Vector2(441,745) if hour<11 or hour>=18 else Vector2(598,712)
		"Data": return Vector2(277,787) if hour<15 else Vector2(870,821)
		"Barrell": return Vector2(399,795) if hour<10 or hour>=19 else Vector2(1075,713)
		"Amelia": return Vector2(800,458) if hour<17 else Vector2(951,823)
		"Junk Shop Man": return Vector2(522,715)
		"Tron": return Vector2(800,567)
	return Vector2(400,700)

func find_interaction() -> Dictionary:
	if not is_instance_valid(world) or not is_instance_valid(player): return {}
	var found: Dictionary={}
	var best: float=46
	for npc in npcs:
		if not is_instance_valid(npc): continue
		var distance: float=player.position.distance_to(npc.position)
		if distance<best: best=distance;found={"action":"npc","person":npc.person,"name":npc.person,"pos":npc.position}
	for item in world.interactables:
		var distance: float=player.position.distance_to(item.pos)
		if distance<best: best=distance;found=item
	if area=="surface" and found.is_empty():
		for i in range(world.crop_nodes.size()):
			var distance: float=player.position.distance_to(world.crop_nodes[i].pos)
			if distance<27 and distance<best:
				best=distance
				var crop: Dictionary=state.crops[i]
				var text: String="Harvest "+str(Catalog.crop(str(crop.get("kind","turnip"))).name) if int(crop.stage)>=int(Catalog.crop(str(crop.get("kind","turnip"))).nights) else ("Till Soil" if not crop.tilled else ("Plant Seed" if int(crop.stage)<0 else ("Water Crop" if not crop.watered else "Growing "+str(Catalog.crop(str(crop.get("kind","turnip"))).name))))
				found={"action":"crop","index":i,"name":text,"pos":world.crop_nodes[i].pos}
	return found

func interact() -> void:
	interaction=find_interaction()
	if not interaction.is_empty(): execute_interaction(interaction)

func execute_interaction(item: Dictionary) -> void:
	audio.effect("select")
	match item.action:
		"npc": talk_to(item.person)
		"home": open_home()
		"cabin": travel("cabin",1,Vector2(320,380))
		"cabin_exit": travel("surface",1,Vector2(350,781))
		"workshop": open_workshop()
		"galley": ui.menu("FLUTTER GALLEY","Cook your catch to restore health and energy.",[{"text":"Cook one lake fish","action":"fish_lunch","disabled":state.items.fish<1}])
		"shop","museum","cafe","hall": travel(item.action,1,Vector2(320,385))
		"town_exit": travel("surface",1,item.return_pos)
		"shop_counter": open_shop()
		"museum_counter": open_museum()
		"cafe_counter": open_cafe()
		"hall_counter": dialogue("Amelia",["The Flutter crew is welcome on Kattelox. The request board offers rewards for helping our neighbours.","If you find any ancient relics, the museum would love to see them. Thank you for looking after our island!"])
		"ruins": open_ruins()
		"sell": sell_produce()
		"board": open_board()
		"fish":
			if state.energy>=5: state.energy-=5;ui.fishing_screen()
			else: toast("Rest or have something from the cafe first.")
		"exit": state.best_dig=maxi(state.best_dig,dig_score);travel("surface",1,Vector2(640,299))
		"treasure": recover_treasure(item)
		"blueprint":
			state.blueprint=true;world.interactables.erase(item);item.sprite.queue_free();state.score+=200;state.save_game()
			dialogue("Roll",["Those are Grenade Arm plans! Bring me 8 scrap, 3 Refractor shards and 450 Zenny. I can build it at the Flutter workbench."])
		"exhibit": dialogue("Barrell",["%d relics preserved for Kattelox. Each one helps us understand the people who built those machines."%state.museum_donated])
		"crop": farm(int(item.index))

func talk_to(person: String) -> void:
	state.greet(person)
	match person:
		"Roll": ui.menu("ROLL'S WORKSHOP","Flutter systems, Buster parts and a little encouragement.",[{"text":"Flutter repairs","action":"roll_story"},{"text":"Upgrade equipment","action":"workshop"},{"text":"Spend some time with Roll","action":"greet_roll"},{"text":"Give Roll a tomato","action":"gift_Roll","disabled":state.items.tomatoes<1 or state.gifts.has("Roll")}])
		"Data":
			state.health=state.max_health();state.energy=100
			var saved: bool=state.save_game()
			dialogue("Data",["Ook ook!","Data patches up your armour, recharges your energy and %s."%("saves your adventure" if saved else "cannot save right now")])
		"Barrell": open_friend("Barrell")
		"Amelia": open_friend("Amelia")
		"Junk Shop Man": open_shop()
		"Tron":
			if not state.tron_defeated: dialogue("Tron",["So you're the Digger who's been taking our treasure? Hmph!","Servbots! Bring out the machine! Let's see what that Buster can really do!"],"start_bonne")
			else: dialogue("Tron",["Don't look so pleased with yourself. Next time, I'll bring a bigger machine!","...Your garden is nice, though. Don't tell the Servbots I said that."])

func open_friend(person: String) -> void:
	var item: String=Catalog.GIFTS[person]
	ui.menu(person.to_upper(),"Friendship %d/10. One gift per neighbour per day."%int(state.friendship.get(person,0)),[{"text":"Chat about the island","action":"chat_"+person},{"text":"Give one "+item,"action":"gift_"+person,"disabled":state.items[item]<1 or state.gifts.has(person)}])

func give_gift(person: String) -> void:
	if not Catalog.GIFTS.has(person) or state.gifts.has(person): return
	var item: String=Catalog.GIFTS[person]
	if state.items[item]<1: return
	state.items[item]-=1;state.gifts[person]=true
	state.friendship[person]=mini(10,int(state.friendship.get(person,0))+2)
	state.score+=60;state.save_game();audio.effect("item")
	dialogue(person,[{"Roll":"Fresh tomatoes for the galley? Thank you, MegaMan! We'll cook something together after your next dig.","Amelia":"These flowers will brighten City Hall. You've made a little piece of Kattelox more beautiful.","Barrell":"A fish for dinner! I could tell you about the old Diggers while we eat."}.get(person,"Thank you, MegaMan. That was thoughtful!")])

func open_seeds() -> void:
	var choices: Array=[]
	for kind in Catalog.CROPS:
		var rules: Dictionary=Catalog.CROPS[kind]
		choices.append({"text":"%s x%d: %d watered nights / %d Z%s"%[rules.name,state.items[rules.seed],rules.nights,rules.price," / regrows" if rules.regrow>=0 else ""],"action":"seed_"+kind})
	ui.menu("GARDEN SEEDS","Select seeds with C. E plants the selected crop in tilled soil.",choices)

func roll_story() -> void:
	if not state.quest_started:
		state.quest_started=true
		dialogue("Roll",["Let's start with the port stabilizer. I need a Servo Motor from the first ruin level.","The entrance is north of City Hall. I'll stay on the radio while you dig. Bring the motor straight back and I'll fit it."])
		state.save_game();return
	var part: String="servo" if state.repair==0 else ("circuit" if state.repair==1 else "refractor")
	if state.repair<3 and int(state.items[part])>0:
		state.items[part]-=1;state.repair+=1;state.score+=500;state.zenny+=200;audio.effect("item")
		if state.repair==1: dialogue("Roll",["This Servo Motor is perfect! The stabilizer is working again.","The lift in the ruins can now reach the second level. I'll need an Ancient Circuit from there to restore navigation."])
		elif state.repair==2:
			if area=="surface": spawn_npc("Tron","tron",Vector2(800,567))
			dialogue("Roll",["Navigation restored! The only thing left is the engine's main Refractor.","Uh... someone's broadcasting a pirate challenge from the plaza. Tron Bonne is waiting near the request board. Be careful, MegaMan!"])
		else:
			state.completed=true
			dialogue("Roll",["MegaMan... this Refractor is beautiful. Main engine pressure is stable. The Flutter can fly again!","We could leave tomorrow, but we've made a home here. There are still ruins, friends and a garden waiting for us.","Thank you for bringing us home, MegaMan. Kattelox is part of our story now."],"ending")
		state.save_game();return
	var hints := ["The Servo Motor is in the western chamber on ruin level 1. Watch the Horokkos around the cache.","The Ancient Circuit is in the northern chamber on level 2. Its guardian has a red eye and a very bad temper.","Tron is waiting in the plaza. Once her machine is down, we can reach the core Refractor on level 3.","The Flutter is flightworthy! Deep digs are open now. Or we could take a quiet day on the island."]
	if state.repair==2 and state.tron_defeated: hints[2]="The last Refractor is in the northern vault on level 3. Defeat its guardian, open the cache, then come home."
	dialogue("Roll",[hints[state.repair]])

func dialogue(person: String, lines: Array, after: String = "") -> void:
	ui.dialogue_screen(person,lines,after)

func dialogue_done(after: String) -> void:
	resume_game()
	match after:
		"start_bonne": travel("bonne",1,Vector2(320,340))
		"bonne_return": travel("surface",1,Vector2(794,596))
		"ending": ui.summary_screen("THE FLUTTER CAN FLY",["All three systems restored.","Total score: %s    Best dig: %s"%[state.score,state.best_dig],"Keep living on Kattelox, or take on the Deep Dig."])

func open_ruins() -> void:
	if not state.quest_started: dialogue("Roll",["Before you go down there, come see me beside the Flutter. We need a repair plan!"]);return
	var choices: Array=[{"text":"Level 1: Stabilizer chambers","action":"dig_1"}]
	choices.append({"text":"Level 2: Navigation vault","action":"dig_2","disabled":state.repair<1})
	choices.append({"text":"Level 3: Refractor core","action":"dig_3","disabled":not state.tron_defeated})
	if state.completed: choices.append({"text":"Deep Dig: Depth %d"%state.deep_depth,"action":"dig_%d"%state.deep_depth})
	ui.menu("NORTHERN RUINS","Choose a lift destination. E opens caches. Return via the southern lift.",choices)

func recover_treasure(item: Dictionary) -> void:
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.defeated and (enemy.boss or enemy.position.distance_to(item.pos)<110): toast("The cache is guarded. Clear the nearby Reaverbots first.");return
	var part: String=item.part
	if floor_number>=4: state.zenny+=500+100*(floor_number-4);state.items.relic+=1;state.score+=1500;dig_score+=1500;state.deep_depth=mini(20,maxi(state.deep_depth,floor_number+1))
	else: state.items[part]=1;state.score+=250;dig_score+=250
	if is_instance_valid(item.sprite): item.sprite.queue_free()
	world.interactables.erase(item);state.best_dig=maxi(state.best_dig,dig_score)
	audio.effect("item");state.save_game()
	var names: Dictionary={"servo":"Servo Motor","circuit":"Ancient Circuit","refractor":"Large Refractor"}
	dialogue("Roll",["Nice work, MegaMan! %s recovered. Take the southern lift back and bring it to the Flutter."%names[part]] if floor_number<4 else ["Deep Dig complete! Another relic, %d Zenny and 1500 score. Depth %d is ready when you are. Let's head home."%[500+100*(floor_number-4),state.deep_depth]])

func open_workshop() -> void:
	var choices: Array=[]
	for entry in [["power","Buster Power",350,4],["rapid","Rapid Fire",300,3],["armour","Armour Jacket",400,5]]:
		var level: int=state.get(entry[0]);var cost: int=entry[2]+level*200;var scrap: int=entry[3]+level*2
		choices.append({"text":"%s Lv.%d   %d Z + %d scrap"%[entry[1],level+1,cost,scrap] if level<3 else "%s MAX"%entry[1],"action":"upgrade_"+entry[0],"disabled":level>=3 or state.zenny<cost or state.items.scrap<scrap})
	choices.append({"text":"Grenade Arm fitted: L / controller B" if state.grenade_unlocked else "Build Grenade Arm: 450 Z + 8 scrap + 3 shards","action":"build_grenade","disabled":state.grenade_unlocked or not state.blueprint or state.zenny<450 or state.items.scrap<8 or state.items.shard<3})
	ui.menu("ROLL'S WORKSHOP","Zenny %d   Scrap %d. Power increases damage and range."%[state.zenny,state.items.scrap],choices)

func upgrade(stat: String) -> void:
	var level: int=state.get(stat);var base: Dictionary={"power":[350,4],"rapid":[300,3],"armour":[400,5]}
	var cost: int=base[stat][0]+level*200;var scrap: int=base[stat][1]+level*2
	if level>=3 or state.zenny<cost or state.items.scrap<scrap: return
	state.zenny-=cost;state.items.scrap-=scrap;state.set(stat,level+1)
	if stat=="armour": state.health=state.max_health()
	audio.effect("item");state.save_game();toast("Roll fitted your new %s upgrade."%stat);open_workshop()

func open_shop() -> void:
	ui.menu("JUNK SHOP","Zenny %d. Seeds become turnips after three watered nights."%state.zenny,[{"text":"Turnip seeds x6   90 Z","action":"buy_seeds","disabled":state.zenny<90},{"text":"Energy bottle   100 Z","action":"buy_heal","disabled":state.zenny<100},{"text":"Scrap bundle x4   180 Z","action":"buy_scrap","disabled":state.zenny<180},{"text":"Tomato seeds x4   140 Z (regrow)","action":"buy_tomato","disabled":state.zenny<140},{"text":"Sunflower seeds x4   180 Z","action":"buy_sunflower","disabled":state.zenny<180},{"text":"Select garden seeds","action":"seeds_menu"}])

func open_cafe() -> void:
	ui.menu("KATTELOX CAFE","A little breathing room between digs.",[{"text":"Lunch: restore health and energy   60 Z","action":"lunch","disabled":state.zenny<60},{"text":"Trade a fish for lunch","action":"fish_lunch","disabled":state.items.fish<1}])

func open_museum() -> void:
	ui.menu("KATTELOX MUSEUM","Relics donated: %d. Each donation earns 250 Z and 500 score."%state.museum_donated,[{"text":"Donate one ancient relic","action":"donate","disabled":state.items.relic<1},{"text":"Ask Barrell about the ruins","action":"museum_story"}])

func open_board() -> void:
	ui.menu("TOWN REQUESTS","Today's requests. New work appears after sleeping aboard the Flutter.",[{"text":"Turnips for the cafe: 3 turnips   300 Z","action":"request_crop","disabled":state.items.turnips<3 or "crop" in state.claimed},{"text":"Fishing delivery: 2 fish   160 Z","action":"request_fish","disabled":state.items.fish<2 or "fish" in state.claimed},{"text":"Tomatoes for the cafe: 2 tomatoes   200 Z","action":"request_tomato","disabled":state.items.tomatoes<2 or "tomato" in state.claimed},{"text":"Flowers for City Hall: 1 sunflower   180 Z","action":"request_flower","disabled":state.items.sunflowers<1 or "flower" in state.claimed},{"text":"Safe ruins: defeat 5 bots   250 Z","action":"request_bots","disabled":state.enemies_today<5 or "bots" in state.claimed}])

func open_home() -> void:
	ui.menu("ABOARD THE FLUTTER","Day %d, %02d:%02d. Your home, even while her engines are grounded."%[state.day,int(state.minutes)/60,int(state.minutes)%60],[{"text":"Sleep until tomorrow","action":"sleep_now"},{"text":"Save adventure","action":"save"},{"text":"Check the Flutter systems","action":"roll_story"}])

func sleep_now() -> void:
	var result: Dictionary=state.next_day();state.save_game()
	build_area("surface",1,Vector2(350,781))
	ui.summary_screen("DAY %d ON KATTELOX"%state.day,["Health and energy restored. Adventure saved.","%d crops grew overnight."%result.grown,"Rain waters your garden today." if result.rain else "A clear morning. The garden needs water."])

func execute_choice(action: String) -> void:
	audio.effect("select")
	if action.begins_with("chat_"):
		var person: String=action.trim_prefix("chat_")
		var lines: Dictionary={"Barrell":["Every relic holds a memory, MegaMan. Look for the red eyes in the ruins. Those machines have watched over the same chambers for centuries.","I used to think a Digger needed only courage. Now I think it helps to have someone waiting for you at home."],"Amelia":["Good to see you, MegaMan! The cafe needs fresh produce, and our museum is always looking for relics.","Your garden gives the Flutter a place in our town. Kattelox is glad to have you here."]}
		dialogue(person,lines.get(person,["It's a good day to be on Kattelox."]));return
	if action.begins_with("dig_"): travel("ruins",int(action.trim_prefix("dig_")),Vector2(480,598));return
	if action.begins_with("seed_"): state.seed_kind=action.trim_prefix("seed_");state.save_game();resume_game();toast("Selected "+str(Catalog.crop(state.seed_kind).name)+" seeds.");return
	if action.begins_with("gift_"): give_gift(action.trim_prefix("gift_"));return
	if action.begins_with("upgrade_"): upgrade(action.trim_prefix("upgrade_"));return
	match action:
		"new": start_new()
		"continue": continue_game()
		"resume": resume_game()
		"title": state.save_game();mode="title";build_area("surface",1,Vector2(350,781));ui.title_screen()
		"roll_story": roll_story()
		"workshop": open_workshop()
		"greet_roll":
			if int(state.friendship.Roll)>=6 and not "roll_gift" in state.claimed:
				state.items.seeds+=3;state.claimed.append("roll_gift");state.save_game()
				dialogue("Roll",["You've made Kattelox feel like home. I picked up three seeds for the garden. They're yours, MegaMan!","Don't forget to take a break. You're allowed to enjoy the island too."])
			else: dialogue("Roll",["It's funny. Before we crashed, I only wanted to leave. Now I look forward to the little things here.","Don't forget to take a break, MegaMan. You're allowed to enjoy the island too."])
		"sleep_now": sleep_now()
		"save": toast("Adventure saved." if state.save_game() else "Could not save your adventure.");resume_game()
		"buy_seeds": purchase("seeds",6,90)
		"buy_tomato": purchase("tomato_seeds",4,140)
		"buy_sunflower": purchase("sunflower_seeds",4,180)
		"seeds_menu": open_seeds()
		"build_grenade":
			if state.blueprint and not state.grenade_unlocked and state.zenny>=450 and state.items.scrap>=8 and state.items.shard>=3:
				state.zenny-=450;state.items.scrap-=8;state.items.shard-=3;state.grenade_unlocked=true;state.save_game();audio.effect("item")
				dialogue("Roll",["Grenade Arm ready! L or controller B lobs a grenade. Hold K to aim at a target. Each shot uses 18 energy.","It bounces off walls before exploding. Use it on clustered bots and salvage crates!"])
		"buy_heal": purchase("heal",1,100)
		"buy_scrap": purchase("scrap",4,180)
		"lunch","fish_lunch":
			if action=="lunch" and state.zenny>=60: state.zenny-=60
			elif action=="fish_lunch" and state.items.fish>=1: state.items.fish-=1
			else: return
			state.health=state.max_health();state.energy=100;state.minutes+=30
			resume_game();toast("A good lunch. Health and energy restored.");state.save_game()
		"donate":
			if state.items.relic<1: return
			state.items.relic-=1;state.museum_donated+=1;state.zenny+=250;state.score+=500
			audio.effect("item");state.save_game();open_museum()
		"museum_story": dialogue("Barrell",["Every relic is a little piece of the past. The museum keeps that past safe for everyone on Kattelox."])
		"request_crop": claim_request("crop","turnips",3,300)
		"request_tomato": claim_request("tomato","tomatoes",2,200)
		"request_flower": claim_request("flower","sunflowers",1,180)
		"request_fish": claim_request("fish","fish",2,160)
		"request_bots":
			if state.enemies_today>=5 and not "bots" in state.claimed: claim_request("bots","scrap",0,250)
		"music": state.music=not state.music;audio.refresh();ui.pause_screen("Options");state.save_game()
		"sound": state.sound=not state.sound;ui.pause_screen("Options");state.save_game()
		"motion": state.reduced_motion=not state.reduced_motion;ui.pause_screen("Options");state.save_game()

func purchase(item: String, quantity: int, cost: int) -> void:
	if state.zenny<cost: return
	state.zenny-=cost;state.items[item]+=quantity;audio.effect("item");state.save_game();open_shop()

func claim_request(request: String, item: String, quantity: int, reward: int) -> void:
	if request in state.claimed or state.items[item]<quantity: return
	state.items[item]-=quantity;state.claimed.append(request);state.zenny+=reward;state.score+=200
	audio.effect("item");state.save_game();open_board()

func sell_produce() -> void:
	var total: int=state.items.turnips*80+state.items.fish*55+state.items.tomatoes*65+state.items.sunflowers*160
	if total<=0: toast("Ship turnips (80 Z), tomatoes (65 Z), sunflowers (160 Z) or fish (55 Z).");return
	var count: int=state.items.turnips+state.items.fish+state.items.tomatoes+state.items.sunflowers
	state.items.turnips=0;state.items.fish=0;state.items.tomatoes=0;state.items.sunflowers=0;state.zenny+=total;state.score+=count*20;last_sell=total
	audio.effect("item");state.save_game();toast("Shipped %d items for %d Zenny."%[count,total])

func farm(index: int, selected: int = -1) -> void:
	if index<0 or index>=state.crops.size(): return
	var crop: Dictionary=state.crops[index]
	if state.energy<2: toast("Low energy. Take a breather, visit Data or eat at the cafe.");return
	var at: Vector2=world.crop_nodes[index].pos
	var rules: Dictionary=Catalog.crop(str(crop.get("kind","turnip")))
	if int(crop.stage)>=int(rules.nights):
		state.items[rules.item]+=1;state.harvested+=1;state.score+=30;crop.stage=int(rules.regrow);crop.watered=false
		audio.effect("item");floating(at+Vector2(0,-32),"+1 "+str(rules.name),Color("fff2b8"))
	elif not bool(crop.tilled) and selected in [-1,1]: crop.tilled=true;audio.effect("plant")
	elif int(crop.stage)<0 and bool(crop.tilled) and selected in [-1,3]:
		var seed: String=Catalog.crop(state.seed_kind).seed
		if state.items[seed]<=0: toast("Out of selected seeds. Visit the Junk Shop or press C to choose another crop.");return
		state.items[seed]-=1;crop.kind=state.seed_kind;crop.stage=0;crop.watered=state.day%4==0;audio.effect("plant")
	elif int(crop.stage)>=0 and not bool(crop.watered) and selected in [-1,2]:
		crop.watered=true;audio.effect("water");burst(at,Color("9bd7d5"),7,25)
	else: toast("This crop is watered. It will grow when you sleep." if bool(crop.watered) else "Use the hoe, seeds, then watering can. E does the next step.");return
	state.energy-=2;world.update_crops();state.save_game()

func use_tool() -> void:
	if area!="surface": return
	var target: Vector2=player.position+player.facing*24
	var nearest: int=-1;var distance: float=35
	for i in range(world.crop_nodes.size()):
		var d: float=world.crop_nodes[i].pos.distance_to(target)
		if d<distance: distance=d;nearest=i
	if nearest>=0: farm(nearest,tool)
	else: toast("Use garden tools on the plots beside the Flutter.")

func use_heal() -> void:
	if state.items.heal<=0: toast("No energy bottles. Visit the Junk Shop.");return
	if state.health>=state.max_health() and state.energy>=100: return
	state.items.heal-=1;state.health=mini(state.max_health(),state.health+55);state.energy=minf(100,state.energy+45)
	audio.effect("item");toast("Energy bottle: +55 health, +45 energy.");state.save_game()

func knock_out(exhausted: bool = false) -> void:
	if mode!="game": return
	var loss: int=mini(state.zenny,int(state.zenny*0.08))
	state.zenny-=loss;state.health=state.max_health();state.energy=100
	if exhausted: state.next_day()
	else: state.minutes=minf(1380,state.minutes+60)
	build_area("surface",1,Vector2(350,781))
	dialogue("Roll",["Data brought you back to the Flutter. You're safe, MegaMan.","We used %d Zenny for repairs. Your recovered parts are still here. Take an energy bottle next time, and dash through an attack if you need to!"%loss])
	state.save_game()

func resume_game() -> void:
	mode="game";ui.clear_overlay()

func objective() -> String:
	if not state.quest_started: return "Talk to Roll beside the Flutter"
	if state.repair==0: return "Bring the Servo Motor to Roll" if state.items.servo>0 else "Find the Servo Motor on ruin level 1"
	if state.repair==1: return "Bring the Ancient Circuit to Roll" if state.items.circuit>0 else "Find the Ancient Circuit on ruin level 2"
	if state.repair==2:
		if not state.tron_defeated: return "Meet Tron Bonne in the town plaza"
		return "Bring the Large Refractor to Roll" if state.items.refractor>0 else "Recover the Refractor on ruin level 3"
	return "Flutter restored. Make Kattelox your home"

func location_name() -> String:
	if area=="cabin": return "Flutter / Crew Cabin"
	if area in ["shop","museum","cafe","hall"]: return {"shop":"Junk Shop","museum":"Kattelox Museum","cafe":"Kattelox Cafe","hall":"City Hall"}[area]
	return "Kattelox Island" if area=="surface" else ("Bonne Showdown" if area=="bonne" else "Northern Ruins / Level %d"%floor_number)

func rank_name() -> String:
	if state.score>=15000: return "Master Digger"
	if state.score>=6000: return "Class A Digger"
	if state.score>=2000: return "Class B Digger"
	return "Apprentice Digger"

func toast(text: String) -> void:
	notice=text;notice_time=3.5

func radio(person: String, text: String) -> void:
	toast("%s: %s"%[person,text])

func particle(at: Vector2, colour: Color, life: float, velocity: Vector2) -> void:
	if effects.size()>160: return
	effects.append({"pos":at,"vel":velocity,"life":life,"max":life,"colour":colour,"text":""})

func burst(at: Vector2, colour: Color, count: int, force: float) -> void:
	for i in range(count): particle(at,colour,randf_range(0.2,0.55),Vector2(randf_range(-force,force),randf_range(-force,force)))

func floating(at: Vector2, text: String, colour: Color) -> void:
	effects.append({"pos":at,"vel":Vector2(0,-24),"life":0.8,"max":0.8,"colour":colour,"text":text})

func update_effects(delta: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		effects[i].life-=delta;effects[i].pos+=effects[i].vel*delta
		if effects[i].life<=0: effects.remove_at(i)

func draw_effects() -> void:
	for effect in effects:
		var colour: Color=effect.colour;colour.a=minf(1,effect.life/effect.max*2)
		if effect.text=="": effect_layer.draw_rect(Rect2(effect.pos,Vector2(3,3)),colour)
		else: effect_layer.draw_string(ThemeDB.fallback_font,effect.pos,effect.text,HORIZONTAL_ALIGNMENT_CENTER,-1,14,colour)
