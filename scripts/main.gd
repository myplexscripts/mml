extends Node2D

# Mega Man Legends: Kattelox Days
# A non-commercial fan-game prototype built around the MML1 opening structure,
# with a Stardew-like top-down presentation and daily-life loop.

const SCREEN := Vector2(640, 360)
const SURFACE_SIZE := Vector2(1600, 1100)
const RUINS_SIZE := Vector2(1500, 1000)

const C_SKY := Color8(69, 151, 226)
const C_SEA := Color8(46, 142, 198)
const C_GRASS := Color8(111, 161, 77)
const C_GRASS_DARK := Color8(83, 132, 62)
const C_PATH := Color8(207, 193, 145)
const C_STONE := Color8(132, 141, 121)
const C_STONE_DARK := Color8(75, 89, 83)
const C_CREAM := Color8(231, 221, 191)
const C_RED := Color8(190, 67, 57)
const C_YELLOW := Color8(229, 184, 48)
const C_BLUE := Color8(40, 103, 211)
const C_BLUE_DARK := Color8(29, 69, 142)
const C_CYAN := Color8(103, 225, 238)
const C_TEAL := Color8(43, 112, 108)
const C_BROWN := Color8(112, 77, 47)
const C_BLACK := Color8(19, 30, 35)

var world := "surface"
var running := true
var day := 1
var minutes := 8 * 60
var zenny := 300
var repair_percent := 0
var quest_started := false
var ruins_unlocked := false
var tron_event_ready := false
var tron_battle_active := false
var tron_defeated := false
var ending_reached := false

var player_pos := Vector2(360, 810)
var player_facing := Vector2.DOWN
var player_hp := 100
var player_max_hp := 100
var shot_cooldown := 0.0
var dash_cooldown := 0.0
var camera_pos := Vector2.ZERO

var inventory := {
    "servo_motor": false,
    "ancient_circuit": false,
    "large_refractor": false,
}

var friendship := {
    "Roll": 2,
    "Data": 3,
    "Barrell": 1,
    "Mayor Amelia": 0,
    "Tron": 0,
}

var talked_today := {}
var bullets: Array = []
var enemies: Array = []
var particles: Array = []

var dialogue_speaker := ""
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var toast_text := ""
var toast_timer := 0.0

var last_interact_down := false
var last_fire_down := false
var last_sleep_down := false

var surface_obstacles := [
    Rect2(600, 665, 190, 112), # Junk Shop
    Rect2(860, 420, 210, 130), # City Hall
    Rect2(1115, 655, 210, 120), # Museum
    Rect2(980, 850, 160, 100), # Cafe
    Rect2(355, 390, 180, 105), # Police
]

var ruin_walls := [
    Rect2(0, 0, 1500, 48), Rect2(0, 952, 1500, 48),
    Rect2(0, 0, 48, 1000), Rect2(1452, 0, 48, 1000),
    Rect2(300, 48, 48, 410), Rect2(300, 575, 48, 377),
    Rect2(620, 245, 48, 707), Rect2(930, 48, 48, 435),
    Rect2(930, 605, 48, 347), Rect2(1210, 245, 242, 48),
    Rect2(1210, 575, 242, 48),
]

func _ready() -> void:
    get_viewport().set_embedding_subwindows(false)
    set_process(true)
    set_process_input(true)
    _spawn_surface_state()
    _show_dialogue("Roll", [
        "MegaMan! You're awake.",
        "The Flutter took a bad hit when we came down. The rudder and propulsion system are both damaged.",
        "Come talk to me by the Flutter when you're ready. We'll figure out how to get off Kattelox together."
    ])
    queue_redraw()

func _process(delta: float) -> void:
    if not running:
        return

    if toast_timer > 0.0:
        toast_timer -= delta
        if toast_timer <= 0.0:
            toast_text = ""

    if _dialogue_open():
        _handle_dialogue_input()
        queue_redraw()
        return

    minutes += delta * 2.0
    if minutes > 22 * 60:
        minutes = 22 * 60

    shot_cooldown = maxf(0.0, shot_cooldown - delta)
    dash_cooldown = maxf(0.0, dash_cooldown - delta)

    _handle_player(delta)
    _handle_bullets(delta)
    _handle_enemies(delta)
    _handle_pickups()
    _handle_interactions()
    _update_camera()
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            get_tree().quit()

