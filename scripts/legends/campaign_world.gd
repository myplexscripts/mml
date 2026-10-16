extends "res://scripts/legends/world.gd"

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
		_: build_campaign_blockout(area)
	finish_batches()
	build_navigation()


func _apply_climate(id: String) -> void:
	var profile := {
		"background": Color("789baa"),
		"ambient": Color("c7d7cd"),
		"ambient_energy": 0.38,
		"sun": Color("fff0c6"),
		"sun_energy": 0.8,
	}
	if id in ["ocean_tower", "portal1", "cardon_subgate", "lake_subgate", "clozer_subgate", "main_gate", "subcity", "central_gate"]:
		profile = {"background":Color("172b35"), "ambient":Color("8fb3b9"), "ambient_energy":0.28, "sun":Color("9dcbd2"), "sun_energy":0.44}
	elif id in ["cardon", "yass_plains", "cardon_approach"]:
		profile = {"background":Color("7ea5ad"), "ambient":Color("cadbc6"), "ambient_energy":0.42, "sun":Color("ffe4ae"), "sun_energy":0.88}
	elif id in ["lake_jyun"]:
		profile = {"background":Color("729db2"), "ambient":Color("bfd8dc"), "ambient_energy":0.4, "sun":Color("f5e6c5"), "sun_energy":0.78}
	elif id in ["flutter_deck"]:
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
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	box(Vector3(0, 1.0, -hz), Vector3(size.x, 2.0, .55), colour, true, texture)
	box(Vector3(0, 1.0, hz), Vector3(size.x, 2.0, .55), colour, true, texture)
	box(Vector3(-hx, 1.0, 0), Vector3(.55, 2.0, size.y), colour, true, texture)
	box(Vector3(hx, 1.0, 0), Vector3(.55, 2.0, size.y), colour, true, texture)


func _floor_grid(size: Vector2, colour: Color, texture: String) -> void:
	box(Vector3(0, -.22, 0), Vector3(size.x, .44, size.y), colour, true)
	var min_x := int(-size.x * .5 + 1)
	var max_x := int(size.x * .5)
	var min_z := int(-size.y * .5 + 1)
	var max_z := int(size.y * .5)
	for x in range(min_x, max_x, 2):
		for z in range(min_z, max_z, 2):
			batch_box(Vector3(x, .012, z), Vector3(1.96, .035, 1.96), colour, texture)


func build_ocean_tower() -> void:
	bounds = Rect2(-19, -14, 38, 28)
	_floor_grid(Vector2(38, 28), Color("94a79d"), C_ART + "cabin_metal.png")
	_perimeter(Vector2(38, 28), Color("728d86"), C_ART + "wall.png")
	# Right-angle mechanical passages. The west branch is deliberately optional,
	# preserving the original wrong-turn/trap idea in a top-down layout.
	for entry in [
		[Vector3(-8, 1.0, 5), Vector3(.65, 2.0, 15)],
		[Vector3(8, 1.0, 3), Vector3(.65, 2.0, 18)],
		[Vector3(0, 1.0, 1), Vector3(8.0, 2.0, .65)],
		[Vector3(-13, 1.0, -4), Vector3(10.0, 2.0, .65)],
		[Vector3(13, 1.0, -7), Vector3(10.0, 2.0, .65)],
	]:
		box(entry[0], entry[1], Color("6f8982"), true, C_ART + "wall.png")
	for at in [Vector3(-4, .04, 8), Vector3(4, .04, 3), Vector3(-13, .04, -8), Vector3(13, .04, -10)]:
		cylinder(at, .72, .08, Color("4b8789"))
		var lamp := OmniLight3D.new()
		lamp.position = at + Vector3.UP * 1.5
		lamp.light_color = Color("76d2cf")
		lamp.light_energy = .5
		lamp.omni_range = 5
		add_child(lamp)
	# Elevation lesson translated into broad steps rather than a camera-facing jump puzzle.
	for i in range(5):
		box(Vector3(3.2, .08 + i * .11, -4.5 - i * .62), Vector3(4.2, .16 + i * .02, .65), Color("a9b7a7"), true, C_ART + "metal.png")
	# Wrong-turn cache and ambush.
	model("container", Vector3(-15, 0, -9.5), .95)
	interact("Ancient side cache", Vector3(-15, 0, -9.5), "ocean_cache")
	game.spawn_enemy("horokko", Vector3(-12.5, 0, -7.7), 32)
	game.spawn_enemy("horokko", Vector3(-15.5, 0, -6.2), 32)
	# Main escape route.
	game.spawn_enemy("sharukurusu", Vector3(4.3, 0, 5.0), 44)
	game.spawn_enemy("horokko", Vector3(11.5, 0, -2.5), 38)
	if not game.state.story_flag(&"hanmuru_defeated"):
		game.spawn_enemy("guardian", Vector3(0, 0, -10.7), 185, true)
	interact("Rooftop exit", Vector3(0, 0, -12.3), "ocean_exit")
	sign_at("OCEAN TOWER / EXIT", Vector3(0, 2.8, -12.7))


