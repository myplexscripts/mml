extends Node3D
const State=preload("res://scripts/legends/state.gd")
const World=preload("res://scripts/legends/world.gd")
const Actor=preload("res://scripts/legends/actor.gd")
const Projectile=preload("res://scripts/legends/projectile.gd")
const Grenade=preload("res://scripts/legends/grenade.gd")
const Pickup=preload("res://scripts/legends/pickup.gd")
const Audio=preload("res://scripts/audio.gd")
const UI=preload("res://scripts/legends/ui.gd")
var state=State.new()
var mode: String="title"
var menu_return_title: bool=false
var area: String="island"
var depth: int=1
var world
var player
var camera: Camera3D
var audio
var ui
var enemies: Array=[]
var npcs: Array=[]
var effects: Array=[]
var interaction: Dictionary={}
var mouse_aim: bool=false
var combo: int=0
var combo_time: float=0
var run_score: int=0
var shake: float=0
var clock: float=0
var notice: String=""
var notice_time: float=0
var save_clock: float=0
var camera_focus:=Vector3.ZERO
var transition: Dictionary={}
var fade: float=0
var fading_in: bool=false

func _ready() -> void:
 inputs();get_tree().auto_accept_quit=false
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=27;camera.near=.1;camera.far=160;add_child(camera)
 audio=Audio.new();audio.game=self;add_child(audio)
 ui=UI.new();ui.game=self;add_child(ui)
 build_area("island",1,Vector3(0,0,8));ui.title_screen()