func _handle_player(delta: float) -> void:
    var move := Vector2.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        move.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        move.y += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        move.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        move.x += 1.0

    var speed := 115.0
    if Input.is_key_pressed(KEY_SHIFT) and dash_cooldown <= 0.0 and move.length() > 0.1:
        speed = 225.0
        dash_cooldown = 0.55

    if move.length() > 0.1:
        move = move.normalized()
        player_facing = move
        var proposed := player_pos + move * speed * delta
        _try_move_player(proposed)

    var fire_down := Input.is_key_pressed(KEY_J)
    if fire_down and not last_fire_down:
        _fire_buster()
    last_fire_down = fire_down

    var sleep_down := Input.is_key_pressed(KEY_R)
    if sleep_down and not last_sleep_down:
        _try_sleep()
    last_sleep_down = sleep_down

func _try_move_player(proposed: Vector2) -> void:
    var bounds := Rect2(Vector2(20, 20), SURFACE_SIZE - Vector2(40, 40))
    var blockers := surface_obstacles
    if world == "ruins":
        bounds = Rect2(Vector2(25, 25), RUINS_SIZE - Vector2(50, 50))
        blockers = ruin_walls

    proposed.x = clampf(proposed.x, bounds.position.x, bounds.end.x)
    proposed.y = clampf(proposed.y, bounds.position.y, bounds.end.y)

    var body := Rect2(proposed - Vector2(8, 8), Vector2(16, 16))
    for rect in blockers:
        if body.intersects(rect):
            return
    player_pos = proposed

func _handle_interactions() -> void:
    var interact_down := Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_SPACE)
    if interact_down and not last_interact_down:
        _interact()
    last_interact_down = interact_down

func _interact() -> void:
    if world == "surface":
        for npc_name in ["Roll", "Data", "Barrell", "Mayor Amelia", "Tron"]:
            var npc_pos := _npc_position(npc_name)
            if npc_pos != Vector2(-9999, -9999) and player_pos.distance_to(npc_pos) < 44.0:
                _talk_to(npc_name)
                return

        if ruins_unlocked and player_pos.distance_to(Vector2(790, 315)) < 52.0:
            _enter_ruins()
            return

        if player_pos.distance_to(Vector2(360, 835)) < 105.0:
            if repair_percent >= 100:
                _show_dialogue("Roll", ["The Flutter is flightworthy again. We can leave Kattelox whenever you're ready."])
            else:
                _toast("The Flutter is still under repair.")
            return
    else:
        if player_pos.distance_to(Vector2(750, 905)) < 55.0:
            _leave_ruins()
            return

        if not inventory["servo_motor"] and player_pos.distance_to(Vector2(455, 185)) < 42.0:
            inventory["servo_motor"] = true
            zenny += 150
            _toast("Servo Motor recovered  +150 Zenny")
            return

        if not inventory["ancient_circuit"] and player_pos.distance_to(Vector2(810, 795)) < 42.0:
            inventory["ancient_circuit"] = true
            zenny += 250
            _toast("Ancient Circuit recovered  +250 Zenny")
            return

        if tron_defeated and not inventory["large_refractor"] and player_pos.distance_to(Vector2(1300, 830)) < 60.0:
            inventory["large_refractor"] = true
            zenny += 1000
            _toast("Large Refractor recovered  +1000 Zenny")
            return

func _talk_to(name: String) -> void:
    if name == "Roll":
        _talk_roll()
    elif name == "Data":
        player_hp = player_max_hp
        _show_dialogue("Data", ["Ook ook!", "Data dances happily. MegaMan's energy is fully restored."])
    elif name == "Barrell":
        if inventory["ancient_circuit"]:
            _show_dialogue("Barrell", [
                "That circuit is much older than the ruins near Apple Market.",
                "Kattelox may have been built over something far larger than anyone realizes."
            ])
        else:
            _show_dialogue("Barrell", [
                "Digging is about more than treasure, MegaMan.",
                "Keep your eyes open. The ruins usually tell a story if you're patient enough to listen."
            ])
    elif name == "Mayor Amelia":
        _show_dialogue("Mayor Amelia", [
            "Welcome to Kattelox. I'm sorry your visit began with a crash landing.",
            "You may use the northern ruins while Roll repairs your ship. Please keep any Reaverbots away from the residential districts."
        ])
    elif name == "Tron":
        if not tron_defeated and not tron_battle_active:
            _show_dialogue("Tron", [
                "So you're MegaMan? Hmph. You don't look like much.",
                "That treasure in the ruins belongs to the Bonne family now!",
                "Servbots! Get him!"
            ])
            tron_battle_active = true
            _spawn_servbot_ambush()
        else:
            _show_dialogue("Tron", ["This isn't over, MegaMan!"])

    if not talked_today.has(name):
        talked_today[name] = true
        friendship[name] = int(friendship.get(name, 0)) + 1

