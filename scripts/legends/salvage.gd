extends StaticBody3D
var game
var claim_id: String=""
var health: int=26
var broken: bool=false
func _ready() -> void:
 add_to_group("legends_salvage");collision_layer=16;collision_mask=0
 var shape:=BoxShape3D.new();shape.size=Vector3(.9,.9,.9)
 var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=.45;add_child(collision)
 var mesh:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.9,.9,.9);mesh.mesh=box;mesh.position.y=.45
 var mat:=StandardMaterial3D.new();mat.albedo_texture=preload("res://assets/world/salvage.png");mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;mat.roughness=.8;mesh.material_override=mat;add_child(mesh)
 for y in [.2,.7]:
  var band:=MeshInstance3D.new();var strip:=BoxMesh.new();strip.size=Vector3(.94,.07,.94);band.mesh=strip;band.position.y=y
  var metal:=StandardMaterial3D.new();metal.albedo_color=Color("b9b98d");band.material_override=metal;add_child(band)
func hurt(damage: int, from: Vector3) -> void:
 if broken or not game.active():return
 health-=damage;game.spark(position+Vector3.UP*.5,Color("dfbd81"),.2,.25)
 if health>0:game.audio.effect("hit");return
 broken=true;collision_layer=0;game.state.claimed.append(claim_id)
 game.drop(position,"scrap",2);game.drop(position,"shards",1);game.drop(position,"zenny",35)
 game.state.score+=40;game.run_score+=40;game.world.build_navigation();game.audio.effect("explosion",1.5);game.state.save_game();queue_free()
