extends "res://scripts/legends/world.gd"

const CampaignActor = preload("res://scripts/legends/campaign_actor.gd")
const C_ART := "res://assets/legends/"
const CUSTOM_AREAS := [
	"ocean_tower", "cardon", "apple_market", "portal1", "downtown", "city_hall",
	"yass_plains", "cardon_approach", "cardon_subgate", "uptown", "lake_jyun",
	"lake_subgate", "flutter_restart", "clozer_subgate", "flutter_deck", "main_gate",
	"old_city", "subcity", "central_gate", "kattelox_departure"
]


func _ready() -> void:
	if not area in CUSTOM_AREAS:
		super._ready()
		return
	origin = Vector2(-21.0, -15.4)
	cell_size = 1.4
	setup_light()
	_apply_climate(area)
	match area:
		"ocean_tower": build_ocean_tower()
		"cardon": build_cardon_forest()
		"apple_market": build_apple_market()
		"portal1": build_portal_one()
		"downtown": build_downtown()
		"city_hall": build_city_hall()
		"yass_plains": build_yass_plains()
		"cardon_approach": build_cardon_approach()
		"cardon_subgate": build_cardon_subgate()
		"uptown": build_uptown()
		"lake_jyun": build_lake_jyun()
		"lake_subgate": build_lake_subgate()
		"flutter_restart": build_flutter_restart()
		"clozer_subgate": build_clozer_subgate()
		_: build_campaign_blockout(area)
	finish_batches()
	build_navigation()


func spawn_special(kind: String, at: Vector3, hp: int, boss: bool = true) -> Node:
	var actor = CampaignActor.new()
	actor.game = game
	actor.role = "enemy"
	actor.kind = kind
	actor.position = at + Vector3.UP * .1
	actor.health = hp
	actor.boss = boss
	add_child(actor)
	game.enemies.append(actor)
	return actor


func _apply_climate(id: String) -> void:
	var profile := {
		"background": Color("789baa"), "ambient": Color("c7d7cd"), "ambient_energy": 0.38,
		"sun": Color("fff0c6"), "sun_energy": 0.8,
	}
	if id in ["ocean_tower", "portal1", "cardon_subgate", "lake_subgate", "clozer_subgate", "main_gate", "subcity", "central_gate"]:
		profile = {"background":Color("172b35"), "ambient":Color("8fb3b9"), "ambient_energy":0.28, "sun":Color("9dcbd2"), "sun_energy":0.44}
	elif id in ["cardon", "yass_plains", "cardon_approach"]:
		profile = {"background":Color("7ea5ad"), "ambient":Color("cadbc6"), "ambient_energy":0.42, "sun":Color("ffe4ae"), "sun_energy":0.88}
	elif id == "lake_jyun":
		profile = {"background":Color("729db2"), "ambient":Color("bfd8dc"), "ambient_energy":0.4, "sun":Color("f5e6c5"), "sun_energy":0.78}
	elif id == "flutter_deck":
		profile = {"background":Color("789aaf"), "ambient":Color("c5d5dc"), "ambient_energy":0.34, "sun":Color("f3e5c6"), "sun_energy":0.72}
	elif id in ["old_city", "downtown", "city_hall", "uptown", "apple_market", "kattelox_departure"]:
		profile = {"background":Color("88a7ae"), "ambient":Color("d7d7c4"), "ambient_energy":0.42, "sun":Color("ffe0af"), "sun_energy":0.85}
	ambient.environment.background_color = profile.background
	ambient.environment.ambient_light_color = profile.ambient
	ambient.environment.ambient_light_energy = profile.ambient_energy
	for child in get_children():
		if child is DirectionalLight3D:
			child.light_color = profile.sun
			child.light_energy = profile.sun_energy


func _perimeter(size: Vector2, colour: Color, texture: String = "") -> void:
	var hx := size.x * .5
	var hz := size.y * .5
	box(Vector3(0,1,-hz),Vector3(size.x,2,.55),colour,true,texture)
	box(Vector3(0,1,hz),Vector3(size.x,2,.55),colour,true,texture)
	box(Vector3(-hx,1,0),Vector3(.55,2,size.y),colour,true,texture)
	box(Vector3(hx,1,0),Vector3(.55,2,size.y),colour,true,texture)


