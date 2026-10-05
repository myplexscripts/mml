extends Node3D
var game
var speed:=Vector3.ZERO
var damage: int=12
var hostile: bool=false
var charged: bool=false
var life: float=1.3
func _ready() -> void:
 var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=.16 if charged else .07;sphere.height=sphere.radius*2;sphere.radial_segments=8;sphere.rings=4;mesh.mesh=sphere
 var material:=StandardMaterial3D.new();material.albedo_color=Color("ff9673") if hostile else Color("b1e9ea");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.emission_enabled=true;material.emission=material.albedo_color;mesh.material_override=material;add_child(mesh)
func _physics_process(delta: float) -> void:
 if not game.active():return
 life-=delta
 var next: Vector3=global_position+speed*delta
 var query:=PhysicsRayQueryParameters3D.create(global_position,next,1|(2 if hostile else 4)|16)
 var hit:=get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():
  if hit.collider.has_method("hurt"):hit.collider.hurt(damage,global_position)
  game.spark(hit.position,Color("ffbb83") if hostile else Color("a8e4e2"),.16,.2)
  queue_free();return
 global_position=next
 if life<=0:queue_free()
