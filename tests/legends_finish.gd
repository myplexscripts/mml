extends SceneTree
var game
var checks: int=0
var failures: int=0
func _init():call_deferred("run")
func ticks(count: int=3):
 for i in range(count):await physics_frame
func check(condition: bool,message: String):
 checks+=1
 if not condition:failures+=1;push_error("FINISH: "+message)
func ray(from: Vector3,to: Vector3) -> Dictionary:
 return game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
func run():
 game=load("res://scenes/legends.tscn").instantiate();root.add_child(game);await ticks()
 var quit_button=game.ui.overlay.find_child("QuitGame",true,false)
 check(quit_button!=null and quit_button.size.y>=44 and quit_button.get_global_rect().end.y<=720,"native Quit button is accessible within the viewport")
 game.start_new()
 while game.mode=="dialogue":game.ui.dialogue_text.visible_characters=-1;game.ui.advance_dialogue()
 await ticks(8)
 game.player.charge=1;game.player.dash_time=.15;game.player.velocity.x=5
 game.ui.pause_screen("Status")
 check(game.player.charge==0 and game.player.dash_time==0,"opening a menu cancels pending charge and dash")
 game.resume_game();await ticks(6)
 check(game.player.shot_cooldown==0 and absf(game.player.velocity.x)<.01,"closing the menu does not release a stale shot or dash")
 game.ui.pause_screen("Options");game.ui.credits_screen()
 var back:=InputEventKey.new();back.physical_keycode=KEY_ESCAPE;back.pressed=true;game._unhandled_input(back)
 check(game.mode=="pause" and game.ui.pause_tab=="Options","Escape from pause credits returns to Options")
 game.ui.title_screen();game.ui.credits_screen();game._unhandled_input(back)
 check(game.mode=="title","Escape from title credits returns to the title")
 game.resume_game();game.build_area("island",1,Vector3(0,0,7));game.npcs.clear();game.world.interactables.clear();await ticks(8)
 game.world.interact("Test console",Vector3(0,0,8.7),"test")
 var wall=game.world.box(Vector3(0,.8,7.85),Vector3(2,1.6,.3),Color.WHITE,true);await ticks()
 check(game.find_interaction().is_empty(),"nearby interactions cannot pass through a solid wall")
 game.world.remove_obstacle(wall);await ticks()
 check(game.find_interaction().get("action","")=="test","interaction becomes reachable when the obstruction is removed")
 game.build_area("ruins",1,Vector3(0,0,10.5));await ticks(6)
 for enemy in game.enemies:enemy.set_physics_process(false)
 var plans: Dictionary={}
 for item in game.world.interactables:
  if item.action=="plans":plans=item;break
 var at: Vector3=plans.pos
 check(not ray(at+Vector3(-1,.4,0),at+Vector3(1,.4,0)).is_empty(),"weapon-plan box is initially solid")
 game.execute_interaction(plans);await ticks(4)
 check(ray(at+Vector3(-1,.4,0),at+Vector3(1,.4,0)).is_empty(),"collecting weapon plans removes their physical collider")
 check(not game.world.blocked(at),"collecting weapon plans also clears navigation")
 for entry in [["island",Vector3(6,0,-1.9),"shop"],["cabin",Vector3(-3.8,0,-2.5),"rest"],["cabin",Vector3(5.8,0,-2),"workshop"],["cabin",Vector3(0,0,5.8),"cabin_exit"]]:
  game.resume_game();game.build_area(entry[0],1,entry[1]);await ticks(8)
  check(game.find_interaction().get("action","")==entry[2],"physical approach remains accessible: "+entry[2])
 game.resume_game();game.build_area("island",1,Vector3(0,0,15));await ticks(8)
 var before: Dictionary=game.state.to_data()
 Input.action_press("move_down");await ticks(45);Input.action_release("move_down");await ticks(110)
 check(game.player.position.y>-.1 and game.player.position.z<17 and game.player.is_on_floor(),"shore barrier prevents walking into the sea")
 game.player.position=Vector3(30,-9,25);await ticks(30)
 check(game.player.position.y>-.1 and game.player.position.z<16.5 and game.player.is_on_floor(),"an unexpected fall below the map recovers onto stable ground")
 check(game.state.zenny==before.zenny and game.state.health==before.health and game.state.parts==before.parts,"shore recovery preserves money, health and parts")
 print("LEGENDS FINISH: %d checks, %d failed"%[checks,failures])
 game.audio.shutdown();game.queue_free();game=null;await ticks(12);quit(1 if failures else 0)
