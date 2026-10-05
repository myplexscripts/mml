extends Node2D
## World visuals and navigation share the same authored collision geometry.
const Catalog = preload("res://scripts/catalog.gd")
const Salvage = preload("res://scripts/salvage.gd")
var game
var area: String = "surface"
var floor_number: int = 1
var size := Vector2(1280,960)
var entities: Node2D
var blockers: Array[Rect2] = []
var floor_cells: Dictionary = {}
var textures: Dictionary = {}
var nav := AStarGrid2D.new()
var crop_nodes: Array = []
var water_clock: float = 0.0
var water_frame: int = 0
var rooms: Array[Rect2] = []
var interactables: Array = []

func _ready() -> void:
	for key in ["grass","grass_flower","grass_daisy","path","paving","water_0","water_1","water_2","ruin_floor","ruin_panel","wall","soil","soil_wet"]:
		textures[key]=load("res://assets/world/%s.png"%key)
	entities = Node2D.new()
	entities.y_sort_enabled = true
	add_child(entities)
	if area=="surface": build_surface()
	elif area=="bonne": build_bonne()
	elif area=="cabin": build_cabin()
	elif area in ["shop","museum","cafe","hall"]: build_interior()
	else: build_ruin()
	build_navigation()
	queue_redraw()

func _process(delta: float) -> void:
	if not game.active() and game.mode!="title": return
	water_clock+=delta
	if water_clock>0.5:
		water_clock=0
		water_frame=(water_frame+1)%3
		queue_redraw()

func prop(name: String, at: Vector2, scale_factor: float = 1.0) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.texture=load("res://assets/world/%s.png"%name)
	sprite.position=at
	sprite.offset=Vector2(0,-sprite.texture.get_height()*0.5+3)
	sprite.scale=Vector2(scale_factor,scale_factor)
	if name=="rug": add_child(sprite);move_child(sprite,0)
	else: entities.add_child(sprite)
	return sprite

func solid(rect: Rect2) -> void:
	blockers.append(rect)
	var body:=StaticBody2D.new()
	body.collision_layer=1
	body.collision_mask=0
	body.position=rect.get_center()
	var collision:=CollisionShape2D.new()
	var shape:=RectangleShape2D.new()
	shape.size=rect.size
	collision.shape=shape
	body.add_child(collision)
	add_child(body)

func building(name: String, at: Vector2, width: float) -> void:
	prop(name,at)
	solid(Rect2(at+Vector2(-width*0.5+8,-51),Vector2(width-16,52)))

