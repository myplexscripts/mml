extends SceneTree

const OUTPUT_DIR := "res://build/screenshots"

var game


func _init() -> void:
	call_deferred("run")


func frames(count: int = 8) -> void:
	for i in range(count):
		await process_frame


func capture(name: String) -> void:
	await frames(18)
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save screenshot %s: %s" % [path, error_string(error)])
	else:
		print("SCREENSHOT: ", path)


func show_area(area: String, spawn: Vector3, depth: int = 1) -> void:
	game.mode = "game"
	game.menu_return_title = false
	game.transition.clear()
	game.fading_in = false
	game.fade = 0.0
	game.ui.clear_overlay()
	game.build_area(area, depth, spawn)
	game.mode = "game"
	game.ui.clear_overlay()
	await frames(24)


func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DisplayServer.window_set_size(Vector2i(1280, 720))

	game = load("res://scenes/legends.tscn").instantiate()
	root.add_child(game)
	await frames(30)

	# The real current title screen and its landing-area background.
	await capture("01-title")

	# Current playable Flutter landing area.
	game.state.repair = 2
	game.state.quest_started = true
	await show_area("island", Vector3(0, 0, 8))
	game.player.position = Vector3(-1.5, 0, 7.0)
	await capture("02-flutter-landing")

	# Flutter interior.
	await show_area("cabin", Vector3(0, 0, 3))
	game.player.position = Vector3(0, 0, 2.5)
	await capture("03-flutter-cabin")

	# Current Northern Ruins layout and combat presentation.
	await show_area("ruins", Vector3(0, 0, 10.5), 1)
	game.player.position = Vector3(0, 0, 9.5)
	await capture("04-northern-ruins")

	# Current Bonne/Feldynaught combat arena.
	game.state.tron_defeated = false
	await show_area("bonne", Vector3(0, 0, 6.5))
	game.player.position = Vector3(0, 0, 6.0)
	await capture("05-bonne-showdown")

	game.audio.shutdown()
	game.queue_free()
	await frames(8)
	quit()
