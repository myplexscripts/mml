extends Node3D
const Models=preload("res://scripts/legends/models.gd")
const Salvage=preload("res://scripts/legends/salvage.gd")
var game
var area: String="island"
var depth: int=1
var walls: Array[Rect2]=[]
var interactables: Array=[]
var cells: Dictionary={}
var nav:=AStarGrid2D.new()
var bounds:=Rect2(-23,-18,46,38)
var repair_visuals: Array=[]
var batches: Dictionary={}
var occluders: Array[Node3D]=[]
var ambient: WorldEnvironment
var cell_size: float=1.4
const ART="res://assets/legends/"
var origin:=Vector2(-21,-15.4)

func _ready() -> void:
 setup_light()
 if area=="island":build_island()
 elif area=="cabin":build_cabin()
 elif area=="bonne":build_bonne()
 else:build_ruins()
 finish_batches();build_navigation()

func _physics_process(delta: float) -> void:
 if not game.active() or occluders.is_empty():return
 var query:=PhysicsRayQueryParameters3D.create(game.camera.global_position,game.player.global_position+Vector3.UP*1.1,1)
 var result:=get_world_3d().direct_space_state.intersect_ray(query)
 var obstruction: Node3D=null
 if not result.is_empty() and result.collider.get_parent() in occluders:obstruction=result.collider.get_parent()
 for visual in occluders:
  var target: float=.32 if visual==obstruction else 1.0
  var alpha: float=move_toward(visual.get_meta("occlusion_alpha",1.0),target,delta*4.0)
  visual.set_meta("occlusion_alpha",alpha)
  for mat in visual.get_meta("materials"):
   mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS if alpha<.99 else BaseMaterial3D.TRANSPARENCY_DISABLED
   mat.albedo_color.a=alpha

func material(colour: Color, texture: String="") -> StandardMaterial3D:
 var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=.9
 if not texture.is_empty():
  mat.albedo_texture=load(texture);mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
 return mat

func box(at: Vector3, size: Vector3, colour: Color, collision: bool=false, texture: String="") -> MeshInstance3D:
 var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size;mesh.mesh=shape
 mesh.material_override=material(colour,texture);mesh.position=at;add_child(mesh)
 if collision:
  var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=0
  var collider:=CollisionShape3D.new();var physics:=BoxShape3D.new();physics.size=size;collider.shape=physics;body.add_child(collider);add_child(body)
  if at.y>=.3:walls.append(Rect2(at.x-size.x/2,at.z-size.z/2,size.x,size.z))
 return mesh

func batch_box(at: Vector3,size: Vector3,colour: Color,texture: String="") -> void:
 var key: String=colour.to_html()+str(size)+texture
 if not batches.has(key):batches[key]={"size":size,"colour":colour,"texture":texture,"positions":[]}
 batches[key].positions.append(at)

func finish_batches() -> void:
 for data in batches.values():
  var mesh:=BoxMesh.new();mesh.size=data.size;mesh.material=material(data.colour,data.texture)
  var multimesh:=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.mesh=mesh;multimesh.instance_count=data.positions.size()
  for i in range(data.positions.size()):multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,data.positions[i]))
  var instance:=MultiMeshInstance3D.new();instance.multimesh=multimesh;add_child(instance)
 batches.clear()

func wall_collision(at: Vector3,size: Vector3) -> void:
 var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=0
 var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;collision.shape=shape;body.add_child(collision);add_child(body)
 walls.append(Rect2(at.x-size.x/2,at.z-size.z/2,size.x,size.z))

func cylinder(at: Vector3, radius: float, height: float, colour: Color, collision: bool=false) -> MeshInstance3D:
 var mesh:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=12
 mesh.mesh=shape;mesh.material_override=material(colour);mesh.position=at;add_child(mesh)
 if collision:
  var body:=StaticBody3D.new();body.position=at;body.collision_layer=1;body.collision_mask=0;add_child(body)
  var col:=CollisionShape3D.new();var physics:=CylinderShape3D.new();physics.radius=radius;physics.height=height;col.shape=physics;body.add_child(col)
  walls.append(Rect2(at.x-radius,at.z-radius,radius*2,radius*2))
 return mesh

