extends Node2D

const W: float = 1280.0
const H: float = 720.0
const ARENA: Rect2 = Rect2(185.0, 54.0, 910.0, 602.0)
const PLAYER_POS: Vector2 = Vector2(640.0, 610.0)
const TOP_Y: float = 86.0
const FLOOR_Y: float = 596.0

const C_TEXT: Color = Color("f5f7fb")
const C_MUTED: Color = Color("99a9bd")
const C_BLUE: Color = Color("56d2ff")
const C_DANGER: Color = Color("ff5b55")
const C_GREEN: Color = Color("8dff9b")
const C_GOLD: Color = Color("ffd85d")
const C_PANEL: Color = Color(0.035, 0.055, 0.09, 0.94)
const C_PANEL_HOT: Color = Color(0.065, 0.095, 0.145, 0.98)

const TEX_MM: Texture2D = preload("res://assets/characters/megaman.png")
const TEX_HOROKKO: Texture2D = preload("res://assets/characters/horokko.png")
const TEX_SHARUKURUSU: Texture2D = preload("res://assets/characters/sharukurusu.png")
const TEX_ZAKOBON: Texture2D = preload("res://assets/characters/zakobon.png")
const TEX_GUARDIAN: Texture2D = preload("res://assets/characters/guardian.png")
const TEX_BOSS: Texture2D = preload("res://assets/world/bonne_mech.png")
const TEX_RUIN_FLOOR: Texture2D = preload("res://assets/world/ruin_floor.png")
const TEX_RUIN_PILLAR: Texture2D = preload("res://assets/world/ruin_pillar.png")
const TEX_RUIN_PANEL: Texture2D = preload("res://assets/world/ruin_panel.png")
const TEX_RUIN_ENTRANCE: Texture2D = preload("res://assets/world/ruin_entrance.png")
const TEX_WORKBENCH: Texture2D = preload("res://assets/world/workbench.png")
const TEX_SALVAGE: Texture2D = preload("res://assets/world/salvage.png")
const TEX_RELIC: Texture2D = preload("res://assets/world/relic_display.png")
const TEX_DATA: Texture2D = preload("res://assets/characters/data.png")

const ENEMY_KEYS: Array[String] = ["horokko", "zakobon", "sharukurusu", "guardian"]

var mode: String = "menu"
var menu_index: int = 0
var upgrade_index: int = 0
var workshop_index: int = 0

var shots: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var effects: Array[Dictionary] = []

var run_time: float = 0.0
var score: int = 0
var kills: int = 0
var level: int = 1
var xp: float = 0.0
var xp_next: float = 16.0
var life: float = 100.0
var max_life: float = 100.0
var zenny: int = 0
var refractors: int = 0
var combo: int = 0
var combo_timer: float = 0.0
var aim_angle: float = -PI / 2.0
var fire_timer: float = 0.0
var spawn_timer: float = 0.0
var boss_timer: float = 38.0
var screen_flash: float = 0.0
var shake: float = 0.0
var message: String = ""
var message_timer: float = 0.0

var buster: Dictionary = {
    "attack": 1,
    "rapid": 1,
    "range": 1,
    "energy": 1,
    "ricochet": 2,
    "spread": 1,
}
var bank: Dictionary = {"zenny": 0, "refractors": 0}
var permanent: Dictionary = {"attack": 0, "rapid": 0, "life": 0}
var upgrade_choices: Array[Dictionary] = []

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    randomize()
    load_save()
    queue_redraw()

func _process(delta: float) -> void:
    screen_flash = maxf(0.0, screen_flash - delta * 3.5)
    shake = maxf(0.0, shake - delta * 20.0)
    message_timer = maxf(0.0, message_timer - delta)
    if mode == "run":
        update_run(delta)
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and mode == "run":
        update_aim(event.position)
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if mode == "run":
            fire_buster(true)
        elif mode == "menu":
            if event.position.y > 410.0 and event.position.y < 474.0:
                menu_index = 0
                activate_menu()
            elif event.position.y > 488.0 and event.position.y < 552.0:
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
            if key == KEY_SPACE:
                fire_buster(true)
            elif key == KEY_ESCAPE:
                finish_run()
        elif mode == "levelup":
            if key == KEY_LEFT or key == KEY_A:
                upgrade_index = maxi(0, upgrade_index - 1)
            elif key == KEY_RIGHT or key == KEY_D:
                upgrade_index = mini(upgrade_choices.size() - 1, upgrade_index + 1)
            elif key == KEY_ENTER or key == KEY_SPACE:
                apply_upgrade(upgrade_index)
        elif mode == "workshop":
            if key == KEY_LEFT or key == KEY_A:
                workshop_index = maxi(0, workshop_index - 1)
            elif key == KEY_RIGHT or key == KEY_D:
                workshop_index = mini(2, workshop_index + 1)
            elif key == KEY_ENTER or key == KEY_SPACE:
                var keys: Array[String] = ["attack", "rapid", "life"]
                buy_permanent(keys[workshop_index])
            elif key == KEY_ESCAPE:
                mode = "menu"
        elif mode == "gameover":
            if key == KEY_ENTER or key == KEY_SPACE:
                mode = "menu"

