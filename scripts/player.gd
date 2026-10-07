extends CharacterBody2D
const ModelSprite = preload("res://scripts/model_sprite.gd")

var game
var facing := Vector2.DOWN
var knockback := Vector2.ZERO
var dash_direction := Vector2.DOWN
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var shot_cooldown: float = 0.0
var grenade_cooldown: float = 0.0
var invincible: float = 0.0
var walk_time: float = 0.0
var step_time: float = 0.0
var sprite: Sprite2D
var model_view
var aim_target

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 8 | 16
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8
	shape.shape = circle
	add_child(shape)

	var model_path := "res://assets/models/megaman/model.glb"
	if ResourceLoader.exists(model_path):
		model_view = ModelSprite.new()
		model_view.model_path = model_path
		model_view.display_height = 67.0
		model_view.yaw_offset = PI
		add_child(model_view)
	else:
		sprite = Sprite2D.new()
		sprite.texture = preload("res://assets/characters/megaman.png")
		sprite.hframes = 4
		sprite.vframes = 3
		sprite.position = Vector2(0,-19)
		sprite.scale = Vector2(0.85,0.85)
		add_child(sprite)

func _physics_process(delta: float) -> void:
	if not game.active():
		velocity = Vector2.ZERO
		return
	grenade_cooldown = maxf(0,grenade_cooldown-delta)
	shot_cooldown = maxf(0,shot_cooldown-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	invincible = maxf(0,invincible-delta)
	dash_time = maxf(0,dash_time-delta)
	var move := Input.get_vector("move_left","move_right","move_up","move_down")
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0 and game.state.energy >= 8:
		dash_direction = move.normalized() if move.length() > 0.1 else facing
		dash_time = 0.17
		dash_cooldown = 0.75
		game.state.energy -= 8
		game.audio.effect("step",0.85)
	if move.length() > 0.1: facing = move.normalized()
	if Input.is_action_pressed("lock"):
		aim_target = game.nearest_enemy(global_position,270)
	else:
		aim_target = null
	if dash_time > 0:
		velocity = dash_direction * 310
		if not game.state.reduced_motion: game.particle(global_position+Vector2(0,-12),Color("93c7e4"),0.2,Vector2.ZERO)
	else:
		velocity = move * 115 + knockback
	knockback = knockback.move_toward(Vector2.ZERO,600*delta)
	move_and_slide()
	if move.length() > 0.1:
		walk_time += delta
		step_time -= delta
		if step_time <= 0:
			step_time = 0.3
			game.audio.effect("step",randf_range(0.95,1.07))
	else:
		walk_time = 0
		game.state.energy = minf(100,game.state.energy+2.8*delta)
	var pointer_in_world: bool = get_viewport().get_mouse_position().y>66 and get_viewport().get_mouse_position().y<302
	var firing_input: bool = Input.is_action_pressed("fire") and (not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or pointer_in_world)
	if firing_input and game.tool == 0:
		fire(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	elif Input.is_action_just_pressed("fire") and firing_input:
		game.use_tool()
	if Input.is_action_just_pressed("special"): special_fire()
	if Input.is_action_just_pressed("heal"): game.use_heal()

	var flash_alpha := 0.4 if invincible>0 and int(invincible*14)%2 == 0 else 1.0
	if is_instance_valid(model_view):
		model_view.set_facing(facing)
		model_view.set_moving(move.length()>0.1 or dash_time>0)
		model_view.set_visual_modulate(Color(1,1,1,flash_alpha))
	elif is_instance_valid(sprite):
		var firing: bool = shot_cooldown > 0.1 and game.tool == 0
		var col := int(walk_time*9)%4 if move.length() > 0.1 else 0
		var row := 1 if firing else (0 if move.length() > 0.1 else 2)
		sprite.frame = row*4+col
		if facing.x != 0: sprite.flip_h = facing.x < 0
		sprite.modulate.a = flash_alpha
	queue_redraw()

func fire(mouse: bool = false) -> void:
	if shot_cooldown > 0 or not game.active(): return
	shot_cooldown = maxf(0.13,0.3-game.state.rapid*0.055)
	var direction := facing
	if mouse: direction = global_position.direction_to(get_global_mouse_position())
	elif is_instance_valid(aim_target): direction = global_position.direction_to(aim_target.global_position)
	if direction.length() < 0.1: direction = Vector2.DOWN
	game.shoot(global_position+direction*12, direction*390, false, 10+game.state.power*6)
	game.audio.effect("buster",randf_range(0.94,1.03))
	game.burst(global_position+direction*17+Vector2(0,-8),Color("f8e8a4"),3,25)

func special_fire() -> void:
	if not game.active() or grenade_cooldown>0: return
	if not game.state.grenade_unlocked: game.toast("Find the weapon plans in the eastern ruins, then see Roll.");return
	if game.state.energy<18: game.toast("Grenade Arm needs 18 energy. Rest or use a bottle.");return
	var direction: Vector2=facing
	if is_instance_valid(aim_target): direction=position.direction_to(aim_target.position)
	game.state.energy-=18;grenade_cooldown=1.2
	var grenade=game.Grenade.new();grenade.game=game;grenade.position=position+direction*13;grenade.motion=direction*180
	game.world.entities.add_child(grenade);game.audio.effect("buster",.65)

func hurt(damage: int, from: Vector2) -> void:
	if invincible > 0 or dash_time > 0 or not game.active(): return
	invincible = 1.0
	game.state.health -= maxi(1,damage-game.state.armour*2)
	knockback = from.direction_to(global_position)*165
	game.combo = 0
	game.shake = 4.0
	game.audio.effect("hurt")
	game.floating(global_position+Vector2(0,-35),"-%d"%damage,Color("ffb1a3"))
	if game.state.health <= 0: game.call_deferred("knock_out")

func _draw() -> void:
	draw_ellipse_shadow()
	if is_instance_valid(aim_target):
		var p: Vector2 = aim_target.global_position-global_position+Vector2(0,-16)
		draw_arc(p,22,0,TAU,24,Color("ffe7a2"),1)
		draw_line(p+Vector2(-27,0),p+Vector2(-20,0),Color("ffe7a2"),2)
		draw_line(p+Vector2(20,0),p+Vector2(27,0),Color("ffe7a2"),2)

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.4))
	draw_circle(Vector2.ZERO,12,Color(0.08,0.15,0.19,0.24))
	draw_set_transform(Vector2.ZERO)