func model(key: String, at: Vector3, height: float, rotation_y: float=0, solid: bool=true) -> Node3D:
 var visual:=Models.make(key,height);visual.position=at;visual.rotation.y=rotation_y;add_child(visual)
 if solid:
  if key in ["flutter","drache","hangar","harbour","bakery"]:occluders.append(visual)
  var body:=StaticBody3D.new();body.name="SolidProp";body.collision_layer=1;body.collision_mask=0;visual.add_child(body)
  for mesh in visual.find_children("*","MeshInstance3D",true,false):
   var col:=CollisionShape3D.new();col.shape=mesh.mesh.create_trimesh_shape();col.transform=visual.global_transform.affine_inverse()*mesh.global_transform;body.add_child(col)
  var aabb: AABB=visual.transform*visual.get_meta("bounds")
  walls.append(Rect2(aabb.position.x,aabb.position.z,aabb.size.x,aabb.size.z))
 return visual

func setup_light() -> void:
 var ruins: bool=area=="ruins"
 ambient=WorldEnvironment.new();ambient.environment=Environment.new()
 var env:=ambient.environment;env.background_mode=Environment.BG_COLOR;env.background_color=Color("152d3b") if ruins else Color("6097a4")
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("abcdd7") if ruins else Color("c6d9cf");env.ambient_light_energy=.35 if ruins else .35
 env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;add_child(ambient)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-62,-25,0);sun.light_color=Color("bddbe5") if ruins else Color("fff0c6");sun.light_energy=.65 if ruins else .8
 sun.shadow_enabled=true;sun.directional_shadow_max_distance=70;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;add_child(sun)

func sign_at(text: String, at: Vector3) -> void:
 var label:=Label3D.new();label.text=text;label.font_size=40;label.pixel_size=.012;label.outline_size=6;label.modulate=Color("fff0c4");label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;label.position=at;add_child(label)

func interact(name_text: String, at: Vector3, action: String, extra: Dictionary={}) -> void:
 var item: Dictionary={"name":name_text,"pos":at,"action":action};item.merge(extra);interactables.append(item)