func build_cardon_forest() -> void:
	bounds = Rect2(-20, -14, 40, 28)
	_floor_grid(Vector2(40, 28), Color("789768"), C_ART + "grass.png")
	# Brown cliff walls around the crash clearing.
	_perimeter(Vector2(40, 28), Color("8e775c"), C_ART + "stone.png")
	for at in [Vector3(-16,0,-9),Vector3(-13,0,9),Vector3(-7,0,-11),Vector3(8,0,10),Vector3(15,0,-7),Vector3(17,0,7)]:
		tree(at)
	for at in [Vector3(-11,0,-7), Vector3(13,0,8), Vector3(10,0,-9)]:
		var rock := box(at + Vector3.UP*.35, Vector3(1.5,.7,1.2), Color("9b8c70"), true, C_ART + "rock.png")
		rock.rotation.y = at.x * .07
	# Damaged Flutter is scenery here, not the opening hub.
	var ship := model("flutter", Vector3(-11,-3.7,2.5), 10.7, -PI/2)
	ship.rotation.z = -.08
	ship.name = "CrashedFlutter"
	game.spawn_npc("Roll", "roll", Vector3(-5.8,0,3.2))
	game.spawn_npc("Barrell", "barrell", Vector3(-7.5,0,5.2))
	game.spawn_npc("Data", "data", Vector3(-4.8,0,5.4))
	# Forest road toward Apple Market.
	box(Vector3(7,.02,0), Vector3(23,.04,4.4), Color("ad9c78"), false, C_ART + "sand.png")
	for z in [-2.7,2.7]:
		for x in range(-1,19,3):
			model("lamp", Vector3(x,0,z), 2.2, 0, false)
	interact("Road to Apple Market", Vector3(18,0,0), "to_market")
	sign_at("APPLE MARKET", Vector3(17,2.4,0))


func build_apple_market() -> void:
	bounds = Rect2(-18,-10,36,20)
	_floor_grid(Vector2(36,20), Color("b5b0a2"), C_ART + "cabin_metal.png")
	_perimeter(Vector2(36,20), Color("9f987e"), C_ART + "cabin_panel.png")
	# Covered market aisle with distinct shop fronts on either side.
	for x in [-12.0,-6.0,0.0,6.0,12.0]:
		box(Vector3(x,1.0,-7.5), Vector3(4.8,2.0,2.6), Color("8f7359"), true, C_ART + "cabin_panel.png")
		box(Vector3(x,1.0,7.5), Vector3(4.8,2.0,2.6), Color("7c8790"), true, C_ART + "cabin_panel.png")
	for x in range(-14,15,4):
		model("lamp", Vector3(x,0,-4.0), 2.0, 0, false)
		model("lamp", Vector3(x,0,4.0), 2.0, PI, false)
	interact("Forest exit", Vector3(-16.5,0,0), "to_cardon")
	interact("Portal 1", Vector3(16.2,0,-3.5), "to_portal1")
	interact("Junk Store", Vector3(16.2,0,3.5), "junk_store")
	sign_at("PORTAL 1", Vector3(15.2,2.5,-3.5))
	sign_at("JUNK STORE", Vector3(15.2,2.5,3.5))
	if game.state.story_flag(&"junk_store_owner_rescued"):
		game.spawn_npc("Junk Store Owner", "barrell", Vector3(12.5,0,3.5))


