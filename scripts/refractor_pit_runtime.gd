extends Node2D

const W: float = 1280.0
const H: float = 720.0
const ARENA: Rect2 = Rect2(170.0, 48.0, 940.0, 610.0)
const COMBAT_BOUNDS: Rect2 = Rect2(220.0, 510.0, 840.0, 120.0)
const TOP_Y: float = 82.0
const RETURN_Y: float = 650.0
const ENEMY_FRONT_Y: float = 522.0

const C_TEXT: Color = Color("f4f8fb")
const C_MUTED: Color = Color("a4b5c4")
const C_BLUE: Color = Color("58d8ff")
const C_BLUE_DARK: Color = Color("17394f")
const C_GREEN: Color = Color("8ef0a1")
const C_GOLD: Color = Color("ffd26a")
const C_DANGER: Color = Color("ff665e")
const C_PANEL: Color = Color(0.025, 0.045, 0.07, 0.94)
const C_PANEL_HOT: Color = Color(0.06, 0.105, 0.15, 0.98)

const TEX_MM: Texture2D = preload("res://assets/characters/megaman.png")
const TEX_ROLL: Texture2D = preload("res://assets/characters/roll.png")
const TEX_DATA: Texture2D = preload("res://assets/characters/data.png")
const TEX_HOROKKO: Texture2D = preload("res://assets/characters/horokko.png")
const TEX_ZAKOBON: Texture2D = preload("res://assets/characters/zakobon.png")
const TEX_SHARUKURUSU: Texture2D = preload("res://assets/characters/sharukurusu.png")
const TEX_GUARDIAN: Texture2D = preload("res://assets/characters/guardian.png")
const TEX_RUIN_FLOOR: Texture2D = preload("res://assets/world/ruin_floor.png")
const TEX_RUIN_PILLAR: Texture2D = preload("res://assets/world/ruin_pillar.png")
const TEX_RUIN_PANEL: Texture2D = preload("res://assets/world/ruin_panel.png")
const TEX_RUIN_ENTRANCE: Texture2D = preload("res://assets/world/ruin_entrance.png")
const TEX_WORKBENCH: Texture2D = preload("res://assets/world/workbench.png")
const TEX_SALVAGE: Texture2D = preload("res://assets/world/salvage.png")
const TEX_RELIC: Texture2D = preload("res://assets/world/relic_display.png")

const SFX_BUSTER: AudioStream = preload("res://assets/audio/buster.ogg")
const SFX_HIT: AudioStream = preload("res://assets/audio/hit.ogg")
const SFX_BOUNCE: AudioStream = preload("res://assets/audio/bounce.ogg")
const SFX_ITEM: AudioStream = preload("res://assets/audio/item.ogg")
const SFX_HURT: AudioStream = preload("res://assets/audio/hurt.ogg")
const SFX_EXPLOSION: AudioStream = preload("res://assets/audio/explosion.ogg")
const MUSIC_RUINS: AudioStream = preload("res://assets/audio/kattelox_ruins.ogg")
const MUSIC_BOSS: AudioStream = preload("res://assets/audio/boss.ogg")

const BASE_PROGRAMS: Array[String] = ["flame", "cryo", "arc", "heavy", "phase", "shockwave", "splitter", "leech"]
const PROGRAM_ORDER: Array[String] = ["standard", "flame", "cryo", "arc", "heavy", "phase", "shockwave", "splitter", "leech"]

const DEVELOPMENT_RECIPES: Array[Dictionary] = [
    {"a":"flame", "b":"heavy", "result":"grenade_arm", "label":"GRENADE ARM"},
    {"a":"cryo", "b":"arc", "result":"storm_buster", "label":"STORM BUSTER"},
    {"a":"shockwave", "b":"heavy", "result":"drill_arm", "label":"DRILL ARM"},
    {"a":"splitter", "b":"arc", "result":"active_buster", "label":"ACTIVE BUSTER"},
    {"a":"phase", "b":"leech", "result":"vacuum_buster", "label":"VACUUM BUSTER"},
    {"a":"flame", "b":"cryo", "result":"thermal_fracture", "label":"THERMAL FRACTURE"},
]

var mode: String = "menu"
var menu_index: int = 0
var upgrade_index: int = 0
var terminal_index: int = 0
var workshop_index: int = 0

var player_pos: Vector2 = Vector2(640.0, 596.0)
var aim_angle: float = -PI / 2.0
var auto_fire: bool = true
var fire_timer: float = 0.0
var fire_cursor: int = 0

var shot_slots: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var next_enemy_id: int = 1

var run_time: float = 0.0
var wave_timer: float = 0.0
var wave_index: int = 0
var miniboss_spawned: bool = false
var boss_spawned: bool = false
var boss_defeated: bool = false
var score: int = 0
var kills: int = 0
var level: int = 1
var combat_data: float = 0.0
var combat_data_next: float = 24.0
var pending_levelups: int = 0
var life: float = 100.0
var max_life: float = 100.0
var zenny: int = 0
var refractors: int = 0
var terminal_charge: float = 0.0
var terminal_threshold: float = 100.0

var buster: Dictionary = {
    "attack": 1,
    "energy": 1,
    "range": 1,
    "rapid": 1,
    "ricochet": 0,
    "bounce_amp": 0,
}
var program_levels: Dictionary = {}
var linked_pairs: Array[String] = []
var evolved_owned: Array[String] = []
var upgrade_choices: Array[Dictionary] = []
var terminal_options: Array[Dictionary] = []

var bank: Dictionary = {"zenny": 0, "refractors": 0}
var permanent: Dictionary = {"attack": 0, "energy": 0, "rapid": 0, "life": 0}

var message: String = ""
var message_timer: float = 0.0
var radio_speaker: String = ""
var radio_text: String = ""
var radio_timer: float = 0.0
var screen_flash: float = 0.0
var shake: float = 0.0

var music: AudioStreamPlayer
var sfx_buster: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_bounce: AudioStreamPlayer
var sfx_item: AudioStreamPlayer
var sfx_hurt: AudioStreamPlayer
var sfx_explosion: AudioStreamPlayer

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    randomize()
    setup_audio()
    load_save()
    initialise_program_levels()
    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.has("--self-test"):
        call_deferred("run_self_test")
    elif args.has("--capture-screens"):
        call_deferred("capture_sequence")
    queue_redraw()

func setup_audio() -> void:
    music = AudioStreamPlayer.new()
    add_child(music)
    music.stream = MUSIC_RUINS
    music.volume_db = -13.0
    music.finished.connect(_on_music_finished)
    sfx_buster = make_audio_player(SFX_BUSTER, -7.0)
    sfx_hit = make_audio_player(SFX_HIT, -8.0)
    sfx_bounce = make_audio_player(SFX_BOUNCE, -10.0)
    sfx_item = make_audio_player(SFX_ITEM, -8.0)
    sfx_hurt = make_audio_player(SFX_HURT, -7.0)
    sfx_explosion = make_audio_player(SFX_EXPLOSION, -6.0)

func make_audio_player(stream: AudioStream, volume: float) -> AudioStreamPlayer:
    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.volume_db = volume
    add_child(player)
    return player

func _on_music_finished() -> void:
    if mode == "run":
        music.play()

func play_music(stream: AudioStream) -> void:
    if music.stream != stream:
        music.stop()
        music.stream = stream
    if not music.playing:
        music.play()

func play_sfx(player: AudioStreamPlayer) -> void:
    if player != null:
        player.play()

func initialise_program_levels() -> void:
    program_levels.clear()
    for key: String in BASE_PROGRAMS:
        program_levels[key] = 0
    program_levels["standard"] = 1

func _process(delta: float) -> void:
    screen_flash = maxf(0.0, screen_flash - delta * 3.8)
    shake = maxf(0.0, shake - delta * 24.0)
    message_timer = maxf(0.0, message_timer - delta)
    radio_timer = maxf(0.0, radio_timer - delta)
    if mode == "run":
        update_run(delta)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and mode == "run":
        update_aim(event.position)
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT and mode == "run":
            fire_one_ready_slot(true)
        elif event.button_index == MOUSE_BUTTON_LEFT and mode == "menu":
            if event.position.y >= 420.0 and event.position.y <= 480.0:
                menu_index = 0
                activate_menu()
            elif event.position.y >= 494.0 and event.position.y <= 554.0:
                menu_index = 1
                activate_menu()
    if event is InputEventKey and event.pressed and not event.echo:
        var key: int = int(event.keycode)
        if mode == "menu":
            if key == KEY_UP or key == KEY_W:
                menu_index = maxi(0, menu_index - 1)
            elif key == KEY_DOWN or key == KEY_S:
                menu_index = mini(1, menu_index + 1)
            elif key == KEY_ENTER or key == KEY_SPACE:
                activate_menu()
        elif mode == "run":
            if key == KEY_F:
                auto_fire = not auto_fire
                show_message("AUTO FIRE: %s" % ("ON" if auto_fire else "OFF"), 1.0)
            elif key == KEY_SPACE:
                fire_one_ready_slot(true)
            elif key == KEY_ESCAPE:
                finish_run(false)
        elif mode == "levelup":
            if key == KEY_LEFT or key == KEY_A:
                upgrade_index = wrapi(upgrade_index - 1, 0, upgrade_choices.size())
            elif key == KEY_RIGHT or key == KEY_D:
                upgrade_index = wrapi(upgrade_index + 1, 0, upgrade_choices.size())
            elif key == KEY_ENTER or key == KEY_SPACE:
                apply_upgrade(upgrade_index)
        elif mode == "terminal":
            if key == KEY_LEFT or key == KEY_A:
                move_terminal_selection(-1)
            elif key == KEY_RIGHT or key == KEY_D:
                move_terminal_selection(1)
            elif key == KEY_ENTER or key == KEY_SPACE:
                apply_terminal_option(terminal_index)
        elif mode == "workshop":
            if key == KEY_LEFT or key == KEY_A:
                workshop_index = wrapi(workshop_index - 1, 0, 4)
            elif key == KEY_RIGHT or key == KEY_D:
                workshop_index = wrapi(workshop_index + 1, 0, 4)
            elif key == KEY_ENTER or key == KEY_SPACE:
                var keys: Array[String] = ["attack", "energy", "rapid", "life"]
                buy_permanent(keys[workshop_index])
            elif key == KEY_ESCAPE:
                mode = "menu"
        elif mode == "gameover" or mode == "victory":
            if key == KEY_ENTER or key == KEY_SPACE:
                mode = "menu"
                play_music(MUSIC_RUINS)

func activate_menu() -> void:
    if menu_index == 0:
        new_run()
    else:
        mode = "workshop"

