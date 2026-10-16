extends Node2D

const W := 1280.0
const H := 720.0
const ARENA := Rect2(185, 54, 910, 602)
const PLAYER_POS := Vector2(640, 610)
const TOP_Y := 86.0
const FLOOR_Y := 596.0

const C_TEXT := Color("f5f7fb")
const C_MUTED := Color("99a9bd")
const C_BLUE := Color("56d2ff")
const C_BLUE2 := Color("2065ff")
const C_DANGER := Color("ff5b55")
const C_GREEN := Color("8dff9b")
const C_GOLD := Color("ffd85d")
const C_PANEL := Color(0.035, 0.055, 0.09, 0.94)
const C_PANEL2 := Color(0.065, 0.095, 0.145, 0.96)

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

const ENEMY_TYPES := {
    "horokko": {"name":"HOROKKO", "tex":TEX_HOROKKO, "hp":36.0, "speed":35.0, "radius":24.0, "score":100},
    "zakobon": {"name":"ZAKOBON", "tex":TEX_ZAKOBON, "hp":54.0, "speed":28.0, "radius":27.0, "score":145},
    "sharukurusu": {"name":"SHARUKURUSU", "tex":TEX_SHARUKURUSU, "hp":78.0, "speed":24.0, "radius":31.0, "score":205},
    "guardian": {"name":"GUARDIAN", "tex":TEX_GUARDIAN, "hp":118.0, "speed":18.0, "radius":35.0, "score":300},
}

var mode := "menu"
var menu_index := 0
var upgrade_index := 0
var workshop_index := 0

var shots: Array = []
var enemies: Array = []
var enemy_shots: Array = []
var pickups: Array = []
var effects: Array = []

var run_time := 0.0
var score := 0
var kills := 0
var level := 1
var xp := 0.0
var xp_next := 16.0
var life := 100.0
var max_life := 100.0
var zenny := 0
var refractors := 0
var combo := 0
var combo_timer := 0.0
var aim_angle := -PI / 2.0
var fire_timer := 0.0
var spawn_timer := 0.0
var boss_timer := 38.0
var screen_flash := 0.0
var shake := 0.0
var message := ""
var message_timer := 0.0

var buster := {
    "attack": 1,
    "rapid": 1,
    "range": 1,
    "energy": 1,
    "ricochet": 2,
    "spread": 1,
}
var bank := {"zenny": 0, "refractors": 0}
var permanent := {"attack": 0, "rapid": 0, "life": 0}
var upgrade_choices: Array = []

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
        var key := event.keycode
        if mode == "menu":
            if key in [KEY_UP, KEY_W]:
                menu_index = maxi(0, menu_index - 1)
            elif key in [KEY_DOWN, KEY_S]:
                menu_index = mini(1, menu_index + 1)
            elif key in [KEY_ENTER, KEY_SPACE]:
                activate_menu()
        elif mode == "run":
            if key == KEY_SPACE:
                fire_buster(true)
            elif key == KEY_ESCAPE:
                finish_run()
        elif mode == "levelup":
            if key in [KEY_LEFT, KEY_A]:
                upgrade_index = maxi(0, upgrade_index - 1)
            elif key in [KEY_RIGHT, KEY_D]:
                upgrade_index = mini(upgrade_choices.size() - 1, upgrade_index + 1)
            elif key in [KEY_ENTER, KEY_SPACE]:
                apply_upgrade(upgrade_index)
        elif mode == "workshop":
            if key in [KEY_LEFT, KEY_A]:
                workshop_index = maxi(0, workshop_index - 1)
            elif key in [KEY_RIGHT, KEY_D]:
                workshop_index = mini(2, workshop_index + 1)
            elif key in [KEY_ENTER, KEY_SPACE]:
                buy_permanent(["attack", "rapid", "life"][workshop_index])
            elif key == KEY_ESCAPE:
                mode = "menu"
        elif mode == "gameover":
            if key in [KEY_ENTER, KEY_SPACE]:
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
    max_life = 100.0 + float(permanent.life) * 12.0
    life = max_life
    zenny = 0
    refractors = 0
    combo = 0
    combo_timer = 0.0
    aim_angle = -PI / 2.0
    fire_timer = 0.16
    spawn_timer = 0.25
    boss_timer = 38.0
    buster = {
        "attack": 1 + permanent.attack,
        "rapid": 1 + permanent.rapid,
        "range": 1,
        "energy": 1,
        "ricochet": 2,
        "spread": 1,
    }
    mode = "run"
    message = "DIG START"
    message_timer = 1.3