func build_portal_one() -> void:
	bounds = Rect2(-18,-13,36,26)
	_floor_grid(Vector2(36,26), Color("9daa94"), C_ART + "hex_floor.png")
	_perimeter(Vector2(36,26), Color("74887a"), C_ART + "wall.png")
	for entry in [
		[Vector3(-8,1,1),Vector3(.65,2,16)], [Vector3(8,1,-2),Vector3(.65,2,15)],
		[Vector3(0,1,4),Vector3(8,2,.65)], [Vector3(-13,1,-5),Vector3(10,2,.65)]
	]:
		box(entry[0],entry[1],Color("7d9282"),true,C_ART+"wall.png")
	for at in [Vector3(-12,0,-8),Vector3(4,0,6),Vector3(12,0,-5)]:
		game.spawn_enemy("horokko",at,38)
	game.spawn_enemy("sharukurusu",Vector3(8,0,-9),52)
	if not game.state.story_flag(&"junk_store_owner_rescued"):
		game.spawn_npc("Junk Store Owner", "barrell", Vector3(13.5,0,-9.8))
	interact("Portal 1 entrance", Vector3(-15.8,0,9.8), "to_market")
	sign_at("PORTAL 1 / DEEP CHAMBER", Vector3(11,2.8,-11.5))


func build_downtown() -> void:
	bounds = Rect2(-20,-14,40,28)
	_floor_grid(Vector2(40,28), Color("a9aaa1"), C_ART + "cabin_metal.png")
	_perimeter(Vector2(40,28), Color("8a9187"), C_ART + "stone.png")
	# Open Kattelox street grid.
	for x in [-13.0,0.0,13.0]:
		box(Vector3(x,1.2,-9),Vector3(8.5,2.4,5.2),Color("aa8b6f"),true,C_ART+"cabin_panel.png")
		box(Vector3(x,1.2,9),Vector3(8.5,2.4,5.2),Color("8096a0"),true,C_ART+"cabin_panel.png")
	for x in range(-16,17,4):
		model("lamp",Vector3(x,0,-5.5),2.3,0,false)
		model("lamp",Vector3(x,0,5.5),2.3,PI,false)
	if game.state.campaign_step <= 5 and not game.state.story_flag(&"feldynaught_defeated"):
		game.spawn_npc("Tron", "tron", Vector3(3,0,-1))
	interact("City Hall district",Vector3(18,0,0),"city_hall_gate")
	interact("Cardon Forest road",Vector3(-18,0,0),"to_cardon")
	sign_at("DOWNTOWN KATTELOX",Vector3(0,3,-11.2))


func build_city_hall() -> void:
	bounds = Rect2(-20,-14,40,28)
	_floor_grid(Vector2(40,28), Color("b0afa2"), C_ART + "cabin_metal.png")
	_perimeter(Vector2(40,28), Color("8d9289"), C_ART + "stone.png")
	# Civic buildings frame the combat district.
	for entry in [
		[Vector3(0,1.6,-9.5),Vector3(12,3.2,5),Color("b9af94")],
		[Vector3(-13,1.3,7.5),Vector3(8,2.6,6),Color("8297a0")],
		[Vector3(13,1.3,7.5),Vector3(8,2.6,6),Color("9b816d")],
	]:
		box(entry[0],entry[1],entry[2],true,C_ART+"cabin_panel.png")
	for at in [Vector3(-9,0,-1),Vector3(9,0,-1),Vector3(-6,0,4),Vector3(6,0,4)]:
		game.spawn_enemy("servbot",at,34)
	if not game.state.story_flag(&"bon_bonne_defeated"):
		game.spawn_enemy("guardian",Vector3(0,0,2),235,true)
	interact("Downtown road",Vector3(0,0,12.5),"downtown_gate")
	sign_at("CITY HALL",Vector3(0,3,-11.5))