func inputs() -> void:
 var keys: Dictionary={"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E,KEY_F,KEY_SPACE],"fire":[KEY_J],"charge":[KEY_H],"dash":[KEY_SHIFT],"lock":[KEY_K],"special":[KEY_L],"heal":[KEY_Q],"pause_game":[KEY_ESCAPE],"map":[KEY_M],"inventory":[KEY_TAB]}
 for action in keys:
  if not InputMap.has_action(action):InputMap.add_action(action)
  InputMap.action_erase_events(action)
  for key in keys[action]:
   var event:=InputEventKey.new();event.physical_keycode=key;InputMap.action_add_event(action,event)
 var buttons: Dictionary={"interact":JOY_BUTTON_A,"fire":JOY_BUTTON_X,"dash":JOY_BUTTON_RIGHT_SHOULDER,"lock":JOY_BUTTON_LEFT_SHOULDER,"special":JOY_BUTTON_B,"heal":JOY_BUTTON_Y,"pause_game":JOY_BUTTON_START}
 for action in buttons:
  var event:=InputEventJoypadButton.new();event.button_index=buttons[action];InputMap.action_add_event(action,event)
 for prefix in ["move","aim"]:
  for direction in ["left","right","up","down"]:
   var action: String=prefix+"_"+direction
   if not InputMap.has_action(action):InputMap.add_action(action,.2)
   var event:=InputEventJoypadMotion.new();event.axis=(JOY_AXIS_LEFT_X if prefix=="move" else JOY_AXIS_RIGHT_X) if direction in ["left","right"] else (JOY_AXIS_LEFT_Y if prefix=="move" else JOY_AXIS_RIGHT_Y)
   event.axis_value=-1 if direction in ["left","up"] else 1;InputMap.action_add_event(action,event)
 var trigger:=InputEventJoypadMotion.new();trigger.axis=JOY_AXIS_TRIGGER_RIGHT;trigger.axis_value=1;InputMap.action_add_event("charge",trigger)
 for pair in [["fire",MOUSE_BUTTON_LEFT],["charge",MOUSE_BUTTON_RIGHT]]:
  var event:=InputEventMouseButton.new();event.button_index=pair[1];InputMap.action_add_event(pair[0],event)

func active() -> bool:return mode=="game" and is_instance_valid(player)
func pointer_in_world() -> bool:
 var p:=get_viewport().get_mouse_position()
 return p.y>105 and p.y<660 and not Rect2(1080,455,178,240).has_point(p) and not Rect2(22,620,294,74).has_point(p)
func mouse_point() -> Vector3:
 var p:=get_viewport().get_mouse_position();var start:=camera.project_ray_origin(p);var direction:=camera.project_ray_normal(p)
 var result=Plane(Vector3.UP,.65).intersects_ray(start,direction)
 return result if result is Vector3 else player.position+player.facing*8

func _process(delta: float) -> void:
 clock+=delta;notice_time=maxf(0,notice_time-delta)
 if not transition.is_empty():
  fade=minf(1,fade+delta*4)
  if fade>=1:
   var target:=transition.duplicate();transition.clear();build_area(target.area,target.depth,target.spawn);fading_in=true
 elif fading_in:
  fade=maxf(0,fade-delta*4)
  if fade<=0:fading_in=false;mode="game";ui.clear_overlay();if_entered()
 if active():
  combo_time=maxf(0,combo_time-delta)
  if combo_time<=0:combo=0
  save_clock+=delta
  if save_clock>=40:save_clock=0;state.save_game()
  interaction=find_interaction();update_effects(delta)
 var focus: Vector3=player.position if is_instance_valid(player) else Vector3.ZERO
 if mode=="title":focus=Vector3(-15,0,-1)
 if area=="bonne":focus=player.position*.4 if state.camera_zoom>1.05 else Vector3.ZERO
 if area=="cabin":focus=Vector3(0,0,-1)
 if area=="ruins":
  focus.x=clampf(focus.x,-10,10);focus.z=clampf(focus.z,-7,7)
 if area=="island" and mode!="title":
  if player.position.x<5 and player.position.z> -5:focus=player.position.lerp(Vector3(-7,0,-3),.4)
  focus.x=clampf(focus.x,-12,12);focus.z=clampf(focus.z,-7,9)
 camera_focus=camera_focus.lerp(focus,1-exp(-delta*7))
 var base_zoom: float=27.0 if mode=="title" or area=="bonne" else (18.0 if area in ["ruins","cabin"] else 20.0)
 camera.size=lerpf(camera.size,base_zoom/(1.0 if mode=="title" else state.camera_zoom),minf(1,delta*8))
 camera.position=camera_focus+Vector3(0,22,19)
 if shake>0 and not state.reduced_motion:camera.position+=Vector3(randf_range(-shake,shake),0,randf_range(-shake,shake))
 shake=move_toward(shake,0,delta*1.5);camera.look_at(camera_focus,Vector3.UP)
 ui.refresh()

func if_entered() -> void:
 if area=="ruins":toast("Roll: Signal clear. Watch the red eyes, MegaMan. E opens caches and consoles.")

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and event.relative.length()>1:mouse_aim=true
 if event is InputEventKey and event.pressed and event.physical_keycode==KEY_F11:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN);return
 if event.is_action_pressed("pause_game"):
  if mode=="game":ui.pause_screen("Status")
  elif mode=="dialogue":ui.advance_dialogue()
  elif mode=="menu" and menu_return_title:ui.title_screen()
  elif mode in ["pause","menu","summary"]:resume_game()
  get_viewport().set_input_as_handled();return
 if event.is_action_pressed("interact"):
  if mode=="game":interact()
  elif mode=="dialogue":ui.advance_dialogue()
  else:
   var focus:=get_viewport().gui_get_focus_owner()
   if focus is Button and not focus.disabled:focus.pressed.emit()
  get_viewport().set_input_as_handled();return
 if not active():return
 if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
  state.camera_zoom=clampf(state.camera_zoom*(1.1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.1),.8,1.6);toast("Camera zoom %d%%"%roundi(state.camera_zoom*100));get_viewport().set_input_as_handled()
 if event.is_action_pressed("map"):ui.pause_screen("Map")
 elif event.is_action_pressed("inventory"):ui.pause_screen("Equipment")

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  if mode!="title":state.save_game()
  call_deferred("quit_game")
 elif what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode=="game" and is_instance_valid(ui):ui.pause_screen("Status")

func quit_game() -> void:
 mode="transition";audio.shutdown();await get_tree().create_timer(.1).timeout;get_tree().quit()

