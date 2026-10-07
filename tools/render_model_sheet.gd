extends SceneTree

const Models = preload("res://scripts/legends/models.gd")

var world: Node3D

func _initialize() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1600)
	ProjectSettings.set_setting("display/window/size/viewport_height", 1200)
	world = Node3D.new()
	world.name = "RealModelSheet"
	root.add_child(world)
	_build_sheet()
	call_deferred("_capture")

func _build_sheet() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("d9d9d6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.62
	env_node.environment = env
	world.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	world.add_child(sun)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.5
	camera.position = Vector3(0, 22, 18)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	camera.current = true

	var keys := [
		["megaman", "MegaMan Volnutt", 2.6],
		["roll", "Roll Caskett", 2.5],
		["data", "Data", 1.7],
		["barrell", "Barrell Caskett", 2.7],
		["tron", "Tron Bonne", 2.5],
		["servbot", "Servbot", 1.7],
		["horokko", "Horokko", 1.8],
		["sharukurusu", "Sharukurusu", 1.8],
		["guardian", "Guardian", 2.2],
		["feldynaught", "Feldynaught", 3.0],
		["flutter", "Flutter", 3.2],
		["drache", "Drache", 2.7],
		["container", "Container", 1.8],
	]

	var cols := 5
	var x_gap := 4.3
	var z_gap := 5.0
	for i in range(keys.size()):
		var col := i % cols
		var row := i / cols
		var x := (float(col) - 2.0) * x_gap
		var z := (float(row) - 1.0) * z_gap
		var key: String = keys[i][0]
		var label_text: String = keys[i][1]
		var height: float = keys[i][2]
		var panel := MeshInstance3D.new()
		var panel_mesh := BoxMesh.new()
		panel_mesh.size = Vector3(3.85, 0.06, 4.4)
		panel.mesh = panel_mesh
		panel.position = Vector3(x, -0.08, z)
		var panel_mat := StandardMaterial3D.new()
		panel_mat.albedo_color = Color("eeeeeb")
		panel_mat.roughness = 1.0
		panel.material_override = panel_mat
		world.add_child(panel)

		var model := Models.make(key, height)
		model.position = Vector3(x, 0, z + 0.15)
		model.rotation.y = PI
		world.add_child(model)

		var label := Label3D.new()
		label.text = label_text
		label.font_size = 44
		label.pixel_size = 0.009
		label.modulate = Color("22252a")
		label.outline_size = 8
		label.outline_modulate = Color("eeeeeb")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(x, 0.16, z + 1.82)
		world.add_child(label)

	_add_refractors(Vector3(6.45, 0, 5.0))

func _add_refractors(origin: Vector3) -> void:
	var panel := MeshInstance3D.new()
	var panel_mesh := BoxMesh.new()
	panel_mesh.size = Vector3(8.15, 0.06, 4.4)
	panel.mesh = panel_mesh
	panel.position = origin + Vector3(2.15, -0.08, 0)
	var panel_mat := StandardMaterial3D.new()
	panel_mat.albedo_color = Color("eeeeeb")
	panel_mat.roughness = 1.0
	panel.material_override = panel_mat
	world.add_child(panel)

	var colours := [Color("ff3157"), Color("2787ff"), Color("37d66b"), Color("ffc633")]
	for i in range(colours.size()):
		var node := _refractor(colours[i])
		node.position = origin + Vector3(float(i) * 1.45, 0.72, 0)
		world.add_child(node)

	var label := Label3D.new()
	label.text = "Refractors: red / blue / green / yellow"
	label.font_size = 44
	label.pixel_size = 0.009
	label.modulate = Color("22252a")
	label.outline_size = 8
	label.outline_modulate = Color("eeeeeb")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = origin + Vector3(2.15, 0.16, 1.82)
	world.add_child(label)

func _refractor(colour: Color) -> Node3D:
	var root_node := Node3D.new()
	var mesh := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.62, 2.45, 0.62)
	mesh.mesh = prism
	mesh.rotation.z = PI
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.emission_enabled = true
	mat.emission = colour * 0.35
	mat.roughness = 0.18
	mat.metallic = 0.08
	mesh.material_override = mat
	root_node.add_child(mesh)
	var base := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.62
	cylinder.height = 0.18
	cylinder.radial_segments = 8
	base.mesh = cylinder
	base.position.y = -1.35
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color("6f747c")
	base_mat.roughness = 0.8
	base.material_override = base_mat
	root_node.add_child(base)
	return root_node

func _capture() -> void:
	await process_frame
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs"))
	var err := image.save_png("res://docs/model-sheet.png")
	if err != OK:
		push_error("Could not save model sheet: %s" % err)
		quit(1)
		return
	print("Saved real model sheet to docs/model-sheet.png")
	quit()