func new_run() -> void:
    projectiles.clear()
    enemies.clear()
    enemy_shots.clear()
    pickups.clear()
    effects.clear()
    shot_slots.clear()
    linked_pairs.clear()
    evolved_owned.clear()
    initialise_program_levels()
    player_pos = Vector2(640.0, 596.0)
    aim_angle = -PI / 2.0
    auto_fire = true
    fire_timer = 0.12
    fire_cursor = 0
    run_time = 0.0
    wave_timer = 0.15
    wave_index = 0
    miniboss_spawned = false
    boss_spawned = false
    boss_defeated = false
    score = 0
    kills = 0
    level = 1
    combat_data = 0.0
    combat_data_next = 24.0
    pending_levelups = 0
    max_life = 100.0 + float(int(permanent["life"])) * 12.0
    life = max_life
    zenny = 0
    refractors = 0
    terminal_charge = 0.0
    buster = {
        "attack": 1 + int(permanent["attack"]),
        "energy": 1 + int(permanent["energy"]),
        "range": 1,
        "rapid": 1 + int(permanent["rapid"]),
        "ricochet": 0,
        "bounce_amp": 0,
    }
    for i: int in range(5):
        add_shot_slot("standard", 1)
    program_levels["flame"] = 1
    add_shot_slot("flame", 1)
    mode = "run"
    play_music(MUSIC_RUINS)
    show_message("OCEAN TOWER DIG START", 1.6)
    show_radio("ROLL", "I'm reading a lot of Reaverbot activity ahead. Keep moving, MegaMan!", 4.0)

func update_run(delta: float) -> void:
    run_time += delta
    update_player(delta)
    update_slot_cooldowns(delta)
    update_projectiles(delta)
    update_enemies(delta)
    update_enemy_shots(delta)
    update_pickups(delta)
    update_effects(delta)

    if mode != "run":
        return

    if auto_fire:
        fire_timer -= delta
        if fire_timer <= 0.0:
            fire_one_ready_slot(false)
            fire_timer = fire_interval()

    if not boss_spawned:
        wave_timer -= delta
        if wave_timer <= 0.0:
            spawn_wave()
            wave_timer = maxf(2.0, 4.5 - run_time * 0.018)

    if not miniboss_spawned and run_time >= 36.0:
        miniboss_spawned = true
        spawn_miniboss()
        show_radio("ROLL", "Large signal! That's not one of the little ones!", 3.5)

    if not boss_spawned and run_time >= 82.0:
        boss_spawned = true
        enemies.clear()
        enemy_shots.clear()
        spawn_boss()
        play_music(MUSIC_BOSS)
        show_message("WARNING - HANMURU DOLL", 2.2)
        show_radio("ROLL", "MegaMan, that's the guardian! Get your shots behind it if you can!", 4.2)

    if terminal_charge >= terminal_threshold and not boss_spawned:
        open_terminal()

func update_player(delta: float) -> void:
    var movement := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        movement.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        movement.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        movement.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        movement.y += 1.0
    if movement.length_squared() > 0.0:
        movement = movement.normalized()
        player_pos += movement * 235.0 * delta
        player_pos.x = clampf(player_pos.x, COMBAT_BOUNDS.position.x, COMBAT_BOUNDS.end.x)
        player_pos.y = clampf(player_pos.y, COMBAT_BOUNDS.position.y, COMBAT_BOUNDS.end.y)

func update_aim(mouse: Vector2) -> void:
    var vector := mouse - player_pos
    if vector.length() > 8.0 and vector.y < 16.0:
        aim_angle = clampf(vector.angle(), -PI + 0.08, -0.08)

func fire_interval() -> float:
    return maxf(0.09, 0.38 * pow(0.88, float(int(buster["rapid"]) - 1)))

func add_shot_slot(program: String, level_value: int, effects_override: Array = []) -> void:
    var effects_list: Array = effects_override.duplicate()
    if effects_list.is_empty():
        effects_list = components_for_program(program)
    shot_slots.append({
        "program": program,
        "name": program_label(program),
        "level": level_value,
        "effects": effects_list,
        "state": "ready",
        "cooldown": 0.0,
    })

func ensure_program_slot(program: String) -> void:
    for slot: Dictionary in shot_slots:
        if str(slot["program"]) == program:
            return
    add_shot_slot(program, int(program_levels.get(program, 1)))

func update_slot_cooldowns(delta: float) -> void:
    for slot: Dictionary in shot_slots:
        if str(slot["state"]) == "cooldown":
            slot["cooldown"] = float(slot["cooldown"]) - delta
            if float(slot["cooldown"]) <= 0.0:
                slot["state"] = "ready"
                slot["cooldown"] = 0.0

func fire_one_ready_slot(manual: bool) -> bool:
    if mode != "run" or shot_slots.is_empty():
        return false
    for offset: int in range(shot_slots.size()):
        var index: int = (fire_cursor + offset) % shot_slots.size()
        var slot: Dictionary = shot_slots[index]
        if str(slot["state"]) == "ready":
            launch_slot(index, manual)
            fire_cursor = (index + 1) % shot_slots.size()
            return true
    return false

func launch_slot(slot_index: int, manual: bool) -> void:
    if slot_index < 0 or slot_index >= shot_slots.size():
        return
    var slot: Dictionary = shot_slots[slot_index]
    slot["state"] = "active"
    var direction := Vector2(cos(aim_angle), sin(aim_angle)).normalized()
    var effects_list: Array = slot["effects"].duplicate()
    var level_value: int = int(slot["level"])
    var speed: float = 510.0 + float(int(buster["energy"]) - 1) * 24.0
    if effects_list.has("heavy") or effects_list.has("drill_arm"):
        speed *= 0.78
    var damage: float = (11.0 + float(int(buster["attack"]) - 1) * 4.5) * program_damage_multiplier(effects_list, level_value)
    var radius: float = 7.0
    if effects_list.has("heavy") or effects_list.has("grenade_arm") or effects_list.has("drill_arm"):
        radius = 11.5
    var wall_bounces: int = 2 + int(buster["range"]) + int(buster["ricochet"])
    projectiles.append({
        "slot": slot_index,
        "pos": player_pos + direction * 34.0,
        "last": player_pos + direction * 20.0,
        "vel": direction * speed,
        "mode": "active",
        "life": 3.8 + float(int(buster["range"])) * 0.42,
        "damage": damage,
        "radius": radius,
        "wall_bounces": wall_bounces,
        "effects": effects_list,
        "level": level_value,
        "hit_cooldowns": {},
        "spawned": false,
        "homing": effects_list.has("active_buster"),
        "manual": manual,
    })
    effects.append({"type":"muzzle", "pos":player_pos + direction * 36.0, "t":0.13})
    play_sfx(sfx_buster)

func program_damage_multiplier(effects_list: Array, level_value: int) -> float:
    var mult: float = 1.0 + float(level_value - 1) * 0.20
    if effects_list.has("heavy"):
        mult *= 1.75
    if effects_list.has("phase"):
        mult *= 0.82
    if effects_list.has("drill_arm"):
        mult *= 2.05
    if effects_list.has("grenade_arm"):
        mult *= 1.35
    if effects_list.has("thermal_fracture"):
        mult *= 1.25
    return mult

func update_projectiles(delta: float) -> void:
    for i: int in range(projectiles.size() - 1, -1, -1):
        var shot: Dictionary = projectiles[i]
        var cooldowns: Dictionary = shot["hit_cooldowns"]
        for key: Variant in cooldowns.keys():
            cooldowns[key] = float(cooldowns[key]) - delta
            if float(cooldowns[key]) <= 0.0:
                cooldowns.erase(key)

        if str(shot["mode"]) == "returning":
            var pos: Vector2 = shot["pos"]
            var to_player := player_pos - pos
            if to_player.length() <= 24.0:
                recharge_slot(int(shot["slot"]))
                effects.append({"type":"return", "pos":player_pos, "t":0.18})
                projectiles.remove_at(i)
                continue
            shot["last"] = pos
            shot["pos"] = pos + to_player.normalized() * 900.0 * delta
            continue

        var pos: Vector2 = shot["pos"]
        var velocity: Vector2 = shot["vel"]
        shot["last"] = pos

        if bool(shot["homing"]) and not enemies.is_empty():
            var target := nearest_enemy(pos)
            if not target.is_empty():
                var target_pos: Vector2 = target["pos"]
                var desired: Vector2 = (target_pos - pos).normalized() * velocity.length()
                velocity = velocity.lerp(desired, minf(1.0, delta * 1.8))

        pos += velocity * delta
        shot["life"] = float(shot["life"]) - delta
        var bounced: bool = false

        if pos.x < ARENA.position.x + 12.0:
            pos.x = ARENA.position.x + 12.0
            velocity.x = absf(velocity.x)
            bounced = true
        elif pos.x > ARENA.end.x - 12.0:
            pos.x = ARENA.end.x - 12.0
            velocity.x = -absf(velocity.x)
            bounced = true
        if pos.y < TOP_Y:
            pos.y = TOP_Y
            velocity.y = absf(velocity.y)
            bounced = true

        if bounced:
            shot["wall_bounces"] = int(shot["wall_bounces"]) - 1
            var amp: float = 1.0 + float(int(buster["bounce_amp"])) * 0.10
            shot["damage"] = float(shot["damage"]) * amp
            effects.append({"type":"spark", "pos":pos, "t":0.15})
            play_sfx(sfx_bounce)

        shot["pos"] = pos
        shot["vel"] = velocity
        handle_projectile_enemy_hits(shot)

        if str(shot["mode"]) == "returning":
            continue
        if float(shot["life"]) <= 0.0 or int(shot["wall_bounces"]) < 0 or pos.y > RETURN_Y:
            if int(shot["slot"]) >= 0:
                shot["mode"] = "returning"
            else:
                projectiles.remove_at(i)

func handle_projectile_enemy_hits(shot: Dictionary) -> void:
    var pos: Vector2 = shot["pos"]
    var radius: float = float(shot["radius"])
    var effects_list: Array = shot["effects"]
    var cooldowns: Dictionary = shot["hit_cooldowns"]
    for enemy: Dictionary in enemies:
        var enemy_id: int = int(enemy["id"])
        if cooldowns.has(enemy_id):
            continue
        var enemy_pos: Vector2 = enemy["pos"]
        if pos.distance_to(enemy_pos) > radius + float(enemy["radius"]):
            continue
        cooldowns[enemy_id] = 0.13 if is_piercing(effects_list) else 0.22
        var dealt: float = damage_enemy(enemy, float(shot["damage"]), pos, effects_list)
        apply_program_effects(shot, enemy, dealt)
        effects.append({"type":"hit", "pos":pos, "t":0.17})
        shake = maxf(shake, 6.0 if bool(enemy["boss"]) else 2.5)
        screen_flash = maxf(screen_flash, 0.10)
        play_sfx(sfx_hit)
        if not is_piercing(effects_list):
            var normal: Vector2 = (pos - enemy_pos).normalized()
            if normal.length_squared() < 0.1:
                normal = Vector2.UP
            shot["vel"] = Vector2(shot["vel"]).bounce(normal)
            shot["pos"] = enemy_pos + normal * (float(enemy["radius"]) + radius + 2.0)
        if not is_piercing(effects_list):
            break

