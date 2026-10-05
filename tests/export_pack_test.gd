extends SceneTree
## Run from an empty project to verify a self-contained exported resource pack.
var game
var failed: bool=false

func _init() -> void: call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failed=true;push_error("Export pack: "+description)

func run() -> void:
	var arguments:=OS.get_cmdline_user_args()
	if arguments.size()!=1 or not ProjectSettings.load_resource_pack(arguments[0]):
		push_error("Could not mount exported resource pack");quit(1);return
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await physics_frame
	check(game.mode=="title","title starts")
	check(is_instance_valid(game.player.sprite.texture),"MegaMan texture is bundled")
	check(not FileAccess.file_exists("res://tools/build_art.py"),"authoring tools are excluded")
	check(not FileAccess.file_exists("res://tests/gameplay_test.gd"),"tests are excluded")
	game.mode="game"
	for area in ["surface","ruins","bonne","cabin"]:
		game.build_area(area,1,Vector2(320,340));await create_timer(.2).timeout
		check(is_instance_valid(game.world),area+" world starts")
		check(is_instance_valid(game.audio.music_player.stream),area+" music is bundled")
	print("EXPORT PACK: %s"%["FAIL" if failed else "PASS"])
	game.audio.shutdown();game.queue_free();game=null
	for i in range(12): await physics_frame
	quit(1 if failed else 0)