func _floor_grid(size: Vector2, colour: Color, texture: String) -> void:
	box(Vector3(0,-.22,0),Vector3(size.x,.44,size.y),colour,true)
	for x in range(int(-size.x*.5+1),int(size.x*.5),2):
		for z in range(int(-size.y*.5+1),int(size.y*.5),2):
			batch_box(Vector3(x,.012,z),Vector3(1.96,.035,1.96),colour,texture)


func build_ocean_tower() -> void:
	bounds = Rect2(-19,-14,38,28)
	_floor_grid(Vector2(38,28),Color("94a79d"),C_ART+"cabin_metal.png")
	_perimeter(Vector2(38,28),Color("728d86"),C_ART+"wall.png")
	for entry in [
		[Vector3(-8,1,5),Vector3(.65,2,15)], [Vector3(8,1,3),Vector3(.65,2,18)],
		[Vector3(0,1,1),Vector3(8,2,.65)], [Vector3(-13,1,-4),Vector3(10,2,.65)],
		[Vector3(13,1,-7),Vector3(10,2,.65)],
	]: box(entry[0],entry[1],Color("6f8982"),true,C_ART+"wall.png")
	for at in [Vector3(-4,.04,8),Vector3(4,.04,3),Vector3(-13,.04,-8),Vector3(13,.04,-10)]:
		cylinder(at,.72,.08,Color("4b8789"))
		var lamp := OmniLight3D.new();lamp.position=at+Vector3.UP*1.5;lamp.light_color=Color("76d2cf");lamp.light_energy=.5;lamp.omni_range=5;add_child(lamp)
	for i in range(5):box(Vector3(3.2,.08+i*.11,-4.5-i*.62),Vector3(4.2,.16+i*.02,.65),Color("a9b7a7"),true,C_ART+"metal.png")
	model("container",Vector3(-15,0,-9.5),.95);interact("Ancient side cache",Vector3(-15,0,-9.5),"ocean_cache")
	game.spawn_enemy("horokko",Vector3(-12.5,0,-7.7),32);game.spawn_enemy("horokko",Vector3(-15.5,0,-6.2),32)
	game.spawn_enemy("sharukurusu",Vector3(4.3,0,5),44);game.spawn_enemy("horokko",Vector3(11.5,0,-2.5),38)
	if not game.state.story_flag(&"hanmuru_defeated"):spawn_special("hanmuru",Vector3(0,0,-10.7),185)
	interact("Rooftop exit",Vector3(0,0,-12.3),"ocean_exit");sign_at("OCEAN TOWER / EXIT",Vector3(0,2.8,-12.7))


func build_cardon_forest() -> void:
	bounds=Rect2(-20,-14,40,28);_floor_grid(Vector2(40,28),Color("789768"),C_ART+"grass.png");_perimeter(Vector2(40,28),Color("8e775c"),C_ART+"stone.png")
	for at in [Vector3(-16,0,-9),Vector3(-13,0,9),Vector3(-7,0,-11),Vector3(8,0,10),Vector3(15,0,-7),Vector3(17,0,7)]:tree(at)
	for at in [Vector3(-11,0,-7),Vector3(13,0,8),Vector3(10,0,-9)]:
		var rock:=box(at+Vector3.UP*.35,Vector3(1.5,.7,1.2),Color("9b8c70"),true,C_ART+"rock.png");rock.rotation.y=at.x*.07
	var ship:=model("flutter",Vector3(-11,-3.7,2.5),10.7,-PI/2);ship.rotation.z=-.08;ship.name="CrashedFlutter"
	game.spawn_npc("Roll","roll",Vector3(-5.8,0,3.2));game.spawn_npc("Barrell","barrell",Vector3(-7.5,0,5.2));game.spawn_npc("Data","data",Vector3(-4.8,0,5.4))
	box(Vector3(7,.02,0),Vector3(23,.04,4.4),Color("ad9c78"),false,C_ART+"sand.png")
	for z in [-2.7,2.7]:
		for x in range(-1,19,3):model("lamp",Vector3(x,0,z),2.2,0,false)
	interact("Road to Apple Market",Vector3(18,0,0),"to_market");sign_at("APPLE MARKET",Vector3(17,2.4,0))