func is_piercing(effects_list: Array) -> bool:
    return effects_list.has("phase") or effects_list.has("drill_arm")

func damage_enemy(enemy: Dictionary, amount: float, impact_pos: Vector2, effects_list: Array) -> float:
    var final_amount: float = amount
    var enemy_pos: Vector2 = enemy["pos"]
    if float(enemy["armor"]) > 0.0 and not effects_list.has("heavy") and not effects_list.has("drill_arm"):
        final_amount *= 1.0 - float(enemy["armor"])
    if float(enemy["shield"]) > 0.0 and impact_pos.y > enemy_pos.y and not effects_list.has("phase") and not effects_list.has("drill_arm"):
        final_amount *= 1.0 - float(enemy["shield"])
    enemy["hp"] = float(enemy["hp"]) - final_amount
    return final_amount

func apply_program_effects(shot: Dictionary, enemy: Dictionary, dealt: float) -> void:
    var effects_list: Array = shot["effects"]
    var level_value: int = int(shot["level"])
    if effects_list.has("flame"):
        enemy["burn"] = minf(8.0, float(enemy["burn"]) + 1.0 + float(level_value) * 0.45)
        enemy["burn_time"] = 4.0
    if effects_list.has("cryo"):
        enemy["slow_time"] = maxf(float(enemy["slow_time"]), 2.0 + float(level_value) * 0.45)
        enemy["slow"] = maxf(float(enemy["slow"]), 0.35 + float(level_value) * 0.08)
        if level_value >= 3 and randf() < 0.18:
            enemy["frozen"] = maxf(float(enemy["frozen"]), 0.75)
    if effects_list.has("arc"):
        chain_damage(enemy, dealt * (0.42 + float(level_value) * 0.08), 1 + level_value / 2)
    if effects_list.has("shockwave"):
        area_damage(enemy["pos"], 68.0 + float(level_value) * 12.0, dealt * 0.45, int(enemy["id"]), effects_list)
    if effects_list.has("splitter") and not bool(shot["spawned"]):
        shot["spawned"] = true
        spawn_splitter_children(enemy["pos"], shot, 2 + level_value)
    if effects_list.has("leech"):
        life = minf(max_life, life + maxf(0.5, dealt * (0.025 + float(level_value) * 0.008)))
    if effects_list.has("grenade_arm"):
        area_damage(enemy["pos"], 95.0, dealt * 0.72, int(enemy["id"]), ["flame"])
        enemy["burn"] = minf(8.0, float(enemy["burn"]) + 2.0)
        enemy["burn_time"] = 4.5
        effects.append({"type":"burst", "pos":enemy["pos"], "t":0.32})
        play_sfx(sfx_explosion)
    if effects_list.has("storm_buster"):
        enemy["slow_time"] = maxf(float(enemy["slow_time"]), 3.0)
        enemy["slow"] = maxf(float(enemy["slow"]), 0.55)
        chain_damage(enemy, dealt * 0.68, 3)
    if effects_list.has("drill_arm"):
        area_damage(enemy["pos"], 48.0, dealt * 0.25, int(enemy["id"]), [])
    if effects_list.has("active_buster") and not bool(shot["spawned"]):
        shot["spawned"] = true
        spawn_homing_children(enemy["pos"], shot, 3)
    if effects_list.has("vacuum_buster"):
        life = minf(max_life, life + maxf(1.0, dealt * 0.055))
        attract_pickups(150.0)
    if effects_list.has("thermal_fracture"):
        enemy["burn"] = minf(8.0, float(enemy["burn"]) + 1.5)
        enemy["burn_time"] = 4.0
        enemy["slow_time"] = maxf(float(enemy["slow_time"]), 2.5)
        enemy["slow"] = maxf(float(enemy["slow"]), 0.50)
        area_damage(enemy["pos"], 78.0, dealt * 0.48, int(enemy["id"]), [])

func chain_damage(source: Dictionary, amount: float, count: int) -> void:
    var source_pos: Vector2 = source["pos"]
    var used: Array[int] = []
    for step: int in range(count):
        var best_enemy: Dictionary = {}
        var best_distance: float = INF
        for enemy: Dictionary in enemies:
            var enemy_id: int = int(enemy["id"])
            if enemy_id == int(source["id"]) or used.has(enemy_id):
                continue
            var enemy_pos: Vector2 = enemy["pos"]
            var distance: float = source_pos.distance_to(enemy_pos)
            if distance <= 155.0 and distance < best_distance:
                best_distance = distance
                best_enemy = enemy
        if best_enemy.is_empty():
            break
        var target_pos: Vector2 = best_enemy["pos"]
        best_enemy["hp"] = float(best_enemy["hp"]) - amount
        used.append(int(best_enemy["id"]))
        effects.append({"type":"arc", "a":source_pos, "b":target_pos, "t":0.12})
        source_pos = target_pos

func area_damage(origin: Vector2, radius: float, amount: float, ignore_id: int, effect_tags: Array) -> void:
    effects.append({"type":"ring", "pos":origin, "r":radius, "t":0.22})
    for enemy: Dictionary in enemies:
        if int(enemy["id"]) == ignore_id:
            continue
        var enemy_pos: Vector2 = enemy["pos"]
        if origin.distance_to(enemy_pos) <= radius + float(enemy["radius"]):
            damage_enemy(enemy, amount, origin, effect_tags)
            if effect_tags.has("flame"):
                enemy["burn"] = minf(8.0, float(enemy["burn"]) + 1.0)
                enemy["burn_time"] = 3.0

func spawn_splitter_children(origin: Vector2, parent: Dictionary, count: int) -> void:
    var base_angle: float = Vector2(parent["vel"]).angle()
    for i: int in range(count):
        var angle: float = base_angle + (float(i) - float(count - 1) * 0.5) * 0.32
        spawn_child_projectile(origin, Vector2(cos(angle), sin(angle)), ["standard"], float(parent["damage"]) * 0.42, false)

func spawn_homing_children(origin: Vector2, parent: Dictionary, count: int) -> void:
    for i: int in range(count):
        var angle: float = -PI * 0.82 + float(i) * (PI * 0.64 / maxf(1.0, float(count - 1)))
        spawn_child_projectile(origin, Vector2(cos(angle), sin(angle)), ["standard"], float(parent["damage"]) * 0.55, true)

func spawn_child_projectile(origin: Vector2, direction: Vector2, effect_tags: Array, damage: float, homing: bool) -> void:
    projectiles.append({
        "slot": -1,
        "pos": origin,
        "last": origin,
        "vel": direction.normalized() * 470.0,
        "mode": "active",
        "life": 1.4,
        "damage": damage,
        "radius": 4.8,
        "wall_bounces": 1,
        "effects": effect_tags.duplicate(),
        "level": 1,
        "hit_cooldowns": {},
        "spawned": true,
        "homing": homing,
        "manual": false,
    })

func begin_return_by_index(index: int) -> void:
    if index < 0 or index >= projectiles.size():
        return
    var shot: Dictionary = projectiles[index]
    if int(shot["slot"]) >= 0:
        shot["mode"] = "returning"
    else:
        projectiles.remove_at(index)