func build_area(target: String, level: int, spawn: Vector3) -> void:
 enemies.clear();npcs.clear();effects.clear();interaction={};combo=0;combo_time=0
 if is_instance_valid(world):world.free()
 area=target;depth=level;run_score=0
 world=World.new();world.game=self;world.area=target;world.depth=level;add_child(world);move_child(world,0)
 player=Actor.new();player.game=self;player.role="player";player.kind="megaman";player.position=spawn+Vector3.UP*.1;world.add_child(player)
 camera_focus=spawn
 audio.track("boss" if target=="bonne" else ("ruins" if target=="ruins" else "town"))

func travel(target: String, level: int=1, spawn: Vector3=Vector3(0,0,8)) -> void:
 if not transition.is_empty():return
 state.save_game();mode="transition";ui.clear_overlay();transition={"area":target,"depth":level,"spawn":spawn};fade=0;audio.effect("door")

func start_new() -> void:
 state=State.new();mode="game";mouse_aim=false;build_area("island",1,Vector3(0,0,8));ui.clear_overlay()
 dialogue("Roll",["MegaMan! The Flutter's grounded, but I think we can fix her. The northern ruins have the parts we need.","Come see me for the repair plan. Data will patch you up and save our progress. You can rest inside the Flutter any time.","Move with WASD, aim with the mouse and fire with left click. Shift dashes, E interacts, and holding right click charges the Buster. Let's get our ship flying again!"])
 state.save_game()

func continue_game() -> void:
 if not state.load_game():toast("The save could not be read.");return
 mode="game";build_area("island",1,Vector3(0,0,8));ui.clear_overlay();toast("Welcome back to the Flutter.");audio.refresh()

func spawn_npc(person: String, art: String, at: Vector3) -> void:
 var actor=Actor.new();actor.game=self;actor.role="npc";actor.kind=art;actor.person=person;actor.position=at;world.add_child(actor);npcs.append(actor)

func spawn_enemy(kind: String, at: Vector3, hp: int=40, boss: bool=false) -> void:
 var actor=Actor.new();actor.game=self;actor.role="enemy";actor.kind=kind;actor.position=at+Vector3.UP*.1;actor.health=hp;actor.boss=boss;world.add_child(actor);enemies.append(actor)

func shoot(at: Vector3, speed: Vector3, hostile: bool, damage: int, charged: bool=false) -> void:
 var shot=Projectile.new();shot.game=self;shot.position=at;shot.speed=speed;shot.hostile=hostile;shot.damage=damage;shot.charged=charged;shot.life=2.8 if hostile else 1.0+state.power*.15;world.add_child(shot)

func throw_grenade(at: Vector3, speed: Vector3) -> void:
 var grenade=Grenade.new();grenade.game=self;grenade.position=at;world.add_child(grenade);grenade.linear_velocity=speed;audio.effect("buster",.6)

func line_clear(from: Vector3,to: Vector3) -> bool:
 return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty()

func nearest_enemy(at: Vector3, distance: float):
 var target=null
 for enemy in enemies:
  if not is_instance_valid(enemy) or enemy.defeated:continue
  var d: float=at.distance_to(enemy.position)
  if d<distance and line_clear(at+Vector3.UP*.8,enemy.position+Vector3.UP*.8):distance=d;target=enemy
 return target

func find_interaction() -> Dictionary:
 var found: Dictionary={};var best: float=2.1
 for npc in npcs:
  if not is_instance_valid(npc):continue
  var d: float=player.position.distance_to(npc.position)
  if d<best:best=d;found={"name":npc.person,"person":npc.person,"pos":npc.position,"action":"npc"}
 for item in world.interactables:
  var d: float=player.position.distance_to(item.pos)
  if d<best:best=d;found=item
 return found

func interact() -> void:
 interaction=find_interaction()
 if not interaction.is_empty():execute_interaction(interaction)