func update_aim(mouse: Vector2) -> void:
    var v := mouse - PLAYER_POS
    if v.length() > 8.0 and v.y < -4.0:
        aim_angle = clampf(v.angle(), -PI + 0.14, -0.14)

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
        fire_timer = maxf(0.19, 0.68 * pow(0.88, float(buster.rapid - 1)))

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
    var count: int = int(buster.spread)
    var spread_step := 0.095
    for i in range(count):
        var offset := (float(i) - float(count - 1) * 0.5) * spread_step
        var angle := aim_angle + offset
        var dir := Vector2(cos(angle), sin(angle))
        shots.append({
            "pos": PLAYER_POS + dir * 34.0,
            "last": PLAYER_POS + dir * 18.0,
            "vel": dir * (520.0 + float(buster.energy - 1) * 28.0),
            "life": 2.1 + float(buster.range - 1) * 0.32,
            "damage": 13.0 + float(buster.attack - 1) * 6.0,
            "bounces": int(buster.ricochet),
            "charged": manual,
        })
    effects.append({"type":"muzzle", "pos":PLAYER_POS + Vector2(cos(aim_angle), sin(aim_angle)) * 36.0, "t":0.13})

func spawn_enemy(boss: bool) -> void:
    if boss:
        enemies.append({
            "kind":"boss", "name":"BONNE ASSAULT MECH", "tex":TEX_BOSS,
            "pos":Vector2(randf_range(430.0, 850.0), 126.0),
            "hp":980.0 + run_time * 5.0, "max_hp":980.0 + run_time * 5.0,
            "speed":12.0, "radius":66.0, "boss":true, "phase":randf()*TAU,
            "shoot":0.9, "score":2200,
        })
        return
    var names := ENEMY_TYPES.keys()
    var key: String = str(names[randi() % names.size()])
    var data: Dictionary = ENEMY_TYPES[key]
    var hp_scale := 1.0 + run_time / 125.0
    enemies.append({
        "kind":key, "name":data.name, "tex":data.tex,
        "pos":Vector2(randf_range(245.0, 1035.0), randf_range(104.0, 144.0)),
        "hp":float(data.hp)*hp_scale, "max_hp":float(data.hp)*hp_scale,
        "speed":float(data.speed)*(1.0 + run_time/320.0), "radius":float(data.radius),
        "boss":false, "phase":randf()*TAU, "shoot":randf_range(1.3, 3.4), "score":int(data.score),
    })

func update_shots(delta: float) -> void:
    for i in range(shots.size() - 1, -1, -1):
        var s: Dictionary = shots[i]
        s.last = s.pos
        s.pos += s.vel * delta
        s.life -= delta
        var bounced := false
        if s.pos.x < ARENA.position.x + 8.0:
            s.pos.x = ARENA.position.x + 8.0
            s.vel.x = absf(s.vel.x)
            bounced = true
        elif s.pos.x > ARENA.end.x - 8.0:
            s.pos.x = ARENA.end.x - 8.0
            s.vel.x = -absf(s.vel.x)
            bounced = true
        if s.pos.y < TOP_Y:
            s.pos.y = TOP_Y
            s.vel.y = absf(s.vel.y)
            bounced = true
        if bounced:
            s.bounces -= 1
            effects.append({"type":"spark", "pos":s.pos, "t":0.18})
        var consumed := false
        for e in enemies:
            if s.pos.distance_to(e.pos) <= float(e.radius) + 8.0:
                e.hp -= float(s.damage) * (1.45 if s.charged else 1.0)
                effects.append({"type":"hit", "pos":s.pos, "t":0.18})
                screen_flash = maxf(screen_flash, 0.14)
                shake = maxf(shake, 3.0 if not e.boss else 6.0)
                combo += 1
                combo_timer = 1.25
                consumed = true
                break
        if consumed or s.life <= 0.0 or s.bounces < 0 or s.pos.y > FLOOR_Y + 46.0:
            shots.remove_at(i)

