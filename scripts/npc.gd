extends CharacterBody2D
const ModelSprite = preload("res://scripts/model_sprite.gd")

var game
var person: String = "Roll"
var art: String = "roll"
var sprite: Sprite2D
var model_view
var clock: float = 0.0
var destination := Vector2.ZERO
var path: PackedVector2Array = []
var refresh: float = 0.0
var frame_row: int = 0

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7
	shape.shape = circle
	add_child(shape)

	var model_path := _model_path()
	if not model_path.is_empty():
		model_view = ModelSprite.new()
		model_view.model_path = model_path
		model_view.display_height = 61.0 if person!="Data" else 48.0
		model_view.yaw_offset = PI
		add_child(model_view)
	else:
		sprite = Sprite2D.new()
		sprite.texture = load("res://assets/characters/%s.png"%art)
		sprite.hframes=4
		sprite.vframes=4
		sprite.position=Vector2(0,-21)
		sprite.scale=Vector2(1.25,1.25)
		add_child(sprite)

func _model_path() -> String:
	for extension in ["glb", "fbx"]:
		var path := "res://assets/models/%s/model.%s" % [art, extension]
		if ResourceLoader.exists(path):
			return path
	return ""

func _physics_process(delta: float) -> void:
	if not game.active(): return
	clock+=delta
	refresh-=delta
	destination = game.npc_destination(person)
	if refresh<=0:
		refresh=1.5
		path=game.world.path_to(global_position,destination)
	var target:=destination
	if path.size()>1:
		if global_position.distance_to(path[1])<9: path.remove_at(0)
		if path.size()>1: target=path[1]
	var move:=global_position.direction_to(target)
	if global_position.distance_to(destination)>10 and path.size()>1:
		velocity=move*23
		if absf(move.x)>absf(move.y): frame_row=2 if move.x<0 else 3
		else: frame_row=1 if move.y<0 else 0
	else:
		velocity=Vector2.ZERO
		frame_row=0
	move_and_slide()
	if is_instance_valid(model_view):
		if velocity.length()>1: model_view.set_facing(velocity.normalized())
		model_view.set_moving(velocity.length()>1 or person=="Data")
	elif is_instance_valid(sprite):
		sprite.frame=frame_row*4+(int(clock*5)%4 if velocity.length()>1 or person=="Data" else 0)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,10,Color(0.06,0.14,0.17,0.22))
	draw_set_transform(Vector2.ZERO)
	if game.player.global_position.distance_to(global_position)<48:
		draw_circle(Vector2(0,-49),7,Color("fff0bd"));draw_string(ThemeDB.fallback_font,Vector2(-4,-44),"E",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("254253"))