func activate_menu() -> void:
    if menu_index == 0:
        new_run()
    else:
        mode = "workshop"

func new_run() -> void:
    shots.clear()
    enemies.clear()
    enemy_shots.clear()
    pickups.clear()
    effects.clear()
    run_time = 0.0
    score = 0
    kills = 0
    level = 1
    xp = 0.0
    xp_next = 16.0
    max_life = 100.0 + float(permanent["life"]) * 12.0
    life = max_life
    zenny = 0
    refractors = 0
    combo = 0
    combo_timer = 0.0
    aim_angle = -PI / 2.0
    fire_timer = 0.12
    spawn_timer = 0.18
    boss_timer = 38.0
    buster = {
        "attack": 1 + int(permanent["attack"]),
        "rapid": 1 + int(permanent["rapid"]),
        "range": 1,
        "energy": 1,
        "ricochet": 2,
        "spread": 1,
    }
    mode = "run"
    message = "DIG START"
    message_timer = 1.3

func update_aim(mouse: Vector2) -> void:
    var vector: Vector2 = mouse - PLAYER_POS
    if vector.length() > 8.0 and vector.y < -4.0:
        aim_angle = clampf(vector.angle(), -PI + 0.14, -0.14)

func update_run(delta: float) -> void:
    run_time += delta
    combo_timer -= delta
    if combo_timer <= 0.0:
        combo = 0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        aim_angle = maxf(-PI + 0.14, aim_angle - delta * 1.9)
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        aim_angle = minf(-0.14, aim_angle + delta * 1.9)

    fire_timer -= delta
    if fire_timer <= 0.0:
        fire_buster(false)
        fire_timer = maxf(0.19, 0.68 * pow(0.88, float(int(buster["rapid"]) - 1)))

    spawn_timer -= delta
    if spawn_timer <= 0.0:
        spawn_enemy(false)
        spawn_timer = maxf(0.28, 0.88 - run_time * 0.006)

    boss_timer -= delta
    if boss_timer <= 0.0 and not has_boss():
        spawn_enemy(true)
        boss_timer = 54.0
        message = "WARNING: HEAVY REAVERBOT"
        message_timer = 2.0

    update_shots(delta)
    update_enemies(delta)
    update_enemy_shots(delta)
    update_pickups(delta)
    update_effects(delta)

func fire_buster(manual: bool) -> void:
    if mode != "run":
        return
    var count: int = int(buster["spread"])
    var spread_step: float = 0.095
    for i: int in range(count):
        var offset: float = (float(i) - float(count - 1) * 0.5) * spread_step
        var angle: float = aim_angle + offset
        var direction: Vector2 = Vector2(cos(angle), sin(angle))
        shots.append({
            "pos": PLAYER_POS + direction * 34.0,
            "last": PLAYER_POS + direction * 18.0,
            "vel": direction * (520.0 + float(int(buster["energy"]) - 1) * 28.0),
            "life": 2.1 + float(int(buster["range"]) - 1) * 0.32,
            "damage": 13.0 + float(int(buster["attack"]) - 1) * 6.0,
            "bounces": int(buster["ricochet"]),
            "charged": manual,
        })
    effects.append({"type":"muzzle", "pos":PLAYER_POS + Vector2(cos(aim_angle), sin(aim_angle)) * 36.0, "t":0.13})

func enemy_data(key: String) -> Dictionary:
    if key == "horokko":
        return {"name":"HOROKKO", "tex":TEX_HOROKKO, "hp":36.0, "speed":35.0, "radius":24.0, "score":100}
    if key == "zakobon":
        return {"name":"ZAKOBON", "tex":TEX_ZAKOBON, "hp":54.0, "speed":28.0, "radius":27.0, "score":145}
    if key == "sharukurusu":
        return {"name":"SHARUKURUSU", "tex":TEX_SHARUKURUSU, "hp":78.0, "speed":24.0, "radius":31.0, "score":205}
    return {"name":"GUARDIAN", "tex":TEX_GUARDIAN, "hp":118.0, "speed":18.0, "radius":35.0, "score":300}

func spawn_enemy(is_boss: bool) -> void:
    if is_boss:
        var boss_hp: float = 980.0 + run_time * 5.0
        enemies.append({
            "kind":"boss", "name":"BONNE ASSAULT MECH", "tex":TEX_BOSS,
            "pos":Vector2(randf_range(430.0, 850.0), 126.0),
            "hp":boss_hp, "max_hp":boss_hp, "speed":12.0, "radius":66.0,
            "boss":true, "phase":randf()*TAU, "shoot":0.9, "score":2200,
        })
        return
    var key: String = ENEMY_KEYS[randi() % ENEMY_KEYS.size()]
    var data: Dictionary = enemy_data(key)
    var hp_scale: float = 1.0 + run_time / 125.0
    var hp: float = float(data["hp"]) * hp_scale
    enemies.append({
        "kind":key, "name":str(data["name"]), "tex":data["tex"],
        "pos":Vector2(randf_range(245.0, 1035.0), randf_range(104.0, 144.0)),
        "hp":hp, "max_hp":hp,
        "speed":float(data["speed"]) * (1.0 + run_time/320.0),
        "radius":float(data["radius"]), "boss":false, "phase":randf()*TAU,
        "shoot":randf_range(1.3, 3.4), "score":int(data["score"]),
    })

