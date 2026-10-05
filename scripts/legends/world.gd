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
var ambient: WorldEnvironment
var cell_size: float=1.4
var origin:=Vector2(-21,-15.4)

func _ready() -> void:
 setup_light()
 if area=="island":build_island()
 elif area=="cabin":build_cabin()
 elif area=="bonne":build_bonne()
 else:build_ruins()
 finish_batches();build_navigation()

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

func cylinder(at: Vector3, radius: float, height: float, colour: Color) -> MeshInstance3D:
 var mesh:=MeshInstance3D.new();var shape:=CylinderMesh.new();shape.top_radius=radius;shape.bottom_radius=radius;shape.height=height;shape.radial_segments=12
 mesh.mesh=shape;mesh.material_override=material(colour);mesh.position=at;add_child(mesh);return mesh

func model(key: String, at: Vector3, height: float, rotation_y: float=0) -> Node3D:
 var visual:=Models.make(key,height);visual.position=at;visual.rotation.y=rotation_y;add_child(visual);return visual

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
 var water:=box(Vector3(0,-.55,0),Vector3(180,.1,180),Color("579fac"))
 var shader:=Shader.new();shader.code="shader_type spatial; render_mode unshaded; uniform vec4 base : source_color=vec4(0.23,0.54,0.63,1.0); void fragment(){float wave=sin(UV.x*240.0+TIME*.65)*sin(UV.y*210.0-TIME*.45);ALBEDO=base.rgb+vec3(wave*.026);ROUGHNESS=0.75;}"
 var water_material:=ShaderMaterial.new();water_material.shader=shader;water.material_override=water_material
 box(Vector3(0,-.25,0),Vector3(44,.5,34),Color("577c61"),true)
 for x in range(-21,22,2):
  for z in range(-15,16,2):
   batch_box(Vector3(x,.002,z),Vector3(2,.008,2),Color("739c72"),"res://assets/world/grass_daisy.png" if (x*7+z*11)%23==0 else "res://assets/world/grass.png")
 box(Vector3(0,-.7,0),Vector3(44,1.2,34),Color("7c8160"))
 # Traversable pale landing apron, paths and a ruin lift.
 box(Vector3(-5,.005,3),Vector3(22,.035,16),Color("c1b786"))
 box(Vector3(6,.012,-4),Vector3(4,.045,21),Color("c6bd99"))
 for x in range(-16,7,2):
  for z in range(-4,12,2):batch_box(Vector3(x,.03,z),Vector3(1.92,.015,1.92),Color("b8ad86"),"res://assets/world/paving.png")
 for x in range(-22,23,2):
  box(Vector3(x,.1,-16.8),Vector3(1.9,.35,.55),Color("aaa987"))
  box(Vector3(x,.1,16.8),Vector3(1.9,.35,.55),Color("aaa987"))
 # Ground clearance and ship collider use its actual footprint.
 var ship=model("flutter",Vector3(-9,0,-1),10.0)
 ship.rotation_degrees=Vector3(-90,0,0)
 ship.position.y=4.2
 ship.position.z=4.0
 box(Vector3(-9,1.1,-1),Vector3(8.0,2.2,9.5),Color(0,0,0,0),true).visible=false
 for x in [-15.0,-3.0]:
  cylinder(Vector3(x,.1,2),.8,.18,Color("566e72"))
 var repair_light:=OmniLight3D.new();repair_light.position=Vector3(-9,2,1);repair_light.light_color=Color("7ed8b3");repair_light.light_energy=.8;repair_light.omni_range=9;add_child(repair_light)
 repair_light.visible=game.state.repair>=3;repair_visuals.append(repair_light)
 for entry in [[Vector3(-2,0,5),"Roll","roll"],[Vector3(3,0,8),"Data","data"],[Vector3(-14,0,8),"Barrell","barrell"]]:game.spawn_npc(entry[1],entry[2],entry[0])
 interact("Board the Flutter",Vector3(-5,0,5),"cabin")
 interact("Northern Ruins",Vector3(6,0,-12),"lift")
 interact("Supply crate",Vector3(13,0,5),"shop")
 sign_at("THE FLUTTER",Vector3(-9,4.5,5))
 sign_at("NORTHERN RUINS",Vector3(6,2.8,-12))
 # Stone arch, steps and physical side walls.
 for x in [3.9,8.1]:box(Vector3(x,1.4,-12),Vector3(1.0,2.8,2),Color("74918b"),true,"res://assets/world/ruin_panel.png")
 box(Vector3(6,2.9,-12),Vector3(5.3,.65,2),Color("9bac8b"))
 cylinder(Vector3(6,.04,-12),1.35,.12,Color("397b83"))
 for z in [-13,-12.5,-12]:box(Vector3(6,.12,z),Vector3(2,.12,.25),Color("bbd1b6"))
 model("drache",Vector3(14,0,-6),4.0,PI*.8)
 box(Vector3(13,.35,5),Vector3(1.7,.7,1.2),Color("758880"),true)
 sign_at("SUPPLIES",Vector3(13,1.5,5))
 for at in [Vector3(-19,0,-12),Vector3(-17,0,-10),Vector3(-13,0,-13),Vector3(-4,0,-13),Vector3(0,0,-11),Vector3(12,0,-13),Vector3(19,0,-11),Vector3(19,0,-3),Vector3(18,0,9),Vector3(12,0,14),Vector3(2,0,14),Vector3(-15,0,14),Vector3(-20,0,8)]:tree(at)
 for i in range(25):
  var at:=Vector3(-20+float((i*17)%40),.12,-15+float((i*7)%31))
  if at.x<7 and at.x>-17 and at.z>-6 and at.z<12:continue
  var rock:=SphereMesh.new();rock.height=.5;rock.radius=.4;rock.radial_segments=6;rock.rings=3
  var mesh:=MeshInstance3D.new();mesh.mesh=rock;mesh.position=at;mesh.scale=Vector3(1.4,.7,1);mesh.material_override=material(Color("8b9d7b"));add_child(mesh)
 # Invisible shoreline collision prevents falling into the sea.
 for entry in [[Vector3(-22.3,1,0),Vector3(.6,2,35)],[Vector3(22.3,1,0),Vector3(.6,2,35)],[Vector3(0,1,-17.3),Vector3(45,2,.6)],[Vector3(0,1,17.3),Vector3(45,2,.6)]]:box(entry[0],entry[1],Color.WHITE,true).visible=false
 if game.state.repair>=2:game.spawn_npc("Tron","tron",Vector3(8,0,3))

