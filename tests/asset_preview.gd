extends SceneTree
const Models=preload("res://scripts/legends/models.gd")
func _init():call_deferred("run")
func run():
 DirAccess.make_dir_recursive_absolute("res://test-results")
 var scene:=Node3D.new();root.add_child(scene)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("537687");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.6;scene.add_child(env)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-20,0);sun.light_energy=.7;scene.add_child(sun)
 var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=16;scene.add_child(camera)
 var ship=Models.make("flutter",6.5);ship.rotation.y=-PI/2;scene.add_child(ship)
 for m in ship.find_children("*","MeshInstance3D",true,false):
  print("SHIP MESH ",m.name," bounds ",m.global_transform*m.get_aabb())
 for index in range(4):
  var angle:float=PI/2*index
  camera.look_at_from_position(Vector3(sin(angle)*15,7,cos(angle)*15),Vector3(0,2.5,0))
  for f in range(3):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/ship_view_%d.png"%index)
 ship.queue_free();await process_frame
 for key in ["megaman","tree","harbour","bakery","shed","boat"]:
  var asset=Models.make(key,2.0 if key=="megaman" else 5.0);scene.add_child(asset);Models.pose(asset,0,false)
  print("ASSET ",key," bounds ",asset.get_meta("bounds"))
  camera.size=3.1 if key=="megaman" else 10
  camera.look_at_from_position(Vector3(3,2,7) if key=="megaman" else Vector3(9,7,12),Vector3(0,1,0) if key=="megaman" else Vector3(0,2,0))
  for f in range(6):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://test-results/asset_"+key+".png")
  asset.queue_free();await process_frame
 quit()
