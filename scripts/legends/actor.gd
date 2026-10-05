extends CharacterBody3D
const Models=preload("res://scripts/legends/models.gd")
var game
var role: String="enemy"
var kind: String="horokko"
var person: String=""
var boss: bool=false
var health: int=40
var max_health: int=40
var visual: Node3D
var ring: MeshInstance3D
var facing:=Vector3.BACK
var knockback:=Vector3.ZERO
var invincible: float=0
var shot_cooldown: float=0
var special_cooldown: float=0
var dash_cooldown: float=0
var dash_time: float=0
var dash_direction:=Vector3.BACK
var charge: float=0
var phase: String="idle"
var timer: float=0
var cooldown: float=1.1
var attack_direction:=Vector3.BACK
var hit_time: float=0
var flash_time: float=0
var walk_phase: float=0
var clock: float=0
var attack_count: int=0
var home:=Vector3.ZERO
var defeated: bool=false
var path: PackedVector3Array=[]
var path_timer: float=0
var step_time: float=0

func _ready() -> void:
 collision_layer=2 if role=="player" else (8 if role=="npc" else 4)
 collision_mask=1|16|(8 if role=="player" else (2 if role=="npc" else 0))
 var collision:=CollisionShape3D.new();var shape:=CapsuleShape3D.new()
 shape.radius=.32 if not boss else .85;shape.height=1.6 if not boss else 3.5
 collision.shape=shape;collision.position.y=shape.height/2;add_child(collision)
 var height: float=1.65 if role=="player" else (1.55 if role=="npc" else 1.25)
 if kind=="data":height=.65
 if kind=="sharukurusu":height=1.65
 if boss:height=4.2 if kind=="guardian" else 4.5
 visual=Models.make(kind,height);add_child(visual)
 home=position;max_health=health
 ring=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=.35;torus.outer_radius=.45
 ring.mesh=torus;ring.position.y=.035
 var material:=StandardMaterial3D.new();material.albedo_color=Color("ff997c");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 ring.material_override=material;ring.visible=false;add_child(ring)
 Models.pose(visual,0,false)

func _physics_process(delta: float) -> void:
 if not game.active() or defeated:return
 clock+=delta;invincible=maxf(0,invincible-delta);hit_time=maxf(0,hit_time-delta);flash_time=maxf(0,flash_time-delta)
 Models.flash(visual,flash_time*4)
 velocity.y=-3.0
 if role=="player":player_step(delta)
 elif role=="enemy":enemy_step(delta)
 else:
  velocity.x=0;velocity.z=0
  Models.pose(visual,clock*4,kind=="data")
  visual.position.y=sin(clock*5)*.025 if kind=="data" else 0
 move_and_slide()
 if role=="player":
  var speed: float=Vector2(get_real_velocity().x,get_real_velocity().z).length();walk_phase+=speed*delta*2.5
  Models.pose(visual,walk_phase,speed>.15,shot_cooldown>.1 or charge>.1)
 visual.rotation.y=lerp_angle(visual.rotation.y,atan2(facing.x,facing.z),minf(1,delta*16))
 if role=="player":
  visual.visible=invincible<=0 or int(invincible*16)%2==0
 elif role=="enemy":
  ring.visible=phase=="windup"
  ring.scale=Vector3.ONE*(2.8 if boss else 1.5)

func player_step(delta: float) -> void:
 shot_cooldown=maxf(0,shot_cooldown-delta);special_cooldown=maxf(0,special_cooldown-delta);dash_cooldown=maxf(0,dash_cooldown-delta);dash_time=maxf(0,dash_time-delta)
 var input:=Input.get_vector("move_left","move_right","move_up","move_down")
 var move:=Vector3(input.x,0,input.y)
 if move.length()>.1:facing=move.normalized()
 var aim:=Input.get_vector("aim_left","aim_right","aim_up","aim_down")
 if aim.length()>.2:game.mouse_aim=false;facing=Vector3(aim.x,0,aim.y).normalized()
 if Input.is_action_pressed("lock"):
  var target=game.nearest_enemy(position,14)
  if is_instance_valid(target):facing=flat_direction(target.position)
 elif game.mouse_aim and game.pointer_in_world():
  var target: Vector3=game.mouse_point()
  if target.distance_to(position)>.4:facing=flat_direction(target)
 if Input.is_action_just_pressed("dash") and dash_cooldown<=0 and game.state.energy>=8:
  dash_time=.19;dash_cooldown=.75;dash_direction=move.normalized() if move.length()>.1 else facing;game.state.energy-=8;game.audio.effect("step",.8)
 var travel: Vector3=(dash_direction*12.0 if dash_time>0 else move*5.2)+knockback
 velocity.x=travel.x;velocity.z=travel.z;knockback=knockback.move_toward(Vector3.ZERO,18*delta)
 if dash_time>0 and not game.state.reduced_motion:game.spark(position+Vector3(0,.65,0),Color("9cd8eb"),.18,.12)
 var charging_input: bool=Input.is_action_pressed("charge") and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or game.pointer_in_world())
 if not charging_input and charge<=0 and Input.is_action_pressed("fire") and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or game.pointer_in_world()):fire()
 if charging_input:
  charge=minf(1.2,charge+delta);ring.visible=true;ring.scale=Vector3.ONE*(1+charge)
 elif charge>0:
  if charge>=.65:fire(true)
  charge=0;ring.visible=false
 if Input.is_action_just_pressed("special"):special_fire()
 if Input.is_action_just_pressed("heal"):game.use_bottle()
 game.state.energy=minf(100,game.state.energy+delta*(5 if move.length()<.1 else 1.8))
 if move.length()>.1:
  step_time-=delta
  if step_time<=0:step_time=.3;game.audio.effect("step",1.2)