func _talk_roll() -> void:
    if not quest_started:
        quest_started = true
        ruins_unlocked = true
        _show_dialogue("Roll", [
            "The Flutter's in rough shape, MegaMan. The landing gear survived, but the propulsion system is a mess.",
            "I need a Servo Motor, an Ancient Circuit, and a Refractor strong enough to restart the main engine.",
            "There's an old ruin north of Central Kattelox. The Junk Shop says Diggers still pull useful parts out of it."
        ])
        return

    if inventory["servo_motor"] and repair_percent < 34:
        inventory["servo_motor"] = false
        repair_percent = 34
        _show_dialogue("Roll", [
            "This servo is perfect! I can rebuild the port stabilizer with it.",
            "There. One system down. We're still grounded, but the Flutter's starting to feel like home again."
        ])
        return

    if inventory["ancient_circuit"] and repair_percent < 67:
        inventory["ancient_circuit"] = false
        repair_percent = 67
        tron_event_ready = true
        _show_dialogue("Roll", [
            "An intact ancient circuit? Nice find! I can adapt this for the navigation controller.",
            "Uh... MegaMan? I just picked up a pirate transmission. Somebody named Tron Bonne is asking around about you."
        ])
        return

    if inventory["large_refractor"] and tron_defeated and repair_percent < 100:
        inventory["large_refractor"] = false
        repair_percent = 100
        ending_reached = true
        _show_dialogue("Roll", [
            "MegaMan... this Refractor is more than enough.",
            "Main engine pressure is stable. Navigation is back. The Flutter can fly again!",
            "We could leave Kattelox tomorrow... but there are still ruins we haven't explored.",
            "Maybe crashing here wasn't such a bad thing after all."
        ])
        _save_game()
        return

    _show_dialogue("Roll", [_current_roll_hint()])

func _current_roll_hint() -> String:
    if repair_percent < 34:
        return "Start with the Servo Motor. Try the upper section of the northern ruin."
    if repair_percent < 67:
        return "The stabilizer is holding. I still need that Ancient Circuit."
    if not tron_defeated:
        return "Keep an eye out for the Bonnes. They're definitely on Kattelox now."
    if repair_percent < 100:
        return "All that's left is a large Refractor for the main engine."
    return "She's ready whenever we are."

func _enter_ruins() -> void:
    world = "ruins"
    player_pos = Vector2(750, 890)
    bullets.clear()
    enemies.clear()
    _spawn_reaverbots()
    _toast("Kattelox Ruins")

func _leave_ruins() -> void:
    world = "surface"
    player_pos = Vector2(790, 365)
    bullets.clear()
    enemies.clear()
    _toast("Central Kattelox")

func _spawn_reaverbots() -> void:
    var points := [
        Vector2(440, 360), Vector2(540, 650), Vector2(760, 470),
        Vector2(1050, 220), Vector2(1110, 720), Vector2(1320, 510)
    ]
    for p in points:
        enemies.append({"pos": p, "hp": 3, "kind": "reaverbot", "cool": randf_range(0.6, 1.8)})

func _spawn_servbot_ambush() -> void:
    var points := [Vector2(780, 565), Vector2(840, 585), Vector2(900, 565), Vector2(810, 625), Vector2(875, 625)]
    for p in points:
        enemies.append({"pos": p, "hp": 2, "kind": "servbot", "cool": 999.0})
    player_pos = Vector2(835, 710)
    _toast("Bonne ambush!")

func _fire_buster() -> void:
    if shot_cooldown > 0.0 or _dialogue_open():
        return
    shot_cooldown = 0.16
    var direction := player_facing.normalized()
    if direction.length() < 0.1:
        direction = Vector2.DOWN
    bullets.append({
        "pos": player_pos + direction * 13.0,
        "vel": direction * 340.0,
        "life": 1.2,
        "enemy": false
    })

func _handle_bullets(delta: float) -> void:
    for i in range(bullets.size() - 1, -1, -1):
        var b: Dictionary = bullets[i]
        b["pos"] += b["vel"] * delta
        b["life"] -= delta

        if bool(b["enemy"]):
            if Vector2(b["pos"]).distance_to(player_pos) < 12.0:
                bullets.remove_at(i)
                player_hp -= 8
                _toast("MegaMan took damage")
                if player_hp <= 0:
                    _knock_out()
                continue
        else:
            var hit := false
            for e_i in range(enemies.size() - 1, -1, -1):
                var e: Dictionary = enemies[e_i]
                if Vector2(b["pos"]).distance_to(Vector2(e["pos"])) < 18.0:
                    e["hp"] = int(e["hp"]) - 1
                    bullets.remove_at(i)
                    hit = true
                    _spark(Vector2(e["pos"]))
                    if int(e["hp"]) <= 0:
                        var reward := 120 if String(e["kind"]) == "reaverbot" else 80
                        zenny += reward
                        enemies.remove_at(e_i)
                        _toast(("Reaverbot destroyed" if String(e["kind"]) == "reaverbot" else "Servbot defeated") + "  +%d Zenny" % reward)
                    break
            if hit:
                continue

        if float(b["life"]) <= 0.0:
            bullets.remove_at(i)