func execute_interaction(item: Dictionary) -> void:
 audio.effect("select")
 match item.action:
  "npc":talk_to(item.person)
  "cabin":travel("cabin",1,Vector3(0,0,5))
  "cabin_exit":travel("island",1,Vector3(-4,0,6))
  "rest":state.health=state.max_health();state.energy=100;state.save_game();toast("Rested aboard the Flutter. Health restored and adventure saved.");audio.effect("item")
  "workshop":open_workshop()
  "shop":open_shop()
  "lift":open_lift()
  "exit":state.best_run=maxi(state.best_run,run_score);travel("island",1,Vector3(6,0,-10))
  "cache":recover_cache(item)
  "plans":
   state.weapon_plans=true;state.score+=200;world.interactables.erase(item);item.visual.queue_free();state.save_game()
   dialogue("Roll",["Grenade Arm plans! Bring me 8 scrap, 3 Refractor shards and 450 Zenny. I can build it at our workbench."])

func talk_to(person: String) -> void:
 match person:
  "Roll":ui.menu("ROLL'S WORKSHOP","The Flutter is our home. Let's get her flying again.",[{"text":"Check Flutter repairs","action":"repairs"},{"text":"Upgrade equipment","action":"workshop"},{"text":"Talk with Roll","action":"roll_chat"}])
  "Data":state.health=state.max_health();state.energy=100;state.save_game();dialogue("Data",["Ook ook!","Data restores your armour, recharges your energy and saves your adventure."])
  "Barrell":dialogue("Barrell",["Those ruins are older than Kattelox itself. The red-eyed machines are still protecting their treasure.","A good Digger knows when to come home. Your crew will always be waiting aboard the Flutter."])
  "Tron":
   if not state.tron_defeated:dialogue("Tron",["So you're the Digger who's been taking our treasure? Hmph!","Servbots! Bring out the Feldynaught! Let's see what that Buster can really do!"],"battle")
   else:dialogue("Tron",["Don't look so pleased with yourself. Next time, I'll bring a bigger machine!"])

func repair_ship() -> void:
 if not state.quest_started:
  state.quest_started=true;state.save_game();dialogue("Roll",["The port stabilizer needs a Servo Motor. There's one in the western chamber on ruin level 1.","Head north to the lift. Clear the bots around the cache, recover the motor and bring it home."]);return
 var part: String="servo" if state.repair==0 else ("circuit" if state.repair==1 else "refractor")
 if state.repair<3 and part in state.parts:
  state.parts.erase(part);state.repair+=1;state.zenny+=250;state.score+=700;audio.effect("item")
  if state.repair==1:dialogue("Roll",["The stabilizer is working! The lift can now reach level 2.","Its northern vault holds an Ancient Circuit, but a Hanmuru Doll guards it. Watch its windup, then dash away from the charge."])
  elif state.repair==2:
   if area=="island":spawn_npc("Tron","tron",Vector3(8,0,3))
   dialogue("Roll",["Navigation restored! The main engine still needs a large Refractor.","Uh... Tron's broadcasting a pirate challenge near the landing pad. We'll have to deal with her before reaching the core."])
  else:
   state.completed=true
   for visual in world.repair_visuals:
    if is_instance_valid(visual):visual.visible=true
   dialogue("Roll",["Main engine pressure is stable. MegaMan, the Flutter can fly again!","We did it together. Digs, mechs, scraped knees... and a ship full of people who believe in you.","The deeper ruins are open if you're ready for another adventure. But for tonight, you're home."],"ending")
  state.save_game();return
 var hints: Array=["Find the Servo Motor in the western chamber on level 1.","The northern vault on level 2 holds the Ancient Circuit. Defeat its guardian first.","Meet Tron near the landing pad. Her Feldynaught is blocking the route to level 3.","The Flutter is ready to fly. Deep Digs are open, and your crew is always here."]
 if state.repair==2 and state.tron_defeated:hints[2]="Recover the large Refractor in the northern vault on level 3. Its guardian is stronger, so bring an energy bottle."
 dialogue("Roll",[hints[state.repair]])