func build_surface() -> void:
	size=Vector2(1280,960)
	building("junk_shop",Vector2(560,676),128)
	building("city_hall",Vector2(800,414),160)
	building("museum",Vector2(1032,664),144)
	building("cafe",Vector2(892,784),112)
	building("police",Vector2(384,386),112)
	building("house",Vector2(1040,386),96)
	building("house",Vector2(1140,510),96)
	prop("flutter",Vector2(300,740))
	solid(Rect2(205,636,187,105))
	prop("ruin_entrance",Vector2(640,249))
	solid(Rect2(602,190,76,52))
	prop("shipping",Vector2(340,845))
	solid(Rect2(321,824,38,24))
	prop("board",Vector2(745,555))
	solid(Rect2(728,530,34,26))
	prop("bench",Vector2(815,602))
	solid(Rect2(796,586,38,16))
	prop("bench",Vector2(905,484))
	solid(Rect2(886,467,38,17))
	for p in [Vector2(700,420),Vector2(930,533),Vector2(590,541),Vector2(830,826),Vector2(1100,735),Vector2(350,552)]: prop("lamp",p)
	for p in [Vector2(446,776),Vector2(470,802),Vector2(595,713)]: prop("crate",p)
	# Border trees and small groves leave the paths and NPC routes open.
	for x in range(64,1216,48):
		for y in [130,176]: tree(Vector2(x+(12 if y==176 else 0),y))
	for p in [Vector2(155,365),Vector2(210,393),Vector2(148,465),Vector2(250,550),Vector2(288,584),Vector2(162,659),Vector2(91,732),Vector2(423,477),Vector2(481,358),Vector2(878,263),Vector2(914,283),Vector2(953,248),Vector2(1149,329),Vector2(1153,632),Vector2(1096,731),Vector2(1160,779),Vector2(668,790),Vector2(651,873),Vector2(708,863)]: tree(p)
	for p in [Vector2(435,643),Vector2(967,716),Vector2(842,683),Vector2(752,657),Vector2(940,371),Vector2(284,490),Vector2(210,758)]:
		prop("bush",p,2)
	for i in range(35):
		var p:=Vector2(90+(i*139)%1100,232+(i*157)%650)
		if not is_path(p) and not blocked(p): prop("flowers",p,1.5)
	# Shoreline and pond are physical obstacles, just like buildings and trees.
	solid(Rect2(0,0,1280,105));solid(Rect2(0,0,52,960))
	solid(Rect2(1216,0,64,960));solid(Rect2(0,928,1280,32))
	solid(Rect2(928,832,160,64))
	interactables=[
		{"name":"Enter the Flutter","pos":Vector2(310,771),"action":"cabin"},
		{"name":"Junk Shop","pos":Vector2(560,704),"action":"shop"},
		{"name":"Museum","pos":Vector2(1032,693),"action":"museum"},
		{"name":"Cafe","pos":Vector2(892,813),"action":"cafe"},
		{"name":"City Hall","pos":Vector2(800,444),"action":"hall"},
		{"name":"Northern Ruins","pos":Vector2(640,269),"action":"ruins"},
		{"name":"Shipping Box","pos":Vector2(342,875),"action":"sell"},
		{"name":"Request Board","pos":Vector2(745,578),"action":"board"},
		{"name":"Fishing Pier","pos":Vector2(1140,910),"action":"fish"},
	]
	for row in range(3):
		for col in range(4):
			var at:=Vector2(136+col*32,816+row*32)
			var soil:=Sprite2D.new()
			soil.position=at
			soil.texture=textures.soil
			add_child(soil);move_child(soil,0)
			var crop_sprite:=Sprite2D.new()
			crop_sprite.position=at+Vector2(0,-10)
			entities.add_child(crop_sprite)
			crop_nodes.append({"soil":soil,"crop":crop_sprite,"pos":at})
	update_crops()

func tree(at: Vector2) -> void:
	prop("tree",at,2.0)
	solid(Rect2(at+Vector2(-6,-8),Vector2(12,12)))

func is_path(p: Vector2) -> bool:
	for rect in [Rect2(160,488,1010,64),Rect2(608,243,64,645),Rect2(208,752,792,48),Rect2(480,432,350,144),Rect2(508,550,96,160),Rect2(960,528,160,200),Rect2(844,550,96,284)]:
		if rect.has_point(p): return true
	return false

