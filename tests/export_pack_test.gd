extends SceneTree
## Run from an empty project, so source assets cannot mask missing exports.
var game
var failed: bool=false
func _init():call_deferred("run")
func check(ok: bool,text: String):
 if not ok:failed=true;push_error("Export pack: "+text)
func run():
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or not ProjectSettings.load_resource_pack(args[0]):push_error("Cannot mount export");quit(1);return
 game=load("res://scenes/legends.tscn").instantiate()
 if game.get_script()==null:push_error("Export main script unavailable");game.free();quit(1);return
 root.add_child(game);await physics_frame
 check(game.mode=="title","title starts")
 check(not FileAccess.file_exists("res://tests/legends_test.gd"),"tests excluded")
 check(not FileAccess.file_exists("res://tools/build_art.py"),"authoring tools excluded")
 game.mode="game"
 for area in ["island","cabin","ruins","bonne"]:
  game.build_area(area,2,Vector3(0,0,5));await create_timer(.2).timeout
  check(is_instance_valid(game.player.visual),area+" character")
  check(is_instance_valid(game.audio.music_player.stream),area+" music")
  for actor in game.npcs+game.enemies+[game.player]:
   for mesh in actor.visual.find_children("*","MeshInstance3D",true,false):
    if mesh.visible:check(mesh.get_active_material(0).albedo_texture!=null,"textured "+actor.kind)
 print("EXPORT PACK: %s"%["FAIL" if failed else "PASS"])
 game.audio.shutdown();game.queue_free();game=null
 for i in range(12):await physics_frame
 quit(1 if failed else 0)