func recharge_slot(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= shot_slots.size():
        return
    var slot: Dictionary = shot_slots[slot_index]
    slot["state"] = "cooldown"
    slot["cooldown"] = maxf(0.05, 0.24 - float(int(buster["energy"]) - 1) * 0.022)

func nearest_enemy(origin: Vector2) -> Dictionary:
    var best: Dictionary = {}
    var best_dist: float = INF
    for enemy: Dictionary in enemies:
        var enemy_pos: Vector2 = enemy["pos"]
        var dist: float = origin.distance_squared_to(enemy_pos)
        if dist < best_dist:
            best_dist = dist
            best = enemy
    return best

func spawn_wave() -> void:
    wave_index += 1
    var rows: int = 1 + int(wave_index >= 3)
    if wave_index >= 7 and wave_index % 2 == 0:
        rows = 3
    var cols: int = 5 + int(wave_index >= 5)
    var spacing_x: float = 126.0
    var total_width: float = float(cols - 1) * spacing_x
    var start_x: float = 640.0 - total_width * 0.5
    for row: int in range(rows):
        for col: int in range(cols):
            if randf() < 0.18 and row > 0:
                continue
            var kind: String = pick_enemy_kind()
            var pos := Vector2(start_x + float(col) * spacing_x + randf_range(-12.0, 12.0), 112.0 - float(row) * 66.0)
            spawn_enemy(kind, pos, false, false)
    if wave_index == 1:
        show_message("REAVERBOT DEFENCE GRID ACTIVE", 1.4)

func pick_enemy_kind() -> String:
    var roll: float = randf()
    if run_time < 18.0:
        return "horokko" if roll < 0.72 else "zakobon"
    if run_time < 45.0:
        if roll < 0.45:
            return "horokko"
        if roll < 0.76:
            return "zakobon"
        return "sharukurusu"
    if roll < 0.34:
        return "horokko"
    if roll < 0.60:
        return "zakobon"
    if roll < 0.84:
        return "sharukurusu"
    return "guardian"

func enemy_template(kind: String) -> Dictionary:
    if kind == "horokko":
        return {"name":"HOROKKO", "tex":TEX_HOROKKO, "hp":42.0, "speed":24.0, "radius":22.0, "shoot":0.0, "armor":0.0, "shield":0.0, "xp":5.0, "score":95}
    if kind == "zakobon":
        return {"name":"ZAKOBON", "tex":TEX_ZAKOBON, "hp":64.0, "speed":18.0, "radius":26.0, "shoot":2.2, "armor":0.0, "shield":0.0, "xp":7.0, "score":130}
    if kind == "sharukurusu":
        return {"name":"SHARUKURUSU", "tex":TEX_SHARUKURUSU, "hp":112.0, "speed":13.0, "radius":31.0, "shoot":3.0, "armor":0.34, "shield":0.0, "xp":10.0, "score":205}
    return {"name":"GUARDIAN", "tex":TEX_GUARDIAN, "hp":155.0, "speed":12.0, "radius":35.0, "shoot":2.0, "armor":0.12, "shield":0.52, "xp":14.0, "score":290}

func spawn_enemy(kind: String, pos: Vector2, elite: bool, boss: bool) -> void:
    var data: Dictionary = enemy_template(kind)
    var scale: float = 1.0 + run_time / 145.0
    if elite:
        scale *= 3.4
    var hp: float = float(data["hp"]) * scale
    enemies.append({
        "id": next_enemy_id,
        "kind": kind,
        "name": str(data["name"]),
        "tex": data["tex"],
        "pos": pos,
        "hp": hp,
        "max_hp": hp,
        "speed": float(data["speed"]) * (1.0 + run_time / 300.0),
        "radius": float(data["radius"]) * (1.35 if elite else 1.0),
        "shoot_timer": randf_range(0.8, maxf(1.0, float(data["shoot"]))),
        "shoot_rate": float(data["shoot"]),
        "armor": float(data["armor"]),
        "shield": float(data["shield"]),
        "burn": 0.0,
        "burn_time": 0.0,
        "burn_tick": 0.25,
        "slow": 0.0,
        "slow_time": 0.0,
        "frozen": 0.0,
        "phase": randf() * TAU,
        "boss": boss,
        "elite": elite,
        "xp": float(data["xp"]) * (3.0 if elite else 1.0),
        "score": int(data["score"]) * (4 if elite else 1),
        "contact_damage": 14.0 if not elite else 24.0,
        "boss_phase": 0,
    })
    next_enemy_id += 1

func spawn_miniboss() -> void:
    spawn_enemy("guardian", Vector2(640.0, 125.0), true, false)
    show_message("ELITE GUARDIAN", 1.5)

func spawn_boss() -> void:
    var hp: float = 2850.0
    enemies.append({
        "id": next_enemy_id,
        "kind": "hanmuru",
        "name": "HANMURU DOLL",
        "tex": TEX_GUARDIAN,
        "pos": Vector2(640.0, 150.0),
        "hp": hp,
        "max_hp": hp,
        "speed": 0.0,
        "radius": 74.0,
        "shoot_timer": 1.0,
        "shoot_rate": 0.8,
        "armor": 0.16,
        "shield": 0.38,
        "burn": 0.0,
        "burn_time": 0.0,
        "burn_tick": 0.25,
        "slow": 0.0,
        "slow_time": 0.0,
        "frozen": 0.0,
        "phase": 0.0,
        "boss": true,
        "elite": true,
        "xp": 100.0,
        "score": 5000,
        "contact_damage": 40.0,
        "boss_phase": 1,
    })
    next_enemy_id += 1

func update_enemies(delta: float) -> void:
    for i: int in range(enemies.size() - 1, -1, -1):
        var enemy: Dictionary = enemies[i]
        enemy["phase"] = float(enemy["phase"]) + delta

        if float(enemy["burn_time"]) > 0.0:
            enemy["burn_time"] = float(enemy["burn_time"]) - delta
            enemy["burn_tick"] = float(enemy["burn_tick"]) - delta
            if float(enemy["burn_tick"]) <= 0.0:
                enemy["burn_tick"] = 0.35
                enemy["hp"] = float(enemy["hp"]) - maxf(1.0, float(enemy["burn"]) * 1.8)
        else:
            enemy["burn"] = 0.0

        if float(enemy["slow_time"]) > 0.0:
            enemy["slow_time"] = float(enemy["slow_time"]) - delta
        else:
            enemy["slow"] = 0.0
        if float(enemy["frozen"]) > 0.0:
            enemy["frozen"] = float(enemy["frozen"]) - delta

        if bool(enemy["boss"]):
            update_boss(enemy, delta)
        else:
            var movement_scale: float = 1.0 - float(enemy["slow"])
            if float(enemy["frozen"]) > 0.0:
                movement_scale = 0.0
            var pos: Vector2 = enemy["pos"]
            pos.y += float(enemy["speed"]) * movement_scale * delta
            if bool(enemy["elite"]):
                pos.x += sin(float(enemy["phase"]) * 1.7) * 25.0 * delta
            enemy["pos"] = pos
            if float(enemy["shoot_rate"]) > 0.0 and pos.y < 470.0:
                enemy["shoot_timer"] = float(enemy["shoot_timer"]) - delta
                if float(enemy["shoot_timer"]) <= 0.0:
                    enemy_fire(enemy)
                    enemy["shoot_timer"] = float(enemy["shoot_rate"]) * randf_range(0.82, 1.18)

        if float(enemy["hp"]) <= 0.0:
            enemy_killed(enemy)
            enemies.remove_at(i)
            continue

        var enemy_pos_now: Vector2 = enemy["pos"]
        if not bool(enemy["boss"]) and enemy_pos_now.y >= ENEMY_FRONT_Y:
            damage_player(float(enemy["contact_damage"]))
            effects.append({"type":"burst", "pos":enemy_pos_now, "t":0.28})
            enemies.remove_at(i)
            if mode != "run":
                return

func update_boss(enemy: Dictionary, delta: float) -> void:
    var ratio: float = float(enemy["hp"]) / float(enemy["max_hp"])
    var new_phase: int = 1
    if ratio < 0.66:
        new_phase = 2
    if ratio < 0.33:
        new_phase = 3
    if new_phase != int(enemy["boss_phase"]):
        enemy["boss_phase"] = new_phase
        show_message("HANMURU DOLL - PHASE %d" % new_phase, 1.4)
        shake = 9.0
    var pos: Vector2 = enemy["pos"]
    pos.x = 640.0 + sin(run_time * (0.8 + float(new_phase) * 0.15)) * (180.0 + float(new_phase) * 28.0)
    pos.y = 150.0 + sin(run_time * 1.7) * 18.0
    enemy["pos"] = pos
    enemy["shoot_timer"] = float(enemy["shoot_timer"]) - delta
    if float(enemy["shoot_timer"]) <= 0.0:
        boss_fire(enemy, new_phase)
        enemy["shoot_timer"] = maxf(0.34, 1.05 - float(new_phase) * 0.17)

func enemy_fire(enemy: Dictionary) -> void:
    var origin: Vector2 = enemy["pos"]
    var direction := (player_pos - origin).normalized()
    enemy_shots.append({"pos":origin, "vel":direction * 190.0, "life":5.0, "radius":7.0, "damage":9.0, "boss":false})

func boss_fire(enemy: Dictionary, phase_value: int) -> void:
    var origin: Vector2 = enemy["pos"]
    var toward := (player_pos - origin).angle()
    var count: int = 3 + phase_value * 2
    var spread: float = 0.16
    for i: int in range(count):
        var offset: float = (float(i) - float(count - 1) * 0.5) * spread
        var angle: float = toward + offset
        enemy_shots.append({"pos":origin, "vel":Vector2(cos(angle), sin(angle)) * (205.0 + float(phase_value) * 16.0), "life":5.2, "radius":8.0, "damage":8.0 + float(phase_value) * 2.0, "boss":true})
    if phase_value >= 2:
        var side_angle: float = 0.35 if int(run_time * 2.0) % 2 == 0 else -0.35
        enemy_shots.append({"pos":origin, "vel":Vector2(cos(PI / 2.0 + side_angle), sin(PI / 2.0 + side_angle)) * 250.0, "life":4.0, "radius":11.0, "damage":13.0, "boss":true})

func update_enemy_shots(delta: float) -> void:
    for i: int in range(enemy_shots.size() - 1, -1, -1):
        var shot: Dictionary = enemy_shots[i]
        var current_pos: Vector2 = shot["pos"]
        var current_vel: Vector2 = shot["vel"]
        shot["pos"] = current_pos + current_vel * delta
        shot["life"] = float(shot["life"]) - delta
        var pos: Vector2 = shot["pos"]
        if pos.distance_to(player_pos) <= float(shot["radius"]) + 20.0:
            damage_player(float(shot["damage"]))
            enemy_shots.remove_at(i)
            if mode != "run":
                return
            continue
        if float(shot["life"]) <= 0.0 or pos.x < 120.0 or pos.x > 1160.0 or pos.y > 690.0 or pos.y < 20.0:
            enemy_shots.remove_at(i)

func damage_player(amount: float) -> void:
    life -= amount
    shake = maxf(shake, 9.0)
    screen_flash = 0.42
    play_sfx(sfx_hurt)
    if life <= 0.0:
        life = 0.0
        finish_run(false)

func enemy_killed(enemy: Dictionary) -> void:
    kills += 1
    score += int(enemy["score"])
    combat_data += float(enemy["xp"])
    terminal_charge += 10.0 if not bool(enemy["elite"]) else 32.0
    var drop_count: int = 1 if not bool(enemy["elite"]) else 4
    if bool(enemy["boss"]):
        drop_count = 10
    var death_pos: Vector2 = enemy["pos"]
    for n: int in range(drop_count):
        pickups.append({
            "pos": death_pos + Vector2(randf_range(-24.0, 24.0), randf_range(-16.0, 16.0)),
            "kind": "refractor" if bool(enemy["elite"]) or randf() < 0.16 else "zenny",
            "t": 0.0,
        })
    effects.append({"type":"burst", "pos":death_pos, "t":0.40})
    play_sfx(sfx_explosion)

    if bool(enemy["boss"]):
        boss_defeated = true
        finish_run(true)
        return

    while combat_data >= combat_data_next:
        combat_data -= combat_data_next
        level += 1
        combat_data_next = 20.0 + float(level) * 7.0
        pending_levelups += 1
    if pending_levelups > 0 and mode == "run":
        open_level_up()

func update_pickups(delta: float) -> void:
    for i: int in range(pickups.size() - 1, -1, -1):
        var pickup: Dictionary = pickups[i]
        pickup["t"] = float(pickup["t"]) + delta
        var pos: Vector2 = pickup["pos"]
        var distance: float = pos.distance_to(player_pos)
        if float(pickup["t"]) > 0.35 or distance < 150.0:
            pos = pos.lerp(player_pos, minf(1.0, delta * 5.5))
            pickup["pos"] = pos
        if pos.distance_to(player_pos) < 30.0:
            if str(pickup["kind"]) == "zenny":
                zenny += 12
            else:
                refractors += 1
            play_sfx(sfx_item)
            pickups.remove_at(i)

func attract_pickups(radius: float) -> void:
    for pickup: Dictionary in pickups:
        var pos: Vector2 = pickup["pos"]
        if pos.distance_to(player_pos) <= radius:
            pickup["t"] = 99.0

func update_effects(delta: float) -> void:
    for i: int in range(effects.size() - 1, -1, -1):
        effects[i]["t"] = float(effects[i]["t"]) - delta
        if float(effects[i]["t"]) <= 0.0:
            effects.remove_at(i)

func open_level_up() -> void:
    if pending_levelups <= 0:
        return
    pending_levelups -= 1
    upgrade_choices = generate_upgrade_choices()
    upgrade_index = 0
    mode = "levelup"

func generate_upgrade_choices() -> Array[Dictionary]:
    var pool: Array[Dictionary] = [
        {"type":"stat", "key":"attack", "name":"POWER RAISER", "desc":"Attack +1. Every Buster shot hits harder."},
        {"type":"stat", "key":"energy", "name":"ENERGY PACK", "desc":"Energy +1. Shots recharge faster and travel faster."},
        {"type":"stat", "key":"range", "name":"SNIPER UNIT", "desc":"Range +1. Shots stay active longer."},
        {"type":"stat", "key":"rapid", "name":"TURBO CHARGER", "desc":"Rapid +1. Auto-fire cycles faster."},
        {"type":"stat", "key":"ricochet", "name":"REFLECTOR LENS", "desc":"Every reusable shot gains another wall ricochet."},
        {"type":"stat", "key":"bounce_amp", "name":"KINETIC CONVERTER", "desc":"Every wall bounce increases that shot's damage."},
        {"type":"standard", "key":"standard", "name":"BUSTER CAPACITOR", "desc":"Adds another Standard Buster Shot to circulation."},
    ]
    for key: String in BASE_PROGRAMS:
        var current: int = int(program_levels[key])
        if current < 3:
            var action: String = "INSTALL" if current == 0 else "TUNE"
            pool.append({
                "type":"program",
                "key":key,
                "name":"%s %s" % [action, program_label(key)],
                "desc":program_description(key, current + 1),
            })
    pool.shuffle()
    var result: Array[Dictionary] = []
    var wanted_program: Dictionary = {}
    for option: Dictionary in pool:
        if str(option["type"]) == "program":
            wanted_program = option
            break
    if not wanted_program.is_empty():
        result.append(wanted_program)
    for option: Dictionary in pool:
        if result.size() >= 3:
            break
        if option == wanted_program:
            continue
        result.append(option)
    return result

func apply_upgrade(index: int) -> void:
    if index < 0 or index >= upgrade_choices.size():
        return
    var choice: Dictionary = upgrade_choices[index]
    var type_name: String = str(choice["type"])
    var key: String = str(choice["key"])
    if type_name == "stat":
        buster[key] = int(buster[key]) + 1
    elif type_name == "standard":
        add_shot_slot("standard", 1)
    elif type_name == "program":
        program_levels[key] = mini(3, int(program_levels[key]) + 1)
        ensure_program_slot(key)
        refresh_program_slot(key)
    show_message(str(choice["name"]), 1.2)
    mode = "run"
    if pending_levelups > 0:
        call_deferred("open_level_up")

func refresh_program_slot(program: String) -> void:
    for slot: Dictionary in shot_slots:
        if str(slot["program"]) == program:
            slot["level"] = int(program_levels[program])

func open_terminal() -> void:
    terminal_charge = 0.0
    recall_and_ready_all()
    terminal_options = build_terminal_options()
    terminal_index = first_enabled_terminal_index()
    mode = "terminal"
    show_radio("ROLL", "This terminal can rewrite the Buster's refractor programs. Let's see what it recognizes.", 5.0)

func build_terminal_options() -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    options.append({"type":"tune", "name":"TUNE-UP", "desc":"Increase one installed program toward Level III.", "enabled":true})
    var pair: Array[String] = find_link_pair()
    if pair.size() == 2:
        options.append({"type":"link", "name":"PROGRAM LINK", "desc":"Link %s + %s. One reusable shot carries both effects." % [program_label(pair[0]), program_label(pair[1])], "enabled":true, "a":pair[0], "b":pair[1]})
    else:
        options.append({"type":"link", "name":"PROGRAM LINK", "desc":"Needs two installed Level III programs.", "enabled":false})
    var recipe: Dictionary = find_development_recipe()
    if not recipe.is_empty():
        options.append({"type":"develop", "name":"ROLL DEVELOPMENT", "desc":"%s + %s -> %s" % [program_label(str(recipe["a"])), program_label(str(recipe["b"])), str(recipe["label"])], "enabled":true, "recipe":recipe})
    else:
        options.append({"type":"develop", "name":"ROLL DEVELOPMENT", "desc":"No compatible Level III development recipe yet.", "enabled":false})
    return options

func first_enabled_terminal_index() -> int:
    for i: int in range(terminal_options.size()):
        if bool(terminal_options[i]["enabled"]):
            return i
    return 0

func move_terminal_selection(direction: int) -> void:
    if terminal_options.is_empty():
        return
    for step: int in range(1, terminal_options.size() + 1):
        var idx: int = wrapi(terminal_index + direction * step, 0, terminal_options.size())
        if bool(terminal_options[idx]["enabled"]):
            terminal_index = idx
            return

func find_link_pair() -> Array[String]:
    var ready: Array[String] = []
    for key: String in BASE_PROGRAMS:
        if int(program_levels[key]) >= 3 and has_program_slot(key):
            ready.append(key)
    if ready.size() >= 2:
        return [ready[0], ready[1]]
    return []

func find_development_recipe() -> Dictionary:
    for recipe: Dictionary in DEVELOPMENT_RECIPES:
        var a: String = str(recipe["a"])
        var b: String = str(recipe["b"])
        if int(program_levels[a]) >= 3 and int(program_levels[b]) >= 3 and has_program_slot(a) and has_program_slot(b):
            return recipe
    return {}

func has_program_slot(program: String) -> bool:
    for slot: Dictionary in shot_slots:
        if str(slot["program"]) == program:
            return true
    return false

func apply_terminal_option(index: int) -> void:
    if index < 0 or index >= terminal_options.size():
        return
    var option: Dictionary = terminal_options[index]
    if not bool(option["enabled"]):
        return
    var type_name: String = str(option["type"])
    if type_name == "tune":
        terminal_tune_up()
    elif type_name == "link":
        create_program_link(str(option["a"]), str(option["b"]))
    elif type_name == "develop":
        var recipe: Dictionary = option["recipe"]
        perform_development(recipe)
    mode = "run"

func terminal_tune_up() -> void:
    var candidates: Array[String] = []
    for key: String in BASE_PROGRAMS:
        if int(program_levels[key]) > 0 and int(program_levels[key]) < 3:
            candidates.append(key)
    if candidates.is_empty():
        buster["attack"] = int(buster["attack"]) + 1
        show_message("TUNE-UP: ATTACK +1", 1.4)
        return
    var key: String = candidates[randi() % candidates.size()]
    program_levels[key] = int(program_levels[key]) + 1
    refresh_program_slot(key)
    show_message("%s -> LEVEL %d" % [program_label(key), int(program_levels[key])], 1.5)

func create_program_link(a: String, b: String) -> void:
    remove_first_program_slot(a)
    remove_first_program_slot(b)
    var label: String = "%s / %s LINK" % [program_label(a), program_label(b)]
    shot_slots.append({
        "program":"linked_%s_%s" % [a, b],
        "name":label,
        "level":3,
        "effects":[a, b],
        "state":"ready",
        "cooldown":0.0,
    })
    linked_pairs.append("%s+%s" % [a, b])
    show_message(label, 1.7)

func perform_development(recipe: Dictionary) -> void:
    var a: String = str(recipe["a"])
    var b: String = str(recipe["b"])
    var result: String = str(recipe["result"])
    remove_first_program_slot(a)
    remove_first_program_slot(b)
    program_levels[a] = 0
    program_levels[b] = 0
    add_shot_slot(result, 3)
    evolved_owned.append(result)
    show_message("DEVELOPED: %s" % str(recipe["label"]), 2.0)
    show_radio("ROLL", "It worked! I combined the two programs into %s!" % str(recipe["label"]), 4.0)

func remove_first_program_slot(program: String) -> void:
    for i: int in range(shot_slots.size()):
        if str(shot_slots[i]["program"]) == program:
            shot_slots.remove_at(i)
            return

func recall_and_ready_all() -> void:
    projectiles.clear()
    for slot: Dictionary in shot_slots:
        slot["state"] = "ready"
        slot["cooldown"] = 0.0

func finish_run(victory: bool) -> void:
    if mode == "gameover" or mode == "victory":
        return
    projectiles.clear()
    enemy_shots.clear()
    bank["zenny"] = int(bank["zenny"]) + zenny
    bank["refractors"] = int(bank["refractors"]) + refractors
    save_game()
    if victory:
        mode = "victory"
        show_radio("ROLL", "You did it! The guardian's down. Let's get out of here with that data.", 5.0)
    else:
        mode = "gameover"
    music.stop()

func permanent_cost(key: String) -> Dictionary:
    var rank: int = int(permanent[key])
    return {"z": 90 + rank * 95, "r": 2 + rank * 2}

func buy_permanent(key: String) -> void:
    var cost: Dictionary = permanent_cost(key)
    if int(bank["zenny"]) >= int(cost["z"]) and int(bank["refractors"]) >= int(cost["r"]):
        bank["zenny"] = int(bank["zenny"]) - int(cost["z"])
        bank["refractors"] = int(bank["refractors"]) - int(cost["r"])
        permanent[key] = int(permanent[key]) + 1
        save_game()
        show_message("ROLL INSTALLED THE UPGRADE", 1.5)
        play_sfx(sfx_item)
    else:
        show_message("NOT ENOUGH ZENNY / REFRACTORS", 1.5)

func save_game() -> void:
    var file := FileAccess.open("user://refractor_pit_v2.save", FileAccess.WRITE)
    if file:
        file.store_var({"bank":bank, "permanent":permanent})

func load_save() -> void:
    if not FileAccess.file_exists("user://refractor_pit_v2.save"):
        return
    var file := FileAccess.open("user://refractor_pit_v2.save", FileAccess.READ)
    if file:
        var data: Variant = file.get_var()
        if data is Dictionary:
            var dictionary: Dictionary = data
            if dictionary.has("bank") and dictionary["bank"] is Dictionary:
                bank = dictionary["bank"]
            if dictionary.has("permanent") and dictionary["permanent"] is Dictionary:
                permanent = dictionary["permanent"]

func components_for_program(program: String) -> Array:
    if program == "grenade_arm":
        return ["grenade_arm", "flame", "shockwave"]
    if program == "storm_buster":
        return ["storm_buster", "arc", "cryo"]
    if program == "drill_arm":
        return ["drill_arm", "heavy", "phase"]
    if program == "active_buster":
        return ["active_buster", "splitter"]
    if program == "vacuum_buster":
        return ["vacuum_buster", "phase", "leech"]
    if program == "thermal_fracture":
        return ["thermal_fracture", "flame", "cryo", "shockwave"]
    return [program]

func program_label(program: String) -> String:
    match program:
        "standard": return "STANDARD BUSTER"
        "flame": return "FLAME PROGRAM"
        "cryo": return "CRYO PROGRAM"
        "arc": return "ARC PROGRAM"
        "heavy": return "HEAVY PROGRAM"
        "phase": return "PHASE PROGRAM"
        "shockwave": return "SHOCKWAVE PROGRAM"
        "splitter": return "SPLITTER PROGRAM"
        "leech": return "ENERGY LEECH"
        "grenade_arm": return "GRENADE ARM"
        "storm_buster": return "STORM BUSTER"
        "drill_arm": return "DRILL ARM"
        "active_buster": return "ACTIVE BUSTER"
        "vacuum_buster": return "VACUUM BUSTER"
        "thermal_fracture": return "THERMAL FRACTURE"
    return program.to_upper()

func program_description(program: String, level_value: int) -> String:
    var suffix: String = " Level %d" % level_value
    match program:
        "flame": return "Heat damage stacks on Reaverbots." + suffix
        "cryo": return "Slows enemies; Level III can freeze." + suffix
        "arc": return "Chains refractor energy into nearby targets." + suffix
        "heavy": return "Slow, oversized shot with armour-breaking damage." + suffix
        "phase": return "Passes through Reaverbots instead of bouncing off them." + suffix
        "shockwave": return "Every impact damages nearby Reaverbots." + suffix
        "splitter": return "First impact creates additional Buster shots." + suffix
        "leech": return "Converts some impact energy into Life Gauge recovery." + suffix
    return "Ancient refractor weapon program." + suffix

func program_color(effects_list: Array) -> Color:
    if effects_list.has("grenade_arm") or effects_list.has("flame"):
        return Color("ff8a45")
    if effects_list.has("storm_buster") or effects_list.has("arc"):
        return Color("bda0ff")
    if effects_list.has("cryo"):
        return Color("8ff6ff")
    if effects_list.has("heavy") or effects_list.has("drill_arm"):
        return Color("ffd36d")
    if effects_list.has("phase"):
        return Color("a5b8ff")
    if effects_list.has("shockwave"):
        return Color("9dff97")
    if effects_list.has("leech") or effects_list.has("vacuum_buster"):
        return Color("ff7fc6")
    if effects_list.has("thermal_fracture"):
        return Color("fff0b0")
    return Color("67e6ff")

func show_message(text: String, duration: float) -> void:
    message = text
    message_timer = duration

func show_radio(speaker: String, text: String, duration: float) -> void:
    radio_speaker = speaker
    radio_text = text
    radio_timer = duration

func _draw() -> void:
    draw_rect(Rect2(0.0, 0.0, W, H), Color("071018"), true)
    if mode == "menu":
        draw_menu()
    elif mode == "workshop":
        draw_workshop()
    else:
        draw_run_world()
        if mode == "levelup":
            draw_level_up()
        elif mode == "terminal":
            draw_terminal()
        elif mode == "gameover":
            draw_result(false)
        elif mode == "victory":
            draw_result(true)
    if message_timer > 0.0 and message != "":
        draw_message_banner(message)
    if radio_timer > 0.0 and radio_text != "":
        draw_radio_box()

func draw_run_world() -> void:
    var ofs := Vector2.ZERO
    if shake > 0.1:
        ofs = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
    draw_set_transform(ofs)
    draw_ruin_arena()
    for pickup: Dictionary in pickups:
        draw_pickup(pickup)
    for enemy: Dictionary in enemies:
        draw_enemy(enemy)
    for shot: Dictionary in projectiles:
        draw_buster_shot(shot)
    for shot: Dictionary in enemy_shots:
        draw_enemy_shot(shot)
    draw_player()
    for fx: Dictionary in effects:
        draw_effect(fx)
    draw_set_transform(Vector2.ZERO)
    draw_hud()
    if screen_flash > 0.0:
        draw_rect(Rect2(0.0, 0.0, W, H), Color(0.65, 0.92, 1.0, screen_flash * 0.22), true)

func draw_ruin_arena() -> void:
    draw_rect(Rect2(150.0, 30.0, 980.0, 650.0), Color("02070b"), true)
    draw_rect(ARENA, Color("10252c"), true)
    var tile: float = 48.0
    var rows: int = int(ARENA.size.y / tile) + 1
    var cols: int = int(ARENA.size.x / tile) + 1
    for y: int in range(rows):
        for x: int in range(cols):
            var rect := Rect2(ARENA.position.x + float(x) * tile, ARENA.position.y + float(y) * tile, tile, tile)
            draw_texture_rect(TEX_RUIN_FLOOR, rect, true, Color(0.72, 0.86, 0.88, 1.0))
    draw_rect(Rect2(ARENA.position.x, ARENA.position.y, ARENA.size.x, 14.0), Color("254c57"), true)
    draw_rect(Rect2(ARENA.position.x, ENEMY_FRONT_Y + 35.0, ARENA.size.x, 3.0), Color(0.4, 0.85, 1.0, 0.15), true)
    draw_texture_rect(TEX_RUIN_ENTRANCE, Rect2(555.0, 57.0, 170.0, 94.0), false, Color(0.72, 0.92, 1.0, 0.82))
    for x: float in [205.0, 1075.0]:
        draw_texture_rect(TEX_RUIN_PILLAR, Rect2(x - 24.0, 100.0, 48.0, 160.0), false, Color(0.72, 0.9, 0.94, 1.0))
        draw_texture_rect(TEX_RUIN_PILLAR, Rect2(x - 24.0, 405.0, 48.0, 160.0), false, Color(0.72, 0.9, 0.94, 1.0))
    for x: float in [350.0, 640.0, 930.0]:
        draw_texture_rect(TEX_RUIN_PANEL, Rect2(x - 30.0, 115.0, 60.0, 60.0), false, Color(0.72, 0.92, 0.96, 0.80))

func draw_player() -> void:
    draw_circle(player_pos + Vector2(0.0, 22.0), 30.0, Color(0.0, 0.0, 0.0, 0.34))
    var size := Vector2(92.0, 92.0)
    draw_texture_rect(TEX_MM, Rect2(player_pos - size * 0.5 + Vector2(0.0, -20.0), size), false)
    var dir := Vector2(cos(aim_angle), sin(aim_angle))
    var cannon_start := player_pos + Vector2(0.0, -8.0) + dir * 16.0
    var cannon_end := player_pos + Vector2(0.0, -8.0) + dir * 42.0
    draw_line(cannon_start, cannon_end, Color("58d8ff"), 8.0, true)
    draw_circle(cannon_end, 6.0, Color("c4ffff"))
    draw_circle(cannon_end, 2.5, Color.WHITE)
    draw_line(player_pos + Vector2(0.0, -12.0), player_pos + dir * 118.0, Color(0.4, 0.94, 1.0, 0.18), 1.5)

func draw_enemy(enemy: Dictionary) -> void:
    var pos: Vector2 = enemy["pos"]
    var radius: float = float(enemy["radius"])
    var tex: Texture2D = enemy["tex"]
    if float(enemy["frozen"]) > 0.0:
        draw_circle(pos, radius + 7.0, Color(0.45, 0.9, 1.0, 0.22))
    elif float(enemy["burn_time"]) > 0.0:
        draw_circle(pos, radius + 6.0, Color(1.0, 0.35, 0.1, 0.16))
    if float(enemy["shield"]) > 0.0:
        draw_arc(pos, radius + 9.0, 0.10, PI - 0.10, 24, Color(0.35, 0.9, 1.0, 0.45), 3.0)
    draw_circle(pos + Vector2(0.0, radius * 0.62), radius * 0.82, Color(0.0, 0.0, 0.0, 0.34))
    var size := Vector2(radius * 2.45, radius * 2.45)
    if bool(enemy["boss"]):
        size = Vector2(175.0, 160.0)
    draw_texture_rect(tex, Rect2(pos - size * 0.5, size), false)
    var ratio: float = clampf(float(enemy["hp"]) / float(enemy["max_hp"]), 0.0, 1.0)
    if bool(enemy["boss"]):
        draw_rect(Rect2(382.0, 65.0, 516.0, 15.0), Color("361016"), true)
        draw_rect(Rect2(382.0, 65.0, 516.0 * ratio, 15.0), C_DANGER, true)
        draw_string(ThemeDB.fallback_font, Vector2(382.0, 57.0), "HANMURU DOLL", HORIZONTAL_ALIGNMENT_LEFT, 280.0, 16, C_TEXT)
        draw_string(ThemeDB.fallback_font, Vector2(778.0, 57.0), "PHASE %d" % int(enemy["boss_phase"]), HORIZONTAL_ALIGNMENT_RIGHT, 120.0, 13, C_MUTED)
    elif bool(enemy["elite"]) or ratio < 0.99:
        draw_rect(Rect2(pos.x - 25.0, pos.y - radius - 12.0, 50.0, 5.0), Color("071014"), true)
        draw_rect(Rect2(pos.x - 25.0, pos.y - radius - 12.0, 50.0 * ratio, 5.0), C_GREEN, true)

func draw_buster_shot(shot: Dictionary) -> void:
    var effects_list: Array = shot["effects"]
    var color := program_color(effects_list)
    var pos: Vector2 = shot["pos"]
    var last: Vector2 = shot["last"]
    var radius: float = float(shot["radius"])
    if str(shot["mode"]) == "returning":
        color = color.lerp(Color.WHITE, 0.55)
        draw_line(last, pos, Color(color.r, color.g, color.b, 0.24), 3.0, true)
        draw_circle(pos, radius + 2.0, Color(color.r, color.g, color.b, 0.42), false, 2.0)
    else:
        draw_line(last, pos, Color(color.r, color.g, color.b, 0.32), radius * 1.25, true)
        if effects_list.has("phase") or effects_list.has("drill_arm"):
            draw_circle(pos, radius + 4.0, Color(color.r, color.g, color.b, 0.20), false, 2.0)
        draw_circle(pos, radius + 3.0, Color(color.r, color.g, color.b, 0.16))
        draw_circle(pos, radius, color)
        draw_circle(pos - Vector2(2.0, 2.0), maxf(1.5, radius * 0.32), Color.WHITE)

func draw_enemy_shot(shot: Dictionary) -> void:
    var pos: Vector2 = shot["pos"]
    var color := Color("ff5964") if bool(shot["boss"]) else Color("ff9a52")
    draw_circle(pos, float(shot["radius"]) + 4.0, Color(color.r, color.g, color.b, 0.18))
    draw_circle(pos, float(shot["radius"]), color)
    draw_circle(pos, 2.2, Color.WHITE)

func draw_pickup(pickup: Dictionary) -> void:
    var bob: float = sin(float(pickup["t"]) * 7.0) * 4.0
    var base_pos: Vector2 = pickup["pos"]
    var pos: Vector2 = base_pos + Vector2(0.0, bob)
    var color := C_GOLD if str(pickup["kind"]) == "zenny" else C_BLUE
    draw_circle(pos, 10.0, Color(color.r, color.g, color.b, 0.15))
    draw_circle(pos, 5.0, color)
    if str(pickup["kind"]) == "refractor":
        var diamond := PackedVector2Array([pos + Vector2(0.0, -7.0), pos + Vector2(6.0, 0.0), pos + Vector2(0.0, 7.0), pos + Vector2(-6.0, 0.0), pos + Vector2(0.0, -7.0)])
        draw_polyline(diamond, Color.WHITE, 1.2)

func draw_effect(fx: Dictionary) -> void:
    var type_name: String = str(fx["type"])
    var t: float = float(fx["t"])
    if type_name == "arc":
        draw_line(Vector2(fx["a"]), Vector2(fx["b"]), Color(0.76, 0.70, 1.0, clampf(t * 6.0, 0.0, 1.0)), 3.0, true)
        return
    var pos: Vector2 = fx.get("pos", Vector2.ZERO)
    if type_name == "muzzle":
        draw_circle(pos, 8.0 + t * 50.0, Color(0.68, 1.0, 1.0, clampf(t * 3.0, 0.0, 1.0)))
    elif type_name == "hit":
        draw_circle(pos, 8.0 + t * 38.0, Color(0.95, 1.0, 0.65, clampf(t * 2.7, 0.0, 1.0)), false, 3.0)
    elif type_name == "spark":
        draw_circle(pos, 5.0 + t * 26.0, Color(0.45, 0.95, 1.0, clampf(t * 2.5, 0.0, 1.0)), false, 2.0)
    elif type_name == "burst":
        draw_circle(pos, 18.0 + t * 82.0, Color(1.0, 0.45, 0.24, clampf(t * 1.9, 0.0, 1.0)), false, 5.0)
    elif type_name == "ring":
        draw_circle(pos, float(fx["r"]) * (1.0 - t * 0.5), Color(0.55, 1.0, 0.9, clampf(t * 2.0, 0.0, 0.8)), false, 3.0)
    elif type_name == "return":
        draw_circle(pos, 8.0 + t * 28.0, Color(0.55, 0.95, 1.0, clampf(t * 2.0, 0.0, 1.0)), false, 2.0)

func draw_hud() -> void:
    panel(Rect2(18.0, 18.0, 145.0, 132.0))
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 42.0), "LIFE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, C_MUTED)
    draw_rect(Rect2(32.0, 51.0, 116.0, 13.0), Color("12212c"), true)
    draw_rect(Rect2(32.0, 51.0, 116.0 * clampf(life / max_life, 0.0, 1.0), 13.0), C_GREEN, true)
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 88.0), "ATK %d   ENG %d" % [int(buster["attack"]), int(buster["energy"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 110.0), "RNG %d   RPD %d" % [int(buster["range"]), int(buster["rapid"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(32.0, 135.0), "AUTO %s" % ("ON" if auto_fire else "OFF"), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, C_BLUE)

    panel(Rect2(1117.0, 18.0, 145.0, 132.0))
    draw_string(ThemeDB.fallback_font, Vector2(1130.0, 42.0), time_string(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(1130.0, 67.0), "DATA %d/%d" % [int(combat_data), int(combat_data_next)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, C_MUTED)
    draw_string(ThemeDB.fallback_font, Vector2(1130.0, 91.0), "ZENNY %d" % zenny, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, C_GOLD)
    draw_string(ThemeDB.fallback_font, Vector2(1130.0, 115.0), "REFR %d" % refractors, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, C_BLUE)
    draw_string(ThemeDB.fallback_font, Vector2(1130.0, 139.0), "TERM %d%%" % int(clampf(terminal_charge, 0.0, terminal_threshold)), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, C_MUTED)

    draw_shot_rack()
    draw_rect(Rect2(250.0, 682.0, 780.0, 10.0), Color("122633"), true)
    draw_rect(Rect2(250.0, 682.0, 780.0 * clampf(combat_data / combat_data_next, 0.0, 1.0), 10.0), C_BLUE, true)
    draw_string(ThemeDB.fallback_font, Vector2(540.0, 675.0), "COMBAT DATA - LV %d" % level, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 11, C_MUTED)

func draw_shot_rack() -> void:
    var x: float = 205.0
    var width: float = 78.0
    for i: int in range(shot_slots.size()):
        if i >= 11:
            break
        var slot: Dictionary = shot_slots[i]
        var effects_list: Array = slot["effects"]
        var color := program_color(effects_list)
        var state: String = str(slot["state"])
        var alpha: float = 1.0 if state == "ready" else 0.34
        draw_rect(Rect2(x + float(i) * width, 645.0, 68.0, 27.0), Color(0.02, 0.05, 0.08, 0.88), true)
        draw_circle(Vector2(x + float(i) * width + 13.0, 658.0), 6.0, Color(color.r, color.g, color.b, alpha))
        var label: String = "STD" if str(slot["program"]) == "standard" else short_program_name(str(slot["name"]))
        draw_string(ThemeDB.fallback_font, Vector2(x + float(i) * width + 23.0, 663.0), label, HORIZONTAL_ALIGNMENT_LEFT, 42.0, 9, Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, alpha))

func short_program_name(label: String) -> String:
    var cleaned: String = label.replace(" PROGRAM", "").replace(" BUSTER", "").replace(" ARM", "")
    return cleaned.left(5)

func draw_menu() -> void:
    draw_menu_backdrop()
    draw_texture_rect(TEX_MM, Rect2(225.0, 342.0, 198.0, 178.0), false, Color(0.92, 1.0, 1.0, 1.0))
    draw_texture_rect(TEX_ROLL, Rect2(890.0, 378.0, 120.0, 150.0), false, Color(1.0, 1.0, 1.0, 0.95))
    draw_string(ThemeDB.fallback_font, Vector2(310.0, 212.0), "MEGA MAN LEGENDS", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 42, Color("e5fbff"))
    draw_string(ThemeDB.fallback_font, Vector2(310.0, 266.0), "REFRACTOR PIT", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 54, C_BLUE)
    draw_string(ThemeDB.fallback_font, Vector2(310.0, 306.0), "OCEAN TOWER PROTOTYPE", HORIZONTAL_ALIGNMENT_CENTER, 660.0, 14, C_MUTED)
    button(Rect2(470.0, 420.0, 340.0, 60.0), "START DIG", menu_index == 0)
    button(Rect2(470.0, 494.0, 340.0, 60.0), "ROLL'S SUPPORT CAR", menu_index == 1)
    draw_string(ThemeDB.fallback_font, Vector2(300.0, 602.0), "WASD / arrows move   Mouse aims   F toggles auto-fire   Click or Space fires", HORIZONTAL_ALIGNMENT_CENTER, 680.0, 13, C_MUTED)

func draw_menu_backdrop() -> void:
    draw_rect(Rect2(0.0, 0.0, W, H), Color("06131b"), true)
    for y: int in range(7, 15):
        for x: int in range(27):
            draw_texture_rect(TEX_RUIN_FLOOR, Rect2(float(x) * 48.0, float(y) * 48.0, 48.0, 48.0), true, Color(0.55, 0.70, 0.72, 1.0))
    draw_texture_rect(TEX_RUIN_ENTRANCE, Rect2(515.0, 72.0, 250.0, 150.0), false, Color(0.78, 0.95, 1.0, 0.92))
    draw_rect(Rect2(0.0, 0.0, W, H), Color(0.02, 0.07, 0.10, 0.32), true)

func draw_level_up() -> void:
    draw_rect(Rect2(0.0, 0.0, W, H), Color(0.01, 0.03, 0.055, 0.80), true)
    draw_string(ThemeDB.fallback_font, Vector2(350.0, 145.0), "COMBAT DATA ANALYZED", HORIZONTAL_ALIGNMENT_CENTER, 580.0, 30, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(350.0, 180.0), "Choose one Buster adjustment", HORIZONTAL_ALIGNMENT_CENTER, 580.0, 14, C_MUTED)
    for i: int in range(upgrade_choices.size()):
        var rect := Rect2(175.0 + float(i) * 315.0, 242.0, 290.0, 252.0)
        panel(rect, i == upgrade_index)
        var choice: Dictionary = upgrade_choices[i]
        var key: String = str(choice["key"])
        var color := C_BLUE
        if str(choice["type"]) == "program":
            color = program_color([key])
        draw_circle(Vector2(rect.position.x + 145.0, rect.position.y + 58.0), 27.0, Color(color.r, color.g, color.b, 0.18))
        draw_circle(Vector2(rect.position.x + 145.0, rect.position.y + 58.0), 11.0, color)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 18.0, rect.position.y + 119.0), str(choice["name"]), HORIZONTAL_ALIGNMENT_LEFT, 254.0, 15, C_TEXT)
        draw_multiline_string(ThemeDB.fallback_font, Vector2(rect.position.x + 18.0, rect.position.y + 151.0), str(choice["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 254.0, 13, 18, C_MUTED)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 18.0, rect.position.y + 226.0), "INSTALL", HORIZONTAL_ALIGNMENT_LEFT, 254.0, 11, C_BLUE if i == upgrade_index else C_MUTED)

func draw_terminal() -> void:
    draw_rect(Rect2(0.0, 0.0, W, H), Color(0.005, 0.02, 0.035, 0.86), true)
    draw_texture_rect(TEX_ROLL, Rect2(70.0, 116.0, 150.0, 188.0), false)
    draw_string(ThemeDB.fallback_font, Vector2(260.0, 125.0), "ANCIENT DEVELOPMENT TERMINAL", HORIZONTAL_ALIGNMENT_LEFT, 760.0, 28, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(260.0, 160.0), "Roll can reinterpret the terminal's refractor program data.", HORIZONTAL_ALIGNMENT_LEFT, 760.0, 14, C_MUTED)
    for i: int in range(terminal_options.size()):
        var rect := Rect2(170.0 + float(i) * 315.0, 260.0, 290.0, 240.0)
        var enabled: bool = bool(terminal_options[i]["enabled"])
        panel(rect, i == terminal_index and enabled)
        var title_color: Color = C_TEXT if enabled else Color(0.45, 0.50, 0.54, 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 20.0, rect.position.y + 52.0), str(terminal_options[i]["name"]), HORIZONTAL_ALIGNMENT_LEFT, 250.0, 17, title_color)
        draw_multiline_string(ThemeDB.fallback_font, Vector2(rect.position.x + 20.0, rect.position.y + 91.0), str(terminal_options[i]["desc"]), HORIZONTAL_ALIGNMENT_LEFT, 250.0, 13, 19, C_MUTED if enabled else Color(0.38, 0.42, 0.46, 1.0))
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 20.0, rect.position.y + 212.0), "SELECT" if enabled else "LOCKED", HORIZONTAL_ALIGNMENT_LEFT, 250.0, 11, C_BLUE if i == terminal_index and enabled else C_MUTED)

func draw_workshop() -> void:
    draw_rect(Rect2(0.0, 0.0, W, H), Color("081119"), true)
    for y: int in range(7, 15):
        for x: int in range(27):
            draw_texture_rect(TEX_RUIN_FLOOR, Rect2(float(x) * 48.0, float(y) * 48.0, 48.0, 48.0), true, Color(0.58, 0.70, 0.71, 1.0))
    draw_texture_rect(TEX_WORKBENCH, Rect2(55.0, 330.0, 210.0, 165.0), false)
    draw_texture_rect(TEX_ROLL, Rect2(1030.0, 320.0, 140.0, 180.0), false)
    draw_texture_rect(TEX_SALVAGE, Rect2(1080.0, 490.0, 100.0, 80.0), false)
    draw_string(ThemeDB.fallback_font, Vector2(320.0, 92.0), "ROLL'S SUPPORT CAR", HORIZONTAL_ALIGNMENT_CENTER, 640.0, 36, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(320.0, 131.0), "Permanent Buster tuning for future digs", HORIZONTAL_ALIGNMENT_CENTER, 640.0, 14, C_MUTED)
    draw_string(ThemeDB.fallback_font, Vector2(320.0, 169.0), "%d ZENNY     %d REFRACTOR SHARDS" % [int(bank["zenny"]), int(bank["refractors"])], HORIZONTAL_ALIGNMENT_CENTER, 640.0, 15, C_GOLD)
    var cards: Array[Array] = [
        ["POWER RAISER", "attack", "Starting Attack +1"],
        ["ENERGY PACK", "energy", "Starting Energy +1"],
        ["TURBO CHARGER", "rapid", "Starting Rapid +1"],
        ["LIFE GAUGE", "life", "Maximum Life +12"],
    ]
    for i: int in range(cards.size()):
        var rect := Rect2(190.0 + float(i) * 230.0, 232.0, 210.0, 244.0)
        panel(rect, i == workshop_index)
        var key: String = str(cards[i][1])
        var cost: Dictionary = permanent_cost(key)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16.0, rect.position.y + 42.0), str(cards[i][0]), HORIZONTAL_ALIGNMENT_LEFT, 178.0, 14, C_TEXT)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16.0, rect.position.y + 72.0), "RANK %d" % int(permanent[key]), HORIZONTAL_ALIGNMENT_LEFT, 178.0, 12, C_BLUE)
        draw_multiline_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16.0, rect.position.y + 112.0), str(cards[i][2]), HORIZONTAL_ALIGNMENT_LEFT, 178.0, 12, 17, C_MUTED)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16.0, rect.position.y + 190.0), "%d Z   %d R" % [int(cost["z"]), int(cost["r"])], HORIZONTAL_ALIGNMENT_LEFT, 178.0, 13, C_GOLD)
        draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 16.0, rect.position.y + 221.0), "INSTALL", HORIZONTAL_ALIGNMENT_LEFT, 178.0, 11, C_BLUE if i == workshop_index else C_MUTED)
    draw_string(ThemeDB.fallback_font, Vector2(350.0, 610.0), "Enter to install   Esc to return", HORIZONTAL_ALIGNMENT_CENTER, 580.0, 13, C_MUTED)

