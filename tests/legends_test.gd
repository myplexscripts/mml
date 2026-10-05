extends SceneTree
var game
var passed: int=0
var failed: int=0
func _init():call_deferred("run")
func check(ok: bool,text: String):
 if ok:passed+=1
 else:failed+=1;push_error("CHECK: "+text)
func ticks(count: int=2):
 for i in range(count):await physics_frame
func close_dialogue():
 while game.mode=="dialogue":
  game.ui.dialogue_text.visible_characters=game.ui.dialogue_text.get_total_character_count();game.ui.advance_dialogue()
 await ticks()
func clear_enemies():
 for enemy in game.enemies.duplicate():
  if is_instance_valid(enemy):enemy.hurt(10000,game.player.position)
 await ticks(3)
func run():
 game=load("res://scenes/legends.tscn").instantiate();root.add_child(game);await ticks()
 check(game.mode=="title","title")
 game.state.zenny=999;game.state.save_game();var original_save: String=FileAccess.get_file_as_string(game.state.SAVE_PATH)
 game.ui.menu("NEW ADVENTURE","Replace save?",[],true)
 var cancel:=InputEventKey.new();cancel.physical_keycode=KEY_ESCAPE;cancel.pressed=true;game._unhandled_input(cancel)
 check(game.mode=="title" and FileAccess.get_file_as_string(game.state.SAVE_PATH)==original_save,"Escape cancels new adventure without replacing save")
 check(game.ui.energy.size.y==6 and game.ui.energy.get_combined_minimum_size().y==0,"energy meter respects its six-pixel height")
 game.start_new();await close_dialogue();check(game.mode=="game","new adventure")
 var ship=game.world.get_node("LandedFlutter")
 check(is_zero_approx(ship.rotation.x) and is_zero_approx(ship.rotation.z) and ship.position.y<1,"Flutter lands upright above its supports")
 game.player.position=Vector3(-5.4,0,4.5);await ticks(2);Input.action_press("move_up");await ticks(30);Input.action_release("move_up")
 check(game.player.position.y>.45,"metal boarding stairs have a climbable physical ramp")
 game.player.position=Vector3(0,0,8)
 game.execute_choice("dig_1");check(game.transition.is_empty(),"ruins require repair plan")
 game.repair_ship();await close_dialogue()
 for locked in ["dig_2","dig_3","dig_4","dig_16"]:game.execute_choice(locked)
 check(game.transition.is_empty(),"locked and invalid floors reject travel")
 var zoom:=InputEventMouseButton.new();zoom.button_index=MOUSE_BUTTON_WHEEL_UP;zoom.pressed=true;game._unhandled_input(zoom)
 check(game.state.camera_zoom>1,"wheel zoom adjusts camera")
 check(game.state.quest_started,"repair plan starts")
 game.build_area("cabin",1,Vector3(0,0,3));await ticks();game.state.health=30;game.state.energy=10
 game.execute_interaction({"action":"rest"});check(game.state.health==100 and game.state.energy==100,"cabin restores")
 game.build_area("ruins",1,Vector3(0,0,10.5));await ticks(3)
 var start: Vector3=game.player.position
 Input.action_press("move_up");await ticks(25);Input.action_release("move_up")
 check(game.player.position.z<start.z-1,"W movement uses physics")
 game.player.position=Vector3(-4,0,9.8);await ticks(2);Input.action_press("move_left");await ticks(30);Input.action_release("move_left")
 check(game.player.position.x> -6.0,"merged ruin wall blocks player")
 game.player.position=Vector3(0,0,10.5);await ticks(3);var energy: float=game.state.energy
 Input.action_press("dash");await ticks(2);Input.action_release("dash");await ticks(10)
 check(game.player.position.distance_to(Vector3(0,0,10.5))>1 and game.state.energy<energy,"dash moves and costs energy")
 var cache: Dictionary=game.world.interactables[1];game.recover_cache(cache);check(not "servo" in game.state.parts,"guarded cache stays closed")
 await clear_enemies();game.recover_cache(cache);await close_dialogue();check("servo" in game.state.parts,"cleared cache grants Servo")
 var score: int=game.state.score;check(score>1000,"combat and cache score")
 game.build_area("island",1,Vector3(0,0,8));game.repair_ship();await close_dialogue();check(game.state.repair==1 and not "servo" in game.state.parts,"repair consumes motor")
 game.build_area("ruins",2,Vector3(0,0,10.5));await ticks();check(game.enemies.any(func(e):return e.boss),"level two guardian")
 await clear_enemies();game.recover_cache(game.world.interactables[1]);await close_dialogue()
 game.build_area("island",1,Vector3(0,0,8));game.repair_ship();await close_dialogue();check(game.state.repair==2,"circuit repair")
 check(game.npcs.any(func(n):return n.person=="Tron"),"Tron appears")
 game.build_area("bonne",1,Vector3(0,0,6.5));await ticks();await clear_enemies();check(game.state.tron_defeated,"Bonne win unlocks core")
 await close_dialogue();game.transition.clear();game.fading_in=false;game.fade=0;game.mode="game"
 game.build_area("ruins",3,Vector3(0,0,10.5));await ticks();await clear_enemies();game.recover_cache(game.world.interactables[1]);await close_dialogue()
 game.build_area("island",1,Vector3(0,0,8));game.repair_ship();await close_dialogue();check(game.state.completed and game.state.repair==3 and game.mode=="summary","complete repair campaign")
 game.resume_game();game.state.zenny=2000;game.state.scrap=30;game.upgrade("power");check(game.state.power==1 and game.state.zenny==1650,"priced upgrade")
 game.state.weapon_plans=true;game.state.shards=8;game.execute_choice("grenade");await close_dialogue();check(game.state.grenade,"Grenade Arm built")
 game.resume_game();game.build_area("ruins",4,Vector3(0,0,10.5));await ticks();await clear_enemies();game.recover_cache(game.world.interactables[1]);await close_dialogue();check(game.state.deepest==5,"repeatable deep digs")
 game.state.health=25;game.use_bottle();check(game.state.health==80 and game.state.bottles==2,"healing inventory")
 game.state.parts=["servo"];game.knock_out();await close_dialogue();check(game.area=="island" and "servo" in game.state.parts and game.state.health==100,"defeat returns home retaining parts")
 check(game.state.save_game(),"atomic save")
 var loaded=load("res://scripts/legends/state.gd").new();check(loaded.load_game() and loaded.completed and loaded.grenade and loaded.power==1 and loaded.deepest==5 and is_equal_approx(loaded.camera_zoom,1.1),"save round trip and camera preference")
 game.ui.pause_screen("Options");game.ui.credits_screen();var buttons=game.ui.overlay.find_children("*","Button",true,false);buttons[-1].pressed.emit();check(game.mode=="pause","credits returns to pause")
 print("LEGENDS CHECKS: %d passed, %d failed"%[passed,failed])
 loaded=null;game.audio.shutdown();game.queue_free();game=null;await ticks(12);quit(1 if failed else 0)
