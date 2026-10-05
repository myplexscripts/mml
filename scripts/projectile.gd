extends Node2D
var game
var speed := Vector2.ZERO
var hostile: bool = false
var damage: int = 10
var life: float = 1.2

func _physics_process(delta: float) -> void:
	if not game.active(): return
	life -= delta
	if life <= 0:
		queue_free()
		return
	var next := global_position + speed*delta
	var query := PhysicsRayQueryParameters2D.create(global_position,next,1 | (2 if hostile else 4) | 16)
	query.collide_with_areas = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var collider = hit.collider
		if collider.has_method("hurt"): collider.hurt(damage,global_position)
		game.burst(hit.position,Color("ee9961") if hostile else Color("f2e7ac"),5,55)
		queue_free()
		return
	global_position = next
	queue_redraw()

func _draw() -> void:
	var colour := Color("ff916c") if hostile else Color("ffd783")
	var tail := -speed.normalized()*10
	draw_line(Vector2(0,-8)+tail,Vector2(0,-8),colour.darkened(0.3),3)
	draw_circle(Vector2(0,-8),3,colour)
	draw_circle(Vector2(0,-8),1.5,Color("fff1c6"))
