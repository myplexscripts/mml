extends Node2D
## Horizontal swept collision and a separate ballistic height give a lobbed shot.
var game
var motion := Vector2.ZERO
var height: float = 14.0
var lift: float = 130.0
var fuse: float = 1.05
var detonated: bool = false

func _physics_process(delta: float) -> void:
	if not game.active(): return
	fuse-=delta
	var next: Vector2=position+motion*delta
	var hit:=get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,next,1|16))
	if not hit.is_empty():
		position=hit.position+hit.normal*2
		motion=motion.bounce(hit.normal)*0.45
	else: position=next
	height+=lift*delta;lift-=320*delta
	if height<3:
		height=3;lift=absf(lift)*0.28;motion*=0.75
	if fuse<=0: explode()
	queue_redraw()

func explode() -> void:
	if detonated: return
	detonated=true
	for target in game.enemies.duplicate()+get_tree().get_nodes_in_group("salvage"):
		if not is_instance_valid(target): continue
		var distance: float=position.distance_to(target.position)
		if distance<88 and game.line_clear(position,target.position):
			target.hurt(48+game.state.power*6,position)
	game.burst(position+Vector2(0,-10),Color("ffd18b"),35,135)
	game.audio.effect("explosion",0.9);game.shake=5
	queue_free()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,.4))
	draw_circle(Vector2.ZERO,7,Color(0,0,0,.3));draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0,-height),5,Color("355e78"))
	draw_circle(Vector2(0,-height),3,Color("b2d7cd"))
	if int(fuse*16)%2==0: draw_circle(Vector2(1,-height-3),2,Color("ffaf64"))
