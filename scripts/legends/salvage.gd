extends StaticBody3D
var game
var claim_id: String=""
var health: int=26
var broken: bool=false
func _ready() -> void:
 add_to_group("legends_salvage");collision_layer=16;collision_mask=0
 var shape:=BoxShape3D.new();shape.size=Vector3(.9,.9,.9)
 var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=.45;add_child(collision)
 var visual=preload("res://scripts/legends/models.gd").make("container",.9);add_child(visual)
func hurt(damage: int, from: Vector3) -> void:
 if broken or not game.active():return
 health-=damage;game.spark(position+Vector3.UP*.5,Color("dfbd81"),.2,.25)
 if health>0:game.audio.effect("hit");return
 broken=true;collision_layer=0;game.state.claimed.append(claim_id)
 game.drop(position,"scrap",2);game.drop(position,"shards",1);game.drop(position,"zenny",35)
 game.state.score+=40;game.run_score+=40;game.world.build_navigation();game.audio.effect("explosion",1.5);game.state.save_game();queue_free()