func update_enemies(delta: float) -> void:
    for i in range(enemies.size() - 1, -1, -1):
        var e: Dictionary = enemies[i]
        e.phase += delta * (1.1 if e.boss else 2.1)
        var drift := sin(float(e.phase)) * (26.0 if e.boss else 38.0)
        e.pos.x += drift * delta
        e.pos.x = clampf(e.pos.x, ARENA.position.x + float(e.radius), ARENA.end.x - float(e.radius))
        e.pos.y += float(e.speed) * delta
        e.shoot -= delta
        if e.shoot <= 0.0 and e.pos.y < 510.0:
            fire_enemy(e)
            e.shoot = randf_range(1.5, 3.0) if not e.boss else randf_range(0.45, 0.8)
        if e.hp <= 0.0:
            enemy_killed(e)
            enemies.remove_at(i)
            continue
        if e.pos.y > FLOOR_Y - 24.0:
            life -= 18.0 if not e.boss else 34.0
            effects.append({"type":"hit", "pos":Vector2(e.pos.x, FLOOR_Y), "t":0.28})
            shake = 9.0
            enemies.remove_at(i)
            if life <= 0.0:
                finish_run()
                return

func fire_enemy(e: Dictionary) -> void:
    var dir := (PLAYER_POS - e.pos).normalized()
    var count := 3 if e.boss else 1
    for n in range(count):
        var angle := dir.angle() + (float(n) - float(count - 1) * 0.5) * 0.20
        enemy_shots.append({"pos":e.pos, "vel":Vector2(cos(angle), sin(angle)) * (220.0 if e.boss else 170.0), "life":4.0, "boss":e.boss})

func update_enemy_shots(delta: float) -> void:
    for i in range(enemy_shots.size() - 1, -1, -1):
        var s: Dictionary = enemy_shots[i]
        s.pos += s.vel * delta
        s.life -= delta
        if s.pos.distance_to(PLAYER_POS) < 25.0:
            life -= 9.0 if not s.boss else 13.0
            screen_flash = 0.38
            shake = 8.0
            effects.append({"type":"hit", "pos":PLAYER_POS, "t":0.24})
            enemy_shots.remove_at(i)
            if life <= 0.0:
                finish_run()
                return
        elif s.life <= 0.0 or not Rect2(150, 30, 980, 680).has_point(s.pos):
            enemy_shots.remove_at(i)

func enemy_killed(e: Dictionary) -> void:
    kills += 1
    score += int(e.score) + combo * 8
    xp += 5.0 if not e.boss else 38.0
    var drops := 1 if not e.boss else 7
    for n in range(drops):
        pickups.append({
            "pos":e.pos + Vector2(randf_range(-24.0,24.0), randf_range(-18.0,18.0)),
            "kind":"refractor" if (e.boss or randf() < 0.18) else "zenny",
            "t":0.0,
        })
    effects.append({"type":"burst", "pos":e.pos, "t":0.42})
    if e.boss:
        message = "REFRACTOR CORE EXPOSED"
        message_timer = 2.2
    while xp >= xp_next:
        xp -= xp_next
        level += 1
        xp_next = 15.0 + float(level) * 5.5
        open_level_up()
        break

func update_pickups(delta: float) -> void:
    for i in range(pickups.size() - 1, -1, -1):
        var p: Dictionary = pickups[i]
        p.t += delta
        var target := PLAYER_POS
        if p.t > 0.38:
            p.pos = p.pos.lerp(target, minf(1.0, delta * 5.5))
        if p.pos.distance_to(target) < 34.0:
            if p.kind == "zenny":
                zenny += 14
            else:
                refractors += 1
            pickups.remove_at(i)

func update_effects(delta: float) -> void:
    for i in range(effects.size() - 1, -1, -1):
        effects[i].t -= delta
        if effects[i].t <= 0.0:
            effects.remove_at(i)