func open_lift() -> void:
 if not state.quest_started:dialogue("Roll",["Come see me beside the Flutter before you go down. We need a repair plan!"]);return
 var choices: Array=[{"text":"Level 1 / Stabilizer chambers","action":"dig_1"},{"text":"Level 2 / Navigation vault","action":"dig_2","disabled":state.repair<1},{"text":"Level 3 / Refractor core","action":"dig_3","disabled":not state.tron_defeated}]
 if state.completed:choices.append({"text":"Deep Dig / Depth %d"%state.deepest,"action":"dig_%d"%state.deepest})
 ui.menu("NORTHERN RUINS","Recover the parts and return via the southern lift.",choices)

func recover_cache(item: Dictionary) -> void:
 for enemy in enemies:
  if is_instance_valid(enemy) and not enemy.defeated and (enemy.boss or enemy.position.distance_to(item.pos)<5):toast("The cache is guarded. Clear the nearby Reaverbots first.");return
 if depth>=4:state.relics+=1;state.zenny+=500+(depth-4)*100;state.score+=1500;run_score+=1500;state.deepest=mini(15,maxi(state.deepest,depth+1))
 else:state.parts.append(item.part);state.score+=300;run_score+=300
 world.interactables.erase(item);item.visual.queue_free();state.best_run=maxi(state.best_run,run_score);state.save_game();audio.effect("item")
 dialogue("Roll",["Nice work, MegaMan! %s recovered. Take the southern lift back to the Flutter."%{"servo":"Servo Motor","circuit":"Ancient Circuit","refractor":"Large Refractor"}[item.part]] if depth<4 else ["Deep Dig clear! Another relic, %d Zenny and 1500 score. Depth %d is ready when you are."%[500+(depth-4)*100,state.deepest]])

func open_workshop() -> void:
 var choices: Array=[]
 for entry in [["power","Buster power",350,4],["rapid","Rapid fire",300,3],["armour","Armour jacket",400,5]]:
  var level: int=state.get(entry[0]);var cost: int=entry[2]+level*200;var scrap: int=entry[3]+level*2
  choices.append({"text":"%s Lv.%d / %d Z + %d scrap"%[entry[1],level+1,cost,scrap] if level<3 else "%s MAX"%entry[1],"action":"upgrade_"+entry[0],"disabled":level>=3 or state.zenny<cost or state.scrap<scrap})
 choices.append({"text":"Grenade Arm fitted / L or B" if state.grenade else "Build Grenade Arm / 450 Z + 8 scrap + 3 shards","action":"grenade","disabled":state.grenade or not state.weapon_plans or state.zenny<450 or state.scrap<8 or state.shards<3})
 ui.menu("ROLL'S WORKBENCH","Zenny %d   Scrap %d   Shards %d"%[state.zenny,state.scrap,state.shards],choices)

func upgrade(stat: String) -> void:
 var prices: Dictionary={"power":[350,4],"rapid":[300,3],"armour":[400,5]}
 if not prices.has(stat):return
 var level: int=state.get(stat);var cost: int=prices[stat][0]+level*200;var scrap: int=prices[stat][1]+level*2
 if level>=3 or state.zenny<cost or state.scrap<scrap:return
 state.zenny-=cost;state.scrap-=scrap;state.set(stat,level+1)
 if stat=="armour":state.health=state.max_health()
 state.save_game();audio.effect("item");open_workshop()

func open_shop() -> void:
 ui.menu("FIELD SUPPLIES","Energy bottles restore 55 health and 45 energy.",[{"text":"Buy energy bottle / 100 Z","action":"buy_bottle","disabled":state.zenny<100},{"text":"Sell one recovered relic / 300 Z","action":"sell_relic","disabled":state.relics<1},{"text":"Repair and save with Data","action":"data_hint"}])