func build_island() -> void:
 bounds=Rect2(-23,-18,46,38)
 var water:=box(Vector3(0,-.65,0),Vector3(180,.1,180),Color("579fac"))
 var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded; uniform vec4 base : source_color=vec4(0.23,0.54,0.63,1.0); uniform sampler2D rip:filter_nearest,repeat_enable; void fragment(){float wave=sin(UV.x*240.0+TIME*.65)*sin(UV.y*210.0-TIME*.45);ALBEDO=mix(base.rgb,texture(rip,UV*48.0+vec2(TIME*.002,0.0)).rgb*.55,.22)+vec3(wave*.026);ROUGHNESS=0.75;}"
 var water_material:=ShaderMaterial.new();water_material.shader=shader;water_material.set_shader_parameter("rip",load(ART+"water.png"));water.material_override=water_material
 box(Vector3(0,-.25,0),Vector3(44,.5,34),Color("577c61"),true)
 for x in range(-21,22,2):
  for z in range(-15,16,2):
   batch_box(Vector3(x,.002,z),Vector3(2,.008,2),Color("7a9464"),ART+("grass_worn.png" if (x*7+z*11)%5==0 else "grass.png"))
 box(Vector3(0,-.7,0),Vector3(44,1.2,34),Color("858878"),false,ART+"sand.png")
 # Traversable pale landing apron, paths and a ruin lift.
 box(Vector3(-5,.005,3),Vector3(22,.035,16),Color("aaa08a"))
 box(Vector3(6,.012,-4),Vector3(4,.045,21),Color("b6bbab"),false,ART+"sand.png")
 for x in range(-16,7,2):
  for z in range(-4,12,2):batch_box(Vector3(x,.03,z),Vector3(2,.015,2),Color("b0aaa0"),ART+"sand.png")
 for x in range(-22,23,2):
  box(Vector3(x,.1,-16.8),Vector3(1.9,.35,.55),Color("aaa987"))
  box(Vector3(x,.1,16.8),Vector3(1.9,.35,.55),Color("aaa987"))
 # The Flutter lands upright: deck above cabin, fin pointing skyward.
 var ship=model("flutter",Vector3(-10,-3.45,-3),11.5,-PI/2)
 ship.name="LandedFlutter";ship.rotation.y=-PI/2
 for x in [-13.0,-7.0]:
  cylinder(Vector3(x,.17,-3.7),.65,.34,Color("495862"))
  cylinder(Vector3(x,.5,-3.7),.16,.8,Color("a2acb0"))
 boarding_stairs(Vector3(-10.45,0,3.2))
 # Painted apron markings and a tidy service bay.
 for x in [-17.0,6.0]:box(Vector3(x,.049,3.3),Vector3(.13,.02,14),Color("eadab4"))
 for z in [-3.8,10.8]:box(Vector3(-5.5,.049,z),Vector3(23,.02,.13),Color("eadab4"))
 for i in range(8):box(Vector3(-16+i*.55,.052,10.4),Vector3(.3,.02,.65),Color("eed07e")).rotation.y=.35
 for at in [Vector3(10,0,6),Vector3(11.0,0,6),Vector3(-16,0,5),Vector3(-15,0,5),Vector3(-16,.85,5),Vector3(7.8,0,-1.8)]:
  model("container",at,.85)
 for z in [-9.0,-6.5,12.0,14.5]:
  railing(Vector3(20,.2,z),2.3)
 for x in [-18.0,-15.0,-12.0,-9.0]:railing(Vector3(x,.2,16),2.7,PI/2)
 var repair_light:=OmniLight3D.new();repair_light.position=Vector3(-9,2,1);repair_light.light_color=Color("7ed8b3");repair_light.light_energy=.8;repair_light.omni_range=9;add_child(repair_light)
 repair_light.visible=game.state.repair>=3;repair_visuals.append(repair_light)
 for entry in [[Vector3(-6.6,0,5),"Roll","roll"],[Vector3(1,0,8),"Data","data"],[Vector3(-14,0,8),"Barrell","barrell"]]:game.spawn_npc(entry[1],entry[2],entry[0])
 interact("Board the Flutter",Vector3(-10.45,2.0,-.85),"cabin")
 interact("Northern Ruins",Vector3(6,0,-12),"lift")
 interact("Junk shop",Vector3(6,0,-1.9),"shop")
 interact("Surface workbench",Vector3(6,0,6.6),"workshop")
 sign_at("FLUTTER",Vector3(-12,.9,4.4))
 sign_at("NORTHERN RUINS",Vector3(6,2.8,-12))
 # Stone arch, steps and physical side walls.
 for x in [3.9,8.1]:box(Vector3(x,1.4,-12),Vector3(1.0,2.8,2),Color("c0c8b1"),true,ART+"wall.png")
 box(Vector3(6,2.9,-12),Vector3(5.3,.65,2),Color("9bac8b"))
 cylinder(Vector3(6,.04,-12),1.35,.12,Color("397b83"))
 for z in [-13,-12.5,-12]:box(Vector3(6,.12,z),Vector3(2,.12,.25),Color("bbd1b6"))
 model("drache",Vector3(14,0,-6),4.0,PI*.8)
 box(Vector3(6,.35,6.1),Vector3(1.9,.7,1.0),Color("929b8e"),true,ART+"metal.png")
 sign_at("JUNK SHOP",Vector3(6,2.0,-2.7))
 for at in [Vector3(-19,0,-12),Vector3(-17,0,-10),Vector3(-13,0,-13),Vector3(-4,0,-13),Vector3(0,0,-11),Vector3(12,0,-13),Vector3(19,0,-11),Vector3(19,0,-3),Vector3(18,0,9),Vector3(12,0,14),Vector3(2,0,14),Vector3(-15,0,14),Vector3(-20,0,8)]:tree(at)
 for i in range(25):
  var at:=Vector3(-20+float((i*17)%40),.12,-15+float((i*7)%31))
  if at.x<7 and at.x>-17 and at.z>-6 and at.z<12:continue
  var rock:=SphereMesh.new();rock.height=.5;rock.radius=.4;rock.radial_segments=6;rock.rings=3
  var mesh:=MeshInstance3D.new();mesh.mesh=rock;mesh.position=at;mesh.scale=Vector3(1.4,.7,1);mesh.material_override=material(Color("a2ab8e"),ART+"rock.png");add_child(mesh)
  var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;add_child(body)
  var col:=CollisionShape3D.new();col.shape=rock.create_convex_shape();col.transform=mesh.transform;body.add_child(col)
  var footprint: AABB=mesh.transform*mesh.get_aabb();walls.append(Rect2(footprint.position.x,footprint.position.z,footprint.size.x,footprint.size.z))
 # Textured harbour scenery from the Legends Station Teomo City resource pack.
 model("hangar",Vector3(6,0,4),5.8,0)
 model("bakery",Vector3(6,0,-5),5.8,0)
 model("shed",Vector3(-16,0,-3.3),1.9,PI/2)
 for at in [Vector3(-17,0,10.5),Vector3(11,0,8),Vector3(8,0,-8),Vector3(-3,0,4)]:
  model("lamp",at,3.5,0,false)
  cylinder(at+Vector3.UP*.9,.14,1.8,Color("73847c"),true)
  var lamp:=OmniLight3D.new();lamp.position=at+Vector3.UP*3;lamp.light_color=Color("ffe0a4");lamp.light_energy=.35;lamp.omni_range=5;add_child(lamp)
 # A pier and moored source-model boat, beyond the walkable shore.
 box(Vector3(11,-.2,20),Vector3(5,.35,7),Color("a49b83"),false,ART+"cabin_panel.png")
 model("boat",Vector3(17,-.8,21),2.3,-PI/2,false)
 # Invisible shoreline collision prevents falling into the sea.
 for entry in [[Vector3(-22.3,1,0),Vector3(.6,2,35)],[Vector3(22.3,1,0),Vector3(.6,2,35)],[Vector3(0,1,-17.3),Vector3(45,2,.6)],[Vector3(0,1,17.3),Vector3(45,2,.6)]]:box(entry[0],entry[1],Color.WHITE,true).visible=false
 if game.state.repair>=2:game.spawn_npc("Tron","tron",Vector3(8,0,3))