func update_shots(delta: float) -> void:
    for i: int in range(shots.size() - 1, -1, -1):
        var shot: Dictionary = shots[i]
        var pos: Vector2 = shot["pos"]
        var velocity: Vector2 = shot["vel"]
        shot["last"] = pos
        pos += velocity * delta
        shot["life"] = float(shot["life"]) - delta
        var bounced: bool = false
        if pos.x < ARENA.position.x + 8.0:
            pos.x = ARENA.position.x + 8.0
            velocity.x = absf(velocity.x)
            bounced = true
        elif pos.x > ARENA.end.x - 8.0:
            pos.x = ARENA.end.x - 8.0
            velocity.x = -absf(velocity.x)
            bounced = true
        if pos.y < TOP_Y:
            pos.y = TOP_Y
            velocity.y = absf(velocity.y)
            bounced = true
        shot["pos"] = pos
        shot["vel"] = velocity
        if bounced:
            shot["bounces"] = int(shot["bounces"]) - 1
            effects.append({"type":"spark", "pos":pos, "t":0.18})
        var consumed: bool = false
        for enemy: Dictionary in enemies:
            var enemy_pos: Vector2 = enemy["pos"]
            if pos.distance_to(enemy_pos) <= float(enemy["radius"]) + 8.0:
                var multiplier: float = 1.45 if bool(shot["charged"]) else 1.0
                enemy["hp"] = float(enemy["hp"]) - float(shot["damage"]) * multiplier
                effects.append({"type":"hit", "pos":pos, "t":0.18})
                screen_flash = maxf(screen_flash, 0.14)
                shake = maxf(shake, 6.0 if bool(enemy["boss"]) else 3.0)
                combo += 1
                combo_timer = 1.25
                consumed = true
                break
        if consumed or float(shot["life"]) <= 0.0 or int(shot["bounces"]) < 0 or pos.y > FLOOR_Y + 46.0:
            shots.remove_at(i)

func update_enemies(delta: float) -> void:
    for i: int in range(enemies.size() - 1, -1, -1):
        var enemy: Dictionary = enemies[i]
        var is_boss: bool = bool(enemy["boss"])
        var phase: float = float(enemy["phase"]) + delta * (1.1 if is_boss else 2.1)
        var pos: Vector2 = enemy["pos"]
        var drift: float = sin(phase) * (26.0 if is_boss else 38.0)
        pos.x += drift * delta
        pos.x = clampf(pos.x, ARENA.position.x + float(enemy["radius"]), ARENA.end.x - float(enemy["radius"]))
        pos.y += float(enemy["speed"]) * delta
        enemy["phase"] = phase
        enemy["pos"] = pos
        enemy["shoot"] = float(enemy["shoot"]) - delta
        if float(enemy["shoot"]) <= 0.0 and pos.y < 510.0:
            fire_enemy(enemy)
            enemy["shoot"] = randf_range(0.45, 0.8) if is_boss else randf_range(1.5, 3.0)
        if float(enemy["hp"]) <= 0.0:
            enemy_killed(enemy)
            enemies.remove_at(i)
            continue
        if pos.y > FLOOR_Y - 24.0:
            life -= 34.0 if is_boss else 18.0
            effects.append({"type":"hit", "pos":Vector2(pos.x, FLOOR_Y), "t":0.28})
            shake = 9.0
            enemies.remove_at(i)
            if life <= 0.0:
                finish_run()
                return

func fire_enemy(enemy: Dictionary) -> void:
    var enemy_pos: Vector2 = enemy["pos"]
    var direction: Vector2 = (PLAYER_POS - enemy_pos).normalized()
    var is_boss: bool = bool(enemy["boss"])
    var count: int = 3 if is_boss else 1
    for n: int in range(count):
        var angle: float = direction.angle() + (float(n) - float(count - 1) * 0.5) * 0.20
        enemy_shots.append({
            "pos":enemy_pos,
            "vel":Vector2(cos(angle), sin(angle)) * (220.0 if is_boss else 170.0),
            "life":4.0,
            "boss":is_boss,
        })