func _handle_enemies(delta: float) -> void:
    for i in range(enemies.size()):
        var enemy: Dictionary = enemies[i]
        var ep := Vector2(enemy["pos"])
        var distance := ep.distance_to(player_pos)
        if distance < 215.0 and distance > 28.0:
            ep += ep.direction_to(player_pos) * 28.0 * delta
            enemy["pos"] = ep

        enemy["cool"] = float(enemy["cool"]) - delta
        if String(enemy["kind"]) == "reaverbot" and distance < 240.0 and float(enemy["cool"]) <= 0.0:
            enemy["cool"] = randf_range(1.3, 2.0)
            var dir := ep.direction_to(player_pos)
            bullets.append({"pos": ep, "vel": dir * 165.0, "life": 2.3, "enemy": true})

    if tron_battle_active:
        var any_servbots := false
        for enemy in enemies:
            if String(enemy["kind"]) == "servbot":
                any_servbots = true
                break
        if not any_servbots:
            tron_battle_active = false
            tron_defeated = true
            _show_dialogue("Tron", [
                "What?! You beat all of them?",
                "Fine! Keep your stupid ruins for now. But this isn't over, MegaMan!"
            ])

func _handle_pickups() -> void:
    if world != "ruins":
        return

func _knock_out() -> void:
    player_hp = player_max_hp
    world = "surface"
    player_pos = Vector2(360, 790)
    enemies.clear()
    bullets.clear()
    minutes = minf(minutes + 60.0, 22.0 * 60.0)
    _show_dialogue("Roll", [
        "MegaMan! Data found you and dragged you back to the Flutter.",
        "Don't push yourself that hard. Those Reaverbots aren't going anywhere."
    ])

func _try_sleep() -> void:
    if world != "surface" or player_pos.distance_to(Vector2(360, 835)) > 105.0:
        _toast("You can only sleep aboard the Flutter.")
        return
    day += 1
    minutes = 8 * 60
    player_hp = player_max_hp
    talked_today.clear()
    _save_game()
    _toast("Day %d" % day)

func _save_game() -> void:
    var save := {
        "day": day,
        "minutes": minutes,
        "zenny": zenny,
        "repair_percent": repair_percent,
        "quest_started": quest_started,
        "ruins_unlocked": ruins_unlocked,
        "tron_event_ready": tron_event_ready,
        "tron_defeated": tron_defeated,
        "ending_reached": ending_reached,
        "friendship": friendship,
    }
    var file := FileAccess.open("user://kattelox_days_save.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(save))

func _handle_dialogue_input() -> void:
    var interact_down := Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_F) or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)
    if interact_down and not last_interact_down:
        dialogue_index += 1
        if dialogue_index >= dialogue_lines.size():
            dialogue_lines.clear()
            dialogue_speaker = ""
            dialogue_index = 0
    last_interact_down = interact_down

func _show_dialogue(speaker: String, lines: Array) -> void:
    dialogue_speaker = speaker
    dialogue_lines.clear()
    for line in lines:
        dialogue_lines.append(String(line))
    dialogue_index = 0

func _dialogue_open() -> bool:
    return dialogue_lines.size() > 0

func _toast(text: String) -> void:
    toast_text = text
    toast_timer = 1.6

func _spark(pos: Vector2) -> void:
    for i in range(5):
        particles.append({"pos": pos, "vel": Vector2(randf_range(-35, 35), randf_range(-35, 35)), "life": 0.35})

func _spawn_surface_state() -> void:
    enemies.clear()

func _npc_position(name: String) -> Vector2:
    if world != "surface":
        return Vector2(-9999, -9999)
    var hour := minutes / 60.0
    match name:
        "Roll":
            return Vector2(455, 820) if hour < 11.0 else Vector2(650, 720)
        "Data":
            return Vector2(325, 855) if hour < 14.0 else Vector2(1035, 875)
        "Barrell":
            return Vector2(390, 785) if hour < 10.0 else Vector2(1220, 815)
        "Mayor Amelia":
            return Vector2(965, 575) if hour < 17.0 else Vector2(1040, 875)
        "Tron":
            if tron_event_ready and not tron_defeated:
                return Vector2(825, 585)
    return Vector2(-9999, -9999)