func railing(at: Vector3,length: float,rotation_y: float=0) -> void:
 var rail:=Node3D.new();rail.position=at;rail.rotation.y=rotation_y;add_child(rail)
 for z in [-length/2,length/2]:
  var post=box(Vector3(0,.5,z),Vector3(.09,1,.09),Color("7b8990"));remove_child(post);rail.add_child(post)
 for y in [.4,.92]:
  var beam=box(Vector3(0,y,0),Vector3(.07,.07,length),Color("bac3be"));remove_child(beam);rail.add_child(beam)
 var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;rail.add_child(body)
 var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.12,1.0,length);col.position.y=.5;col.shape=shape;body.add_child(col)
 var footprint: AABB=rail.transform*AABB(Vector3(-.06,0,-length/2),Vector3(.12,1,length))
 walls.append(Rect2(footprint.position.x,footprint.position.z,footprint.size.x,footprint.size.z))

func boarding_stairs(at: Vector3) -> void:
 # Hatch UV mapped to the actual ship surface: relative (-.45, 5.45, 1.98).
 # With the folded lower fin below the apron, the cabin sill is 2.0 m high.
 var steps: int=10
 var tread: float=.4
 var top: Vector3=at+Vector3(0,2.0,-4.1)
 set_meta("boarding_bottom",at+Vector3(0,0,.25));set_meta("boarding_top",top)
 for i in range(steps):
  var h: float=minf(2.0,.025+(.4+float(i)*tread)/3.8*1.975)
  box(at+Vector3(0,h-.04,-i*tread),Vector3(1.4,.08,tread+.015),Color("cdd3cc"),false,ART+"metal.png")
  for x in [-.72,.72]:
   box(at+Vector3(x,h/2,-i*tread),Vector3(.07,h,.07),Color("63797e"))
   box(at+Vector3(x,h+.47,-i*tread),Vector3(.05,.94,.05),Color("b6c3c3"))
 var slope: float=atan(2.0/4.0)
 for x in [-.72,.72]:
  var rail=box(at+Vector3(x,1.95,-1.8),Vector3(.065,.065,4.45),Color("d4dcd7"));rail.rotation.x=slope
  var guard:=StaticBody3D.new();guard.position=at+Vector3(x,1.55,-1.8);guard.rotation.x=slope;guard.collision_layer=1;guard.collision_mask=0;add_child(guard)
  var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.10,.95,4.45);col.shape=shape;guard.add_child(col)
 box(top-Vector3.UP*.06,Vector3(1.4,.12,1.2),Color("cdd3cc"),true,ART+"metal.png")
 for x in [-.72,.72]:railing(top+Vector3(x,0,0),1.2)
 # Smooth ramp meets the apron and top landing at the same heights as the treads.
 var body:=StaticBody3D.new();body.name="BoardingRamp";body.position=at;body.collision_layer=1;body.collision_mask=0;add_child(body)
 var col:=CollisionShape3D.new();var ramp:=ConvexPolygonShape3D.new()
 var vertices:=PackedVector3Array()
 for x in [-.68,.68]:
  for yz in [Vector2(-.2,.4),Vector2(.025,.4),Vector2(2.0,-3.4),Vector2(2.0,-4.7),Vector2(-.2,-4.7)]:vertices.append(Vector3(x,yz.x,yz.y))
 ramp.points=vertices;col.shape=ramp;body.add_child(col)