func draw_result(victory: bool) -> void:
    draw_rect(Rect2(0.0, 0.0, W, H), Color(0.0, 0.0, 0.0, 0.76), true)
    panel(Rect2(380.0, 178.0, 520.0, 350.0))
    var title: String = "GUARDIAN DEFEATED" if victory else "DIG FAILED"
    draw_string(ThemeDB.fallback_font, Vector2(420.0, 240.0), title, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 34, C_GREEN if victory else C_DANGER)
    draw_string(ThemeDB.fallback_font, Vector2(420.0, 298.0), "Score %d" % score, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 17, C_TEXT)
    draw_string(ThemeDB.fallback_font, Vector2(420.0, 330.0), "Reaverbots destroyed %d" % kills, HORIZONTAL_ALIGNMENT_CENTER, 440.0, 14, C_MUTED)
    draw_string(ThemeDB.fallback_font, Vector2(420.0, 364.0), "Recovered %d Zenny   %d Refractor Shards" % [zenny, refractors], HORIZONTAL_ALIGNMENT_CENTER, 440.0, 14, C_GOLD)
    draw_string(ThemeDB.fallback_font, Vector2(420.0, 414.0), "Roll has banked the recovered resources.", HORIZONTAL_ALIGNMENT_CENTER, 440.0, 13, C_MUTED)
    draw_string(ThemeDB.fallback_font, Vector2(420.0, 480.0), "Press Enter", HORIZONTAL_ALIGNMENT_CENTER, 440.0, 14, C_BLUE)

