extends "res://scripts/legends/actor.gd"

const VISUAL_FALLBACK := {
	"hanmuru": "guardian",
	"bonbonne": "guardian",
	"marlwolf": "feldynaught",
	"balcon": "guardian",
	"garudoriten": "guardian",
	"karumuna": "guardian",
	"gesellschaft": "drache",
	"fokkerwolf": "drache",
	"juno": "guardian",
}

var logical_kind: String = ""
var weakpoint_notice_cooldown: float = 0.0
var special_clock: float = 0.0


func _ready() -> void:
	logical_kind = kind
	if VISUAL_FALLBACK.has(kind):
		kind = String(VISUAL_FALLBACK[kind])
	super._ready()
	kind = logical_kind
	if boss:
		match kind:
			"marlwolf":
				visual.scale *= Vector3(1.45, .92, 1.75)
			"balcon":
				visual.scale *= Vector3(1.35, .78, 1.55)
			"garudoriten":
				visual.scale *= Vector3(.92, 1.2, .92)
			"karumuna":
				visual.scale *= Vector3(1.1, 1.25, 1.1)
			"bonbonne":
				visual.scale *= Vector3(1.2, 1.15, 1.2)


func _physics_process(delta: float) -> void:
	weakpoint_notice_cooldown = maxf(0.0, weakpoint_notice_cooldown - delta)
	special_clock += delta
	super._physics_process(delta)


func enemy_step(delta: float) -> void:
	match kind:
		"marlwolf":
			_marlwolf_step(delta)
		"garudoriten":
			_garudoriten_step(delta)
		"balcon":
			_balcon_step(delta)
		"karumuna":
			_karumuna_step(delta)
		_:
			super.enemy_step(delta)


func _marlwolf_step(delta: float) -> void:
	# Marlwolf keeps its front armour aimed at MegaMan and alternates cannon
	# volleys with a slow tread advance. The rear hatch is handled in hurt().
	cooldown -= delta
	var distance := position.distance_to(game.player.position)
	var direction := flat_direction(game.player.position)
	facing = direction
	var travel := knockback
	knockback = knockback.move_toward(Vector3.ZERO, 10.0 * delta)
	if phase == "windup":
		timer -= delta
		if timer <= 0.0:
			phase = "attack"
			timer = .72
			attack_count += 1
			for spread in [-.18, 0.0, .18]:
				var shot_dir := direction.rotated(Vector3.UP, spread)
				game.shoot(position + Vector3.UP * 1.5 + shot_dir * 1.5, shot_dir * 8.5, true, 15)
			game.audio.effect("mech_shot", .82)
	elif phase == "attack":
		timer -= delta
		travel += direction * (2.8 if attack_count % 2 == 0 else .6)
		if timer <= 0.0:
			phase = "recover"
			timer = 1.0
	elif phase == "recover":
		timer -= delta
		if timer <= 0.0:
			phase = "idle"
			cooldown = .65
	elif distance < 19.0 and cooldown <= 0.0:
		phase = "windup"
		timer = .72
	velocity.x = travel.x
	velocity.z = travel.z
	Models.pose(visual, clock * 4.0, travel.length() > .2)


func _garudoriten_step(delta: float) -> void:
	# Its exposed eye opens only after an attack. The visual pulse communicates
	# the vulnerability window in the fixed top-down camera.
	super.enemy_step(delta)
	if phase == "recover":
		visual.scale = Vector3.ONE * (1.0 + sin(special_clock * 10.0) * .035)
	else:
		visual.scale = Vector3.ONE


func _balcon_step(delta: float) -> void:
	# The lake boss stays off the edge of the boat and fires readable missile
	# fans inward rather than trying to occupy the tiny player deck.
	cooldown -= delta
	facing = flat_direction(game.player.position)
	velocity = Vector3.ZERO
	if cooldown <= 0.0:
		cooldown = 1.15 if health > max_health / 2 else .72
		attack_count += 1
		var count := 3 if health > max_health / 2 else 5
		for i in range(count):
			var spread := (float(i) - float(count - 1) * .5) * .16
			var direction := facing.rotated(Vector3.UP, spread)
			game.shoot(position + Vector3.UP * 1.2 + direction, direction * 6.2, true, 13)
		game.audio.effect("mech_shot", .92)
	Models.pose(visual, clock * 3.0, false)


func _karumuna_step(delta: float) -> void:
	# Karumuna Bash pressures the elevator room with radial volleys and charges.
	super.enemy_step(delta)
	if boss and phase == "attack" and attack_count % 2 == 0:
		visual.rotation.x = sin(special_clock * 14.0) * .035
	else:
		visual.rotation.x = 0.0


func hurt(damage: int, from: Vector3) -> void:
	if role != "enemy" or defeated:
		super.hurt(damage, from)
		return
	if kind == "marlwolf" and boss:
		var incoming := flat_direction(from)
		# facing points toward the front of the machine. Hits from the opposite
		# direction reach the rear hatch and deal full damage.
		var rear_hit := incoming.dot(facing) < -.28
		if not rear_hit:
			if weakpoint_notice_cooldown <= 0.0:
				game.toast("Roll: Its front armour is too thick. Get behind Marlwolf and hit the rear hatch!")
				weakpoint_notice_cooldown = 2.2
			damage = maxi(1, int(damage * .14))
	elif kind == "garudoriten" and boss and phase != "recover":
		if weakpoint_notice_cooldown <= 0.0:
			game.toast("Roll: The eye is sealed. Wait for Garudoriten to attack, then hit it while the eye is exposed!")
			weakpoint_notice_cooldown = 2.0
		damage = maxi(1, int(damage * .08))
	super.hurt(damage, from)