func build_ruin() -> void:
	size=Vector2(960,704)
	rooms=[Rect2(352,512,256,160),Rect2(64,352,224,256),Rect2(352,256,256,192),Rect2(672,320,224,288),Rect2(256,64,448,160),Rect2(256,448,128,64),Rect2(576,448,128,64),Rect2(448,192,64,352)]
	if floor_number==2:
		rooms.append(Rect2(64,128,192,160));rooms.append(Rect2(128,256,64,128))
	elif floor_number>=3:
		rooms[4]=Rect2(128,64,704,160)
	# Deep levels rotate three connected side-chamber plans. The main lift and
	# northern guardian vault stay readable while optional routes change.
	if floor_number>=4:
		var variant: int=(floor_number+game.state.day)%3
		if variant==0:
			rooms.append(Rect2(64,128,224,160));rooms.append(Rect2(160,256,64,128))
		elif variant==1:
			rooms.append(Rect2(672,128,224,160));rooms.append(Rect2(736,256,64,128))
		else:
			rooms.append(Rect2(64,224,832,64));rooms.append(Rect2(160,256,64,128));rooms.append(Rect2(736,256,64,128))
	for y in range(22):
		for x in range(30):
			var p:=Vector2(x*32+16,y*32+16)
			for rect in rooms:
				if rect.has_point(p):
					floor_cells[Vector2i(x,y)]=true
					break
	# Merge adjacent wall tiles into collision strips. No missing seams.
	for y in range(22):
		var start: int = -1
		for x in range(31):
			var is_wall:=x<30 and not floor_cells.has(Vector2i(x,y))
			if is_wall and start<0: start=x
			if not is_wall and start>=0:
				solid(Rect2(start*32,y*32,(x-start)*32,32))
				start=-1
	for p in [Vector2(105,390),Vector2(270,574),Vector2(380,303),Vector2(576,405),Vector2(704,369),Vector2(864,571),Vector2(283,95),Vector2(676,94)]:
		prop("ruin_pillar",p,0.55)
		solid(Rect2(p+Vector2(-10,-10),Vector2(20,20)))
	interactables=[{"name":"Return to Kattelox","pos":Vector2(480,634),"action":"exit"}]
	var part:= "servo" if floor_number==1 else ("circuit" if floor_number==2 else "refractor")
	var part_position:=Vector2(168,421) if floor_number==1 else Vector2(480,112)
	if game.state.repair<floor_number and int(game.state.items.get(part,0))==0 or floor_number>=4:
		var treasure:=Sprite2D.new()
		treasure.texture=load("res://assets/items/%s.png"%part)
		treasure.position=part_position+Vector2(0,-15)
		entities.add_child(treasure)
		interactables.append({"name":"%s Cache"%part.capitalize(),"pos":part_position,"action":"treasure","part":part,"sprite":treasure})
	for p in [Vector2(183,522),Vector2(397,375),Vector2(533,331),Vector2(793,420),Vector2(821,550)]:
		game.spawn_enemy("zakobon" if p.x in [397.0,793.0] else "horokko",p,25+floor_number*8)
	game.spawn_enemy("zakobon",Vector2(736,514),22+floor_number*8)
	game.spawn_enemy("sharukurusu",Vector2(597,144),28+floor_number*12)
	if floor_number==2: game.spawn_enemy("zakobon",Vector2(166,203),44)
	elif floor_number>=3: game.spawn_enemy("sharukurusu",Vector2(728,151),48)
	if floor_number>=2:
		game.spawn_enemy("guardian",Vector2(450,157),120 if floor_number==2 else 230+(floor_number-3)*40,true)
	else:
		game.spawn_enemy("horokko",Vector2(211,399),40)
	if not game.state.blueprint:
		var plans:=prop("weapon_plans",Vector2(835,475))
		interactables.append({"name":"Weapon Plans","pos":Vector2(835,483),"action":"blueprint","sprite":plans})
	var crate_positions: Array=[Vector2(137,565),Vector2(559,392),Vector2(849,552),Vector2(314,147)]
	if floor_number>=4:
		crate_positions.append(Vector2(186,245) if (floor_number+game.state.day)%3!=1 else Vector2(810,245))
	for i in range(crate_positions.size()):
		var id: String="salvage_%d_%d"%[floor_number,i]
		if id in game.state.claimed: continue
		var crate=Salvage.new();crate.game=game;crate.position=crate_positions[i];crate.claim_id=id
		entities.add_child(crate)