func _update_camera() -> void:
    var size := SURFACE_SIZE if world == "surface" else RUINS_SIZE
    var desired := player_pos - SCREEN * 0.5
    desired.x = clampf(desired.x, 0.0, maxf(0.0, size.x - SCREEN.x))
    desired.y = clampf(desired.y, 0.0, maxf(0.0, size.y - SCREEN.y))
    camera_pos = camera_pos.lerp(desired, 0.14)

func _objective_text() -> String:
    if ending_reached:
        return "Flutter repaired. Kattelox remains open to explore."
    if not quest_started:
        return "Talk to Roll at the crash site."
    if repair_percent < 34:
        return "Find a Servo Motor in the ruins."
    if repair_percent < 67:
        return "Find an Ancient Circuit deeper in the ruins."
    if not tron_defeated:
        return "Deal with the Bonne pirates in Central Kattelox."
    if repair_percent < 100:
        return "Find a large Refractor in the ruin core."
    return "Talk to Roll."

func _draw() -> void:
    if world == "surface":
        _draw_surface()
    else:
        _draw_ruins()

    _draw_enemies()
    _draw_bullets()
    _draw_player()
    _draw_hud()

    if _dialogue_open():
        _draw_dialogue()
    elif toast_text != "":
        _draw_toast()

func _draw_surface() -> void:
    draw_rect(Rect2(Vector2.ZERO, SCREEN), C_SEA)
    var offset := -camera_pos
    draw_rect(Rect2(offset + Vector2(0, 170), Vector2(SURFACE_SIZE.x, SURFACE_SIZE.y - 170)), C_GRASS)

    # Cliff band and shoreline.
    draw_rect(Rect2(offset + Vector2(0, 170), Vector2(SURFACE_SIZE.x, 42)), Color8(154, 143, 110))
    for x in range(0, int(SURFACE_SIZE.x), 48):
        var shade := Color8(142, 132, 102) if (x / 48) % 2 == 0 else Color8(166, 154, 117)
        draw_rect(Rect2(offset + Vector2(x, 176), Vector2(38, 30)), shade)

    # Main Kattelox roads.
    draw_rect(Rect2(offset + Vector2(180, 550), Vector2(1260, 84)), C_PATH)
    draw_rect(Rect2(offset + Vector2(745, 300), Vector2(88, 620)), C_PATH)
    draw_rect(Rect2(offset + Vector2(240, 820), Vector2(1000, 70)), C_PATH)

    # Grass pixel accents.
    for i in range(60):
        var gx := float((i * 127) % 1500 + 40)
        var gy := float(260 + ((i * 211) % 760))
        draw_rect(Rect2(offset + Vector2(gx, gy), Vector2(3, 3)), C_GRASS_DARK)

    _draw_flutter(Vector2(360, 850))
    _draw_building(Vector2(600, 665), Vector2(190, 112), Color8(177, 78, 59), "JUNK SHOP")
    _draw_building(Vector2(860, 420), Vector2(210, 130), Color8(82, 113, 145), "CITY HALL")
    _draw_building(Vector2(1115, 655), Vector2(210, 120), Color8(153, 91, 70), "MUSEUM")
    _draw_building(Vector2(980, 850), Vector2(160, 100), Color8(95, 130, 101), "CAFE")
    _draw_building(Vector2(355, 390), Vector2(180, 105), Color8(97, 119, 145), "POLICE")

    # Ruin entrance.
    var entrance := Vector2(790, 315) + offset
    draw_rect(Rect2(entrance - Vector2(45, 22), Vector2(90, 44)), C_STONE_DARK)
    draw_rect(Rect2(entrance - Vector2(24, 3), Vector2(48, 28)), C_BLACK)
    _label("RUINS", entrance + Vector2(-20, -29), 10, C_CREAM)

    # Trees, docks and environmental clutter.
    var tree_points := [Vector2(500, 700), Vector2(550, 900), Vector2(1180, 880), Vector2(1290, 830), Vector2(1190, 520), Vector2(560, 470), Vector2(250, 660), Vector2(1390, 650)]
    for p in tree_points:
        _draw_tree(p + offset)

    draw_rect(Rect2(offset + Vector2(190, 1030), Vector2(980, 12)), C_BROWN)
    for x in range(210, 1160, 56):
        draw_rect(Rect2(offset + Vector2(x, 1042), Vector2(38, 18)), Color8(205, 186, 135))

    for npc in ["Roll", "Data", "Barrell", "Mayor Amelia", "Tron"]:
        var np := _npc_position(npc)
        if np != Vector2(-9999, -9999):
            _draw_npc(npc, np + offset)

