extends Node2D
var game
var kind: String = "zenny"
var amount: int = 1
var motion := Vector2.ZERO
var height: float = 16.0
var rise: float = 60.0
var age: float = 0.0
var sprite: Sprite2D

func _ready() -> void:
	if kind!="zenny":
		sprite = Sprite2D.new()
		var path := "res://assets/items/%s.png"%kind
		if ResourceLoader.exists(path):
			sprite.texture = load(path)
			sprite.scale = Vector2(0.65,0.65)
		add_child(sprite)

func _physics_process(delta: float) -> void:
	if not game.active(): return
	age += delta
	rise -= 190*delta
	height += rise*delta
	if height<0:
		height=0
		rise = absf(rise)*0.35 if absf(rise)>18 else 0
	var next: Vector2 = global_position+motion*delta
	if game.line_clear(global_position,next): global_position=next
	else: motion=Vector2.ZERO
	motion = motion.move_toward(Vector2.ZERO,80*delta)
	var distance: float = global_position.distance_to(game.player.global_position)
	if distance<80 and age>0.35:
		var target: Vector2 = game.player.global_position
		var attracted: Vector2 = global_position.move_toward(target,(120+(80-distance)*3)*delta)
		if game.line_clear(global_position,attracted): global_position=attracted
	if distance<16 and age>0.35:
		if kind=="zenny": game.state.zenny += amount
		else: game.state.items[kind]=int(game.state.items.get(kind,0))+amount
		game.audio.effect("item",1.15 if kind=="zenny" else 1)
		queue_free()
	if is_instance_valid(sprite): sprite.position.y = -height-8
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO,5,Color(0.07,0.12,0.15,0.2))
	if kind=="zenny":
		var p := Vector2(0,-height-5)
		draw_circle(p,5,Color("a97947"));draw_circle(p+Vector2(0,-1),4,Color("ffe1a0"));draw_line(p+Vector2(0,-3),p+Vector2(0,1),Color("b08e53"),1)