func update_enemy_shots(delta: float) -> void:
    for i: int in range(enemy_shots.size() - 1, -1, -1):
        var shot: Dictionary = enemy_shots[i]
        var pos: Vector2 = shot["pos"]
        var velocity: Vector2 = shot["vel"]
        pos += velocity * delta
        shot["pos"] = pos
        shot["life"] = float(shot["life"]) - delta
        if pos.distance_to(PLAYER_POS) < 25.0:
            life -= 13.0 if bool(shot["boss"]) else 9.0
            screen_flash = 0.38
            shake = 8.0
            effects.append({"type":"hit", "pos":PLAYER_POS, "t":0.24})
            enemy_shots.remove_at(i)
            if life <= 0.0:
                finish_run()
                return
        elif float(shot["life"]) <= 0.0 or not Rect2(150.0, 30.0, 980.0, 680.0).has_point(pos):
            enemy_shots.remove_at(i)

func enemy_killed(enemy: Dictionary) -> void:
    var is_boss: bool = bool(enemy["boss"])
    var pos: Vector2 = enemy["pos"]
    kills += 1
    score += int(enemy["score"]) + combo * 8
    xp += 38.0 if is_boss else 5.0
    var drops: int = 7 if is_boss else 1
    for n: int in range(drops):
        pickups.append({
            "pos":pos + Vector2(randf_range(-24.0,24.0), randf_range(-18.0,18.0)),
            "kind":"refractor" if (is_boss or randf() < 0.18) else "zenny",
            "t":0.0,
        })
    effects.append({"type":"burst", "pos":pos, "t":0.42})
    if is_boss:
        message = "REFRACTOR CORE EXPOSED"
        message_timer = 2.2
    if xp >= xp_next:
        xp -= xp_next
        level += 1
        xp_next = 15.0 + float(level) * 5.5
        open_level_up()

func update_pickups(delta: float) -> void:
    for i: int in range(pickups.size() - 1, -1, -1):
        var pickup: Dictionary = pickups[i]
        var age: float = float(pickup["t"]) + delta
        var pos: Vector2 = pickup["pos"]
        pickup["t"] = age
        if age > 0.38:
            pos = pos.lerp(PLAYER_POS, minf(1.0, delta * 5.5))
            pickup["pos"] = pos
        if pos.distance_to(PLAYER_POS) < 34.0:
            if str(pickup["kind"]) == "zenny":
                zenny += 14
            else:
                refractors += 1
            pickups.remove_at(i)

func update_effects(delta: float) -> void:
    for i: int in range(effects.size() - 1, -1, -1):
        var effect: Dictionary = effects[i]
        effect["t"] = float(effect["t"]) - delta
        if float(effect["t"]) <= 0.0:
            effects.remove_at(i)

func open_level_up() -> void:
    upgrade_choices = [
        {"name":"POWER RAISER", "desc":"Buster damage +6", "key":"attack"},
        {"name":"TURBO CHARGER", "desc":"Faster automatic firing", "key":"rapid"},
        {"name":"SNIPER UNIT", "desc":"Longer shot lifetime", "key":"range"},
    ]
    var pool: Array[Dictionary] = [
        {"name":"ENERGY PACK", "desc":"Faster buster shots", "key":"energy"},
        {"name":"REFLECTOR PART", "desc":"One extra wall ricochet", "key":"ricochet"},
        {"name":"SPREAD ADAPTER", "desc":"Adds a shot to every volley", "key":"spread"},
    ]
    upgrade_choices[randi() % 3] = pool[randi() % pool.size()]
    upgrade_index = 0
    mode = "levelup"

func apply_upgrade(index: int) -> void:
    if index < 0 or index >= upgrade_choices.size():
        return
    var choice: Dictionary = upgrade_choices[index]
    var key: String = str(choice["key"])
    buster[key] = int(buster[key]) + 1
    mode = "run"
    message = str(choice["name"])
    message_timer = 1.4

func finish_run() -> void:
    if mode != "run":
        return
    bank["zenny"] = int(bank["zenny"]) + zenny
    bank["refractors"] = int(bank["refractors"]) + refractors
    save_game()
    mode = "gameover"

func has_boss() -> bool:
    for enemy: Dictionary in enemies:
        if bool(enemy["boss"]):
            return true
    return false

func permanent_cost(key: String) -> Dictionary:
    var rank: int = int(permanent[key])
    return {"z": 80 + rank * 70, "r": 2 + rank * 2}

func buy_permanent(key: String) -> void:
    var cost: Dictionary = permanent_cost(key)
    if int(bank["zenny"]) >= int(cost["z"]) and int(bank["refractors"]) >= int(cost["r"]):
        bank["zenny"] = int(bank["zenny"]) - int(cost["z"])
        bank["refractors"] = int(bank["refractors"]) - int(cost["r"])
        permanent[key] = int(permanent[key]) + 1
        save_game()
        message = "UPGRADE INSTALLED"
        message_timer = 1.3
    else:
        message = "NOT ENOUGH SALVAGE"
        message_timer = 1.3

func save_game() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("bank", "zenny", int(bank["zenny"]))
    config.set_value("bank", "refractors", int(bank["refractors"]))
    config.set_value("permanent", "attack", int(permanent["attack"]))
    config.set_value("permanent", "rapid", int(permanent["rapid"]))
    config.set_value("permanent", "life", int(permanent["life"]))
    config.save("user://refractor_pit.cfg")

