extends SceneTree
## Play the Bonne fight using normal movement, lock-on and Buster inputs.
## No damage overrides, stat cheats, frozen enemies or teleports during combat.
var game
func _init() -> void: call_deferred("run")

func steer(direction: Vector2) -> void:
	for action in ["move_left","move_right","move_up","move_down"]: Input.action_release(action)
	if direction.x<-.1: Input.action_press("move_left",absf(direction.x))
	if direction.x>.1: Input.action_press("move_right",absf(direction.x))
	if direction.y<-.1: Input.action_press("move_up",absf(direction.y))
	if direction.y>.1: Input.action_press("move_down",absf(direction.y))

func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await physics_frame
	game.mode="game";game.state.quest_started=true;game.state.repair=2
	game.build_area("bonne",1,Vector2(320,340))
	Input.action_press("lock");Input.action_press("fire")
	var won: bool=false
	for frame in range(1800):
		if game.state.tron_defeated:
			won=true;break
		if game.mode!="game": break
		# Strafe around the arena. Telegraphs indicate when to dash away.
		var angle: float=frame*.017
		var destination:=Vector2(320+sin(angle)*175,285+cos(angle)*103)
		var direction: Vector2=game.player.position.direction_to(destination)
		steer(direction)
		if game.state.health<45 and game.state.items.heal>0: game.use_heal()
		var threat=game.nearest_enemy(game.player.position,110)
		if is_instance_valid(threat) and threat.phase=="windup" and game.player.dash_cooldown<=0:
			Input.action_press("dash")
		else: Input.action_release("dash")
		await physics_frame
	for action in ["move_left","move_right","move_up","move_down","fire","lock","dash"]: Input.action_release(action)
	print("COMBAT PLAYTEST: %s. Health %d, bottles %d, score %d."%["PASS" if won else "FAIL",game.state.health,game.state.items.heal,game.state.score])
	game.audio.shutdown();game.queue_free();game=null
	for i in range(12): await process_frame
	quit(0 if won else 1)