func build_apple_market() -> void:
	bounds=Rect2(-18,-10,36,20);_floor_grid(Vector2(36,20),Color("b5b0a2"),C_ART+"cabin_metal.png");_perimeter(Vector2(36,20),Color("9f987e"),C_ART+"cabin_panel.png")
	for x in [-12.0,-6.0,0.0,6.0,12.0]:
		box(Vector3(x,1,-7.5),Vector3(4.8,2,2.6),Color("8f7359"),true,C_ART+"cabin_panel.png");box(Vector3(x,1,7.5),Vector3(4.8,2,2.6),Color("7c8790"),true,C_ART+"cabin_panel.png")
	for x in range(-14,15,4):model("lamp",Vector3(x,0,-4),2,0,false);model("lamp",Vector3(x,0,4),2,PI,false)
	interact("Forest exit",Vector3(-16.5,0,0),"to_cardon");interact("Portal 1",Vector3(16.2,0,-3.5),"to_portal1");interact("Junk Store",Vector3(16.2,0,3.5),"junk_store")
	sign_at("PORTAL 1",Vector3(15.2,2.5,-3.5));sign_at("JUNK STORE",Vector3(15.2,2.5,3.5))
	if game.state.story_flag(&"junk_store_owner_rescued"):game.spawn_npc("Junk Store Owner","barrell",Vector3(12.5,0,3.5))


func build_portal_one() -> void:
	bounds=Rect2(-18,-13,36,26);_floor_grid(Vector2(36,26),Color("9daa94"),C_ART+"hex_floor.png");_perimeter(Vector2(36,26),Color("74887a"),C_ART+"wall.png")
	for entry in [[Vector3(-8,1,1),Vector3(.65,2,16)],[Vector3(8,1,-2),Vector3(.65,2,15)],[Vector3(0,1,4),Vector3(8,2,.65)],[Vector3(-13,1,-5),Vector3(10,2,.65)]]:box(entry[0],entry[1],Color("7d9282"),true,C_ART+"wall.png")
	for at in [Vector3(-12,0,-8),Vector3(4,0,6),Vector3(12,0,-5)]:game.spawn_enemy("horokko",at,38)
	game.spawn_enemy("sharukurusu",Vector3(8,0,-9),52)
	if not game.state.story_flag(&"junk_store_owner_rescued"):game.spawn_npc("Junk Store Owner","barrell",Vector3(13.5,0,-9.8))
	interact("Portal 1 entrance",Vector3(-15.8,0,9.8),"to_market");sign_at("PORTAL 1 / DEEP CHAMBER",Vector3(11,2.8,-11.5))


func build_downtown() -> void:
	bounds=Rect2(-20,-14,40,28);_floor_grid(Vector2(40,28),Color("a9aaa1"),C_ART+"cabin_metal.png");_perimeter(Vector2(40,28),Color("8a9187"),C_ART+"stone.png")
	for x in [-13.0,0.0,13.0]:box(Vector3(x,1.2,-9),Vector3(8.5,2.4,5.2),Color("aa8b6f"),true,C_ART+"cabin_panel.png");box(Vector3(x,1.2,9),Vector3(8.5,2.4,5.2),Color("8096a0"),true,C_ART+"cabin_panel.png")
	for x in range(-16,17,4):model("lamp",Vector3(x,0,-5.5),2.3,0,false);model("lamp",Vector3(x,0,5.5),2.3,PI,false)
	if game.state.campaign_step<=5 and not game.state.story_flag(&"feldynaught_defeated"):game.spawn_npc("Tron","tron",Vector3(3,0,-1))
	interact("City Hall district",Vector3(18,0,0),"city_hall_gate");interact("Cardon Forest road",Vector3(-18,0,0),"to_cardon");sign_at("DOWNTOWN KATTELOX",Vector3(0,3,-11.2))


