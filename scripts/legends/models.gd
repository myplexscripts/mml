extends RefCounted
## Textured fan resources are credited in docs/ASSETS.md.
const TEXTURES := {"flutter":"EM0A00.png","feldynaught":"BS0000.png","drache":"SH0C00.png","horokko":"EM0300.png","sharukurusu":"EM3701.png","guardian":"BS0200.png","roll":"EM0500.PNG","data":"GAUGE01.png","barrell":"EM2500.png","tron":"EM2800.png","servbot":"EM0000.png"}

static func make(key: String, height: float) -> Node3D:
 var scene: PackedScene=load("res://assets/models/%s/model.%s"%[key,"glb" if key=="megaman" else "fbx"])
 var root:=Node3D.new();root.name=key.capitalize()
 var model=scene.instantiate();root.add_child(model)
 var bounds:=AABB();var first:=true
 var materials: Array=[]
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  if key=="megaman" and mesh.name in ["Helmet","Head_2","Head2","Machine_Buster","Powered_Buster","Drill_Arm","Spread_Buster","Vacuum_Arm","Active_Buster","Blade_Arm","Shield_Arm","Shining_Laser"]:
   mesh.visible=mesh.name=="Head2"
   if not mesh.visible: continue
  var transform: Transform3D=mesh.transform
  var ancestor=mesh.get_parent()
  while ancestor!=root and ancestor is Node3D:
   transform=ancestor.transform*transform;ancestor=ancestor.get_parent()
  var box: AABB=transform*mesh.get_aabb()
  bounds=box if first else bounds.merge(box);first=false
  for i in range(mesh.mesh.get_surface_count()):
   var source=mesh.get_active_material(i)
   var material:=StandardMaterial3D.new()
   if source is StandardMaterial3D: material=source.duplicate()
   if key=="megaman":
    var file: String="MegamanBody.png"
    if str(source.resource_name)=="Body2": file="MegamanBody2.png"
    elif str(source.resource_name)=="SWeapons" or str(source.resource_name)=="Sweapons": file="MegamanSW.png"
    elif str(source.resource_name)=="Faces": file="ST00_00_0000 upd.png"
    if "Eyes" in str(source.resource_name): file="EyeFull.png"
    elif "Hair" in str(source.resource_name): file="MegamanHair.png"
    material.albedo_texture=load("res://assets/models/megaman/tex/"+file)
   else: material.albedo_texture=load("res://assets/models/%s/tex/%s"%[key,TEXTURES[key]])
   material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
   material.emission_enabled=false;material.albedo_color=Color.WHITE;material.vertex_color_use_as_albedo=false;material.roughness=.9;material.metallic=0;material.cull_mode=BaseMaterial3D.CULL_DISABLED
   mesh.set_surface_override_material(i,material);materials.append(material)
 if key=="megaman":bounds=AABB(Vector3(-.687902,1.126752,-.46603),Vector3(4.054277,3.963527,1.013878))
 var factor: float=height/maxf(bounds.size.y,.001)
 model.scale=Vector3.ONE*factor*(1.0 if key=="megaman" else .01)
 model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
 root.set_meta("model",model)
 root.set_meta("height",height)
 root.set_meta("materials",materials)
 root.set_meta("skeletons",model.find_children("*","Skeleton3D",true,false))
 return root

static func pose(visual: Node3D, phase: float, walking: bool, firing: bool=false) -> void:
 var model=visual.get_meta("model")
 for skeleton in visual.get_meta("skeletons"):
  if visual.name=="Megaman":
   for name in ["RLeg1","LLeg1","RArm1","LArm1"]:
    var bone: int=skeleton.find_bone(name)
    if bone<0: continue
    var angle: float=sin(phase)*(0.38 if walking else .025)*(1 if name in ["RLeg1","LArm1"] else -1)
    if firing and name=="LArm1": angle=-.7
    if "Arm" in name:
     var axis: Vector3=skeleton.get_bone_global_rest(bone).basis.inverse()*Vector3.BACK
     angle=(1.25 if name=="RArm1" else -1.25)
     if firing and name=="LArm1":
      axis=skeleton.get_bone_global_rest(bone).basis.inverse()*Vector3.UP;angle=-1.35
     skeleton.set_bone_pose_rotation(bone,Quaternion(axis.normalized(),angle))
    else:
     var axis: Vector3=skeleton.get_bone_global_rest(bone).basis.inverse()*Vector3.RIGHT
     skeleton.set_bone_pose_rotation(bone,Quaternion(axis.normalized(),angle*(1 if name=="RLeg1" else -1)))
  elif walking:
   for i in range(1,mini(4,skeleton.get_bone_count())):
    skeleton.set_bone_pose_rotation(i,Quaternion(Vector3.RIGHT,sin(phase+float(i)*PI)*.12))

static func flash(visual: Node3D,strength: float) -> void:
 for mat in visual.get_meta("materials"):
  mat.emission_enabled=strength>0
  if strength>0:mat.emission=Color(1,.75,.4)*strength