func execute_choice(action: String) -> void:
 audio.effect("select")
 if action.begins_with("dig_"):
  var level: int=int(action.trim_prefix("dig_"))
  if not state.quest_started or level<1 or level>15 or level==2 and state.repair<1 or level==3 and not state.tron_defeated or level>=4 and (not state.completed or level>state.deepest):toast("That ruin level is still locked.");return
  travel("ruins",level,Vector3(0,0,10.5));return
 if action.begins_with("upgrade_"):upgrade(action.trim_prefix("upgrade_"));return
 match action:
  "new":start_new()
  "continue":continue_game()
  "resume":resume_game()
  "title":state.save_game();mode="title";build_area("island",1,Vector3(0,0,8));ui.title_screen()
  "repairs":repair_ship()
  "workshop":open_workshop()
  "roll_chat":dialogue("Roll",["I like having a place to come back to. Engines humming, Barrell telling stories, Data getting into trouble...","Don't make me worry too much on your next dig, okay?"])
  "grenade":
   if state.grenade or not state.weapon_plans or state.zenny<450 or state.scrap<8 or state.shards<3:return
   state.zenny-=450;state.scrap-=8;state.shards-=3;state.grenade=true;state.save_game();audio.effect("item")
   dialogue("Roll",["Grenade Arm ready! Press L or controller B to throw one. Each shot costs 18 energy.","Grenades bounce off walls and deal splash damage. They're great against clustered bots and salvage crates."])
  "buy_bottle":
   if state.zenny<100:return
   state.zenny-=100;state.bottles+=1;state.save_game();open_shop()
  "sell_relic":
   if state.relics<1:return
   state.relics-=1;state.zenny+=300;state.save_game();open_shop()
  "data_hint":dialogue("Data",["Find Data near the Flutter. He's small, but he takes very good care of the crew."])
  "music":state.music=not state.music;audio.refresh();state.save_game();ui.pause_screen("Options")
  "sound":state.sound=not state.sound;state.save_game();ui.pause_screen("Options")
  "motion":state.reduced_motion=not state.reduced_motion;state.save_game();ui.pause_screen("Options")
  "save":toast("Adventure saved." if state.save_game() else "Save unavailable.");resume_game()
  "quit":quit_game()

func enemy_defeated(enemy) -> void:
 enemies.erase(enemy);combo=mini(9,combo+1);combo_time=5
 var points: int=(900 if enemy.boss else 100+depth*25)*(1+int(combo/3));state.score+=points;run_score+=points
 floating(enemy.position+Vector3.UP*2.8,"+%d"%points,Color("ffe2a0"));explosion(enemy.position+Vector3.UP*.7);audio.effect("explosion",.7 if enemy.boss else 1.15)
 if area=="bonne" and enemy.boss:
  state.zenny+=480;state.scrap+=6;state.shards+=3;state.relics+=1;call_deferred("bonne_win")
 else:
  for i in range(3):drop(enemy.position,"zenny",60 if enemy.boss else 12+depth*2)
  drop(enemy.position,"scrap",3 if enemy.boss else 1)
  if enemy.boss:drop(enemy.position,"shards",2);drop(enemy.position,"relics",1);toast("Roll: The guardian is down! The northern cache is safe to open.")
 state.best_run=maxi(state.best_run,run_score)

func bonne_win() -> void:
 state.tron_defeated=true;state.save_game()
 for enemy in enemies:
  if is_instance_valid(enemy):enemy.queue_free()
 enemies.clear();dialogue("Tron",["My beautiful Feldynaught! Do you know how long that took to build?!","Fine. The core passage is yours. But you owe me a rematch, MegaMan!"],"return")

func drop(at: Vector3,kind: String,amount: int) -> void:
 var pickup=Pickup.new();pickup.game=self;pickup.kind=kind;pickup.amount=amount;pickup.position=at+Vector3.UP*.8;world.add_child(pickup)

func use_bottle() -> void:
 if not active():return
 if state.bottles<1:toast("No energy bottles. Visit the supply crate by the landing pad.");return
 if state.health>=state.max_health() and state.energy>=100:return
 state.bottles-=1;state.health=mini(state.max_health(),state.health+55);state.energy=minf(100,state.energy+45);state.save_game();audio.effect("item");toast("Energy bottle / +55 health, +45 energy.")

func knock_out() -> void:
 if mode!="game":return
 var loss: int=int(state.zenny*.08);state.zenny-=loss;state.health=state.max_health();state.energy=100
 build_area("island",1,Vector3(0,0,8));state.save_game();dialogue("Roll",["Data brought you back to the Flutter. You're safe, MegaMan.","Repairs cost %d Zenny. Your recovered parts are still here. Take a bottle and use your dash next time."%loss])

