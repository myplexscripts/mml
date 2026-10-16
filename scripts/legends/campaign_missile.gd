extends StaticBody3D

var game
var velocity := Vector3.ZERO
var target := Vector3.ZERO
var health: int = 18
var life: float = 6.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = .34
	collision.shape = shape
	add_child(collision)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = .22
	sphere.height = .44
	sphere.radial_segments = 8
	sphere.rings = 4
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ff735f")
	mat.emission_enabled = true
	mat.emission = Color("d7402f")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	add_child(mesh)
	var light := OmniLight3D.new()
	light.light_color = Color("ff6a52")
	light.light_energy = .55
	light.omni_range = 2.5
	add_child(light)


func _physics_process(delta: float) -> void:
	if not game.active(): return
	life -= delta
	var desired := global_position.direction_to(target)
	velocity = velocity.move_toward(desired * 5.2, delta * 6.0)
	global_position += velocity * delta
	rotation.y += delta * 5.0
	if global_position.distance_to(target) < .75:
		game.lake_missile_hit(global_position)
		queue_free()
	elif life <= 0.0:
		queue_free()


func hurt(damage: int, from: Vector3) -> void:
	health -= damage
	game.spark(global_position, Color("fff0bd"), .18, .24)
	if health > 0: return
	game.lake_missile_intercepted(global_position)
	queue_free()
