extends Node3D
var game
var kind: String="zenny"
var amount: int=1
var motion:=Vector3.ZERO
var age: float=0
var visual: Node3D
func _ready() -> void:
 motion=Vector3(randf_range(-2,2),3.5,randf_range(-2,2))
 if kind=="shards":
  var colours: Array=[Color("ff315f"),Color("48b9ff"),Color("6ee98a"),Color("ffd65b"),Color("b77cff")]
  visual=make_shard(colours[randi()%colours.size()]);visual.rotation.z=randf_range(-.32,.32);add_child(visual)
 else:
  var colour: Color=Color("ffe0a0") if kind=="zenny" else Color("a8b4b4")
  visual=game.crystal(Vector3.ZERO,colour,.17 if kind=="zenny" else .24,self)
func make_shard(colour: Color) -> Node3D:
 var root:=Node3D.new();root.name="RefractorShard"
 var mesh:=MeshInstance3D.new();var prism:=PrismMesh.new();prism.size=Vector3(.13,.48,.105);mesh.mesh=prism;mesh.rotation.z=PI
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color(colour.r,colour.g,colour.b,.86);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS;mat.emission_enabled=true;mat.emission=colour*.42;mat.roughness=.22;mat.metallic=.05;mesh.material_override=mat;root.add_child(mesh)
 var glow:=OmniLight3D.new();glow.light_color=colour;glow.light_energy=.28;glow.omni_range=1.1;glow.shadow_enabled=false;root.add_child(glow)
 return root
func _physics_process(delta: float) -> void:
 if not game.active():return
 age+=delta;motion.y-=9.8*delta
 var next: Vector3=position+motion*delta
 var query:=PhysicsRayQueryParameters3D.create(position,next,1)
 var hit:=get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():
  position=hit.position+hit.normal*.14;motion=motion.bounce(hit.normal)*.35
 else:position=next
 motion.x=move_toward(motion.x,0,3*delta);motion.z=move_toward(motion.z,0,3*delta)
 if position.y<.14:position.y=.14;motion.y=absf(motion.y)*.25
 var target: Vector3=game.player.position+Vector3.UP*.4
 var distance: float=position.distance_to(target)
 if distance<3.7 and age>.35:
  var attracted: Vector3=position.move_toward(target,(5+(3.7-distance)*3)*delta)
  if game.line_clear(position,attracted):position=attracted
 if distance<.7 and age>.35:
  game.state.set(kind,int(game.state.get(kind))+amount);game.audio.effect("item",1.1);queue_free()
 if is_instance_valid(visual):
  visual.rotation.y+=delta*2
  if kind=="shards":visual.rotation.z+=delta*.35