func draw_message_banner(text: String) -> void:
    var alpha: float = minf(1.0, message_timer * 2.2)
    draw_rect(Rect2(410.0, 104.0, 460.0, 52.0), Color(0.02, 0.05, 0.08, 0.88 * alpha), true)
    draw_string(ThemeDB.fallback_font, Vector2(425.0, 137.0), text, HORIZONTAL_ALIGNMENT_CENTER, 430.0, 15, Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, alpha))

func draw_radio_box() -> void:
    var rect := Rect2(210.0, 546.0, 860.0, 88.0)
    draw_style_box(make_box(Color(0.02, 0.05, 0.075, 0.96), Color(0.25, 0.70, 0.88, 0.55), 10), rect)
    if radio_speaker == "ROLL":
        draw_texture_rect(TEX_ROLL, Rect2(224.0, 552.0, 62.0, 76.0), false)
    else:
        draw_texture_rect(TEX_DATA, Rect2(224.0, 552.0, 62.0, 76.0), false)
    draw_string(ThemeDB.fallback_font, Vector2(300.0, 570.0), radio_speaker, HORIZONTAL_ALIGNMENT_LEFT, 150.0, 13, C_BLUE)
    draw_multiline_string(ThemeDB.fallback_font, Vector2(300.0, 592.0), radio_text, HORIZONTAL_ALIGNMENT_LEFT, 748.0, 13, 18, C_TEXT)