func build_city_hall() -> void:
	bounds=Rect2(-20,-14,40,28);_floor_grid(Vector2(40,28),Color("b0afa2"),C_ART+"cabin_metal.png");_perimeter(Vector2(40,28),Color("8d9289"),C_ART+"stone.png")
	for entry in [[Vector3(0,1.6,-9.5),Vector3(12,3.2,5),Color("b9af94")],[Vector3(-13,1.3,7.5),Vector3(8,2.6,6),Color("8297a0")],[Vector3(13,1.3,7.5),Vector3(8,2.6,6),Color("9b816d")]]:box(entry[0],entry[1],entry[2],true,C_ART+"cabin_panel.png")
	for at in [Vector3(-9,0,-1),Vector3(9,0,-1),Vector3(-6,0,4),Vector3(6,0,4)]:game.spawn_enemy("servbot",at,34)
	if not game.state.story_flag(&"bon_bonne_defeated"):spawn_special("bonbonne",Vector3(0,0,2),235)
	interact("Downtown road",Vector3(0,0,12.5),"downtown_gate");sign_at("CITY HALL",Vector3(0,3,-11.5))


func build_yass_plains() -> void:
	bounds=Rect2(-21,-15,42,30);_floor_grid(Vector2(42,30),Color("789568"),C_ART+"grass.png");_perimeter(Vector2(42,30),Color("92785b"),C_ART+"stone.png")
	# Raised firing ledges around the excavation preserve the original option to fight from high ground.
	for x in [-15.0,15.0]:
		box(Vector3(x,.45,-3),Vector3(7,.9,15),Color("957858"),true,C_ART+"stone.png")
		for i in range(4):box(Vector3(x-signf(x)*(3.6+i*.65),.1+i*.11,5.5-i*.5),Vector3(.8,.2+i*.02,2.2),Color("aa906b"),true,C_ART+"stone.png")
	# Deep excavation scar and pirate gun positions.
	box(Vector3(0,-.05,-5),Vector3(18,.1,13),Color("80694f"),false,C_ART+"sand.png")
	for at in [Vector3(-11,0,4),Vector3(11,0,4),Vector3(-15,1,-8),Vector3(15,1,-8)]:game.spawn_enemy("horokko",at,48)
	if not game.state.story_flag(&"marlwolf_defeated"):spawn_special("marlwolf",Vector3(0,0,-8),330)
	interact("Northern route",Vector3(0,0,-13),"yass_exit");sign_at("MARLWOLF EXCAVATION",Vector3(0,3,-13.2))


func build_cardon_approach() -> void:
	bounds=Rect2(-21,-15,42,30);_floor_grid(Vector2(42,30),Color("769366"),C_ART+"grass.png");_perimeter(Vector2(42,30),Color("8c7358"),C_ART+"stone.png")
	for at in [Vector3(-17,0,-10),Vector3(-17,0,10),Vector3(16,0,-9),Vector3(16,0,9),Vector3(-8,0,-12),Vector3(8,0,12)]:tree(at)
	box(Vector3(0,.02,1),Vector3(35,.04,5),Color("ad9973"),false,C_ART+"sand.png")
	# Roll's support car, represented with authored vehicle-scale geometry until the extracted mesh is imported.
	var car:=Node3D.new();car.name="SupportCar";car.position=Vector3(-12,0,5);add_child(car)
	var body:=box(Vector3(-12,.55,5),Vector3(3.8,1.1,2.1),Color("d7c9a6"),true,C_ART+"metal.png");body.name="SupportCarBody"
	for wheel in [Vector3(-13.2,.28,4),Vector3(-10.8,.28,4),Vector3(-13.2,.28,6),Vector3(-10.8,.28,6)]:cylinder(wheel,.42,.35,Color("34383a"))
	game.spawn_npc("Roll","roll",Vector3(-9,0,5))
	for at in [Vector3(-4,0,-3),Vector3(2,0,5),Vector3(7,0,-4),Vector3(12,0,4),Vector3(15,0,-6)]:game.spawn_enemy("servbot" if int(at.x)%2==0 else "horokko",at,45)
	interact("Sub-Gate approach",Vector3(18,0,0),"cardon_assault_finish");sign_at("CARDON SUB-GATE",Vector3(17,2.6,0))