func build_interior() -> void:
	size=Vector2(640,480)
	solid(Rect2(0,0,640,156));solid(Rect2(0,420,640,60))
	solid(Rect2(0,0,72,480));solid(Rect2(568,0,72,480))
	var exits: Dictionary={"shop":Vector2(560,724),"museum":Vector2(1032,713),"cafe":Vector2(892,833),"hall":Vector2(800,464)}
	interactables=[{"name":"Return to town","pos":Vector2(320,401),"action":"town_exit","return_pos":exits[area]}]
	prop("rug",Vector2(320,385))
	var counter:=Vector2(320,252)
	prop("counter",counter);solid(Rect2(240,225,160,27))
	interactables.append({"name":{"shop":"Browse stock","museum":"Relic donations","cafe":"Order lunch","hall":"Speak with Amelia"}[area],"pos":Vector2(320,280),"action":area+"_counter"})
	if area=="shop":
		for at in [Vector2(134,225),Vector2(506,225)]:
			prop("shelves",at);solid(Rect2(at+Vector2(-42,-23),Vector2(84,23)))
		for at in [Vector2(127,362),Vector2(501,357)]:
			prop("salvage",at);solid(Rect2(at+Vector2(-14,-20),Vector2(28,20)))
	elif area=="cafe":
		for at in [Vector2(152,320),Vector2(487,320)]:
			prop("cafe_table",at);solid(Rect2(at+Vector2(-27,-23),Vector2(54,23)))
		for at in [Vector2(146,224),Vector2(487,224)]: prop("plant_pot",at)
	elif area=="museum":
		for i in range(4):
			var at:=Vector2(136+(i%2)*368,260+int(i/2)*108)
			var display:=prop("display_case",at);solid(Rect2(at+Vector2(-26,-19),Vector2(52,19)))
			if game.state.museum_donated>i:
				var relic:=Sprite2D.new();relic.texture=preload("res://assets/world/relic_display.png");relic.position=Vector2(0,-38);display.add_child(relic)
			interactables.append({"name":"Ancient relic exhibit","pos":at+Vector2(0,27),"action":"exhibit"})
	else:
		for at in [Vector2(137,235),Vector2(503,235)]: prop("plant_pot",at)
		prop("board",Vector2(495,348));solid(Rect2(478,323,34,25))
		interactables.append({"name":"Town requests","pos":Vector2(495,375),"action":"board"})
		prop("bench",Vector2(145,350));solid(Rect2(126,334,38,16))
	# Interior people use stationary destinations so they stay behind the desk.
	if area=="shop": game.spawn_npc("Junk Shop Man","junkman",Vector2(320,218))
	elif area=="museum": game.spawn_npc("Barrell","barrell",Vector2(430,290))
	elif area=="hall": game.spawn_npc("Amelia","amelia",Vector2(320,218))
	for y in range(5,13):
		for x in range(3,17): floor_cells[Vector2i(x,y)]=true

func build_bonne() -> void:
	size=Vector2(640,480)
	solid(Rect2(0,0,640,32));solid(Rect2(0,448,640,32));solid(Rect2(0,0,32,480));solid(Rect2(608,0,32,480))
	for p in [Vector2(80,100),Vector2(560,100),Vector2(80,400),Vector2(560,400)]:
		prop("crate",p)
		solid(Rect2(p+Vector2(-18,-18),Vector2(36,20)))
	game.spawn_enemy("bonne",Vector2(320,230),260,true)
	game.spawn_enemy("servbot",Vector2(190,220),25)
	game.spawn_enemy("servbot",Vector2(450,220),25)

func build_cabin() -> void:
	size=Vector2(640,480)
	solid(Rect2(0,0,640,145));solid(Rect2(0,420,640,60))
	solid(Rect2(0,0,80,480));solid(Rect2(560,0,80,480))
	prop("bed",Vector2(145,241))
	solid(Rect2(125,191,40,51))
	prop("workbench",Vector2(465,246))
	solid(Rect2(429,211,72,37))
	prop("bench",Vector2(470,350))
	solid(Rect2(451,332,38,18))
	prop("rug",Vector2(318,336))
	for p in [Vector2(95,379),Vector2(532,223)]: prop("crate",p)
	interactables=[
		{"name":"Bunk / Sleep and Save","pos":Vector2(173,250),"action":"home"},
		{"name":"Workbench","pos":Vector2(465,272),"action":"workshop"},
		{"name":"Leave the Flutter","pos":Vector2(320,405),"action":"cabin_exit"},
		{"name":"Galley / Cook a Fish","pos":Vector2(470,378),"action":"galley"}]
	for y in range(5,13):
		for x in range(3,17): floor_cells[Vector2i(x,y)]=true

