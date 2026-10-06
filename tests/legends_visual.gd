extends SceneTree
var game
func _init():call_deferred("run")
func frames(count: int=8):
 for i in range(count):await process_frame
 await RenderingServer.frame_post_draw
func capture(name: String):
 await frames(16);root.get_texture().get_image().save_png("res://test-results/legends_"+name+".png")
func close_dialogue():
 while game.mode=="dialogue":
  game.ui.dialogue_text.visible_characters=game.ui.dialogue_text.get_total_character_count();game.ui.advance_dialogue()
 await frames()
func run():
 DirAccess.make_dir_recursive_absolute("res://test-results")
 game=load("res://scenes/legends.tscn").instantiate();root.add_child(game);await capture("title")
 game.start_new();game.ui.type_clock=9999;await capture("dialogue");await close_dialogue()
 await capture("flutter")
 game.player.position=Vector3(-4.4,0,5.9);await frames(45);await capture("landing")
 game.player.position=game.world.get_meta("boarding_bottom");await frames(4)
 Input.action_press("move_up")
 for tick in range(65):await physics_frame
 Input.action_release("move_up");await frames(20);await capture("boarding")
 for tab in ["Status","Equipment","Map","Journal","Options"]:game.ui.pause_screen(tab);await capture(tab.to_lower())
 game.resume_game();game.build_area("cabin",1,Vector3(0,0,3));await capture("cabin")
 game.open_workshop();await capture("workshop")
 game.resume_game();game.state.quest_started=true;game.build_area("ruins",1,Vector3(0,0,10.5));await capture("ruins")
 game.player.position=Vector3(0,0,0);await frames(40);await capture("ruins_centre")
 game.ui.pause_screen("Map");await capture("ruin_map")
 game.resume_game();game.state.repair=2;game.build_area("bonne",1,Vector3(0,0,6.5));await capture("bonne")
 game.audio.shutdown();game.queue_free();game=null;await frames(12);quit()
