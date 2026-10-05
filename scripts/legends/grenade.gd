extends RigidBody3D
var game
var fuse: float=1.15
var detonated: bool=false
func _ready() -> void:
 collision_layer=32;collision_mask=1|16;continuous_cd=true;mass=.4
 physics_material_override=PhysicsMaterial.new();physics_material_override.bounce=.55;physics_material_override.friction=.55
 var shape:=SphereShape3D.new();shape.radius=.16
 var collision:=CollisionShape3D.new();collision.shape=shape;add_child(collision)
 var mesh:=MeshInstance3D.new();var ball:=SphereMesh.new();ball.radius=.16;ball.height=.32;mesh.mesh=ball
 var mat:=StandardMaterial3D.new();mat.albedo_color=Color("759cae");mat.metallic=.5;mat.roughness=.3;mesh.material_override=mat;add_child(mesh)
func _physics_process(delta: float) -> void:
 freeze=not game.active()
 if freeze:return
 fuse-=delta
 if fuse<=0:explode()
func explode() -> void:
 if detonated:return
 detonated=true
 for target in game.enemies.duplicate()+get_tree().get_nodes_in_group("legends_salvage"):
  if not is_instance_valid(target):continue
  var to: Vector3=target.position+Vector3.UP*.65
  if position.distance_to(to)<3.5 and game.line_clear(position,to):target.hurt(48+game.state.power*6,position)
 game.explosion(position);game.audio.effect("explosion",.85);game.shake=.3;queue_free()