func load_save() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load("user://refractor_pit.cfg") != OK:
        return
    bank["zenny"] = int(config.get_value("bank", "zenny", 0))
    bank["refractors"] = int(config.get_value("bank", "refractors", 0))
    permanent["attack"] = int(config.get_value("permanent", "attack", 0))
    permanent["rapid"] = int(config.get_value("permanent", "rapid", 0))
    permanent["life"] = int(config.get_value("permanent", "life", 0))

func _draw() -> void:
    draw_rect(Rect2(0.0,0.0,W,H), Color("071018"))
    if mode == "menu":
        draw_menu()
    elif mode == "workshop":
        draw_workshop()
    else:
        draw_run_world()
        if mode == "levelup":
            draw_level_up()
        elif mode == "gameover":
            draw_game_over()
    if message_timer > 0.0 and message != "":
        draw_message(message)

func draw_run_world() -> void:
    var offset: Vector2 = Vector2.ZERO
    if shake > 0.1:
        offset = Vector2(randf_range(-shake,shake), randf_range(-shake,shake))
    draw_set_transform(offset)
    draw_ruin_arena()
    draw_player()
    for pickup: Dictionary in pickups:
        draw_pickup(pickup)
    for enemy: Dictionary in enemies:
        draw_enemy(enemy)
    for shot: Dictionary in shots:
        draw_buster_shot(shot)
    for enemy_shot: Dictionary in enemy_shots:
        draw_enemy_shot(enemy_shot)
    for effect: Dictionary in effects:
        draw_effect(effect)
    draw_set_transform(Vector2.ZERO)
    draw_hud()
    if screen_flash > 0.0:
        draw_rect(Rect2(0.0,0.0,W,H), Color(0.55,0.85,1.0,screen_flash * 0.26))

func draw_ruin_arena() -> void:
    draw_rect(Rect2(168.0,38.0,944.0,634.0), Color("03070c"), true)
    draw_rect(ARENA, Color("10242d"), true)
    var tile_size: float = 48.0
    for y: int in range(1, 13):
        for x: int in range(1, 20):
            var rect: Rect2 = Rect2(ARENA.position.x + float(x-1)*tile_size, ARENA.position.y + float(y-1)*tile_size, tile_size, tile_size)
            draw_texture_rect(TEX_RUIN_FLOOR, rect, true, Color(0.78,0.92,0.92,1.0))
    draw_rect(Rect2(ARENA.position.x, ARENA.position.y, ARENA.size.x, 18.0), Color("244957"), true)
    draw_rect(Rect2(ARENA.position.x, FLOOR_Y, ARENA.size.x, 5.0), Color("ff6f44"), true)
    draw_texture_rect(TEX_RUIN_PILLAR, Rect2(186.0,96.0,56.0,170.0), false, Color(0.72,0.9,0.95,1.0))
    draw_texture_rect(TEX_RUIN_PILLAR, Rect2(1002.0,96.0,56.0,170.0), false, Color(0.72,0.9,0.95,1.0))
    draw_texture_rect(TEX_RUIN_PILLAR, Rect2(186.0,410.0,56.0,170.0), false, Color(0.72,0.9,0.95,1.0))
    draw_texture_rect(TEX_RUIN_PILLAR, Rect2(1002.0,410.0,56.0,170.0), false, Color(0.72,0.9,0.95,1.0))
    draw_texture_rect(TEX_RUIN_ENTRANCE, Rect2(557.0,62.0,166.0,100.0), false, Color(0.65,0.85,0.94,1.0))
    draw_texture_rect(TEX_RUIN_PANEL, Rect2(314.0,105.0,72.0,72.0), false, Color(0.68,0.9,0.95,0.85))
    draw_texture_rect(TEX_RUIN_PANEL, Rect2(604.0,105.0,72.0,72.0), false, Color(0.68,0.9,0.95,0.85))
    draw_texture_rect(TEX_RUIN_PANEL, Rect2(894.0,105.0,72.0,72.0), false, Color(0.68,0.9,0.95,0.85))
    draw_line(Vector2(PLAYER_POS.x, PLAYER_POS.y-22.0), PLAYER_POS + Vector2(cos(aim_angle),sin(aim_angle))*116.0, Color(0.3,0.9,1.0,0.28), 2.0)

func draw_player() -> void:
    var size: Vector2 = Vector2(96.0, 92.0)
    draw_circle(PLAYER_POS + Vector2(0.0,20.0), 31.0, Color(0.0,0.0,0.0,0.30))
    draw_texture_rect(TEX_MM, Rect2(PLAYER_POS - size*0.5 + Vector2(0.0,-18.0), size), false)
    var muzzle: Vector2 = PLAYER_POS + Vector2(cos(aim_angle),sin(aim_angle))*39.0
    draw_circle(muzzle, 5.5, Color(0.76,1.0,0.98,0.95))
    draw_circle(muzzle, 2.6, Color.WHITE)