func tree(at: Vector3) -> void:
 model("tree",at,4.0+fmod(absf(at.x+at.z),1.6),fmod(at.x*3.1,TAU),false)
 cylinder(at+Vector3.UP*.9,.26,1.8,Color("685b45"),true).visible=false

func build_cabin() -> void:
 bounds=Rect2(-10,-8,20,16)
 box(Vector3(0,-.2,0),Vector3(19,.4,14),Color("9d987a"),true)
 for x in range(-9,10,2):
  for z in range(-6,8,2):batch_box(Vector3(x,.01,z),Vector3(1.94,.025,1.94),Color("ccd3cb"),ART+"cabin_metal.png")
 box(Vector3(0,1.4,-7),Vector3(20,2.8,.4),Color("d0d4c5"),true,ART+"cabin_panel.png")
 for x in [-9.5,9.5]:box(Vector3(x,.55,0),Vector3(.4,1.1,14),Color("bcbf9f"),true)
 box(Vector3(0,.4,7),Vector3(20,.8,.4),Color("bcbf9f"),true)
 for x in [-6,0,6]:
  box(Vector3(x,1.6,-6.76),Vector3(3.6,1.2,.05),Color("4f8599"))
  for edge in [-1.8,1.8]:box(Vector3(x+edge,1.6,-6.68),Vector3(.08,1.4,.08),Color("ead8a7"))
 box(Vector3(-6,.35,-3.7),Vector3(3,.7,4.0),Color("745d4c"),true)
 box(Vector3(-6,.77,-3.7),Vector3(2.9,.2,3.8),Color("b6b79b"))
 box(Vector3(-6,.9,-4.6),Vector3(2.3,.22,.8),Color("e7dcc0"))
 box(Vector3(-6,.92,-3.1),Vector3(2.9,.08,2.5),Color("668997"))
 interact("Bunk: rest and save",Vector3(-3.8,0,-2.5),"rest")
 box(Vector3(5.8,.55,-4),Vector3(4,1.1,2),Color("947655"),true)
 box(Vector3(5.8,1.2,-4),Vector3(4.2,.15,2.2),Color("c3b18b"))
 for x in [4.4,6.4]:box(Vector3(x,1.8,-4.8),Vector3(1.3,.85,.25),Color("375c74"))
 box(Vector3(5.4,1.1,-3.8),Vector3(2.1,.06,.65),Color("69999c"))
 interact("Roll's workbench",Vector3(5.8,0,-2),"workshop")
 box(Vector3(0,.03,2),Vector3(5.5,.035,4),Color("a36f56"))
 for x in [-2.5,2.5]:box(Vector3(x,.04,2),Vector3(.12,.02,3.8),Color("dfc696"))
 cylinder(Vector3(6,.45,3),1.5,.3,Color("b29868"),true);cylinder(Vector3(6,.2,3),.18,.4,Color("685545"))
 box(Vector3(-6,.4,4),Vector3(4,.8,1.7),Color("557b88"),true)
 box(Vector3(-6,1.0,4.7),Vector3(4,.8,.25),Color("557b88"))
 game.spawn_npc("Roll","roll",Vector3(3,0,-3));game.spawn_npc("Data","data",Vector3(-2,0,4));game.spawn_npc("Barrell","barrell",Vector3(-5,0,2))
 interact("Disembark",Vector3(0,0,5.8),"cabin_exit")
 sign_at("CREW CABIN",Vector3(0,2.8,-6.8))