func open_level_up() -> void:
    upgrade_choices = [
        {"name":"POWER RAISER", "desc":"Buster damage +6", "key":"attack"},
        {"name":"TURBO CHARGER", "desc":"Faster automatic firing", "key":"rapid"},
        {"name":"SNIPER UNIT", "desc":"Longer shot lifetime", "key":"range"},
    ]
    var pool := [
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
    var key: String = str(upgrade_choices[index].key)
    buster[key] = int(buster[key]) + 1
    mode = "run"
    message = str(upgrade_choices[index].name)
    message_timer = 1.4

func finish_run() -> void:
    if mode != "run":
        return
    bank.zenny += zenny
    bank.refractors += refractors
    save_game()
    mode = "gameover"

func has_boss() -> bool:
    for e in enemies:
        if e.boss:
            return true
    return false

func permanent_cost(key: String) -> Dictionary:
    var rank: int = permanent[key]
    return {"z": 80 + rank * 70, "r": 2 + rank * 2}

func buy_permanent(key: String) -> void:
    var cost := permanent_cost(key)
    if bank.zenny >= cost.z and bank.refractors >= cost.r:
        bank.zenny -= cost.z
        bank.refractors -= cost.r
        permanent[key] += 1
        save_game()
        message = "UPGRADE INSTALLED"
        message_timer = 1.3
    else:
        message = "NOT ENOUGH SALVAGE"
        message_timer = 1.3

func save_game() -> void:
    var f := FileAccess.open("user://refractor_pit.save", FileAccess.WRITE)
    if f:
        f.store_var({"bank":bank, "permanent":permanent})

func load_save() -> void:
    if not FileAccess.file_exists("user://refractor_pit.save"):
        return
    var f := FileAccess.open("user://refractor_pit.save", FileAccess.READ)
    if f:
        var data = f.get_var()
        if data is Dictionary:
            if data.has("bank"):
                bank = data.bank
            if data.has("permanent"):
                permanent = data.permanent

func _draw() -> void:
    draw_rect(Rect2(0,0,W,H), Color("071018"))
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
    var ofs := Vector2(randf_range(-shake,shake), randf_range(-shake,shake)) if shake > 0.1 else Vector2.ZERO
    draw_set_transform(ofs)
    draw_ruin_arena()
    draw_player()
    for p in pickups:
        draw_pickup(p)
    for e in enemies:
        draw_enemy(e)
    for s in shots:
        draw_buster_shot(s)
    for s in enemy_shots:
        draw_enemy_shot(s)
    for fx in effects:
        draw_effect(fx)
    draw_set_transform(Vector2.ZERO)
    draw_hud()
    if screen_flash > 0.0:
        draw_rect(Rect2(0,0,W,H), Color(0.55,0.85,1.0,screen_flash * 0.26))

func draw_ruin_arena() -> void:
    draw_rect(Rect2(168,38,944,634), Color("03070c"), true)
    draw_rect(ARENA, Color("10242d"), true)
    var tile_size := 48.0
    for y in range(1, 13):
        for x in range(1, 20):
            var r := Rect2(ARENA.position.x + float(x-1)*tile_size, ARENA.position.y + float(y-1)*tile_size, tile_size, tile_size)
            draw_texture_rect(TEX_RUIN_FLOOR, r, true, Color(0.78,0.92,0.92,1.0))
    draw_rect(Rect2(ARENA.position.x, ARENA.position.y, ARENA.size.x, 18), Color("244957"), true)
    draw_rect(Rect2(ARENA.position.x, FLOOR_Y, ARENA.size.x, 5), Color("ff6f44"), true)
    for x in [214.0, 1030.0]:
        draw_texture_rect(TEX_RUIN_PILLAR, Rect2(x-28,96,56,170), false, Color(0.72,0.9,0.95,1))
        draw_texture_rect(TEX_RUIN_PILLAR, Rect2(x-28,410,56,170), false, Color(0.72,0.9,0.95,1))
    draw_texture_rect(TEX_RUIN_ENTRANCE, Rect2(557,62,166,100), false, Color(0.65,0.85,0.94,1))
    for x in [350.0, 640.0, 930.0]:
        draw_texture_rect(TEX_RUIN_PANEL, Rect2(x-36,105,72,72), false, Color(0.68,0.9,0.95,0.85))
    draw_line(Vector2(PLAYER_POS.x, PLAYER_POS.y-22), PLAYER_POS + Vector2(cos(aim_angle),sin(aim_angle))*116.0, Color(0.3,0.9,1.0,0.28), 2.0)

func draw_player() -> void:
    var sz := Vector2(96, 92)
    draw_circle(PLAYER_POS + Vector2(0,20), 31.0, Color(0,0,0,0.30))
    draw_texture_rect(TEX_MM, Rect2(PLAYER_POS - sz*0.5 + Vector2(0,-18), sz), false)
    var muzzle := PLAYER_POS + Vector2(cos(aim_angle),sin(aim_angle))*39.0
    draw_circle(muzzle, 5.5, Color(0.76,1.0,0.98,0.95))
    draw_circle(muzzle, 2.6, Color.WHITE)

func draw_enemy(e: Dictionary) -> void:
    var rad: float = e.radius
    var pos: Vector2 = e.pos
    if e.boss:
        draw_circle(pos, rad+18.0, Color(1.0,0.18,0.14,0.10))
    draw_circle(pos + Vector2(0,rad*0.55), rad*0.78, Color(0,0,0,0.36))
    var size := Vector2(rad*2.5, rad*2.5)
    if e.boss:
        size = Vector2(190,150)
    draw_texture_rect(e.tex, Rect2(pos-size*0.5,size), false)
    var ratio: float = clampf(float(e.hp)/float(e.max_hp),0.0,1.0)
    if e.boss:
        draw_rect(Rect2(396,72,488,13),Color("341116"),true)
        draw_rect(Rect2(396,72,488*ratio,13),C_DANGER,true)
        draw_string(ThemeDB.fallback_font,Vector2(396,64),"BONNE ASSAULT MECH",HORIZONTAL_ALIGNMENT_LEFT,260,16,C_TEXT)
    elif ratio < 0.99:
        draw_rect(Rect2(pos.x-22,pos.y-rad-13,44,5),Color("081014"),true)
        draw_rect(Rect2(pos.x-22,pos.y-rad-13,44*ratio,5),C_GREEN,true)

func draw_buster_shot(s: Dictionary) -> void:
    var col := Color("b7ffea") if not s.charged else Color("fff37d")
    draw_line(s.last,s.pos,col*Color(1,1,1,0.38),8.0,true)
    draw_circle(s.pos,10.0,col*Color(1,1,1,0.18))
    draw_circle(s.pos,6.2,col)
    draw_circle(s.pos-Vector2(2,2),2.3,Color.WHITE)

func draw_enemy_shot(s: Dictionary) -> void:
    var col := Color("ff8b55") if not s.boss else Color("ff4d83")
    draw_circle(s.pos,10.0,col*Color(1,1,1,0.18))
    draw_circle(s.pos,6.0,col)
    draw_circle(s.pos,2.0,Color.WHITE)

func draw_pickup(p: Dictionary) -> void:
    var bob := sin(float(p.t)*7.0)*4.0
    var pos: Vector2 = p.pos + Vector2(0,bob)
    var col := C_GOLD if p.kind == "zenny" else Color("58f6ff")
    draw_circle(pos,10.0,col*Color(1,1,1,0.15))
    draw_circle(pos,5.0,col)
    if p.kind == "refractor":
        draw_polyline(PackedVector2Array([pos+Vector2(0,-7),pos+Vector2(6,0),pos+Vector2(0,7),pos+Vector2(-6,0),pos+Vector2(0,-7)]),Color.WHITE,1.5)

func draw_effect(fx: Dictionary) -> void:
    var t: float = fx.t
    var pos: Vector2 = fx.pos
    if fx.type == "muzzle":
        draw_circle(pos,8.0+t*50.0,Color(0.65,1,1,t*3.0))
    elif fx.type == "hit":
        draw_circle(pos,8.0+t*40.0,Color(0.95,1,0.65,t*2.5),false,3.0)
    elif fx.type == "spark":
        draw_circle(pos,5.0+t*26.0,Color(0.45,0.95,1,t*2.0),false,2.0)
    elif fx.type == "burst":
        draw_circle(pos,18.0+t*80.0,Color(1.0,0.45,0.24,t*1.6),false,5.0)

func draw_hud() -> void:
    panel(Rect2(18,18,150,118))
    draw_string(ThemeDB.fallback_font,Vector2(34,43),"LIFE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,C_MUTED)
    draw_rect(Rect2(34,53,116,13),Color("12212c"),true)
    draw_rect(Rect2(34,53,116*clampf(life/max_life,0.0,1.0),13),C_GREEN,true)
    draw_string(ThemeDB.fallback_font,Vector2(34,92),"BUSTER  A%d R%d" % [buster.attack,buster.rapid],HORIZONTAL_ALIGNMENT_LEFT,-1,13,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(34,116),"LV %d" % level,HORIZONTAL_ALIGNMENT_LEFT,-1,13,C_BLUE)

    panel(Rect2(1112,18,150,118))
    draw_string(ThemeDB.fallback_font,Vector2(1128,43),time_string(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(1128,69),"SCORE %06d" % score,HORIZONTAL_ALIGNMENT_LEFT,-1,12,C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(1128,93),"Z %d" % zenny,HORIZONTAL_ALIGNMENT_LEFT,-1,12,C_GOLD)
    draw_string(ThemeDB.fallback_font,Vector2(1128,117),"R %d" % refractors,HORIZONTAL_ALIGNMENT_LEFT,-1,12,C_BLUE)

    if combo >= 3:
        draw_string(ThemeDB.fallback_font,Vector2(1110,168),"x%d COMBO" % combo,HORIZONTAL_ALIGNMENT_RIGHT,150,18,Color("fff58a"))
    panel(Rect2(230,680,820,24))
    draw_rect(Rect2(244,688,792,8),Color("132735"),true)
    draw_rect(Rect2(244,688,792*clampf(xp/xp_next,0.0,1.0),8),C_BLUE,true)

func draw_menu() -> void:
    draw_menu_backdrop()
    draw_texture_rect(TEX_MM,Rect2(238,345,188,166),false,Color(0.9,1,1,1))
    draw_texture_rect(TEX_HOROKKO,Rect2(880,386,110,110),false,Color(1,0.88,0.8,0.9))
    draw_texture_rect(TEX_DATA,Rect2(926,472,92,92),false)
    draw_string(ThemeDB.fallback_font,Vector2(330,224),"MEGA MAN LEGENDS",HORIZONTAL_ALIGNMENT_CENTER,620,44,Color("dff8ff"))
    draw_string(ThemeDB.fallback_font,Vector2(330,275),"REFRACTOR PIT",HORIZONTAL_ALIGNMENT_CENTER,620,52,Color("61e5ff"))
    draw_string(ThemeDB.fallback_font,Vector2(330,312),"RICOCHET BUSTER ROGUELITE",HORIZONTAL_ALIGNMENT_CENTER,620,14,C_MUTED)
    button(Rect2(470,410,340,64),"START DIG",menu_index==0)
    button(Rect2(470,488,340,64),"ROLL'S WORKSHOP",menu_index==1)
    draw_string(ThemeDB.fallback_font,Vector2(320,602),"Mouse to aim   A / D fine aim   Space to fire",HORIZONTAL_ALIGNMENT_CENTER,640,13,C_MUTED)

func draw_menu_backdrop() -> void:
    draw_rect(Rect2(0,0,W,H),Color("06131c"),true)
    for y in range(7,15):
        for x in range(27):
            draw_texture_rect(TEX_RUIN_FLOOR,Rect2(float(x)*48,float(y)*48,48,48),true,Color(0.55,0.72,0.74,1))
    draw_texture_rect(TEX_RUIN_ENTRANCE,Rect2(518,76,244,146),false,Color(0.78,0.95,1,0.92))
    draw_rect(Rect2(0,0,W,H),Color(0.02,0.08,0.11,0.36),true)

func draw_level_up() -> void:
    draw_rect(Rect2(0,0,W,H),Color(0.01,0.03,0.06,0.78),true)
    draw_string(ThemeDB.fallback_font,Vector2(380,150),"BUSTER PART FOUND",HORIZONTAL_ALIGNMENT_CENTER,520,30,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(380,186),"Choose one upgrade",HORIZONTAL_ALIGNMENT_CENTER,520,14,C_MUTED)
    for i in range(upgrade_choices.size()):
        var r := Rect2(180 + i*310,250,280,244)
        panel(r, i==upgrade_index)
        draw_circle(Vector2(r.position.x+140,r.position.y+64),28,Color(0.3,0.9,1,0.15))
        draw_circle(Vector2(r.position.x+140,r.position.y+64),12,Color("9effe9") if i != 1 else Color("fff16b"))
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+126),str(upgrade_choices[i].name),HORIZONTAL_ALIGNMENT_LEFT,244,16,C_TEXT)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+158),str(upgrade_choices[i].desc),HORIZONTAL_ALIGNMENT_LEFT,244,13,C_MUTED)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+214),"SELECT",HORIZONTAL_ALIGNMENT_LEFT,244,12,C_BLUE if i==upgrade_index else C_MUTED)

