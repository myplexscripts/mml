extends StaticBody2D
const ModelSprite = preload("res://scripts/model_sprite.gd")

var game
var claim_id: String
var health: int = 22
var broken: bool = false
var sprite: Sprite2D
var model_view
var flash: float = 0.0

func _ready() -> void:
	add_to_group("salvage")
	collision_layer=16;collision_mask=0
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new();shape.size=Vector2(28,20)
	collision.shape=shape;collision.position.y=-7;add_child(collision)

	var model_path := "res://assets/models/container/model.glb"
	if not ResourceLoader.exists(model_path): model_path = "res://assets/models/container/model.fbx"
	if ResourceLoader.exists(model_path):
		model_view = ModelSprite.new()
		model_view.model_path = model_path
		model_view.display_height = 43.0
		model_view.yaw_offset = -0.35
		add_child(model_view)
	else:
		sprite=Sprite2D.new();sprite.texture=preload("res://assets/world/salvage.png")
		sprite.position.y=-16;add_child(sprite)

func _process(delta: float) -> void:
	if not game.active(): return
	flash=maxf(0,flash-delta)
	var tint := Color(2,2,2) if flash>0 else Color.WHITE
	if is_instance_valid(model_view): model_view.set_visual_modulate(tint)
	elif is_instance_valid(sprite): sprite.modulate=tint

func hurt(damage: int, from: Vector2) -> void:
	if broken or not game.active(): return
	health-=damage;flash=.12
	game.burst(position+Vector2(0,-15),Color("c3ab78"),5,40)
	if health>0: game.audio.effect("hit");return
	broken=true;game.state.claimed.append(claim_id)
	collision_layer=0
	game.world.build_navigation()
	game.drop(position,"scrap",2,Vector2(20,-25))
	game.drop(position,"shard",1,Vector2(-20,-25))
	game.drop(position,"zenny",35,Vector2(0,-35))
	game.state.score+=40;game.dig_score+=40
	game.audio.effect("explosion",1.4);game.state.save_game()
	queue_free()
