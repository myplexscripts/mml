extends SceneTree

const State = preload("res://scripts/legends/state.gd")
const World = preload("res://scripts/legends/world.gd")
const Models = preload("res://scripts/legends/models.gd")
const OUTPUT_DIR := "res://build/screenshots"

var state = State.new()
var world


func _initialize() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	state.repair = 2
	state.quest_started = true
	state.weapon_plans = true
	call_deferred("_render_all")


func frames(count: int = 4) -> void:
	for i in range(count):
		await process_frame


func active() -> bool:
	return false


func spawn_npc(person: String, art: String, at: Vector3) -> void:
	var heights := {"roll": 2.5, "data": 1.7, "barrell": 2.7, "tron": 2.5}
	var node := Models.make(art, float(heights.get(art, 2.4)))
	node.position = at
	node.rotation.y = PI
	world.add_child(node)


func spawn_enemy(kind: String, at: Vector3, hp: int = 40, boss: bool = false) -> void:
	var heights := {"servbot": 1.7, "horokko": 1.8, "sharukurusu": 1.8, "guardian": 2.2, "feldynaught": 3.0}
	var node := Models.make(kind, float(heights.get(kind, 2.0)))
	node.position = at + Vector3.UP * 0.1
	node.rotation.y = PI
	world.add_child(node)


func crystal(at: Vector3, colour: Color, size: float, parent: Node = null) -> Node3D:
	var mesh := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(size * 1.2, size * 2.0, size)
	mesh.mesh = prism
	mesh.position = at
	mesh.rotation.z = PI
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.emission_enabled = true
	mat.emission = colour * 0.22
	mat.roughness = 0.35
	mat.metallic = 0.2
	mesh.material_override = mat
	(world if parent == null else parent).add_child(mesh)
	return mesh


func capture(name: String) -> void:
	await frames(5)
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save screenshot %s: %s" % [path, error_string(error)])
		quit(1)
		return
	print("SCREENSHOT: ", path)


func render_area(area: String, depth: int, player_at: Vector3, focus: Vector3, camera_size: float, name: String) -> void:
	if is_instance_valid(world):
		world.queue_free()
		await frames(2)

	world = World.new()
	world.game = self
	world.area = area
	world.depth = depth
	root.add_child(world)

	var player := Models.make("megaman", 2.6)
	player.position = player_at + Vector3.UP * 0.1
	player.rotation.y = PI
	world.add_child(player)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = camera_size
	camera.near = 0.1
	camera.far = 160.0
	camera.position = focus + Vector3(0, 22, 19)
	world.add_child(camera)
	camera.look_at(focus, Vector3.UP)
	camera.current = true

	await capture(name)


func _render_all() -> void:
	await render_area("island", 1, Vector3(-1.5, 0, 7.0), Vector3(-4, 0, 2), 20.0, "01-flutter-landing")
	await render_area("cabin", 1, Vector3(0, 0, 2.5), Vector3(0, 0, -1), 18.0, "02-flutter-cabin")
	await render_area("ruins", 1, Vector3(0, 0, 9.5), Vector3(0, 0, 3), 18.0, "03-northern-ruins")
	await render_area("bonne", 1, Vector3(0, 0, 6.0), Vector3.ZERO, 27.0, "04-bonne-showdown")
	if is_instance_valid(world):
		world.queue_free()
	await frames(2)
	quit()