func draw_workshop() -> void:
    draw_rect(Rect2(0,0,W,H),Color("081018"),true)
    for y in range(7,15):
        for x in range(27):
            draw_texture_rect(TEX_RUIN_FLOOR,Rect2(float(x)*48,float(y)*48,48,48),true,Color(0.6,0.72,0.72,1))
    draw_texture_rect(TEX_WORKBENCH,Rect2(70,318,200,160),false)
    draw_texture_rect(TEX_SALVAGE,Rect2(1008,350,120,100),false)
    draw_texture_rect(TEX_RELIC,Rect2(1120,430,88,88),false)
    draw_string(ThemeDB.fallback_font,Vector2(340,106),"ROLL'S WORKSHOP",HORIZONTAL_ALIGNMENT_CENTER,600,38,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(340,142),"Permanent buster tuning",HORIZONTAL_ALIGNMENT_CENTER,600,14,C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(340,178),"Z %d     REFRACTORS %d" % [bank.zenny,bank.refractors],HORIZONTAL_ALIGNMENT_CENTER,600,15,C_GOLD)
    var cards := [
        ["POWER RAISER","attack","Starting attack +1"],
        ["TURBO CHARGER","rapid","Starting rapid +1"],
        ["ARMOR PLATING","life","Maximum life +12"],
    ]
    for i in range(cards.size()):
        var r := Rect2(250+i*270,236,246,236)
        panel(r,i==workshop_index)
        var key: String = str(cards[i][1])
        var cost := permanent_cost(key)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+40),str(cards[i][0]),HORIZONTAL_ALIGNMENT_LEFT,210,15,C_TEXT)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+72),"RANK %d" % permanent[key],HORIZONTAL_ALIGNMENT_LEFT,210,12,C_BLUE)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+116),str(cards[i][2]),HORIZONTAL_ALIGNMENT_LEFT,210,12,C_MUTED)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+184),"%d Z   %d R" % [cost.z,cost.r],HORIZONTAL_ALIGNMENT_LEFT,210,13,C_GOLD)
        draw_string(ThemeDB.fallback_font,Vector2(r.position.x+18,r.position.y+214),"INSTALL",HORIZONTAL_ALIGNMENT_LEFT,210,11,C_BLUE if i==workshop_index else C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(340,615),"Enter to install   Esc to return",HORIZONTAL_ALIGNMENT_CENTER,600,13,C_MUTED)