func update_crops() -> void:
	for i in range(crop_nodes.size()):
		var data: Dictionary=game.state.crops[i]
		crop_nodes[i].soil.visible=bool(data.tilled)
		crop_nodes[i].soil.texture=textures.soil_wet if bool(data.watered) else textures.soil
		crop_nodes[i].crop.visible=int(data.stage)>=0
		if int(data.stage)>=0: crop_nodes[i].crop.texture=load("res://assets/world/crop_%s_%d.png"%[str(data.get("kind","turnip")),Catalog.visual_stage(data)])

func blocked(at: Vector2) -> bool:
	for crate in get_tree().get_nodes_in_group("salvage"):
		if not crate.broken and Rect2(crate.position+Vector2(-14,-17),Vector2(28,20)).grow(8).has_point(at): return true
	for rect in blockers:
		if rect.grow(8).has_point(at): return true
	return false

func build_navigation() -> void:
	nav.region=Rect2i(0,0,int(size.x/32),int(size.y/32))
	nav.cell_size=Vector2(32,32)
	nav.offset=Vector2(16,16)
	nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	nav.update()
	for y in range(nav.region.size.y):
		for x in range(nav.region.size.x):
			nav.set_point_solid(Vector2i(x,y),blocked(Vector2(x*32+16,y*32+16)))

