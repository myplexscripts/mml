extends SceneTree
var game
func _init() -> void: call_deferred("run")

func wait_frames(count: int = 6) -> void:
	for i in range(count): await process_frame
	await RenderingServer.frame_post_draw

func capture(name: String) -> void:
	await wait_frames(10)
	root.get_texture().get_image().save_png("res://test-results/"+name+".png")
	for node in game.ui.overlay.find_children("*","Control",true,false):
		if node is Button and node.visible:
			var bounds: Rect2=node.get_global_rect()
			var ancestor=node.get_parent()
			while ancestor is Control:
				if ancestor.clip_contents: bounds=bounds.intersection(ancestor.get_global_rect())
				ancestor=ancestor.get_parent()
			if bounds.has_area() and (bounds.end.y>360.5 or bounds.position.y<0):
				push_error("Clipped control: "+node.name+" "+str(bounds))

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://test-results")
	var ignored:=FileAccess.open("res://test-results/.gdignore",FileAccess.WRITE);ignored.close()
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await capture("title")
	game.start_new();game.ui.type_clock=9999;await capture("dialogue")
	while game.mode=="dialogue": game.ui.advance_dialogue()
	await capture("flutter")
	game.player.position=Vector2(760,530);await wait_frames(65)
	await capture("town")
	for tab in ["Status","Equipment","Map","Journal","Options"]:
		game.ui.pause_screen(tab);await capture("pause_"+tab.to_lower())
	game.open_shop();await capture("shop")
	game.open_home();await capture("home")
	game.resume_game();game.build_area("cabin",1,Vector2(320,375));await capture("cabin")
	for area in ["shop","museum","cafe","hall"]:
		game.resume_game();game.state.museum_donated=3
		game.build_area(area,1,Vector2(320,335));await capture("interior_"+area)
	game.resume_game();game.build_area("surface",1,Vector2(184,845))
	for i in range(12): game.state.crops[i]={"tilled":true,"stage":3 if i%3==0 else (4 if i%3==1 else 5),"watered":true,"kind":["turnip","tomato","sunflower"][i%3]}
	game.world.update_crops();await capture("garden")
	game.open_seeds();await capture("seed_menu")
	game.resume_game();game.state.quest_started=true
	game.build_area("ruins",3,Vector2(480,329));await wait_frames(15)
	game.state.grenade_unlocked=true;await capture("ruins")
	game.ui.pause_screen("Map");await capture("ruin_map")
	game.resume_game();game.build_area("bonne",1,Vector2(320,350));await wait_frames(10)
	await capture("bonne")
	game.resume_game();game.build_area("surface",1,Vector2(1140,910))
	game.ui.fishing_screen();game.ui.fish_time=3;await capture("fishing")
	game.audio.shutdown();game.queue_free();game=null;await wait_frames(12)
	await create_timer(.15).timeout
	quit()