func draw_enemy(enemy: Dictionary) -> void:
    var radius: float = float(enemy["radius"])
    var pos: Vector2 = enemy["pos"]
    var is_boss: bool = bool(enemy["boss"])
    if is_boss:
        draw_circle(pos, radius+18.0, Color(1.0,0.18,0.14,0.10))
    draw_circle(pos + Vector2(0.0,radius*0.55), radius*0.78, Color(0.0,0.0,0.0,0.36))
    var size: Vector2 = Vector2(radius*2.5, radius*2.5)
    if is_boss:
        size = Vector2(190.0,150.0)
    var texture: Texture2D = enemy["tex"]
    draw_texture_rect(texture, Rect2(pos-size*0.5,size), false)
    var ratio: float = clampf(float(enemy["hp"])/float(enemy["max_hp"]),0.0,1.0)
    if is_boss:
        draw_rect(Rect2(396.0,72.0,488.0,13.0),Color("341116"),true)
        draw_rect(Rect2(396.0,72.0,488.0*ratio,13.0),C_DANGER,true)
        draw_string(ThemeDB.fallback_font,Vector2(396.0,64.0),"BONNE ASSAULT MECH",HORIZONTAL_ALIGNMENT_LEFT,260.0,16,C_TEXT)
    elif ratio < 0.99:
        draw_rect(Rect2(pos.x-22.0,pos.y-radius-13.0,44.0,5.0),Color("081014"),true)
        draw_rect(Rect2(pos.x-22.0,pos.y-radius-13.0,44.0*ratio,5.0),C_GREEN,true)

func draw_buster_shot(shot: Dictionary) -> void:
    var pos: Vector2 = shot["pos"]
    var last: Vector2 = shot["last"]
    var colour: Color = Color("fff37d") if bool(shot["charged"]) else Color("b7ffea")
    draw_line(last,pos,Color(colour.r,colour.g,colour.b,0.38),8.0,true)
    draw_circle(pos,10.0,Color(colour.r,colour.g,colour.b,0.18))
    draw_circle(pos,6.2,colour)
    draw_circle(pos-Vector2(2.0,2.0),2.3,Color.WHITE)

func draw_enemy_shot(shot: Dictionary) -> void:
    var pos: Vector2 = shot["pos"]
    var colour: Color = Color("ff4d83") if bool(shot["boss"]) else Color("ff8b55")
    draw_circle(pos,10.0,Color(colour.r,colour.g,colour.b,0.18))
    draw_circle(pos,6.0,colour)
    draw_circle(pos,2.0,Color.WHITE)

func draw_pickup(pickup: Dictionary) -> void:
    var bob: float = sin(float(pickup["t"])*7.0)*4.0
    var base_pos: Vector2 = pickup["pos"]
    var pos: Vector2 = base_pos + Vector2(0.0,bob)
    var is_zenny: bool = str(pickup["kind"]) == "zenny"
    var colour: Color = C_GOLD if is_zenny else Color("58f6ff")
    draw_circle(pos,10.0,Color(colour.r,colour.g,colour.b,0.15))
    draw_circle(pos,5.0,colour)

func draw_effect(effect: Dictionary) -> void:
    var time: float = float(effect["t"])
    var pos: Vector2 = effect["pos"]
    var kind: String = str(effect["type"])
    if kind == "muzzle":
        draw_circle(pos,8.0+time*50.0,Color(0.65,1.0,1.0,clampf(time*3.0,0.0,1.0)))
    elif kind == "hit":
        draw_circle(pos,8.0+time*40.0,Color(0.95,1.0,0.65,clampf(time*2.5,0.0,1.0)),false,3.0)
    elif kind == "spark":
        draw_circle(pos,5.0+time*26.0,Color(0.45,0.95,1.0,clampf(time*2.0,0.0,1.0)),false,2.0)
    elif kind == "burst":
        draw_circle(pos,18.0+time*80.0,Color(1.0,0.45,0.24,clampf(time*1.6,0.0,1.0)),false,5.0)