func build_campaign_blockout(id: String) -> void:
	bounds = Rect2(-20,-14,40,28)
	var underground := id in ["cardon_subgate","lake_subgate","clozer_subgate","main_gate","subcity","central_gate"]
	var outdoor := id in ["yass_plains","cardon_approach","lake_jyun","old_city","kattelox_departure"]
	var floor_texture := C_ART + ("hex_floor.png" if underground else ("grass.png" if outdoor and id != "old_city" else "cabin_metal.png"))
	var floor_colour := Color("97a790") if underground else (Color("7e9a6d") if outdoor and id != "old_city" else Color("a7aaa2"))
	_floor_grid(Vector2(40,28),floor_colour,floor_texture)
	_perimeter(Vector2(40,28),Color("768a7c") if underground else Color("8b8b7d"),C_ART+("wall.png" if underground else "stone.png"))

	# Give each later campaign region a recognisable spatial identity while it is
	# still a gameplay blockout. These are replaced with researched layouts stage by stage.
	if id in ["yass_plains","cardon_approach"]:
		for at in [Vector3(-15,0,-9),Vector3(-10,0,9),Vector3(11,0,-9),Vector3(15,0,8),Vector3(0,0,10)]:tree(at)
	elif id == "lake_jyun":
		box(Vector3(0,-.55,-9),Vector3(36,.3,7),Color("579fac"))
		model("boat",Vector3(0,0,-7.5),3.1,PI/2,false)
	elif id == "flutter_deck":
		for at in [Vector3(-10,0,-7),Vector3(10,0,-7),Vector3(-10,0,7),Vector3(10,0,7)]:model("drache",at,3.2,PI*.5,false)
	elif id in ["uptown","old_city","kattelox_departure"]:
		model("bakery",Vector3(-11,0,-8),5.0,0)
		model("hangar",Vector3(11,0,-8),5.0,0)
		model("shed",Vector3(-12,0,8),2.0,PI/2)
	else:
		for p in [Vector3(-10,1,-5),Vector3(10,1,-5),Vector3(-10,1,5),Vector3(10,1,5)]:
			box(p,Vector3(2.0,2.0,2.0),Color("879b8c"),true,C_ART+"pillar.png")

	var step := game.state.campaign_step
	var enemy_count := 0 if step == 20 else clampi(2 + int(step / 4), 3, 6)
	for i in range(enemy_count):
		var x := -10.0 + float((i * 7) % 21)
		var z := -3.0 + float((i * 5) % 11)
		game.spawn_enemy("sharukurusu" if i % 3 == 2 else "horokko",Vector3(x,0,z),40+step*3)
	if step in [7,9,11,12,14,15,17,19] and not game.state.story_flag(StringName("campaign_boss_%d_defeated" % step)):
		game.spawn_enemy("guardian",Vector3(0,0,-8.5),180+step*8,true)
	interact("Mission objective",Vector3(0,0,-11.5),"stage_complete")
	sign_at(_stage_name(step),Vector3(0,3,-12.3))


func _stage_name(step: int) -> String:
	var names := {
		7:"YASS PLAINS / CLOZER WOODS", 8:"CARDON SUB-GATE APPROACH", 9:"CARDON SUB-GATE",
		10:"UPTOWN", 11:"LAKE JYUN", 12:"LAKE SUB-GATE", 13:"FLUTTER ENGINE ROOM",
		14:"CLOZER SUB-GATE", 15:"FLUTTER DECK", 16:"MAIN GATE", 17:"OLD CITY",
		18:"SUB-CITY", 19:"CENTRAL GATE", 20:"KATTELOX DEPARTURE"
	}
	return String(names.get(step,"KATTELOX"))