func panel(rect: Rect2, hot: bool = false) -> void:
    draw_style_box(make_box(C_PANEL_HOT if hot else C_PANEL, C_BLUE if hot else Color(1.0, 1.0, 1.0, 0.10), 12), rect)

func button(rect: Rect2, label: String, hot: bool) -> void:
    draw_style_box(make_box(Color("16384f") if hot else C_PANEL, C_BLUE if hot else Color(1.0, 1.0, 1.0, 0.12), 12), rect)
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, rect.position.y + 38.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, C_TEXT)

func make_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(1)
    box.set_corner_radius_all(radius)
    return box

func time_string() -> String:
    var total: int = int(run_time)
    return "%02d:%02d" % [total / 60, total % 60]

func run_self_test() -> void:
    print("SELFTEST: begin")
    new_run()
    if shot_slots.size() < 6:
        push_error("SELFTEST: expected reusable Buster slots")
        get_tree().quit(2)
        return
    var fired: bool = fire_one_ready_slot(false)
    if not fired or projectiles.is_empty():
        push_error("SELFTEST: reusable shot launch failed")
        get_tree().quit(3)
        return
    var slot_index: int = int(projectiles[0]["slot"])
    projectiles[0]["mode"] = "returning"
    projectiles[0]["pos"] = player_pos + Vector2(5.0, 0.0)
    update_projectiles(0.05)
    if slot_index < 0 or str(shot_slots[slot_index]["state"]) != "cooldown":
        push_error("SELFTEST: projectile return/recharge failed")
        get_tree().quit(4)
        return
    update_slot_cooldowns(1.0)
    if str(shot_slots[slot_index]["state"]) != "ready":
        push_error("SELFTEST: slot did not become ready")
        get_tree().quit(5)
        return
    spawn_wave()
    if enemies.is_empty():
        push_error("SELFTEST: formation spawn failed")
        get_tree().quit(6)
        return
    program_levels["flame"] = 3
    program_levels["cryo"] = 3
    ensure_program_slot("cryo")
    refresh_program_slot("flame")
    refresh_program_slot("cryo")
    var recipe: Dictionary = find_development_recipe()
    if recipe.is_empty():
        push_error("SELFTEST: expected Roll development recipe")
        get_tree().quit(7)
        return
    perform_development(recipe)
    if evolved_owned.is_empty():
        push_error("SELFTEST: evolution/development failed")
        get_tree().quit(8)
        return
    spawn_boss()
    var found_boss: bool = false
    for enemy: Dictionary in enemies:
        if bool(enemy["boss"]):
            found_boss = true
    if not found_boss:
        push_error("SELFTEST: boss spawn failed")
        get_tree().quit(9)
        return
    mode = "run"
    damage_player(5.0)
    if life >= max_life:
        push_error("SELFTEST: player damage failed")
        get_tree().quit(10)
        return
    print("SELFTEST PASS: reusable shots, formations, program development, boss, damage")
    get_tree().quit(0)