func flat_direction(to: Vector3) -> Vector3:
 var d: Vector3=to-position;d.y=0
 return d.normalized() if d.length()>.01 else facing

func fire(charged: bool=false) -> void:
 if shot_cooldown>0 or not game.active():return
 shot_cooldown=.38 if charged else maxf(.12,.26-game.state.rapid*.045)
 game.shoot(position+Vector3(0,.85,0)+facing*.5,facing*24,false,(40 if charged else 12)+game.state.power*6,charged)
 game.audio.effect("buster",.7 if charged else randf_range(.94,1.04))
 game.spark(position+Vector3(0,.85,0)+facing*.8,Color("c2f5ed"),.1,.22 if charged else .12)

func special_fire() -> void:
 if not game.active() or special_cooldown>0:return
 if not game.state.grenade:game.toast("Roll can build a Grenade Arm from the eastern weapon plans.");return
 if game.state.energy<18:game.toast("The Grenade Arm needs 18 energy.");return
 game.state.energy-=18;special_cooldown=1.15
 game.throw_grenade(position+Vector3(0,1,0)+facing*.55,facing*8+Vector3.UP*4.0)

func enemy_step(delta: float) -> void:
 cooldown-=delta;path_timer-=delta
 var distance: float=position.distance_to(game.player.position)
 var direction:=flat_direction(game.player.position)
 var travel:=knockback;knockback=knockback.move_toward(Vector3.ZERO,14*delta)
 if phase=="windup":
  timer-=delta
  if timer<=0:
   phase="attack";timer=.5;attack_count+=1
   if kind in ["horokko","guardian","feldynaught","servbot"]:
    var count: int=(12 if health<max_health/2 else 8) if boss else 1
    for i in range(count):
     var dir: Vector3=Vector3(sin(TAU*i/count+clock*.1),0,cos(TAU*i/count+clock*.1)) if boss else attack_direction
     game.shoot(position+Vector3(0,.8,0)+dir*(1.15 if boss else .5),dir*(6.5 if boss else 7.5),true,14 if boss else 8)
    game.audio.effect("buster",.6)
   if boss and attack_count%3==0 and game.enemies.size()<7:game.spawn_enemy("servbot" if kind=="feldynaught" else "horokko",game.world.safe_spawn(home+Vector3(3,0,2)),24)
 elif phase=="attack":
  timer-=delta
  if kind=="sharukurusu" or boss and attack_count%2==0:travel+=attack_direction*(8 if boss else 10)
  if timer<=0:phase="recover";timer=.85 if boss else .5
 elif phase=="recover":
  timer-=delta
  if timer<=0:phase="idle";cooldown=.65 if boss and health<max_health/2 else 1.1
 elif distance<(16 if boss else 11):
  facing=direction
  if distance>(4.5 if kind=="horokko" else (2.6 if boss else 1.0)):
   if path_timer<=0:path_timer=.4;path=game.world.path_to(position,game.player.position)
   var target: Vector3=game.player.position
   if path.size()>1:target=path[1]
   travel+=flat_direction(target)*(1.45 if boss else (2.3 if kind=="servbot" else 1.8))
  if cooldown<=0 and game.line_clear(position+Vector3.UP*.8,game.player.position+Vector3.UP*.8):
   phase="windup";timer=.85 if boss else .6;attack_direction=direction
 velocity.x=travel.x;velocity.z=travel.z
 if distance<(1.3 if boss else .72):game.player.hurt(18 if boss else 9,position)
 Models.pose(visual,clock*8,travel.length()>.2)
 if phase=="windup":visual.position.y=sin(clock*20)*.04
 else:visual.position.y=sin(clock*5)*.025

func hurt(damage: int, from: Vector3) -> void:
 if not game.active() or defeated or role=="npc":return
 if role=="player":
  if invincible>0 or dash_time>0:return
  invincible=.9;game.state.health-=maxi(1,damage-game.state.armour*2)
  knockback=from.direction_to(position)*5;knockback.y=0
  game.combo=0;game.audio.effect("hurt");game.shake=.13
  flash_time=.16
  game.floating(position+Vector3.UP*2,"-%d"%maxi(1,damage-game.state.armour*2),Color("ffb19c"))
  if game.state.health<=0:game.call_deferred("knock_out")
 else:
  hit_time=2.5;flash_time=.16
  health-=damage;game.audio.effect("hit");game.floating(position+Vector3.UP*2,"%d"%damage,Color("ffe4a0"))
  knockback=from.direction_to(position)*(1.2 if boss else 4.0);knockback.y=0
  if health<=0:defeated=true;game.enemy_defeated(self);queue_free()