func _draw_ruins() -> void:
    draw_rect(Rect2(Vector2.ZERO, SCREEN), Color8(19, 38, 40))
    var offset := -camera_pos
    draw_rect(Rect2(offset, RUINS_SIZE), Color8(56, 75, 72))

    # Repeating ancient panels.
    for x in range(0, int(RUINS_SIZE.x), 64):
        draw_line(offset + Vector2(x, 0), offset + Vector2(x, RUINS_SIZE.y), Color8(73, 93, 88), 1.0)
    for y in range(0, int(RUINS_SIZE.y), 64):
        draw_line(offset + Vector2(0, y), offset + Vector2(RUINS_SIZE.x, y), Color8(73, 93, 88), 1.0)

    for wall in ruin_walls:
        draw_rect(Rect2(wall.position + offset, wall.size), C_STONE)
        draw_rect(Rect2(wall.position + offset + Vector2(4, 4), wall.size - Vector2(8, 8)), Color8(113, 125, 111), false, 2.0)

    # Ancient circular wall nodes.
    for p in [Vector2(150, 170), Vector2(470, 510), Vector2(790, 155), Vector2(1100, 760)]:
        draw_circle(p + offset, 18, Color8(31, 78, 76))
        draw_circle(p + offset, 9, Color8(71, 159, 153))

    if not inventory["servo_motor"] and repair_percent < 34:
        _draw_treasure_box(Vector2(455, 185) + offset, C_YELLOW)
        _label("SERVO", Vector2(435, 218) + offset, 9, C_CREAM)
    if not inventory["ancient_circuit"] and repair_percent < 67:
        _draw_treasure_box(Vector2(810, 795) + offset, C_TEAL)
        _label("CIRCUIT", Vector2(783, 828) + offset, 9, C_CREAM)
    if tron_defeated and not inventory["large_refractor"] and repair_percent < 100:
        _draw_refractor(Vector2(1300, 830) + offset)

    var exit_pos := Vector2(750, 905) + offset
    draw_rect(Rect2(exit_pos - Vector2(44, 17), Vector2(88, 34)), C_BLACK)
    _label("EXIT", exit_pos + Vector2(-14, 4), 10, C_CREAM)

func _draw_flutter(world_pos: Vector2) -> void:
    var p := world_pos - camera_pos
    draw_circle(p + Vector2(0, 15), 78, Color(0, 0, 0, 0.12))
    draw_rect(Rect2(p + Vector2(-76, -30), Vector2(152, 64)), C_YELLOW)
    draw_rect(Rect2(p + Vector2(-76, -30), Vector2(152, 16)), C_RED)
    draw_rect(Rect2(p + Vector2(-48, -14), Vector2(96, 24)), Color8(37, 82, 119))
    for x in [-42, -18, 6, 30]:
        draw_rect(Rect2(p + Vector2(x, -10), Vector2(18, 16)), Color8(83, 153, 198))
    draw_rect(Rect2(p + Vector2(50, -68), Vector2(18, 42)), C_RED)
    draw_rect(Rect2(p + Vector2(-96, -4), Vector2(28, 26)), C_RED)
    draw_rect(Rect2(p + Vector2(68, -4), Vector2(28, 26)), C_RED)
    draw_circle(p + Vector2(56, 14), 7, Color8(55, 208, 103))
    draw_line(p + Vector2(-62, -37), p + Vector2(54, -37), Color8(74, 79, 78), 2.0)
    for x in range(-58, 56, 18):
        draw_line(p + Vector2(x, -37), p + Vector2(x, -48), Color8(74, 79, 78), 2.0)

    if repair_percent < 100:
        draw_line(p + Vector2(73, 16), p + Vector2(90, 29), Color8(63, 51, 41), 3.0)
    if repair_percent < 67:
        draw_circle(p + Vector2(-58, 16), 11, Color(0.1, 0.1, 0.1, 0.25))
    if repair_percent < 34:
        draw_line(p + Vector2(-60, 30), p + Vector2(-72, 48), C_BROWN, 3.0)

func _draw_building(pos: Vector2, size: Vector2, roof: Color, title: String) -> void:
    var p := pos - camera_pos
    draw_rect(Rect2(p, size), C_CREAM)
    draw_rect(Rect2(p + Vector2(-4, -10), Vector2(size.x + 8, 18)), roof)
    draw_rect(Rect2(p + Vector2(20, size.y - 38), Vector2(24, 38)), Color8(82, 108, 126))
    draw_rect(Rect2(p + Vector2(size.x - 40, 30), Vector2(22, 22)), Color8(96, 137, 164))
    _label(title, p + Vector2(8, size.y + 14), 9, C_BLACK)

func _draw_tree(p: Vector2) -> void:
    draw_rect(Rect2(p + Vector2(-3, 3), Vector2(6, 18)), Color8(102, 73, 45))
    draw_circle(p + Vector2(0, -4), 15, Color8(64, 117, 57))
    draw_circle(p + Vector2(-10, 1), 10, Color8(79, 139, 65))
    draw_circle(p + Vector2(10, 1), 10, Color8(79, 139, 65))

