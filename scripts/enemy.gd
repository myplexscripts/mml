extends CharacterBody2D
const ModelSprite = preload("res://scripts/model_sprite.gd")

var game
var kind: String = "horokko"
var health: int = 30
var max_health: int = 30
var home := Vector2.ZERO
var phase: String = "idle"
var timer: float = 0.0
var cooldown: float = 1.0
var hurt_flash: float = 0.0
var knockback := Vector2.ZERO
var attack_direction := Vector2.DOWN
var clock: float = 0.0
var sprite: Sprite2D
var model_view
var boss: bool = false
var reward: int = 40
var score_value: int = 100
var defeated: bool = false
var path: PackedVector2Array = []
var path_timer: float = 0.0
var attack_count: int = 0

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 16
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25 if boss else 12
	shape.shape = circle
	add_child(shape)

	var model_path := _model_path()
	if not model_path.is_empty():
		model_view = ModelSprite.new()
		model_view.model_path = model_path
		model_view.display_height = 86.0 if boss else 56.0
		model_view.yaw_offset = PI
		add_child(model_view)
	else:
		sprite = Sprite2D.new()
		if kind == "bonne":
			sprite.texture = preload("res://assets/world/bonne_mech.png")
			sprite.scale = Vector2(0.9,0.9)
			sprite.position = Vector2(0,-42)
		elif boss:
			sprite.texture = preload("res://assets/characters/guardian.png")
			sprite.position = Vector2(0,-29)
		else:
			sprite.texture = load("res://assets/characters/%s.png"%kind)
			sprite.hframes = 4
			sprite.position = Vector2(0,-18)
		add_child(sprite)
	home = global_position
	max_health = health

func _model_path() -> String:
	var model_name := kind
	if kind == "bonne": model_name = "feldynaught"
	for extension in ["glb", "fbx"]:
		var path := "res://assets/models/%s/model.%s" % [model_name, extension]
		if ResourceLoader.exists(path):
			return path
	return ""

func _physics_process(delta: float) -> void:
	if not game.active() or defeated: return
	clock += delta
	hurt_flash = maxf(0,hurt_flash-delta)
	cooldown -= delta
	path_timer -= delta
	var player = game.player
	var distance: float = global_position.distance_to(player.global_position)
	var direction: Vector2 = global_position.direction_to(player.global_position)
	velocity = knockback
	knockback = knockback.move_toward(Vector2.ZERO,550*delta)
	if phase == "windup":
		timer -= delta
		if timer <= 0:
			phase = "attack"
			timer = 0.35 if kind == "sharukurusu" else 0.48
			if kind in ["zakobon","guardian","bonne"]:
				var spread := 8 if boss else 1
				for i in range(spread):
					var dir := Vector2.RIGHT.rotated(TAU*i/spread+clock*0.3) if boss else attack_direction
					game.shoot(global_position+dir*22,dir*(130 if boss else 155),true,14 if boss else 8)
				if boss:
					attack_count += 1
					if attack_count % 3 == 0 and game.enemies.size() < 6:
						game.spawn_enemy("horokko" if kind=="guardian" else "servbot",home+Vector2(70,45),24)
				game.audio.effect("buster",0.65)
	elif phase == "attack":
		timer -= delta
		if kind=="sharukurusu" or boss and attack_count%2==0:
			velocity += attack_direction*(210 if boss else 225)
		if timer<=0:
			phase = "recover"
			timer = 0.75 if boss else 0.45
	elif phase == "recover":
		timer -= delta
		if timer<=0:
			phase = "idle"
			cooldown = 0.7 if boss else 1.0
	elif distance < (330 if boss else 230):
		if distance > (125 if kind=="zakobon" else 25):
			if path_timer <= 0:
				path_timer = 0.65
				path = game.world.path_to(global_position,player.global_position)
			var target: Vector2 = player.global_position
			if path.size()>1: target = path[1]
			velocity += global_position.direction_to(target)*(28 if boss else (48 if kind=="servbot" else 34))
		if cooldown<=0 and game.line_clear(global_position,player.global_position):
			if kind in ["zakobon","sharukurusu","guardian","bonne"]:
				phase = "windup"
				timer = 0.8 if boss else 0.6
				attack_direction = direction
			else:
				cooldown = 0.8
	move_and_slide()
	if distance < (34 if boss else 20): player.hurt(18 if boss else 9,global_position)
	if is_instance_valid(model_view):
		if velocity.length()>1: model_view.set_facing(velocity.normalized())
		model_view.set_moving(velocity.length()>1)
		model_view.set_visual_modulate(Color(2.3,1.4,1.1) if hurt_flash>0 else Color.WHITE)
	elif is_instance_valid(sprite):
		if not boss: sprite.frame = int(clock*7)%4
		sprite.modulate = Color(2.3,1.4,1.1) if hurt_flash>0 else Color.WHITE
	queue_redraw()

func hurt(amount: int, from: Vector2) -> void:
	if defeated: return
	health -= amount
	hurt_flash = 0.1
	knockback = from.direction_to(global_position)*(20 if boss else 100)
	game.audio.effect("hit",randf_range(0.85,1.1))
	game.floating(global_position+Vector2(0,-36),str(amount),Color("fff4bf"))
	if health<=0:
		defeated = true
		game.enemy_defeated(self)
		queue_free()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,28 if boss else 15,Color(0.04,0.08,0.12,0.32))
	draw_set_transform(Vector2.ZERO)
	if health<max_health and not boss:
		draw_rect(Rect2(-17,-43,34,4),Color("1b303a"))
		draw_rect(Rect2(-16,-42,32*float(health)/max_health,2),Color("e6ad75"))
	if phase=="windup":
		if kind=="sharukurusu" or boss:
			draw_line(Vector2.ZERO,attack_direction*150,Color(1,0.52,0.34,0.65),10)
			draw_line(Vector2.ZERO,attack_direction*150,Color("ffd18a"),1)
		else:
			draw_arc(Vector2(0,-16),22,0,TAU,24,Color("ffbe79"),2)