func draw_game_over() -> void:
    draw_rect(Rect2(0,0,W,H),Color(0,0,0,0.72),true)
    panel(Rect2(390,190,500,330))
    draw_string(ThemeDB.fallback_font,Vector2(430,250),"DIG ENDED",HORIZONTAL_ALIGNMENT_CENTER,420,36,C_DANGER)
    draw_string(ThemeDB.fallback_font,Vector2(430,302),"Score  %d" % score,HORIZONTAL_ALIGNMENT_CENTER,420,17,C_TEXT)
    draw_string(ThemeDB.fallback_font,Vector2(430,335),"Reaverbots destroyed  %d" % kills,HORIZONTAL_ALIGNMENT_CENTER,420,15,C_MUTED)
    draw_string(ThemeDB.fallback_font,Vector2(430,368),"Salvaged  %d Z   %d refractors" % [zenny,refractors],HORIZONTAL_ALIGNMENT_CENTER,420,15,C_GOLD)
    draw_string(ThemeDB.fallback_font,Vector2(430,447),"Press Enter",HORIZONTAL_ALIGNMENT_CENTER,420,14,C_BLUE)

func draw_message(text: String) -> void:
    var alpha := minf(1.0,message_timer*2.2)
    draw_rect(Rect2(430,112,420,54),Color(0.02,0.05,0.08,0.86*alpha),true)
    draw_string(ThemeDB.fallback_font,Vector2(445,146),text,HORIZONTAL_ALIGNMENT_CENTER,390,15,Color(C_TEXT.r, C_TEXT.g, C_TEXT.b, alpha))

func panel(rect: Rect2, hot: bool=false) -> void:
    draw_style_box(make_box(C_PANEL2 if hot else C_PANEL, C_BLUE if hot else Color(1,1,1,0.10), 12), rect)

func button(rect: Rect2, label: String, hot: bool) -> void:
    draw_style_box(make_box(Color("163047") if hot else C_PANEL, C_BLUE if hot else Color(1,1,1,0.12), 12), rect)
    draw_string(ThemeDB.fallback_font,Vector2(rect.position.x,rect.position.y+39),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,16,C_TEXT)

func make_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
    var b := StyleBoxFlat.new()
    b.bg_color = fill
    b.border_color = border
    b.set_border_width_all(1)
    b.set_corner_radius_all(radius)
    return b

func time_string() -> String:
    var total := int(run_time)
    return "%02d:%02d" % [total/60,total%60]
