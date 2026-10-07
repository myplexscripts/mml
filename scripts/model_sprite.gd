extends Node2D
## Renders one of the original Legends 3D assets into the 2D top-down world.
## The model stays genuinely 3D, while the gameplay remains CharacterBody2D based.

var model_path: String = ""
var display_height: float = 58.0
var yaw_offset: float = 0.0
var viewport_size := Vector2i(144, 144)
var camera_elevation: float = 0.62
var camera_turn: float = -0.60
var moving: bool = false
var motion_clock: float = 0.0

var viewport: SubViewport
var stage: Node3D
var model_root: Node3D
var screen_sprite: Sprite2D
var camera: Camera3D
var base_model_y: float = 0.0
var ready_for_motion: bool = false

func _ready() -> void:
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return

	viewport = SubViewport.new()
	viewport.name = "ModelViewport"
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(viewport)

	stage = Node3D.new()
	stage.name = "Stage"
	viewport.add_child(stage)

	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.82, 0.87, 0.92)
	environment.ambient_light_energy = 1.45
	environment_node.environment = environment
	stage.add_child(environment_node)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-52, -38, 0)
	key.light_energy = 1.05
	key.shadow_enabled = false
	stage.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 145, 0)
	fill.light_energy = 0.38
	fill.light_color = Color(0.60, 0.72, 0.88)
	fill.shadow_enabled = false
	stage.add_child(fill)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.85
	camera.position = Vector3(3.45, 4.20, 5.55)
	stage.add_child(camera)
	camera.look_at(Vector3(0, 0.90, 0), Vector3.UP)

	var source = load(model_path)
	if source is PackedScene:
		model_root = source.instantiate()
	elif source is Mesh:
		model_root = Node3D.new()
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = source
		model_root.add_child(mesh_instance)
	else:
		return

	model_root.name = "OriginalModel"
	stage.add_child(model_root)
	_normalize_model()
	model_root.rotation.y = yaw_offset

	screen_sprite = Sprite2D.new()
	screen_sprite.name = "RenderedModel"
	screen_sprite.texture = viewport.get_texture()
	screen_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen_sprite.position = Vector2(0, -display_height * 0.53)
	screen_sprite.scale = Vector2.ONE * (display_height / 88.0)
	add_child(screen_sprite)
	ready_for_motion = true

func _process(delta: float) -> void:
	if not ready_for_motion:
		return
	motion_clock += delta
	var bob := 0.0
	if moving:
		bob = absf(sin(motion_clock * 11.0)) * 0.035
	model_root.position.y = base_model_y + bob

func set_facing(direction: Vector2) -> void:
	if not ready_for_motion or direction.length_squared() < 0.01:
		return
	model_root.rotation.y = yaw_offset + atan2(direction.x, direction.y)

func set_moving(value: bool) -> void:
	moving = value
	if not moving and ready_for_motion:
		model_root.position.y = base_model_y

func set_visual_modulate(value: Color) -> void:
	if is_instance_valid(screen_sprite):
		screen_sprite.modulate = value

func _normalize_model() -> void:
	var bounds := _collect_bounds(model_root)
	if bounds.size.length_squared() <= 0.000001:
		base_model_y = model_root.position.y
		return

	var dominant := maxf(bounds.size.y, maxf(bounds.size.x, bounds.size.z) * 0.92)
	var scale_factor := 1.78 / maxf(dominant, 0.001)
	model_root.scale = Vector3.ONE * scale_factor
	var centre_x := bounds.position.x + bounds.size.x * 0.5
	var centre_z := bounds.position.z + bounds.size.z * 0.5
	model_root.position = Vector3(
		-centre_x * scale_factor,
		-bounds.position.y * scale_factor,
		-centre_z * scale_factor
	)
	base_model_y = model_root.position.y

func _collect_bounds(root: Node3D) -> AABB:
	var found := false
	var result := AABB()
	var root_inverse := root.global_transform.affine_inverse()
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var local_to_root := root_inverse * mesh_instance.global_transform
		var box := local_to_root * mesh_instance.get_aabb()
		if not found:
			result = box
			found = true
		else:
			result = result.merge(box)
	return result if found else AABB()