func point(cell: Vector2) -> Vector3:return Vector3(origin.x+cell.x*cell_size,0,origin.y+cell.y*cell_size)

func build_ruins() -> void:
 bounds=Rect2(origin.x,origin.y,42,30.8)
 var rooms: Array[Rect2]=[Rect2(11,16,8,5),Rect2(2,11,7,8),Rect2(11,8,8,6),Rect2(21,10,7,9),Rect2(8,2,14,5),Rect2(8,14,4,2),Rect2(18,14,4,2),Rect2(14,6,2,11)]
 if depth>=2:rooms.append(Rect2(2,4,6,5));rooms.append(Rect2(4,8,2,5))
 if depth>=3:rooms[4]=Rect2(4,2,22,5)
 if depth>=4 and depth%2==0:rooms.append(Rect2(21,4,7,5));rooms.append(Rect2(23,8,2,5))
 box(Vector3(0,-.2,0),Vector3(43,.4,32),Color("18303a"),true)
 for y in range(22):
  for x in range(30):
   for room in rooms:
    if room.has_point(Vector2(x+.5,y+.5)):cells[Vector2i(x,y)]=true;break
 for y in range(22):
  for x in range(30):
   var at:=point(Vector2(x+.5,y+.5))
   if cells.has(Vector2i(x,y)):
    batch_box(at-Vector3.UP*.055,Vector3(1.38,.14,1.38),Color("acb89f") if (x+y)%4==0 else Color("9fad96"),ART+"hex_floor.png")
    if (x*7+y*3)%11==0:batch_box(at+Vector3.UP*.012,Vector3(.9,.035,.03),Color("abc8a9"))
   else:
    batch_box(at+Vector3.UP*.65,Vector3(1.4,1.3,1.4),Color("aabba2"),ART+"wall.png")
    batch_box(at+Vector3.UP*1.32,Vector3(1.4,.06,1.4),Color("7a8e78"),ART+"wall_cap.png")
 for y in range(22):
  var start: int=-1
  for x in range(31):
   var wall: bool=x<30 and not cells.has(Vector2i(x,y))
   if wall and start<0:start=x
   if not wall and start>=0:
    var at:=point(Vector2((start+x)*.5,y+.5))+Vector3.UP*.65
    wall_collision(at,Vector3((x-start)*1.4,1.3,1.4));start=-1
 for p in [Vector2(3.2,12.2),Vector2(8.3,17.8),Vector2(12,9.5),Vector2(18,12.6),Vector2(22,11.5),Vector2(27,17.8)]:
  var at:=point(p)
  box(at+Vector3.UP*1.2,Vector3(.75,2.4,.75),Color("94b095"),true,ART+"pillar.png")
  cylinder(at+Vector3.UP*2.5,.5,.2,Color("819281"))
 for p in [Vector2(11.5,8.8),Vector2(18.5,8.8),Vector2(8.5,2.8),Vector2(21.5,2.8)]:
  var at:=point(p)
  box(at+Vector3.UP*.8,Vector3(.24,1.6,.55),Color("a6bdb4"),false,ART+"circuit.png")
  var light:=OmniLight3D.new();light.position=at+Vector3.UP*1.2;light.light_color=Color("65c9c3");light.light_energy=.4;light.omni_range=3;add_child(light)
 interact("Return to the Flutter",point(Vector2(15,19.8)),"exit")
 cylinder(point(Vector2(15,19.8))+Vector3.UP*.07,1.3,.15,Color("548a90"))
 sign_at("SURFACE LIFT",point(Vector2(15,19.8))+Vector3.UP*1.2)
 var part: String="servo" if depth==1 else ("circuit" if depth==2 else "refractor")
 var at:=point(Vector2(5.3,13.1) if depth==1 else Vector2(15,3.5))
 if game.state.repair<depth and not part in game.state.parts or depth>=4:
  var pedestal:=cylinder(at+Vector3.UP*.35,.55,.7,Color("829b8d"),true)
  var crystal=game.crystal(at+Vector3.UP*1.1,Color("a7eedb"),.35)
  interact("%s cache"%part.capitalize(),at,"cache",{"part":part,"visual":crystal,"pedestal":pedestal})
 for entry in [[Vector2(5.7,16.3),"horokko"],[Vector2(12.4,11.7),"horokko"],[Vector2(16.7,10.3),"sharukurusu"],[Vector2(24.8,13.1),"horokko"],[Vector2(25.7,17.2),"sharukurusu"],[Vector2(23,16),"horokko"]]:game.spawn_enemy(entry[1],point(entry[0]),32+depth*8)
 game.spawn_enemy("sharukurusu",point(Vector2(18.5,4.5)),35+depth*10)
 if depth>=2:game.spawn_enemy("guardian",point(Vector2(14,4.8)),130 if depth==2 else 210+(depth-3)*35,true)
 else:game.spawn_enemy("horokko",point(Vector2(6.6,12.5)),55)
 for i in range(4):
  var positions: Array=[Vector2(4.3,17.6),Vector2(17.4,12.2),Vector2(26.3,17.2),Vector2(10,4.6)]
  spawn_salvage(point(positions[i]),"%d_%d"%[depth,i])
 if not game.state.weapon_plans:
  var plans:=box(point(Vector2(26.2,14.9))+Vector3.UP*.3,Vector3(.8,.6,.8),Color("86b9b7"),true)
  interact("Weapon plans",point(Vector2(26.2,14.9)),"plans",{"visual":plans})
 for p in [Vector2(5,14.5),Vector2(15,9.5),Vector2(25,14.5),Vector2(15,4.5)]:
  var lamp:=OmniLight3D.new();lamp.position=point(p)+Vector3.UP*2;lamp.light_color=Color("76d3d1");lamp.light_energy=.6;lamp.omni_range=6;add_child(lamp)
  cylinder(point(p)+Vector3.UP*.02,.7,.035,Color("467d7d"))