func build_cardon_subgate() -> void:
	bounds=Rect2(-20,-15,40,30);_floor_grid(Vector2(40,30),Color("8fa18d"),C_ART+"hex_floor.png");_perimeter(Vector2(40,30),Color("6e877b"),C_ART+"wall.png")
	# Central room, side routes, conveyor lanes and an elevated walkway.
	for entry in [[Vector3(-9,1,1),Vector3(.65,2,19)],[Vector3(9,1,-1),Vector3(.65,2,19)],[Vector3(0,1,5),Vector3(10,2,.65)],[Vector3(0,1,-6),Vector3(10,2,.65)]]:box(entry[0],entry[1],Color("6e877b"),true,C_ART+"wall.png")
	for x in range(-6,7,2):batch_box(Vector3(x,.04,0),Vector3(1.8,.06,3.2),Color("758b83"),C_ART+"circuit.png")
	box(Vector3(0,.85,-9),Vector3(13,.35,2.4),Color("879b91"),true,C_ART+"metal.png")
	for i in range(5):box(Vector3(-7+i*.7,.12+i*.14,-8),Vector3(.75,.24+i*.02,2),Color("8fa59a"),true,C_ART+"metal.png")
	var keys := [["cardon_key_1",Vector3(-15,0,-8)],["cardon_key_2",Vector3(14,0,7)],["cardon_key_3",Vector3(0,.95,-9)]]
	for entry in keys:
		if not game.state.story_flag(StringName(entry[0])):
			crystal(entry[1]+Vector3.UP*.55,Color("82d5d2"),.28,self);interact("Starter Key",entry[1],entry[0])
	for at in [Vector3(-13,0,-4),Vector3(12,0,2),Vector3(2,0,8)]:game.spawn_enemy("sharukurusu",at,58)
	var count:=game.state.story_counter(&"cardon_starter_keys")
	if count<3:box(Vector3(0,1,-12),Vector3(8,2,.45),Color("54a6a3"),true,C_ART+"circuit.png")
	else:
		crystal(Vector3(0,.8,-12),Color("ffdc51"),.7,self);interact("Yellow Refractor",Vector3(0,0,-12),"yellow_refractor")
	if not game.state.story_flag(&"spring_set_found"):interact("Spring Set chest",Vector3(-14,0,10),"spring_set")
	if not game.state.story_flag(&"grenade_kit_found"):interact("Grenade Kit chest",Vector3(14,0,-10),"grenade_kit")
	sign_at("CARDON SUB-GATE / STARTER LOCK",Vector3(0,3,-13.2))


func build_uptown() -> void:
	bounds=Rect2(-21,-15,42,30);_floor_grid(Vector2(42,30),Color("aaa99f"),C_ART+"cabin_metal.png");_perimeter(Vector2(42,30),Color("8b9088"),C_ART+"stone.png")
	# Terraced civic district and waterfront.
	for y in [0.0,.35,.7]:box(Vector3(-5+y*10,y-0.15,-2-y*6),Vector3(11,.3,8),Color("b1ab99"),true,C_ART+"cabin_metal.png")
	model("bakery",Vector3(-14,0,-9),4.2,0);model("hangar",Vector3(11,0,-9),4.8,0);model("shed",Vector3(-14,0,8),2.1,PI/2)
	box(Vector3(9,-.5,9),Vector3(23,.2,8),Color("579ca9"),false)
	model("boat",Vector3(10,0,7),3.4,PI/2,false)
	game.spawn_npc("Roll","roll",Vector3(4,0,5.5))
	interact("Wily's boat",Vector3(8,0,5.5),"repair_wily_boat");sign_at("WILY'S BOAT HOUSE",Vector3(8,2.5,4))