func _draw_player() -> void:
    var p := player_pos - camera_pos
    draw_circle(p + Vector2(0, 11), 10, Color(0, 0, 0, 0.18))
    draw_rect(Rect2(p + Vector2(-7, -4), Vector2(14, 18)), C_BLUE)
    draw_rect(Rect2(p + Vector2(-11, -2), Vector2(4, 14)), C_BLUE)
    draw_rect(Rect2(p + Vector2(7, -2), Vector2(5, 14)), C_BLUE_DARK)
    draw_rect(Rect2(p + Vector2(-6, 13), Vector2(5, 9)), Color8(178, 188, 198))
    draw_rect(Rect2(p + Vector2(1, 13), Vector2(5, 9)), Color8(178, 188, 198))
    draw_rect(Rect2(p + Vector2(-7, 20), Vector2(6, 4)), C_BLUE_DARK)
    draw_rect(Rect2(p + Vector2(1, 20), Vector2(6, 4)), C_BLUE_DARK)
    draw_circle(p + Vector2(0, -12), 7, Color8(237, 184, 139))
    draw_rect(Rect2(p + Vector2(-7, -18), Vector2(14, 6)), Color8(89, 49, 38))
    draw_rect(Rect2(p + Vector2(-4, 2), Vector2(8, 6)), Color8(226, 124, 42))

func _draw_npc(name: String, p: Vector2) -> void:
    draw_circle(p + Vector2(0, 9), 9, Color(0, 0, 0, 0.14))
    if name == "Roll":
        draw_circle(p + Vector2(0, -11), 6, Color8(238, 185, 137))
        draw_rect(Rect2(p + Vector2(-7, -5), Vector2(14, 19)), C_RED)
        draw_rect(Rect2(p + Vector2(-7, -18), Vector2(14, 6)), Color8(226, 196, 72))
    elif name == "Data":
        draw_circle(p + Vector2(0, -7), 8, Color8(213, 208, 194))
        draw_rect(Rect2(p + Vector2(-6, 0), Vector2(12, 12)), Color8(68, 74, 76))
        draw_circle(p + Vector2(-3, -8), 1.5, C_BLACK)
        draw_circle(p + Vector2(3, -8), 1.5, C_BLACK)
    elif name == "Barrell":
        draw_circle(p + Vector2(0, -10), 7, Color8(219, 174, 132))
        draw_rect(Rect2(p + Vector2(-8, -4), Vector2(16, 22)), Color8(211, 207, 188))
        draw_rect(Rect2(p + Vector2(-7, -7), Vector2(14, 4)), Color.WHITE)
    elif name == "Mayor Amelia":
        draw_circle(p + Vector2(0, -10), 7, Color8(231, 181, 137))
        draw_rect(Rect2(p + Vector2(-7, -4), Vector2(14, 22)), Color8(84, 121, 174))
    elif name == "Tron":
        draw_circle(p + Vector2(0, -11), 7, Color8(238, 176, 132))
        draw_rect(Rect2(p + Vector2(-8, -5), Vector2(16, 23)), Color8(132, 43, 87))
        draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -17), p + Vector2(-17, -11), p + Vector2(-7, -9)]), Color8(55, 32, 62))
        draw_colored_polygon(PackedVector2Array([p + Vector2(8, -17), p + Vector2(17, -11), p + Vector2(7, -9)]), Color8(55, 32, 62))
    _label(name, p + Vector2(-18, 31), 8, Color.WHITE)

func _draw_enemies() -> void:
    for enemy in enemies:
        var p := Vector2(enemy["pos"]) - camera_pos
        draw_circle(p + Vector2(0, 11), 11, Color(0, 0, 0, 0.18))
        if String(enemy["kind"]) == "servbot":
            draw_rect(Rect2(p + Vector2(-8, -14), Vector2(16, 14)), C_YELLOW)
            draw_circle(p + Vector2(-3, -8), 1.5, C_BLACK)
            draw_circle(p + Vector2(3, -8), 1.5, C_BLACK)
            draw_rect(Rect2(p + Vector2(-7, 0), Vector2(14, 15)), Color8(41, 92, 166))
            draw_rect(Rect2(p + Vector2(-11, 1), Vector2(4, 9)), Color8(235, 143, 57))
            draw_rect(Rect2(p + Vector2(7, 1), Vector2(4, 9)), Color8(235, 143, 57))
        else:
            draw_circle(p, 16, Color8(113, 132, 125))
            draw_arc(p, 12, 0.0, TAU, 16, Color8(66, 88, 84), 4.0)
            draw_circle(p + Vector2(0, 1), 4, Color8(236, 65, 53))
            draw_rect(Rect2(p + Vector2(-14, 12), Vector2(5, 13)), Color8(77, 100, 96))
            draw_rect(Rect2(p + Vector2(9, 12), Vector2(5, 13)), Color8(77, 100, 96))