func tree(at: Vector3) -> void:
 cylinder(at+Vector3(0,1.3,0),.2,2.6,Color("836a4e"))
 var body:=StaticBody3D.new();body.position=at+Vector3.UP;body.collision_layer=1
 var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=.22;shape.height=2;collision.shape=shape;body.add_child(collision);add_child(body)
 walls.append(Rect2(at.x-.25,at.z-.25,.5,.5))
 for i in range(3):
  var mesh:=MeshInstance3D.new();var cone:=CylinderMesh.new();cone.top_radius=.1;cone.bottom_radius=1.3-float(i)*.25;cone.height=1.6;cone.radial_segments=7
  mesh.mesh=cone;mesh.material_override=material(Color("598767") if i%2==0 else Color("75a270"));mesh.position=at+Vector3(0,2.2+i*.65,0);add_child(mesh)

func build_cabin() -> void:
 bounds=Rect2(-10,-8,20,16)
 box(Vector3(0,-.2,0),Vector3(19,.4,14),Color("9d987a"),true)
 for x in range(-9,10,2):
  for z in range(-6,8,2):batch_box(Vector3(x,.01,z),Vector3(1.94,.025,1.94),Color("82938d"))
 box(Vector3(0,1.4,-7),Vector3(20,2.8,.4),Color("d0c7a1"),true)
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
 cylinder(Vector3(6,.45,3),1.5,.3,Color("b29868"));cylinder(Vector3(6,.2,3),.18,.4,Color("685545"))
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
    batch_box(at-Vector3.UP*.07,Vector3(1.38,.14,1.38),Color("9ea89d") if (x+y)%4==0 else Color("869893"),"res://assets/world/ruin_floor.png")
    if (x*7+y*3)%11==0:batch_box(at+Vector3.UP*.012,Vector3(.9,.035,.03),Color("abc8a9"))
   else:
    batch_box(at+Vector3.UP*.65,Vector3(1.4,1.3,1.4),Color("627d79"),"res://assets/world/ruin_panel.png")
    batch_box(at+Vector3.UP*1.32,Vector3(1.4,.06,1.4),Color("80968e"),"res://assets/world/ruin_panel.png")
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
  box(at+Vector3.UP*1.2,Vector3(.75,2.4,.75),Color("9eae99"),true,"res://assets/world/ruin_panel.png")
  cylinder(at+Vector3.UP*2.5,.5,.2,Color("b7c7a5"))
 interact("Return to the Flutter",point(Vector2(15,19.8)),"exit")
 cylinder(point(Vector2(15,19.8))+Vector3.UP*.07,1.3,.15,Color("548a90"))
 sign_at("SURFACE LIFT",point(Vector2(15,19.8))+Vector3.UP*1.2)
 var part: String="servo" if depth==1 else ("circuit" if depth==2 else "refractor")
 var at:=point(Vector2(5.3,13.1) if depth==1 else Vector2(15,3.5))
 if game.state.repair<depth and not part in game.state.parts or depth>=4:
  var pedestal:=cylinder(at+Vector3.UP*.35,.55,.7,Color("829b8d"))
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
  var plans:=box(point(Vector2(26.2,14.9))+Vector3.UP*.3,Vector3(.8,.6,.8),Color("86b9b7"))
  interact("Weapon plans",point(Vector2(26.2,14.9)),"plans",{"visual":plans})
 for p in [Vector2(5,14.5),Vector2(15,9.5),Vector2(25,14.5),Vector2(15,4.5)]:
  var lamp:=OmniLight3D.new();lamp.position=point(p)+Vector3.UP*2;lamp.light_color=Color("76d3d1");lamp.light_energy=.6;lamp.omni_range=6;add_child(lamp)
  cylinder(point(p)+Vector3.UP*.02,.7,.035,Color("467d7d"))

func spawn_salvage(at: Vector3, id: String) -> void:
 if id in game.state.claimed:return
 var salvage=Salvage.new();salvage.game=game;salvage.claim_id=id;salvage.position=at;add_child(salvage)

func build_bonne() -> void:
 bounds=Rect2(-12,-10,24,20)
 box(Vector3(0,-.2,0),Vector3(24,.4,20),Color("b7b394"),true)
 for x in range(-11,12,2):
  for z in range(-9,10,2):batch_box(Vector3(x,.012,z),Vector3(1.95,.03,1.95),Color("bfc0a5"),"res://assets/world/paving.png")
 for entry in [[Vector3(0,.8,-10),Vector3(25,1.6,.5)],[Vector3(0,.8,10),Vector3(25,1.6,.5)],[Vector3(-12,.8,0),Vector3(.5,1.6,20)],[Vector3(12,.8,0),Vector3(.5,1.6,20)]]:box(entry[0],entry[1],Color("7c9184"),true)
 for at in [Vector3(-9,0,-7),Vector3(9,0,-7),Vector3(-9,0,7),Vector3(9,0,7)]:spawn_salvage(at,"arena_%s"%at)
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