func path_to(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a:=Vector2i(clampi(int(from.x/32),0,nav.region.size.x-1),clampi(int(from.y/32),0,nav.region.size.y-1))
	var b:=Vector2i(clampi(int(to.x/32),0,nav.region.size.x-1),clampi(int(to.y/32),0,nav.region.size.y-1))
	if nav.is_point_solid(b):
		for shift in [Vector2i(0,1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1)]:
			var c: Vector2i=b+shift
			if nav.is_in_boundsv(c) and not nav.is_point_solid(c):
				b=c
				break
	if nav.is_point_solid(a) or nav.is_point_solid(b): return PackedVector2Array()
	return nav.get_point_path(a,b)

func _draw() -> void:
	if textures.is_empty(): return
	if area=="surface":
		for y in range(30):
			for x in range(40):
				var p:=Vector2(x*32,y*32)
				var key: String="grass"
				if y<3 or y>=29 or x>=38 or Rect2(928,832,160,64).has_point(p+Vector2(16,16)): key="water_%d"%water_frame
				elif is_path(p+Vector2(16,16)): key="paving" if x>14 and y<19 else "path"
				elif (x*7+y*13)%39==0: key="grass_daisy"
				elif (x*13+y*3)%43==0: key="grass_flower"
				draw_texture_rect(textures[key],Rect2(p,Vector2(32,32)),false)
		# Timber fishing platform, fence posts and the garden's stone edging.
		draw_rect(Rect2(1108,856,67,70),Color("695f4d"))
		for y in range(858,926,8):
			draw_rect(Rect2(1110,y,63,6),Color("bca775"));draw_line(Vector2(1112,y),Vector2(1171,y),Color("d9c795"),1)
		for x in [1110,1170]:
			draw_rect(Rect2(x,850,5,74),Color("655543"))
		draw_rect(Rect2(114,794,138,106),Color("bbc08c"),false,3)
		for x in range(117,253,16): draw_rect(Rect2(x,792,9,4),Color("e3d3a1"))
	elif area=="bonne":
		for y in range(15):
			for x in range(20):draw_texture_rect(textures.paving,Rect2(x*32,y*32,32,32),false)
		for x in range(0,640,32):draw_texture_rect(textures.wall,Rect2(x,0,32,48),false)
		for y in range(0,480,32):
			draw_rect(Rect2(4,y,24,24),Color("607c78"));draw_rect(Rect2(612,y,24,24),Color("607c78"))
	elif area in ["shop","museum","cafe","hall"]:
		draw_rect(Rect2(Vector2.ZERO,size),Color("233e4a"))
		for y in range(5,13):
			for x in range(3,17):
				var p:=Vector2(x*32,y*32)
				var tint:=Color("bdac81") if area=="cafe" else Color("829a90")
				if area=="museum": tint=Color("b5bbac")
				draw_rect(Rect2(p,Vector2(32,32)),tint)
				draw_rect(Rect2(p+Vector2(1,1),Vector2(30,30)),Color("607a78"),false,1)
		for x in range(80,560,32):
			draw_rect(Rect2(x,104,32,57),Color("ded5af"))
			draw_rect(Rect2(x+2,108,28,48),Color("b6b694"),false,1)
		for x in [177,389]:
			draw_rect(Rect2(x,110,74,42),Color("4c6d79"))
			draw_rect(Rect2(x+4,114,66,34),Color("8fc6c3"))
			draw_line(Vector2(x+37,113),Vector2(x+37,149),Color("d7d6b2"),3)
			draw_line(Vector2(x+4,130),Vector2(x+70,130),Color("d7d6b2"),3)
		draw_rect(Rect2(294,395,52,21),Color("4c7179"),false,2)
	elif area=="cabin":
		draw_rect(Rect2(Vector2.ZERO,size),Color("162f42"))
		for y in range(5,13):
			for x in range(3,17):
				var p:=Vector2(x*32,y*32)
				draw_rect(Rect2(p,Vector2(32,32)),Color("50717b"))
				draw_rect(Rect2(p+Vector2(2,2),Vector2(28,28)),Color("64838a"),false,1)
		for x in range(96,544,32):
			draw_rect(Rect2(x,100,32,60),Color("b8bea5"))
			draw_rect(Rect2(x+2,103,28,52),Color("d7d4b5"),false,2)
		for x in [184,278,372]:
			draw_rect(Rect2(x,110,69,34),Color("294957"))
			draw_rect(Rect2(x+3,113,63,28),Color("7bb6bd"))
			draw_line(Vector2(x+5,114),Vector2(x+59,114),Color("c5dfcd"),2)
			draw_line(Vector2(x+34,113),Vector2(x+34,140),Color("446b75"),2)
		draw_rect(Rect2(294,388,52,30),Color("9da990"),false,2)
		for y in [395,402,409]: draw_line(Vector2(299,y),Vector2(341,y),Color("d7d2af"))
	else:
		draw_rect(Rect2(Vector2.ZERO,size),Color("132835"))
		for cell in floor_cells:
			var at:=Vector2(cell)*32
			draw_texture_rect(textures.ruin_floor,Rect2(at,Vector2(32,32)),false)
			if not floor_cells.has(cell+Vector2i.UP):
				draw_texture_rect(textures.wall,Rect2(at-Vector2(0,40),Vector2(32,48)),false)
				if int(cell.x)%4==0: draw_texture_rect(textures.ruin_panel,Rect2(at-Vector2(0,40),Vector2(32,40)),false)
			if not floor_cells.has(cell+Vector2i.LEFT):draw_rect(Rect2(at,Vector2(3,32)),Color("69837d"))
			if not floor_cells.has(cell+Vector2i.RIGHT):draw_rect(Rect2(at+Vector2(29,0),Vector2(3,32)),Color("2c454b"))
			if not floor_cells.has(cell+Vector2i.DOWN):draw_rect(Rect2(at+Vector2(0,29),Vector2(32,3)),Color("748f87"))
		for p in [Vector2(480,306),Vector2(175,463),Vector2(790,463)]:
			draw_arc(p,25,0,TAU,24,Color("577d7c"),2)
			draw_arc(p,19,0,TAU,24,Color("315762"),1)
			draw_circle(p,4,Color("82c9bd"))
		draw_rect(Rect2(450,621,60,26),Color("578996"),false,2)
		for y in [627,634,641]:draw_line(Vector2(456,y),Vector2(504,y),Color("9bb9b0"),1)
