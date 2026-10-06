extends RefCounted
## Textured fan resources are credited in docs/ASSETS.md.
const TEXTURES := {"container":"KONTE.png","flutter":"EM0A00.png","feldynaught":"BS0000.png","drache":"SH0C00.png","horokko":"EM0300.png","sharukurusu":"EM3701.png","guardian":"BS0200.png","roll":"EM0500.PNG","data":"GAUGE01.png","barrell":"EM2500.png","tron":"EM2800.png","servbot":"EM0000.png"}

static func make(key: String, height: float) -> Node3D:
 var scenery: bool=key in ["tree","lamp","shed","harbour","bakery","boat","buster","hangar"]
 var modern: bool=scenery or key in ["megaman","flutter","container","drache"]
 var path: String="res://assets/scenery/%s.glb"% ("volnutt" if key=="megaman" else key) if scenery or key=="megaman" else "res://assets/models/%s/model.%s"%[key,"glb" if modern else "fbx"]
 var scene: PackedScene=load(path)
 var root:=Node3D.new();root.name=key.capitalize()
 var model=scene.instantiate();root.add_child(model)
 var bounds:=AABB();var first:=true
 var materials: Array=[]
 for mesh in model.find_children("*","MeshInstance3D",true,false):
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
   if not modern:material.albedo_texture=load("res://assets/models/%s/tex/%s"%[key,TEXTURES[key]])
   material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
   material.emission_enabled=false;
   if material.albedo_texture!=null:material.albedo_color=Color.WHITE
   material.vertex_color_use_as_albedo=false;material.roughness=.95;material.metallic=0;material.cull_mode=BaseMaterial3D.CULL_DISABLED
   mesh.set_surface_override_material(i,material);materials.append(material)
 var factor: float=height/maxf(bounds.size.y,.001)
 model.scale=Vector3.ONE*factor*(1.0 if modern else .01)
 model.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
 if key=="buster":model.position.y-=height/2
 root.set_meta("bounds",AABB(Vector3(-bounds.size.x/2,0,-bounds.size.z/2)*factor,bounds.size*factor))
 var animations=model.find_children("*","AnimationPlayer",true,false)
 if key=="megaman" and not animations.is_empty():
  var animation: AnimationPlayer=animations[0]
  animation.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  animation.get_animation("Run").loop_mode=Animation.LOOP_LINEAR
  animation.get_animation("Idle").loop_mode=Animation.LOOP_LINEAR
  animation.play("Idle");animation.advance(0);root.set_meta("run_animation",animation)
  var skeleton: Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
  var socket:=BoneAttachment3D.new();socket.bone_name="Hand.l";skeleton.add_child(socket)
  var buster=make("buster",.55);buster.position=Vector3(0,.1,0);socket.add_child(buster)
  root.set_meta("buster",buster)
 root.set_meta("model",model)
 root.set_meta("height",height)
 root.set_meta("materials",materials)
 root.set_meta("skeletons",model.find_children("*","Skeleton3D",true,false))
 return root

static func pose(visual: Node3D, phase: float, walking: bool, firing: bool=false, advance_time: bool=true) -> void:
 var model=visual.get_meta("model")
 for skeleton in visual.get_meta("skeletons"):
  if visual.name=="Megaman":
   if visual.has_meta("run_animation"):
    var animation: AnimationPlayer=visual.get_meta("run_animation")
    var desired: String="Run" if walking else "Idle"
    if animation.current_animation!=desired or not animation.is_playing():animation.play(desired,.12)
    animation.speed_scale=1.1 if walking else .65
    animation.advance(1.0/Engine.physics_ticks_per_second if advance_time else 0.0)
   # Keep the buster aimed while the authored running animation drives the legs.
   if firing:
    for name in ["Bicep.l","Forearm.l"]:
     var bone: int=skeleton.find_bone(name)
     var next: int=skeleton.find_bone("Forearm.l" if name=="Bicep.l" else "Hand.l")
     var rest: Transform3D=skeleton.get_bone_global_rest(bone)
     var direction: Vector3=(skeleton.get_bone_global_rest(next).origin-rest.origin).normalized()
     var aligned: Basis=Basis(Quaternion(direction,Vector3.BACK))*rest.basis
     var parent: int=skeleton.get_bone_parent(bone)
     var local: Basis=(skeleton.get_bone_global_pose(parent).basis*skeleton.get_bone_rest(bone).basis).inverse()*aligned
     skeleton.set_bone_pose_rotation(bone,local.get_rotation_quaternion())
   if visual.has_meta("buster"):
    var hand: Transform3D=skeleton.get_bone_global_pose(skeleton.find_bone("Hand.l"))
    var elbow: Transform3D=skeleton.get_bone_global_pose(skeleton.find_bone("Forearm.l"))
    var direction: Vector3=(hand.origin-elbow.origin).normalized()
    var buster: Node3D=visual.get_meta("buster")
    buster.basis=hand.basis.inverse()*Basis(Quaternion(Vector3.UP,direction))
    buster.position=hand.basis.inverse()*direction*-.12
  elif walking:
   for i in range(1,mini(4,skeleton.get_bone_count())):
    skeleton.set_bone_pose_rotation(i,Quaternion(Vector3.RIGHT,sin(phase+float(i)*PI)*.12))

static func muzzle(visual: Node3D) -> Vector3:
 var skeleton: Skeleton3D=visual.get_meta("skeletons")[0]
 var hand: Transform3D=skeleton.get_bone_global_pose(skeleton.find_bone("Hand.l"))
 var buster: Node3D=visual.get_meta("buster")
 return skeleton.global_transform*(hand*(buster.transform*Vector3(0,.275,0)))

static func flash(visual: Node3D,strength: float) -> void:
 for mat in visual.get_meta("materials"):
  mat.emission_enabled=strength>0
  if strength>0:mat.emission=Color(1,.75,.4)*strength