func build_lake_jyun() -> void:
	bounds=Rect2(-18,-15,36,30)
	box(Vector3(0,-.6,0),Vector3(36,.2,30),Color("579eac"),false)
	# Small moving-boat combat deck. Water surrounds every side, so missiles remain readable.
	box(Vector3(0,-.08,2),Vector3(10,.25,17),Color("9f9278"),true,C_ART+"metal.png");model("boat",Vector3(0,-.7,2),5.2,0,false)
	for x in [-4.2,4.2]:box(Vector3(x,.35,2),Vector3(.35,.7,16),Color("766e61"),true,C_ART+"metal.png")
	if not game.state.story_flag(&"balcon_defeated"):spawn_special("balcon",Vector3(0,0,-10),300)
	sign_at("LAKE JYUN / BOAT BATTLE",Vector3(0,3,-13))


func build_lake_subgate() -> void:
	bounds=Rect2(-20,-15,40,30);_floor_grid(Vector2(40,30),Color("8e9f91"),C_ART+"hex_floor.png");_perimeter(Vector2(40,30),Color("6b857d"),C_ART+"wall.png")
	for entry in [[Vector3(-10,1,0),Vector3(.65,2,20)],[Vector3(10,1,0),Vector3(.65,2,20)],[Vector3(0,1,-4),Vector3(11,2,.65)]]:box(entry[0],entry[1],Color("6b857d"),true,C_ART+"wall.png")
	for at in [Vector3(-15,0,-8),Vector3(15,0,-7),Vector3(0,0,7)]:game.spawn_enemy("horokko",at,58)
	var keys := [["lake_key_1",Vector3(-15,0,8)],["lake_key_2",Vector3(15,0,8)],["lake_key_3",Vector3(0,0,-7)]]
	for entry in keys:
		if not game.state.story_flag(StringName(entry[0])):
			crystal(entry[1]+Vector3.UP*.55,Color("83d4d7"),.28,self);interact("Starter Key",entry[1],entry[0])
	var count:=game.state.story_counter(&"lake_starter_keys")
	if count>=3 and not game.state.story_flag(&"red_refractor_acquired"):
		crystal(Vector3(0,.8,-12),Color("ef4b59"),.72,self);interact("Red Refractor",Vector3(0,0,-12),"red_refractor")
	elif game.state.story_flag(&"red_refractor_acquired") and not game.state.story_flag(&"garudoriten_defeated"):
		# The apparent pedestal has transformed on the return route.
		spawn_special("garudoriten",Vector3(0,0,1),320)
		interact("Sub-Gate exit",Vector3(0,0,12),"lake_exit_locked")
	elif game.state.story_flag(&"garudoriten_defeated"):
		interact("Sub-Gate exit",Vector3(0,0,12),"lake_exit")
	sign_at("LAKE SUB-GATE",Vector3(0,3,-13.2))


func build_flutter_restart() -> void:
	bounds=Rect2(-16,-11,32,22);_floor_grid(Vector2(32,22),Color("838f8e"),C_ART+"cabin_metal.png");_perimeter(Vector2(32,22),Color("667477"),C_ART+"cabin_panel.png")
	box(Vector3(0,1,-6),Vector3(10,2,4),Color("59676b"),true,C_ART+"cabin_panel.png")
	for x in [-5.0,5.0]:cylinder(Vector3(x,.7,-4),1.1,1.4,Color("566c70"));model("lamp",Vector3(x,0,-1),2.0,0,false)
	game.spawn_npc("Roll","roll",Vector3(-4,0,3));game.spawn_npc("Data","data",Vector3(4,0,3));game.spawn_npc("Barrell","barrell",Vector3(0,0,5))
	interact("Main engine refractor socket",Vector3(0,0,-4),"restart_flutter");sign_at("FLUTTER / MAIN ENGINE",Vector3(0,3,-7.5))


