extends SceneTree
## Regression tests exercise real game actions and physics, using an isolated
## user-data directory supplied by CI. No production save is ever overwritten.
var game
var failures: int = 0
var checks: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error("FAIL: "+description)
	else: print("PASS: "+description)

func frames(count: int = 2) -> void:
	for i in range(count): await physics_frame

func close_dialogue() -> void:
	while game.mode=="dialogue": game.ui.advance_dialogue()
	await frames()

func defeat_room() -> void:
	for enemy in game.enemies.duplicate():
		if is_instance_valid(enemy): enemy.hurt(10000,enemy.position+Vector2(0,20))
	await frames(3)

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(3)
	check(game.mode=="title","Game starts at a working title screen")
	game.start_new()
	await close_dialogue()
	check(game.active(),"Opening dialogue returns control to the player")
	game.roll_story()
	await close_dialogue()
	check(game.state.quest_started,"Roll starts the repair quest")
	# Capsule/foot collision must slide along a building instead of tunnelling.
	game.player.position=Vector2(560,705)
	await frames()
	Input.action_press("move_up")
	await frames(50)
	Input.action_release("move_up")
	check(game.player.position.y>=game.world.blockers[0].end.y+7,"Player cannot walk through the Junk Shop")
	var location: Vector2=game.player.position
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(game.player.position.x>location.x+15,"Player slides along a blocking wall")
	# Pause stops simulation time and movement, but it does not quit the game.
	game.ui.pause_screen("Map")
	var minute: float=game.state.minutes
	Input.action_press("move_right")
	await frames(5)
	Input.action_release("move_right")
	check(is_equal_approx(minute,game.state.minutes),"Pause freezes the daily clock")
	game.resume_game()
	# Garden progression requires watered nights, never an unwatered exploit.
	game.build_area("surface",1,Vector2(136,816))
	game.farm(0);game.farm(0);game.farm(0)
	check(game.state.crops[0].tilled and game.state.crops[0].stage==0 and game.state.crops[0].watered,"Garden can be tilled, planted and watered")
	game.state.next_day()
	check(game.state.crops[0].stage==1,"Watered crops grow overnight")
	game.state.next_day()
	check(game.state.crops[0].stage==1,"Unwatered crops do not advance")
	game.state.crops[0].watered=true;game.state.next_day()
	game.state.crops[0].watered=true;game.state.next_day()
	game.farm(0)
	check(game.state.items.turnips==1,"Mature crops become inventory produce")
	var before: int=game.state.zenny
	game.sell_produce()
	check(game.state.zenny==before+80 and game.state.items.turnips==0,"Shipping exchanges produce for the listed price")
	game.state.items.fish=2
	game.claim_request("fish","fish",2,160)
	before=game.state.zenny
	game.claim_request("fish","fish",2,160)
	check(game.state.zenny==before,"A daily request cannot be paid twice")
	# Real ray collision: a high-speed shot cannot pass a ruin wall.
	game.mode="game"
	game.build_area("ruins",1,Vector2(480,598))
	await frames(3)
	for enemy in game.enemies: enemy.set_physics_process(false)
	var enemy=game.enemies[0]
	enemy.position=Vector2(240,300)
	var health: int=enemy.health
	game.shoot(Vector2(240,420),Vector2(0,-600),false,100)
	await frames(25)
	check(enemy.health==health,"Projectiles stop at solid walls")
	# Close-range shot must damage an actual physics body.
	enemy.position=Vector2(210,510)
	game.shoot(Vector2(210,570),Vector2(0,-390),false,5)
	await frames(15)
	check(enemy.health==health-5,"Projectile ray hits a Reaverbot collision body")
	game.player.invincible=0;game.state.health=100
	game.player.hurt(10,game.player.position+Vector2(10,0))
	game.player.hurt(10,game.player.position+Vector2(10,0))
	check(game.state.health==90,"Damage grants invulnerability instead of repeated contact damage")
	game.player.invincible=0;game.player.dash_time=.1
	game.player.hurt(10,game.player.position+Vector2(10,0))
	check(game.state.health==90,"Dash safely passes through attacks")
	game.player.dash_time=0
	await defeat_room()
	check(game.state.enemies_today>=5 and game.state.score>0,"Combat awards score and town request progress")
	var cache: Dictionary=game.world.interactables[1]
	game.recover_treasure(cache)
	await close_dialogue()
	check(game.state.items.servo==1,"First ruin cache awards the Servo Motor")
	game.build_area("surface",1,Vector2(441,790));game.roll_story()
	await close_dialogue()
	check(game.state.repair==1 and game.state.items.servo==0,"Roll consumes the motor and unlocks level 2")
	game.build_area("ruins",2,Vector2(480,598))
	await frames(3)
	check(game.world.path_to(Vector2(480,598),Vector2(480,112)).size()>0,"Navigation reaches the northern vault")
	cache=game.world.interactables[1]
	game.recover_treasure(cache)
	check(game.state.items.circuit==0,"A living guardian blocks its cache")
	await defeat_room()
	game.recover_treasure(cache)
	await close_dialogue()
	game.build_area("surface",1,Vector2(441,790));game.roll_story()
	await close_dialogue()
	check(game.state.repair==2,"Ancient Circuit restores navigation")
	var tron_found: bool=false
	for npc in game.npcs:
		if npc.person=="Tron": tron_found=true
	check(tron_found,"Tron appears immediately after the second repair")
	game.build_area("bonne",1,Vector2(320,370))
	check(game.tool==0,"Combat areas equip the Buster automatically")
	await frames(2)
	await defeat_room()
	await close_dialogue()
	await frames(45)
	check(game.state.tron_defeated and game.area=="surface","Bonne battle unlocks the core and returns to town")
	game.build_area("ruins",3,Vector2(480,598))
	await frames(3)
	await defeat_room()
	cache=game.world.interactables[1];game.recover_treasure(cache)
	await close_dialogue()
	check(game.state.items.refractor==1,"Final guardian protects a recoverable Refractor")
	game.build_area("surface",1,Vector2(441,790));game.roll_story()
	await close_dialogue()
	check(game.state.completed and game.state.repair==3,"The full campaign reaches its ending")
	game.resume_game()
	game.build_area("cabin",1,Vector2(320,380))
	await frames(3)
	check(game.world.path_to(Vector2(320,380),Vector2(173,250)).size()>0,"Flutter cabin has a reachable bunk")
	game.build_area("surface",1,Vector2(350,781))
	game.state.items.scrap=20;game.state.zenny=2000
	game.upgrade("power")
	check(game.state.power==1 and game.state.zenny==1650 and game.state.items.scrap==16,"Workshop charges exactly the displayed upgrade cost")
	game.resume_game();game.state.health=20;game.state.items.heal=1
	game.use_heal()
	check(game.state.health==75 and game.state.items.heal==0,"Energy bottles heal and are consumed")
	game.ui.fishing_screen();game.ui.fish_time=3
	for i in range(3): game.ui.fish_cursor=game.ui.fish_target;game.ui.fish_press()
	check(game.state.items.fish>=1 and game.mode=="game","Fishing's three timing checks award a real item")
	game.state.crops[5]={"tilled":true,"stage":2,"watered":true}
	game.state.energy=73;game.state.health=66
	check(game.state.save_game(),"Atomic save succeeds")
	var restored=load("res://scripts/state.gd").new()
	check(restored.load_game(),"Save loads successfully")
	check(restored.completed and restored.repair==3 and restored.power==1,"Save preserves campaign and equipment progress")
	check(restored.crops[5].stage==2 and restored.crops[5].watered and restored.health==66 and restored.energy==73,"Save preserves farm, health and energy")
	check(restored.items==game.state.items and restored.claimed==game.state.claimed,"Save preserves inventory and request rewards")
	# Sleeping restores stats, clears daily rewards and persists crop growth.
	game.sleep_now()
	check(game.state.health==game.state.max_health() and game.state.energy==100 and game.state.claimed.is_empty(),"Sleep resets daily state and restores the player")
	print("GAMEPLAY CHECKS: %d passed, %d failed"%[checks-failures,failures])
	game.audio.shutdown();game.queue_free();game=null;await frames(12)
	quit(1 if failures>0 else 0)
