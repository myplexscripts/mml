extends SceneTree
var game
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if condition: print("PASS: "+description)
	else: failures+=1;push_error("FAIL: "+description)

func frames(count: int = 3) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await frames();game.mode="game";game.ui.clear_overlay()
	# A literal v0.2 save has neither crop kinds nor the new persistent fields.
	var legacy: Dictionary=game.state.to_data().duplicate(true)
	for key in ["grenade_unlocked","blueprint","deep_depth","seed_kind","gifts"]: legacy.erase(key)
	legacy.items={"scrap":7,"seeds":4,"turnips":2,"fish":1,"heal":2,"relic":1,"servo":1,"circuit":0,"refractor":0}
	legacy.crops[0]={"tilled":true,"stage":3,"watered":true}
	legacy.repair=1
	var file:=FileAccess.open(game.state.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy));file.close()
	check(game.state.load_game() and game.state.crops[0].kind=="turnip" and game.state.crops[0].stage==3 and game.state.repair==1,"v0.2 saves retain mature crops and repair progress")
	check(game.state.items.shard==0 and game.state.deep_depth==4 and not game.state.grenade_unlocked,"Old saves receive safe expansion defaults")
	for area in ["shop","museum","cafe","hall"]:
		game.build_area(area,1,Vector2(320,385));await frames()
		check(game.world.path_to(Vector2(320,385),Vector2(320,280)).size()>0,"Reachable counter in "+area)
		var start: Vector2=game.player.position
		Input.action_press("move_up");await frames(100);Input.action_release("move_up")
		check(game.player.position.y>=260 and game.player.position.y<start.y,"Solid counter blocks movement in "+area)
		game.execute_interaction(game.world.interactables[0]);await frames(45)
		check(game.area=="surface" and not game.world.blocked(game.player.position),"Interior door returns to safe town position: "+area)
	game.build_area("surface",1,Vector2(136,816));game.mode="game"
	game.state.seed_kind="tomato";game.state.items.tomato_seeds=1
	game.state.crops[1]={"tilled":true,"stage":-1,"watered":false,"kind":"turnip"}
	game.farm(1)
	check(game.state.items.tomato_seeds==0 and game.state.crops[1].kind=="tomato","Selected crop consumes its own seed")
	for i in range(4): game.state.crops[1].watered=true;game.state.next_day()
	game.farm(1)
	check(game.state.items.tomatoes==1 and game.state.crops[1].stage==2,"Tomatoes harvest after four nights and retain regrowth plant")
	for i in range(2): game.state.crops[1].watered=true;game.state.next_day()
	game.farm(1)
	check(game.state.items.tomatoes==2,"Tomato regrowth produces a second harvest without another seed")
	game.state.items.sunflowers=1;game.state.items.turnips=0;game.state.items.fish=0
	var money: int=game.state.zenny;game.sell_produce()
	check(game.state.zenny==money+290 and game.state.items.tomatoes==0 and game.state.items.sunflowers==0,"New crops ship at their catalogue prices")
	game.state.items.sunflowers=2;var bond: int=game.state.friendship.Amelia
	game.give_gift("Amelia");game.resume_game();game.give_gift("Amelia")
	check(game.state.friendship.Amelia==mini(10,bond+2) and game.state.items.sunflowers==1,"A favourite gift improves friendship once per day")
	game.mode="game";game.build_area("ruins",1,Vector2(137,600));await frames()
	for enemy in game.enemies: enemy.set_physics_process(false)
	var crates: Array=get_nodes_in_group("salvage")
	var crate=crates[0];var id: String=crate.claim_id
	game.shoot(crate.position+Vector2(0,50),Vector2(0,-390),false,30)
	await frames(20)
	check(id in game.state.claimed and get_nodes_in_group("salvage").size()==crates.size()-1,"Buster breaks a physical salvage crate")
	game.player.position=Vector2(137,565);await frames(70)
	check(game.state.items.shard>=1,"Salvage drops a collectable Refractor shard")
	var bounced=game.Grenade.new();bounced.game=game;bounced.position=Vector2(240,380);bounced.motion=Vector2(0,-180)
	game.world.entities.add_child(bounced);await frames(20)
	check(bounced.motion.y>0 and bounced.position.y>=354 and bounced.height>14,"Lobbed grenade bounces off a swept wall hit while its height follows gravity")
	var fuse: float=bounced.fuse;game.ui.pause_screen("Status");await frames(5)
	check(is_equal_approx(bounced.fuse,fuse),"Pause freezes an airborne grenade fuse")
	game.resume_game();bounced.queue_free();await frames()
	game.build_area("ruins",1,Vector2(480,598));await frames()
	var duplicate: bool=false
	for box in get_nodes_in_group("salvage"):
		if box.claim_id==id: duplicate=true
	check(not duplicate,"Re-entering a ruin cannot duplicate claimed salvage")
	for item in game.world.interactables.duplicate():
		if item.action=="blueprint": game.execute_interaction(item)
	check(game.state.blueprint,"Eastern weapon plans unlock Roll's crafting recipe")
	game.resume_game();game.state.zenny=900;game.state.items.scrap=12;game.state.items.shard=4
	game.execute_choice("build_grenade");game.resume_game()
	check(game.state.grenade_unlocked and game.state.zenny==450 and game.state.items.scrap==4 and game.state.items.shard==1,"Grenade Arm crafting charges the exact recipe once")
	game.execute_choice("build_grenade")
	check(game.state.zenny==450,"Crafted equipment cannot charge the recipe twice")
	game.state.energy=100;game.player.special_fire()
	check(game.state.energy==82 and game.player.grenade_cooldown>0,"Grenade fire consumes energy and begins cooldown")
	game.player.special_fire();check(game.state.energy==82,"Cooldown prevents repeated grenade spending")
	await frames(80)
	# Splash damages enemies in view, but never an enemy behind a wall.
	for enemy in game.enemies: enemy.set_physics_process(false)
	var near=game.enemies[0];var behind=game.enemies[1]
	near.position=Vector2(210,420);behind.position=Vector2(210,310)
	near.health=100;behind.health=100
	var grenade=game.Grenade.new();grenade.game=game;grenade.position=Vector2(210,385)
	game.world.entities.add_child(grenade);await frames();grenade.explode();await frames()
	check(near.health==52 and behind.health==100,"Grenade splash respects wall occlusion")
	game.state.completed=true
	var layouts: Array=[]
	for depth in [4,5,6]:
		game.build_area("ruins",depth,Vector2(480,598));await frames()
		layouts.append(game.world.floor_cells.duplicate())
		check(game.world.path_to(Vector2(480,598),Vector2(480,112)).size()>0,"Deep Dig has a connected guardian route at depth %d"%depth)
	check(layouts[0]!=layouts[1] and layouts[1]!=layouts[2],"Deep Dig rotates distinct side-chamber layouts")
	for enemy in game.enemies.duplicate(): enemy.hurt(10000,enemy.position+Vector2(0,20))
	await frames()
	money=game.state.zenny;game.recover_treasure(game.world.interactables[1])
	check(game.state.deep_depth==7 and game.state.zenny==money+700,"A completed Deep Dig advances depth and pays the scaled cache reward")
	game.resume_game()
	game.state.save_game();var restored=game.State.new();restored.load_game()
	check(restored.grenade_unlocked and restored.blueprint and restored.seed_kind=="tomato" and restored.gifts.has("Amelia"),"Expansion equipment, seeds and daily gifts persist")
	game.state.next_day()
	check(game.state.gifts.is_empty(),"Sleeping permits a new day of neighbour gifts")
	print("EXPANSION CHECKS: %d passed, %d failed"%[checks-failures,failures])
	game.audio.shutdown();game.queue_free();game=null;await frames(12)
	quit(1 if failures>0 else 0)