func build_clozer_subgate() -> void:
	bounds=Rect2(-20,-15,40,30);_floor_grid(Vector2(40,30),Color("7f9788"),C_ART+"hex_floor.png");_perimeter(Vector2(40,30),Color("617d71"),C_ART+"wall.png")
	# Elevated entry, generator wing, elevator chamber and the control console return route.
	box(Vector3(0,.7,10),Vector3(15,.35,5),Color("789083"),true,C_ART+"metal.png")
	for i in range(5):box(Vector3(-7+i*.8,.1+i*.14,9),Vector3(.9,.2+i*.02,3),Color("82988d"),true,C_ART+"metal.png")
	for entry in [[Vector3(-9,1,0),Vector3(.65,2,17)],[Vector3(9,1,0),Vector3(.65,2,17)],[Vector3(0,1,-4),Vector3(10,2,.65)]]:box(entry[0],entry[1],Color("617d71"),true,C_ART+"wall.png")
	interact("Sub-Gate generator",Vector3(-15,0,-8),"clozer_generator")
	if game.state.story_flag(&"clozer_generator_on"):
		for entry in [["clozer_id_1",Vector3(-14,0,6)],["clozer_id_2",Vector3(14,0,6)],["clozer_id_3",Vector3(14,0,-8)]]:
			if not game.state.story_flag(StringName(entry[0])):
				crystal(entry[1]+Vector3.UP*.45,Color("d8cf91"),.24,self);interact("ID Card",entry[1],entry[0])
		if not game.state.story_flag(&"karumuna_defeated"):spawn_special("karumuna",Vector3(0,0,-7),340)
	interact("Main Gate control console",Vector3(0,0,8),"clozer_control")
	sign_at("CLOZER SUB-GATE / CONTROL",Vector3(0,3,11.8))


func build_campaign_blockout(id: String) -> void:
	bounds=Rect2(-20,-14,40,28)
	var underground:=id in ["main_gate","subcity","central_gate"]
	var outdoor:=id in ["old_city","kattelox_departure"]
	var floor_texture:=C_ART+("hex_floor.png" if underground else ("grass.png" if outdoor and id!="old_city" else "cabin_metal.png"))
	var floor_colour:=Color("97a790") if underground else (Color("7e9a6d") if outdoor and id!="old_city" else Color("a7aaa2"))
	_floor_grid(Vector2(40,28),floor_colour,floor_texture);_perimeter(Vector2(40,28),Color("768a7c") if underground else Color("8b8b7d"),C_ART+("wall.png" if underground else "stone.png"))
	if id=="flutter_deck":
		for at in [Vector3(-10,0,-7),Vector3(10,0,-7),Vector3(-10,0,7),Vector3(10,0,7)]:model("drache",at,3.2,PI*.5,false)
	elif id in ["old_city","kattelox_departure"]:
		model("bakery",Vector3(-11,0,-8),5,0);model("hangar",Vector3(11,0,-8),5,0);model("shed",Vector3(-12,0,8),2,PI/2)
	else:
		for p in [Vector3(-10,1,-5),Vector3(10,1,-5),Vector3(-10,1,5),Vector3(10,1,5)]:box(p,Vector3(2,2,2),Color("879b8c"),true,C_ART+"pillar.png")
	var step:int=int(game.state.campaign_step);var enemy_count:=0 if step==20 else clampi(2+int(step/4),3,6)
	for i in range(enemy_count):game.spawn_enemy("sharukurusu" if i%3==2 else "horokko",Vector3(-10+float((i*7)%21),0,-3+float((i*5)%11)),40+step*3)
	if step in [15,17,19] and not game.state.story_flag(StringName("campaign_boss_%d_defeated"%step)):game.spawn_enemy("guardian",Vector3(0,0,-8.5),180+step*8,true)
	interact("Mission objective",Vector3(0,0,-11.5),"stage_complete");sign_at(_stage_name(step),Vector3(0,3,-12.3))


func _stage_name(step: int) -> String:
	var names:={15:"FLUTTER DECK",16:"MAIN GATE",17:"OLD CITY",18:"SUB-CITY",19:"CENTRAL GATE",20:"KATTELOX DEPARTURE"}
	return String(names.get(step,"KATTELOX"))