func _draw_bullets() -> void:
    for b in bullets:
        var p := Vector2(b["pos"]) - camera_pos
        draw_circle(p, 3.5, Color8(255, 101, 89) if bool(b["enemy"]) else Color8(151, 243, 255))

func _draw_treasure_box(p: Vector2, accent: Color) -> void:
    draw_rect(Rect2(p + Vector2(-16, -10), Vector2(32, 20)), Color8(137, 91, 48))
    draw_rect(Rect2(p + Vector2(-3, -10), Vector2(6, 20)), accent)

func _draw_refractor(p: Vector2) -> void:
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(0, -31), p + Vector2(20, -10), p + Vector2(14, 20),
        p + Vector2(0, 35), p + Vector2(-16, 18), p + Vector2(-20, -11)
    ]), Color8(75, 210, 229))
    draw_colored_polygon(PackedVector2Array([
        p + Vector2(0, -31), p + Vector2(20, -10), p + Vector2(0, 2), p + Vector2(-20, -11)
    ]), Color8(163, 247, 255))

func _draw_hud() -> void:
    draw_rect(Rect2(8, 8, 112, 48), Color(0.03, 0.08, 0.12, 0.78))
    _label("DAY %d" % day, Vector2(16, 23), 9, Color8(194, 209, 219))
    _label(_time_string(), Vector2(16, 42), 14, Color.WHITE)
    _label("%d Z" % zenny, Vector2(76, 42), 11, C_YELLOW)

    draw_rect(Rect2(455, 8, 177, 55), Color(0.03, 0.08, 0.12, 0.78))
    _label("FLUTTER REPAIR", Vector2(464, 21), 8, Color8(194, 209, 219))
    draw_rect(Rect2(464, 27, 158, 7), Color8(52, 70, 77))
    draw_rect(Rect2(464, 27, 158.0 * float(repair_percent) / 100.0, 7), C_YELLOW)
    _label(_objective_text(), Vector2(464, 49), 8, Color.WHITE)

    draw_rect(Rect2(8, 66, 12, 92), Color(0.03, 0.08, 0.12, 0.68))
    var hp_height := 86.0 * float(player_hp) / float(player_max_hp)
    draw_rect(Rect2(11, 69 + 86 - hp_height, 6, hp_height), Color8(72, 213, 126))

func _draw_dialogue() -> void:
    draw_rect(Rect2(14, 270, 612, 78), Color(0.03, 0.10, 0.16, 0.95))
    draw_rect(Rect2(24, 280, 54, 54), Color8(38, 65, 82))
    _label(dialogue_speaker.left(1), Vector2(43, 316), 24, C_YELLOW)
    _label(dialogue_speaker, Vector2(90, 292), 12, Color8(247, 211, 123))
    if dialogue_index < dialogue_lines.size():
        _wrapped_label(dialogue_lines[dialogue_index], Vector2(90, 311), 520, 10, Color.WHITE)
    _label("E / F / SPACE", Vector2(526, 339), 8, Color8(142, 166, 181))

func _draw_toast() -> void:
    var width := maxf(140.0, float(toast_text.length()) * 6.0 + 24.0)
    draw_rect(Rect2((SCREEN.x - width) * 0.5, 316, width, 28), Color(0.02, 0.05, 0.07, 0.88))
    _label(toast_text, Vector2((SCREEN.x - width) * 0.5 + 12, 334), 9, Color.WHITE)

func _label(text: String, pos: Vector2, size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _wrapped_label(text: String, pos: Vector2, width: float, size: int, color: Color) -> void:
    var words := text.split(" ")
    var line := ""
    var y := pos.y
    for word in words:
        var proposed := line + (" " if line != "" else "") + String(word)
        var measured := ThemeDB.fallback_font.get_string_size(proposed, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
        if measured > width and line != "":
            _label(line, Vector2(pos.x, y), size, color)
            line = String(word)
            y += size + 4
        else:
            line = proposed
    if line != "":
        _label(line, Vector2(pos.x, y), size, color)

func _time_string() -> String:
    var hour24 := int(minutes / 60.0) % 24
    var minute := int(minutes) % 60
    var suffix := "PM" if hour24 >= 12 else "AM"
    var hour12 := hour24 % 12
    if hour12 == 0:
        hour12 = 12
    return "%d:%02d %s" % [hour12, minute, suffix]