func dialogue(person: String,lines: Array,after: String="") -> void:ui.dialogue_screen(person,lines,after)
func dialogue_done(after: String) -> void:
 resume_game()
 match after:
  "battle":travel("bonne",1,Vector3(0,0,6.5))
  "return":travel("island",1,Vector3(6,0,5))
  "ending":ui.summary("THE FLUTTER CAN FLY",["All three ship systems restored.","Score %d   Best dig %d"%[state.score,state.best_run],"Your crew is home. Deep Digs are now open."])
func resume_game() -> void:mode="game";ui.clear_overlay();mouse_aim=false
func toast(text: String) -> void:notice=text;notice_time=4.0
func objective() -> String:
 if not state.quest_started:return "Talk to Roll beside the Flutter"
 if state.repair==0:return "Bring the Servo Motor to Roll" if "servo" in state.parts else "Find the Servo Motor on ruin level 1"
 if state.repair==1:return "Bring the Ancient Circuit to Roll" if "circuit" in state.parts else "Recover the Ancient Circuit on level 2"
 if state.repair==2:
  if not state.tron_defeated:return "Defeat Tron’s Feldynaught" if area=="bonne" else "Meet Tron near the landing pad"
  return "Bring the Refractor to Roll" if "refractor" in state.parts else "Recover the Large Refractor on level 3"
 return "Flutter restored / Explore the deeper ruins"
func location() -> String:return {"island":"FLUTTER LANDING","cabin":"FLUTTER / CREW CABIN","bonne":"BONNE SHOWDOWN","ruins":"NORTHERN RUINS / LEVEL %d"%depth}[area]

func crystal(at: Vector3,colour: Color,size: float,parent: Node=null) -> Node3D:
 var mesh:=MeshInstance3D.new();var prism:=PrismMesh.new();prism.size=Vector3(size*1.2,size*2,size);mesh.mesh=prism;mesh.position=at;mesh.rotation.z=PI
 var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.emission_enabled=true;mat.emission=colour*.22;mat.roughness=.35;mat.metallic=.2;mesh.material_override=mat
 (world if parent==null else parent).add_child(mesh);return mesh
func spark(at: Vector3,colour: Color,life: float,size: float) -> void:
 if effects.size()>100:return
 var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=size;sphere.height=size*2;sphere.radial_segments=6;sphere.rings=3;mesh.mesh=sphere;mesh.position=at
 var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mesh.material_override=mat;mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;world.add_child(mesh)
 effects.append({"node":mesh,"life":life,"max":life,"kind":"spark","vel":Vector3.ZERO})
func explosion(at: Vector3) -> void:
 spark(at,Color("ffbc83"),.32,.5)
 for i in range(14):
  spark(at+Vector3(randf_range(-.4,.4),randf_range(0,.6),randf_range(-.4,.4)),Color("f4cf99"),randf_range(.25,.5),.11)
  effects[-1].vel=Vector3(randf_range(-4,4),randf_range(1,4),randf_range(-4,4))
func floating(at: Vector3,text: String,colour: Color) -> void:
 var label:=Label3D.new();label.text=text;label.font_size=32;label.pixel_size=.014;label.outline_size=5;label.modulate=colour;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=at;label.no_depth_test=true;world.add_child(label)
 effects.append({"node":label,"life":.75,"max":.75,"kind":"text","vel":Vector3.UP*1.1})
func update_effects(delta: float) -> void:
 for i in range(effects.size()-1,-1,-1):
  var fx: Dictionary=effects[i];fx.life-=delta
  if not is_instance_valid(fx.node):effects.remove_at(i);continue
  fx.node.position+=fx.vel*delta
  if fx.kind=="spark":
   fx.node.scale=Vector3.ONE*(1+(1-fx.life/fx.max)*1.4);fx.node.material_override.albedo_color.a=maxf(0,fx.life/fx.max)
  if fx.life<=0:fx.node.queue_free();effects.remove_at(i)