func spawn_salvage(at: Vector3, id: String) -> void:
 if id in game.state.claimed:return
 var salvage=Salvage.new();salvage.game=game;salvage.claim_id=id;salvage.position=at;add_child(salvage)

func build_bonne() -> void:
 bounds=Rect2(-12,-10,24,20)
 # A service dock surrounds the combat enclosure, rather than empty sky.
 box(Vector3(0,-.7,0),Vector3(47,.5,35),Color("4b666c"))
 for x in range(-22,23,2):
  for z in range(-16,17,2):
   if abs(x)<13 and abs(z)<11:continue
   batch_box(Vector3(x,-.43,z),Vector3(2,.04,2),Color("99ada9"),ART+"cabin_metal.png")
 for x in [-14.0,14.0]:
  for z in [-12.0,12.0]:
   box(Vector3(x,1.25,z),Vector3(.4,3.4,.4),Color("718e95"),false,ART+"metal.png")
   railing(Vector3(x,-.4,z),4)
 for z in [-12.0,12.0]:box(Vector3(0,2.8,z),Vector3(28.5,.22,.22),Color("718e95"))
 model("drache",Vector3(17,-.4,-3),3.5,-PI/3)
 model("container",Vector3(-17,-.4,-5),1.15)
 model("container",Vector3(-17,-.4,-3),1.15)

 box(Vector3(0,-.2,0),Vector3(24,.4,20),Color("b7b394"),true)
 for x in range(-11,12,2):
  for z in range(-9,10,2):batch_box(Vector3(x,.012,z),Vector3(1.95,.03,1.95),Color.WHITE,ART+"sand.png")
 for entry in [[Vector3(0,.8,-10),Vector3(25,1.6,.5)],[Vector3(0,.8,10),Vector3(25,1.6,.5)],[Vector3(-12,.8,0),Vector3(.5,1.6,20)],[Vector3(12,.8,0),Vector3(.5,1.6,20)]]:box(entry[0],entry[1],Color("7c9184"),true)
 for at in [Vector3(-9,0,-7),Vector3(9,0,-7),Vector3(-9,0,7),Vector3(9,0,7)]:spawn_salvage(at,"arena_%s"%at)
 for side in [-1.0,1.0]:
  for i in range(16):
   var marker=box(Vector3(-10+i*1.3,.05,side*8.5),Vector3(.55,.025,.6),Color("ebce79"));marker.rotation.y=.35
  for x in [-10.5,10.5]:
   cylinder(Vector3(x,.55,side*8.5),.22,1.1,Color("7b888a"))
   cylinder(Vector3(x,1.15,side*8.5),.3,.12,Color("e28861"))
 for z in [-4,0,4]:box(Vector3(0,.05,z),Vector3(.14,.02,2),Color("e0d4a0"))
 game.spawn_enemy("feldynaught",Vector3(0,0,-2),290,true)
 game.spawn_enemy("servbot",Vector3(-5,0,-3),30);game.spawn_enemy("servbot",Vector3(5,0,-3),30)
 sign_at("BONNE TERRITORY",Vector3(0,3,-9))