func capture_sequence() -> void:
    var screen_dir: String = ProjectSettings.globalize_path("res://build/screens")
    DirAccess.make_dir_recursive_absolute(screen_dir)
    await get_tree().process_frame
    await get_tree().process_frame
    save_runtime_screen(screen_dir.path_join("01_menu.png"))

    new_run()
    spawn_wave()
    spawn_wave()
    for n: int in range(mini(4, shot_slots.size())):
        aim_angle = -PI / 2.0 + (float(n) - 1.5) * 0.18
        fire_one_ready_slot(false)
    await get_tree().create_timer(0.45).timeout
    save_runtime_screen(screen_dir.path_join("02_early_combat.png"))

    program_levels["flame"] = 3
    program_levels["cryo"] = 3
    program_levels["arc"] = 3
    ensure_program_slot("cryo")
    ensure_program_slot("arc")
    refresh_program_slot("flame")
    refresh_program_slot("cryo")
    refresh_program_slot("arc")
    for n: int in range(8):
        spawn_enemy(pick_enemy_kind(), Vector2(randf_range(285.0, 995.0), randf_range(120.0, 355.0)), false, false)
    for n: int in range(shot_slots.size()):
        aim_angle = -PI / 2.0 + randf_range(-0.65, 0.65)
        fire_one_ready_slot(false)
    await get_tree().create_timer(0.55).timeout
    save_runtime_screen(screen_dir.path_join("03_dense_combat.png"))

    recall_and_ready_all()
    terminal_options = build_terminal_options()
    terminal_index = first_enabled_terminal_index()
    mode = "terminal"
    await get_tree().process_frame
    save_runtime_screen(screen_dir.path_join("04_development_terminal.png"))

    mode = "run"
    enemies.clear()
    enemy_shots.clear()
    spawn_boss()
    for n: int in range(7):
        boss_fire(enemies[0], 3)
    for n: int in range(shot_slots.size()):
        aim_angle = -PI / 2.0 + randf_range(-0.45, 0.45)
        fire_one_ready_slot(false)
    await get_tree().create_timer(0.35).timeout
    save_runtime_screen(screen_dir.path_join("05_boss.png"))
    print("CAPTURE PASS: %s" % screen_dir)
    get_tree().quit(0)

func save_runtime_screen(path: String) -> void:
    var image: Image = get_viewport().get_texture().get_image()
    var error: Error = image.save_png(path)
    if error != OK:
        push_error("Failed to save screenshot %s: %s" % [path, error_string(error)])
