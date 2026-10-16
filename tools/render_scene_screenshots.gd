extends SceneTree

const OUTPUT_DIR := "res://build/screenshots"

var game
var watchdog: Timer


func _initialize() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	watchdog = Timer.new()
	watchdog.one_shot = true
	watchdog.wait_time = 75.0
	watchdog.timeout.connect(func():
		push_error("Screenshot renderer timed out")
		quit(1)
	)
	root.add_child(watchdog)
	watchdog.start()
	call_deferred("_render_all")


func frames(count: int = 4) -> void:
	for i in range(count):
		await process_frame


func capture(name: String) -> void:
	await frames(4)
	RenderingServer.force_draw()
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save screenshot %s: %s" % [path, error_string(error)])
		quit(1)
		return
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
	await frames(6)


func _render_all() -> void:
	game = load("res://scenes/legends.tscn").instantiate()
	root.add_child(game)
	game.state.music = false
	game.state.sound = false
	game.audio.playback_enabled = false
	game.audio.shutdown()
	await frames(8)

	await capture("01-title")

	game.state.repair = 2
	game.state.quest_started = true
	await show_area("island", Vector3(0, 0, 8))
	game.player.position = Vector3(-1.5, 0, 7.0)
	await capture("02-flutter-landing")

	await show_area("cabin", Vector3(0, 0, 3))
	game.player.position = Vector3(0, 0, 2.5)
	await capture("03-flutter-cabin")

	await show_area("ruins", Vector3(0, 0, 10.5), 1)
	game.player.position = Vector3(0, 0, 9.5)
	await capture("04-northern-ruins")

	game.state.tron_defeated = false
	await show_area("bonne", Vector3(0, 0, 6.5))
	game.player.position = Vector3(0, 0, 6.0)
	await capture("05-bonne-showdown")

	watchdog.stop()
	game.audio.shutdown()
	game.queue_free()
	await frames(3)
	quit()
