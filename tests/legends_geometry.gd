extends SceneTree
var game
var failures: int=0
var checks: int=0
func _init():call_deferred("run")
func ticks(count: int=3):
 for i in range(count):await physics_frame
func check(condition: bool,message: String):
 checks+=1
 if not condition:failures+=1;push_error("GEOMETRY: "+message)
func ray(from: Vector3,to: Vector3) -> Dictionary:
 return game.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
func run():
 game=load("res://scenes/legends.tscn").instantiate();root.add_child(game);await ticks()
 game.start_new()
 while game.mode=="dialogue":
  game.ui.dialogue_text.visible_characters=-1;game.ui.advance_dialogue()
 await ticks(6)
 check(not ray(Vector3(8,.45,6),Vector3(12,.45,6)).is_empty(),"source-model container has solid geometry")
 game.player.position=Vector3(8.4,0,6);await ticks();Input.action_press("move_right");await ticks(35);Input.action_release("move_right")
 check(game.player.position.x<9.8,"walking cannot pass through service containers")
 check(game.world.blocked(Vector3(10,0,6)),"navigation agrees with container collision")
 check(not ray(Vector3(-18,2,-3),Vector3(-5,2,-3)).is_empty(),"Flutter fuselage blocks physical rays")
 var bottom: Vector3=game.world.get_meta("boarding_bottom")
 game.player.position=bottom;await ticks(6);Input.action_press("move_up");await ticks(65);Input.action_release("move_up");await ticks(3)
 print("STAIR END: ",game.player.position)
 check(game.player.position.y>1.8,"player can climb the whole staircase onto the landing")
 check(game.player.position.z<-.35,"staircase connects to the hatch")
 var hatch:=Vector3(-10.44,1.95,-1.025)
 var landing: Vector3=game.world.get_meta("boarding_top")
 check(landing.distance_to(hatch)<.2,"landing meets measured ship hatch")
 check(game.find_interaction().get("action","")=="cabin","boarding is reachable from the landing")
 check(not ray(Vector3(19,.7,12),Vector3(21,.7,12)).is_empty(),"harbour railing blocks movement and shots")
 check(not ray(Vector3(2,1,-5),Vector3(10,1,-5)).is_empty(),"authored shop building has collision")
 check(not ray(Vector3(-21,.8,8),Vector3(-19,.8,8)).is_empty(),"textured trees retain trunk collision")
 var rig=game.player.visual.get_meta("skeletons")[0]
 var anim: AnimationPlayer=game.player.visual.get_meta("run_animation")
 check(anim.has_animation("Run") and anim.has_animation("Idle"),"character has authored run and grounded idle animations")
 game.build_area("cabin",1,Vector3(3,0,3));await ticks(6);Input.action_press("move_right");await ticks(40);Input.action_release("move_right")
 check(game.player.position.x<4.5,"cabin table is solid")
 game.build_area("bonne",1,Vector3(0,0,3.5));await ticks(6)
 for enemy in game.enemies:enemy.set_physics_process(false)
 Input.action_press("move_up");await ticks(65);Input.action_release("move_up")
 check(game.player.position.z>-.95,"player cannot walk through the boss body")
 print("LEGENDS GEOMETRY: %d checks, %d failed"%[checks,failures])
 game.audio.shutdown();game.queue_free();game=null;await ticks(12);quit(1 if failures else 0)
