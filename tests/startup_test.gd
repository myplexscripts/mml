extends SceneTree
## Boot the real main scene and close through the game's normal shutdown path.
var game

func _init() -> void: call_deferred("run")

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(120): await process_frame
	if game.mode!="title" or not is_instance_valid(game.ui.overlay.find_child("ContinueAdventure",true,false)):
		push_error("Startup did not reach the title screen")
		quit(1);return
	print("STARTUP: PASS")
	game.quit_game()
