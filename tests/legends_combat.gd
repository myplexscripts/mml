extends SceneTree
var game
var failed: bool=false
func _init():call_deferred("run")
func check(ok: bool,text: String):
 if not ok:failed=true;push_error("COMBAT: "+text)
func ticks(count: int):
 for i in range(count):await physics_frame
func stop_inputs():
 for action in ["move_left","move_right","move_up","move_down","fire","charge","lock","dash"]:Input.action_release(action)
func move(direction: Vector3):
 for pair in [["move_left",maxf(0,-direction.x)],["move_right",maxf(0,direction.x)],["move_up",maxf(0,-direction.z)],["move_down",maxf(0,direction.z)]]:
  if pair[1]>.05:Input.action_press(pair[0],pair[1])
  else:Input.action_release(pair[0])
func run():
 game=load("res://scenes/legends.tscn").instantiate();root.add_child(game);await ticks(2);game.mode="game"
 game.build_area("bonne",1,Vector3(0,0,6.5));await ticks(3)
 # Normal starting armour, Buster and three bottles. AI remains fully active.
 Input.action_press("lock");Input.action_press("fire")
 var hits: int=0;var old_health: int=game.state.health
 for frame in range(3600):
  if game.state.tron_defeated or game.mode!="game":break
  var radial: Vector3=game.player.position;radial.y=0
  var direction:=Vector3(-radial.z,0,radial.x).normalized()
  direction+=radial.normalized()*(5.8-radial.length())*.8
  move(direction.normalized())
  if frame%75==0:Input.action_press("dash")
  elif frame%75==2:Input.action_release("dash")
  if game.state.health<50:game.use_bottle()
  if game.state.health<old_health:hits+=1
  old_health=game.state.health
  await physics_frame
 stop_inputs()
 check(game.state.tron_defeated,"Feldynaught beatable with normal controls and starting equipment")
 check(game.state.health>0 and game.state.score>=900,"survival and scoring")
 print("BONNE INPUT PLAYTEST: health=%d bottles=%d hits=%d score=%d won=%s"%[game.state.health,game.state.bottles,hits,game.state.score,game.state.tron_defeated])
 game.transition.clear();game.mode="game";game.build_area("bonne",1,Vector3(0,0,7));await ticks(3)
 for enemy in game.enemies:enemy.set_physics_process(false)
 var target=game.enemies[0];target.position=Vector3(0,0,2);target.health=100;game.player.facing=Vector3.FORWARD
 game.mouse_aim=true;Input.action_press("aim_right");await ticks(2)
 check(not game.mouse_aim and game.player.facing.x>.9,"right stick overrides stale mouse aim")
 Input.action_release("aim_right");game.player.facing=Vector3.FORWARD
 Input.action_press("fire");Input.action_press("charge");await ticks(48)
 check(target.health==100,"charging suppresses held normal fire")
 Input.action_release("charge");Input.action_release("fire");await ticks(18)
 check(target.hit_time>0,"hits expose enemy health feedback")
 check(target.health==60,"charged input deals 40 damage")
 game.player.shot_cooldown=0;target.position=Vector3(0,0,12)
 game.player.facing=Vector3.BACK;game.player.fire();await ticks(35)
 check(target.health==60,"swept Buster ray stops at arena wall")
 target.position=Vector3(0,0,3);game.throw_grenade(Vector3(0,1,3),Vector3.ZERO);await ticks(90)
 check(target.health==12,"physical grenade deals splash damage")
 game.shoot(Vector3(0,1,4),Vector3(0,0,-4),false,12)
 var shot=game.world.get_child(game.world.get_child_count()-1);var before: Vector3=shot.position
 game.ui.pause_screen("Status");await ticks(20);check(shot.position.is_equal_approx(before),"pause freezes projectiles")
 game.resume_game();await ticks(30);check(not is_instance_valid(shot) or not shot.position.is_equal_approx(before),"resume advances projectiles")
 print("LEGENDS COMBAT: %s"%["FAIL" if failed else "PASS"])
 game.audio.shutdown();game.queue_free();game=null;await ticks(12);quit(1 if failed else 0)