func draw_hud() -> void:
    draw_panel(Rect2(18.0,18.0,150.0,118.0), false)
    draw_string(ThemeDB.fallback_font,Vector2(34.0,43.0),"LIFE",HORIZONTAL_ALIGNMENT_LEFT,-1.0,14,C_MUTED)
    draw_rect(Rect2(34.0,53.0,116.0,13.0),Color("12212c"),true)
    draw_rect(Rect2(34.0,53.0,116.0*clampf(life/max_life,0.0,1.0),13.0),C_GREEN,true)
    draw_string(ThemeDB.fallback_font,Vector2(34.0,92.0),"BUSTER A%d R%d" % [int(buster["attack"]),int(buster["rapid"])],HORIZONTAL_ALIGNMENT_LEFT,-1.0,13,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(34.0,116.0),"LV %d" % level,HORIZONTAL_ALIGNMENT_LEFT,-1.0,13,C_BLUE)

    draw_panel(Rect2(1112.0,18.0,150.0,118.0), false)
    draw_string(ThemeDB.fallback_font,Vector2(1128.0,43.0),time_string(),HORIZONTAL_ALIGNMENT_LEFT,-1.0,14,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(1128.0,69.0),"SCORE %06d" % score,HORIZONTAL_ALIGNMENT_LEFT,-1.0,12,C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(1128.0,93.0),"Z %d" % zenny,HORIZONTAL_ALIGNMENT_LEFT,-1.0,12,C_GOLD)
    draw_string(ThemeDB.fallback_font,Vector2(1128.0,117.0),"R %d" % refractors,HORIZONTAL_ALIGNMENT_LEFT,-1.0,12,C_BLUE)
    if combo >= 3:
        draw_string(ThemeDB.fallback_font,Vector2(1110.0,168.0),"x%d COMBO" % combo,HORIZONTAL_ALIGNMENT_RIGHT,150.0,18,Color("fff58a"))
    draw_panel(Rect2(230.0,680.0,820.0,24.0), false)
    draw_rect(Rect2(244.0,688.0,792.0,8.0),Color("132735"),true)
    draw_rect(Rect2(244.0,688.0,792.0*clampf(xp/xp_next,0.0,1.0),8.0),C_BLUE,true)

func draw_menu() -> void:
    draw_menu_backdrop()
    draw_texture_rect(TEX_MM,Rect2(238.0,345.0,188.0,166.0),false,Color(0.9,1.0,1.0,1.0))
    draw_texture_rect(TEX_HOROKKO,Rect2(880.0,386.0,110.0,110.0),false,Color(1.0,0.88,0.8,0.9))
    draw_texture_rect(TEX_DATA,Rect2(926.0,472.0,92.0,92.0),false)
    draw_string(ThemeDB.fallback_font,Vector2(330.0,224.0),"MEGA MAN LEGENDS",HORIZONTAL_ALIGNMENT_CENTER,620.0,44,Color("dff8ff"))
    draw_string(ThemeDB.fallback_font,Vector2(330.0,275.0),"REFRACTOR PIT",HORIZONTAL_ALIGNMENT_CENTER,620.0,52,Color("61e5ff"))
    draw_string(ThemeDB.fallback_font,Vector2(330.0,312.0),"RICOCHET BUSTER ROGUELITE",HORIZONTAL_ALIGNMENT_CENTER,620.0,14,C_MUTED)
    draw_button(Rect2(470.0,410.0,340.0,64.0),"START DIG",menu_index==0)
    draw_button(Rect2(470.0,488.0,340.0,64.0),"ROLL'S WORKSHOP",menu_index==1)
    draw_string(ThemeDB.fallback_font,Vector2(320.0,602.0),"Mouse to aim   A / D fine aim   Space to fire",HORIZONTAL_ALIGNMENT_CENTER,640.0,13,C_MUTED)

func draw_menu_backdrop() -> void:
    draw_rect(Rect2(0.0,0.0,W,H),Color("06131c"),true)
    for y: int in range(7,15):
        for x: int in range(27):
            draw_texture_rect(TEX_RUIN_FLOOR,Rect2(float(x)*48.0,float(y)*48.0,48.0,48.0),true,Color(0.55,0.72,0.74,1.0))
    draw_texture_rect(TEX_RUIN_ENTRANCE,Rect2(518.0,76.0,244.0,146.0),false,Color(0.78,0.95,1.0,0.92))
    draw_rect(Rect2(0.0,0.0,W,H),Color(0.02,0.08,0.11,0.36),true)

func draw_level_up() -> void:
    draw_rect(Rect2(0.0,0.0,W,H),Color(0.01,0.03,0.06,0.78),true)
    draw_string(ThemeDB.fallback_font,Vector2(380.0,150.0),"BUSTER PART FOUND",HORIZONTAL_ALIGNMENT_CENTER,520.0,30,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(380.0,186.0),"Choose one upgrade",HORIZONTAL_ALIGNMENT_CENTER,520.0,14,C_MUTED)
    for i: int in range(upgrade_choices.size()):
        var rect: Rect2 = Rect2(180.0 + float(i)*310.0,250.0,280.0,244.0)
        draw_panel(rect, i==upgrade_index)
        draw_circle(Vector2(rect.position.x+140.0,rect.position.y+64.0),28.0,Color(0.3,0.9,1.0,0.15))
        draw_circle(Vector2(rect.position.x+140.0,rect.position.y+64.0),12.0,Color("9effe9"))
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+126.0),str(upgrade_choices[i]["name"]),HORIZONTAL_ALIGNMENT_LEFT,244.0,16,C_TEXT)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+158.0),str(upgrade_choices[i]["desc"]),HORIZONTAL_ALIGNMENT_LEFT,244.0,13,C_MUTED)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+214.0),"SELECT",HORIZONTAL_ALIGNMENT_LEFT,244.0,12,C_BLUE if i==upgrade_index else C_MUTED)