func blocked(at: Vector3) -> bool:
 var p:=Vector2(at.x,at.z)
 for rect in walls:
  if rect.grow(.3).has_point(p):return true
 for crate in get_tree().get_nodes_in_group("legends_salvage"):
  if not crate.broken and crate.position.distance_to(at)<.8:return true
 return false

func build_navigation() -> void:
 nav.region=Rect2i(0,0,30,22);nav.cell_size=Vector2(cell_size,cell_size);nav.offset=origin+Vector2.ONE*cell_size*.5;nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;nav.update()
 for y in range(22):
  for x in range(30):nav.set_point_solid(Vector2i(x,y),blocked(point(Vector2(x+.5,y+.5))))

func free_cell(at: Vector3) -> Vector2i:
 var p:=Vector2i((Vector2(at.x,at.z)-origin)/cell_size)
 p=Vector2i(clampi(p.x,0,29),clampi(p.y,0,21))
 if not nav.is_point_solid(p):return p
 for radius in range(1,4):
  for y in range(-radius,radius+1):
   for x in range(-radius,radius+1):
    var candidate:=p+Vector2i(x,y)
    if nav.is_in_boundsv(candidate) and not nav.is_point_solid(candidate):return candidate
 return p

func path_to(from: Vector3,to: Vector3) -> PackedVector3Array:
 var a:=free_cell(from);var b:=free_cell(to);var result:=PackedVector3Array()
 if nav.is_point_solid(a) or nav.is_point_solid(b):return result
 for p in nav.get_point_path(a,b):result.append(Vector3(p.x,0,p.y))
 return result

func safe_spawn(at: Vector3) -> Vector3:
 var cell:=free_cell(at)
 return point(Vector2(cell)+Vector2.ONE*.5)