func draw_workshop() -> void:
    draw_rect(Rect2(0.0,0.0,W,H),Color("081018"),true)
    for y: int in range(7,15):
        for x: int in range(27):
            draw_texture_rect(TEX_RUIN_FLOOR,Rect2(float(x)*48.0,float(y)*48.0,48.0,48.0),true,Color(0.6,0.72,0.72,1.0))
    draw_texture_rect(TEX_WORKBENCH,Rect2(70.0,318.0,200.0,160.0),false)
    draw_texture_rect(TEX_SALVAGE,Rect2(1008.0,350.0,120.0,100.0),false)
    draw_texture_rect(TEX_RELIC,Rect2(1120.0,430.0,88.0,88.0),false)
    draw_string(ThemeDB.fallback_font,Vector2(340.0,106.0),"ROLL'S WORKSHOP",HORIZONTAL_ALIGNMENT_CENTER,600.0,38,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(340.0,142.0),"Permanent buster tuning",HORIZONTAL_ALIGNMENT_CENTER,600.0,14,C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(340.0,178.0),"Z %d     REFRACTORS %d" % [int(bank["zenny"]),int(bank["refractors"])],HORIZONTAL_ALIGNMENT_CENTER,600.0,15,C_GOLD)
    var cards: Array[Array] = [
        ["POWER RAISER","attack","Starting attack +1"],
        ["TURBO CHARGER","rapid","Starting rapid +1"],
        ["ARMOR PLATING","life","Maximum life +12"],
    ]
    for i: int in range(cards.size()):
        var rect: Rect2 = Rect2(250.0+float(i)*270.0,236.0,246.0,236.0)
        draw_panel(rect,i==workshop_index)
        var key: String = str(cards[i][1])
        var cost: Dictionary = permanent_cost(key)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+40.0),str(cards[i][0]),HORIZONTAL_ALIGNMENT_LEFT,210.0,15,C_TEXT)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+72.0),"RANK %d" % int(permanent[key]),HORIZONTAL_ALIGNMENT_LEFT,210.0,12,C_BLUE)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+116.0),str(cards[i][2]),HORIZONTAL_ALIGNMENT_LEFT,210.0,12,C_MUTED)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+184.0),"%d Z   %d R" % [int(cost["z"]),int(cost["r"])],HORIZONTAL_ALIGNMENT_LEFT,210.0,13,C_GOLD)
        draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+18.0,rect.position.y+214.0),"INSTALL",HORIZONTAL_ALIGNMENT_LEFT,210.0,11,C_BLUE if i==workshop_index else C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(340.0,615.0),"Enter to install   Esc to return",HORIZONTAL_ALIGNMENT_CENTER,600.0,13,C_MUTED)

func draw_game_over() -> void:
    draw_rect(Rect2(0.0,0.0,W,H),Color(0.0,0.0,0.0,0.72),true)
    draw_panel(Rect2(390.0,190.0,500.0,330.0), false)
    draw_string(ThemeDB.fallback_font,Vector2(430.0,250.0),"DIG ENDED",HORIZONTAL_ALIGNMENT_CENTER,420.0,36,C_DANGER)
    draw_string(ThemeDB.fallback_font,Vector2(430.0,302.0),"Score %d" % score,HORIZONTAL_ALIGNMENT_CENTER,420.0,17,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(430.0,335.0),"Reaverbots destroyed %d" % kills,HORIZONTAL_ALIGNMENT_CENTER,420.0,15,C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(430.0,368.0),"Salvaged %d Z   %d refractors" % [zenny,refractors],HORIZONTAL_ALIGNMENT_CENTER,420.0,15,C_GOLD)
    draw_string(ThemeDB.fallback_font,Vector2(430.0,447.0),"Press Enter",HORIZONTAL_ALIGNMENT_CENTER,420.0,14,C_BLUE)

func draw_message(text: String) -> void:
    var alpha: float = minf(1.0,message_timer*2.2)
    draw_rect(Rect2(430.0,112.0,420.0,54.0),Color(0.02,0.05,0.08,0.86*alpha),true)
    draw_string(ThemeDB.fallback_font,Vector2(445.0,146.0),text,HORIZONTAL_ALIGNMENT_CENTER,390.0,15,Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, alpha))

func draw_panel(rect: Rect2, hot: bool) -> void:
    draw_rect(rect, C_PANEL_HOT if hot else C_PANEL, true)
    draw_rect(rect, C_BLUE if hot else Color(1.0,1.0,1.0,0.10), false, 1.0)

func draw_button(rect: Rect2, label: String, hot: bool) -> void:
    draw_rect(rect, Color("163047") if hot else C_PANEL, true)
    draw_rect(rect, C_BLUE if hot else Color(1.0,1.0,1.0,0.12), false, 1.0)
    draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+39.0),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,16,C_TEXT)

func time_string() -> String:
    var total: int = int(run_time)
    return "%02d:%02d" % [total/60,total%60]
