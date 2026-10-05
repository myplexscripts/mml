extends CanvasLayer
const BLUE:=Color("173e62")
const GOLD:=Color("f4d484")
const WHITE:=Color("fff2d4")
var game
var root: Control
var overlay: Control
var hud: Control
var fade_rect: ColorRect
var health: ProgressBar
var energy: ProgressBar
var health_text: Label
var currency: Label
var objective: Label
var location_text: Label
var prompt: Label
var notice: Label
var notice_panel: PanelContainer
var weapon: Label
var score: Label
var boss_bar: ProgressBar
var boss_label: Label
var reticle: Control
var combo: Label
var dialogue_lines: Array=[]
var dialogue_index: int=0
var dialogue_after: String=""
var dialogue_text: RichTextLabel
var type_clock: float=0
var portrait: SubViewport
var pause_tab: String="Status"
var font: Font=ThemeDB.fallback_font

func _ready() -> void:
 layer=10;root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.theme=theme();add_child(root)
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud)
 var mission_panel:=Panel.new();mission_panel.position=Vector2(380,16);mission_panel.size=Vector2(638,80);mission_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;mission_panel.add_theme_stylebox_override("panel",style(Color(.06,.17,.26,.87)));hud.add_child(mission_panel)
 var money_panel:=Panel.new();money_panel.position=Vector2(1030,16);money_panel.size=Vector2(232,80);money_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;money_panel.add_theme_stylebox_override("panel",style(Color(.06,.17,.26,.87)));hud.add_child(money_panel)
 var top:=Panel.new();top.position=Vector2(18,16);top.size=Vector2(348,80);top.add_theme_stylebox_override("panel",style(Color(.06,.17,.26,.94)));hud.add_child(top)
 health_text=label("MEGAMAN",18,GOLD);health_text.position=Vector2(34,26);hud.add_child(health_text)
 health=ProgressBar.new();health.position=Vector2(34,55);health.size=Vector2(314,15);health.max_value=100;health.show_percentage=false;health.add_theme_font_size_override("font_size",1)
 health.add_theme_stylebox_override("background",bar_style(Color("29434b")));health.add_theme_stylebox_override("fill",bar_style(GOLD));hud.add_child(health)
 energy=ProgressBar.new();energy.position=Vector2(34,78);energy.size=Vector2(314,5);energy.max_value=100;energy.show_percentage=false;energy.add_theme_font_size_override("font_size",1);energy.add_theme_stylebox_override("background",bar_style(Color("29434b")));energy.add_theme_stylebox_override("fill",bar_style(Color("8fcbb8")));hud.add_child(energy)
 currency=label("250 Z",22,GOLD);currency.position=Vector2(1030,24);currency.size=Vector2(230,32);currency.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(currency)
 score=label("SCORE 0",16);score.position=Vector2(1030,60);score.size=Vector2(230,25);score.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(score)
 objective=label("",18);objective.position=Vector2(390,28);objective.size=Vector2(618,30);objective.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;objective.autowrap_mode=TextServer.AUTOWRAP_OFF;hud.add_child(objective)
 location_text=label("",14,Color("b2d4d6"));location_text.position=Vector2(390,61);location_text.size=Vector2(618,25);location_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(location_text)
 prompt=label("",19,GOLD);prompt.position=Vector2(280,575);prompt.size=Vector2(720,44);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prompt.add_theme_stylebox_override("normal",style(Color(.06,.17,.26,.9)));hud.add_child(prompt)
 notice_panel=PanelContainer.new();notice_panel.position=Vector2(335,104);notice_panel.size=Vector2(610,64);notice_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(notice_panel)
 notice=label("",17);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;notice_panel.add_child(notice)
 weapon=label("",16,GOLD);weapon.position=Vector2(34,602);weapon.size=Vector2(520,28);hud.add_child(weapon)
 combo=label("",20,GOLD);combo.position=Vector2(1050,580);combo.size=Vector2(200,30);combo.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(combo)
 var footer:=Panel.new();footer.position=Vector2(0,646);footer.size=Vector2(1280,74);footer.add_theme_stylebox_override("panel",style(Color(.045,.14,.22,.96)));hud.add_child(footer)
 var controls:=label("WASD  MOVE     CLICK / J  BUSTER     SHIFT  DASH     E  INTERACT",16,Color("c7d8d2"));controls.position=Vector2(218,665);controls.size=Vector2(830,32);controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(controls)
 var heal:=button("Q  BOTTLE",func():game.use_bottle());heal.name="HealButton";heal.position=Vector2(18,657);heal.size=Vector2(180,52);heal.focus_mode=Control.FOCUS_NONE;hud.add_child(heal)
 var menu_button:=button("MENU",func():game.ui.pause_screen("Status"));menu_button.position=Vector2(1090,657);menu_button.size=Vector2(172,52);menu_button.focus_mode=Control.FOCUS_NONE;hud.add_child(menu_button)
 boss_label=label("",18,GOLD);boss_label.position=Vector2(430,504);boss_label.size=Vector2(420,28);boss_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(boss_label)
 boss_bar=ProgressBar.new();boss_bar.position=Vector2(430,535);boss_bar.size=Vector2(420,12);boss_bar.show_percentage=false;boss_bar.add_theme_font_size_override("font_size",1);boss_bar.add_theme_stylebox_override("background",bar_style(Color("152e3a")));boss_bar.add_theme_stylebox_override("fill",bar_style(Color("d98465")));hud.add_child(boss_bar)
 reticle=Control.new();reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(reticle);reticle.draw.connect(draw_reticle)
 overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(overlay)
 fade_rect=ColorRect.new();fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade_rect.color=Color(0,0,0,0);fade_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(fade_rect)

func style(colour: Color,border: Color=Color("567689")) -> StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=colour;s.border_color=border;s.set_border_width_all(1);s.content_margin_left=18;s.content_margin_right=18;s.content_margin_top=12;s.content_margin_bottom=12;return s
func bar_style(colour: Color) -> StyleBoxFlat:
 var result:=StyleBoxFlat.new();result.bg_color=colour;return result
func theme() -> Theme:
 var t:=Theme.new();t.default_font_size=18
 for key in ["Label","Button","RichTextLabel"]:t.set_color("font_color",key,WHITE)
 t.set_stylebox("normal","Button",style(Color("234c6c")))
 t.set_stylebox("hover","Button",style(Color("356280"),GOLD))
 t.set_stylebox("pressed","Button",style(Color("496c80"),GOLD))
 t.set_stylebox("focus","Button",style(Color("335b77"),GOLD))
 t.set_stylebox("disabled","Button",style(Color("203c50"),Color("304e61")));t.set_color("font_disabled_color","Button",Color("809b9e"))
 t.set_stylebox("panel","PanelContainer",style(BLUE));return t
func label(text: String,size: int=18,colour: Color=WHITE) -> Label:
 var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",colour);node.add_theme_color_override("font_outline_color",Color("152f41"));node.add_theme_constant_override("outline_size",2);node.mouse_filter=Control.MOUSE_FILTER_IGNORE;return node
func button(text: String,callable: Callable) -> Button:
 var node:=Button.new();node.text=text;node.custom_minimum_size=Vector2(0,52);node.pressed.connect(callable);return node
func clear_overlay() -> void:
 for child in overlay.get_children():child.queue_free()
 portrait=null
func shade(alpha: float=.55) -> void:
 var cover:=ColorRect.new();cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);cover.color=Color(.025,.07,.12,alpha);overlay.add_child(cover)
func panel(rect: Rect2) -> VBoxContainer:
 var shell:=PanelContainer.new();shell.position=rect.position;shell.size=rect.size;overlay.add_child(shell)
 var margin:=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,22)
 shell.add_child(margin)
 var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);margin.add_child(box);return box

func title_screen() -> void:
 game.mode="title";clear_overlay()
 var box:=panel(Rect2(54,130,476,466))
 box.add_child(label("MEGA MAN LEGENDS",17,GOLD))
 box.add_child(label("FLUTTERBOUND",43,GOLD))
 var subtitle:=label("A top-down Digger adventure",20);box.add_child(subtitle)
 var gap:=Control.new();gap.custom_minimum_size.y=24;box.add_child(gap)
 var new_button:=button("New adventure",func():
  if game.state.save_exists():menu("NEW ADVENTURE","Replace this Flutterbound save? The previous Kattelox Days save remains separate.",[{"text":"Start a new adventure","action":"new"}],true)
  else:game.start_new())
 new_button.name="NewAdventure";box.add_child(new_button)
 var load_button:=button("Continue",func():game.continue_game());load_button.name="ContinueAdventure";load_button.disabled=not game.state.save_exists();box.add_child(load_button)
 var credits:=button("Controls and credits",func():credits_screen());box.add_child(credits)
 box.add_child(label("v0.4.0 / Unofficial fan adventure",14,Color("aac8c7")))
 new_button.grab_focus()

func credits_screen() -> void:
 var from_pause: bool=game.mode=="pause"
 clear_overlay();shade(.75);var box:=panel(Rect2(165,82,950,556))
 box.add_child(label("CONTROLS & CREDITS",28,GOLD))
 for text in ["WASD / arrows: move. Left click or J: fire. K: lock on. Shift: dash.","Hold right click or H, then release: charged shot. L: Grenade Arm. Q: bottle.","E / F / Space: interact. Esc: pause. M: map. Tab: equipment. F11: fullscreen.","Controller: left stick moves, right stick aims, X fires, RB dashes, LB locks.","A interacts, B fires grenades, Y uses a bottle, Start pauses.","Mega Man Legends characters and original assets belong to Capcom.","Textured model rips and MegaMan fan model: Xinus22, using tools by Kion.","Models sourced from Sky Pirate Arcade / Legends Station. Full credits: docs/ASSETS.md.","Original music and environment construction: this fan project."]:
  box.add_child(label(text,17))
 var back:=button("Back",func():pause_screen("Options") if from_pause else title_screen());box.add_child(back);back.grab_focus()

func menu(title: String,description: String,choices: Array,return_title: bool=false) -> void:
 game.mode="menu";clear_overlay();shade()
 var box:=panel(Rect2(272,90,736,540));box.add_child(label(title,28,GOLD))
 var desc:=label(description,18);desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.custom_minimum_size.y=62;box.add_child(desc)
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(scroll)
 var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",10);scroll.add_child(list)
 var first: Button
 for choice in choices:
  var action: String=choice.action
  var b:=button(choice.text,func():game.execute_choice(action));b.name=action;b.disabled=choice.get("disabled",false);list.add_child(b)
  if first==null and not b.disabled:first=b
 var back:=button("Back",func():title_screen() if return_title else game.resume_game());box.add_child(back)
 if first!=null:first.grab_focus()
 else:back.grab_focus()

func dialogue_screen(person: String,lines: Array,after: String="") -> void:
 game.mode="dialogue";clear_overlay();dialogue_lines=lines;dialogue_index=0;dialogue_after=after;type_clock=0
 var shell:=PanelContainer.new();shell.position=Vector2(68,438);shell.size=Vector2(1144,238);overlay.add_child(shell)
 var layout:=HBoxContainer.new();layout.add_theme_constant_override("separation",20);shell.add_child(layout)
 portrait=SubViewport.new();portrait.size=Vector2i(188,188);portrait.transparent_bg=true;portrait.own_world_3d=true;portrait.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 var portrait_root:=Node3D.new();portrait.add_child(portrait_root)
 var keys: Dictionary={"Roll":"roll","Data":"data","Barrell":"barrell","Tron":"tron"}
 var character=preload("res://scripts/legends/models.gd").make(keys.get(person,"megaman"),2.0);portrait_root.add_child(character)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=1.5;portrait_root.add_child(light)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=.8;portrait_root.add_child(env)
 var cam:=Camera3D.new();cam.position=Vector3(0,1.35,3.2);cam.projection=Camera3D.PROJECTION_ORTHOGONAL;cam.size=2.4;portrait_root.add_child(cam);cam.look_at_from_position(cam.position,Vector3(0,1.1,0));portrait_root.add_child(Node3D.new())
 var portrait_control:=TextureRect.new();portrait_control.custom_minimum_size=Vector2(188,188);portrait_control.texture=portrait.get_texture();portrait_control.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait_control.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;layout.add_child(portrait_control);portrait_control.add_child(portrait)
 var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",8);layout.add_child(column)
 var header:=HBoxContainer.new();column.add_child(header);var name_label:=label(person.to_upper(),22,GOLD);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(name_label);header.add_child(label("ROLL RADIO" if game.area=="ruins" else "E / A  CONTINUE",14,Color("a8cace")))
 dialogue_text=RichTextLabel.new();dialogue_text.bbcode_enabled=false;dialogue_text.scroll_active=false;dialogue_text.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialogue_text.add_theme_font_size_override("normal_font_size",20);dialogue_text.text=str(lines[0]);column.add_child(dialogue_text)
 var advance:=button("Continue",func():advance_dialogue());advance.custom_minimum_size.y=44;column.add_child(advance);advance.grab_focus()

func advance_dialogue() -> void:
 if not is_instance_valid(dialogue_text):return
 if dialogue_text.visible_characters>=0 and dialogue_text.visible_characters<dialogue_text.get_total_character_count():type_clock=9999;dialogue_text.visible_characters=-1;return
 dialogue_index+=1;type_clock=0
 if dialogue_index>=dialogue_lines.size():game.dialogue_done(dialogue_after);return
 dialogue_text.text=str(dialogue_lines[dialogue_index]);dialogue_text.visible_characters=0

func pause_screen(tab: String="Status") -> void:
 game.mode="pause";pause_tab=tab;clear_overlay()
 var background:=ColorRect.new();background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(background)
 var shader:=Shader.new();shader.code="shader_type canvas_item; uniform bool still=false; void fragment(){vec2 p=UV;float t=still?0.0:TIME*.025;float s=step(.48,fract((p.x-p.y+t)*10.0));COLOR=vec4(mix(vec3(.045,.16,.27),vec3(.07,.23,.36),s),1.0);}"
 var mat:=ShaderMaterial.new();mat.shader=shader;mat.set_shader_parameter("still",game.state.reduced_motion);background.material=mat
 var title:=label("MEGAMAN / FIELD LOG",32,GOLD);title.position=Vector2(64,36);overlay.add_child(title)
 var stats:=label("%d Z    SCORE %d"%[game.state.zenny,game.state.score],22);stats.position=Vector2(780,43);stats.size=Vector2(436,34);stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;overlay.add_child(stats)
 var tabs:=HBoxContainer.new();tabs.position=Vector2(64,96);tabs.size=Vector2(1152,54);tabs.add_theme_constant_override("separation",8);overlay.add_child(tabs)
 for name in ["Status","Equipment","Map","Journal","Options"]:
  var selected: String=name;var b:=button(name,func():pause_screen(selected));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(b)
  if name==tab:b.add_theme_stylebox_override("normal",style(GOLD));b.add_theme_color_override("font_color",BLUE)
 var box:=panel(Rect2(64,170,1152,414))
 match tab:
  "Status":
   box.add_child(label("%s"%game.location(),26,GOLD))
   box.add_child(label("Health %d / %d     Energy %d / 100"%[game.state.health,game.state.max_health(),int(game.state.energy)],21))
   box.add_child(label("FLUTTER SYSTEMS",18,Color("a4cfcd")))
   for i in range(3):box.add_child(label("%s     %s"%[["Port stabilizer","Navigation","Main engine"][i],"ONLINE" if game.state.repair>i else "OFFLINE"],21,GOLD if game.state.repair>i else WHITE))
   box.add_child(label("Best dig %d    Recovered relics %d"%[game.state.best_run,game.state.relics],19))
   box.add_child(label(game.objective(),20,GOLD))
  "Equipment":
   box.add_child(label("BUSTER / SPECIAL WEAPONS",26,GOLD))
   box.add_child(label("Power %d     Rapid fire %d     Armour %d"%[game.state.power,game.state.rapid,game.state.armour],22))
   box.add_child(label("Scrap %d     Refractor shards %d     Bottles %d"%[game.state.scrap,game.state.shards,game.state.bottles],22))
   box.add_child(label("Buster damage %d     Charged shot %d"%[12+game.state.power*6,40+game.state.power*6],20))
   box.add_child(label("Grenade Arm fitted / L or B / 18 energy" if game.state.grenade else "Grenade Arm: find the eastern weapon plans, then see Roll.",20))
   box.add_child(label("Repair parts: "+(", ".join(game.state.parts) if not game.state.parts.is_empty() else "None carried"),20))
   box.add_child(label("Hold K / LB to lock onto a visible enemy. Hold right click / H to charge.",18,Color("b4d0cc")))
  "Map":
   var map:=Control.new();map.custom_minimum_size=Vector2(1100,350);box.add_child(map);map.draw.connect(func():draw_map(map));map.queue_redraw()
  "Journal":
   box.add_child(label(game.objective(),26,GOLD))
   for text in ["1. Start the repair plan with Roll, then recover the Servo Motor on level 1.","2. Defeat the northern Hanmuru Doll and return the Ancient Circuit from level 2.","3. Challenge Tron's Feldynaught on the landing pad to open the Refractor core.","4. Defeat the core guardian, recover the Large Refractor and bring it home.","Break salvage for scrap and shards. Spend Zenny on Buster upgrades and bottles.","The Flutter cabin and Data restore your health. Defeat keeps your repair parts."]:
    box.add_child(label(text,20))
  "Options":
   for entry in [["Music: "+("On" if game.state.music else "Off"),"music"],["Sound effects: "+("On" if game.state.sound else "Off"),"sound"],["Reduced motion: "+("On" if game.state.reduced_motion else "Off"),"motion"]]:
    var action: String=entry[1];box.add_child(button(entry[0],func():game.execute_choice(action)))
   box.add_child(button("Controls and credits",func():credits_screen()))
 var actions:=HBoxContainer.new();actions.position=Vector2(64,620);actions.size=Vector2(1152,54);actions.add_theme_constant_override("separation",12);overlay.add_child(actions)
 for entry in [["Return to game","resume"],["Save adventure","save"],["Title screen","title"]]:
  var action: String=entry[1];var b:=button(entry[0],func():game.execute_choice(action));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(b)
 actions.get_child(0).grab_focus()

func draw_map(canvas: Control) -> void:
 var rect:=Rect2(270,8,570,325);canvas.draw_rect(rect,Color("102c3b"))
 var bounds: Rect2=game.world.bounds
 var scale: float=minf(rect.size.x/bounds.size.x,rect.size.y/bounds.size.y)*.95
 var offset: Vector2=rect.get_center()-bounds.get_center()*scale
 if game.area=="ruins":
  for cell in game.world.cells:
   var at: Vector2=game.world.origin+Vector2(cell)*game.world.cell_size
   canvas.draw_rect(Rect2(offset+at*scale,Vector2.ONE*game.world.cell_size*scale),Color("6a9391"))
 else:
  canvas.draw_rect(Rect2(offset+bounds.position*scale,bounds.size*scale),Color("567e75"))
  for wall in game.world.walls:canvas.draw_rect(Rect2(offset+wall.position*scale,wall.size*scale),Color("193646"))
 for item in game.world.interactables:canvas.draw_circle(offset+Vector2(item.pos.x,item.pos.z)*scale,4,Color("99d2c4"))
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.boss:canvas.draw_circle(offset+Vector2(enemy.position.x,enemy.position.z)*scale,6,Color("e99577"))
 canvas.draw_circle(offset+Vector2(game.player.position.x,game.player.position.z)*scale,5,GOLD)
 canvas.draw_string(font,Vector2(20,44),"YELLOW / MEGAMAN",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
 canvas.draw_string(font,Vector2(20,78),"CYAN / INTERACT",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("99d2c4"))
 canvas.draw_string(font,Vector2(20,112),"RED / GUARDIAN",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("e99577"))

func summary(title: String,lines: Array) -> void:
 game.mode="summary";clear_overlay();shade(.75);var box:=panel(Rect2(252,175,776,370));box.add_child(label(title,32,GOLD))
 for text in lines:box.add_child(label(str(text),22))
 var b:=button("Keep exploring Kattelox",func():game.resume_game());box.add_child(b);b.grab_focus()

func draw_reticle() -> void:
 for i in range(1,10):reticle.draw_line(Vector2(34+i*31.4,55),Vector2(34+i*31.4,70),BLUE,2)
 if not game.active():return
 var target=game.nearest_enemy(game.player.position,14) if Input.is_action_pressed("lock") else null
 var point: Vector2=game.get_viewport().get_mouse_position()
 if is_instance_valid(target):point=game.camera.unproject_position(target.position+Vector3.UP*.8)
 elif not game.mouse_aim or not game.pointer_in_world():return
 for offset in [Vector2(-12,0),Vector2(12,0),Vector2(0,-12),Vector2(0,12)]:reticle.draw_line(point+offset,point+offset*.5,GOLD,2,true)
 if is_instance_valid(target):reticle.draw_arc(point,16,0,TAU,24,GOLD,1.5,true)

func refresh() -> void:
 hud.visible=game.mode!="title"
 for child in hud.get_children():
  if child is Button:child.visible=game.mode=="game"
 health.max_value=game.state.max_health();health.value=game.state.health;energy.value=game.state.energy
 health_text.text="MEGAMAN  %d / %d"%[game.state.health,game.state.max_health()]
 currency.text="%d Z"%game.state.zenny;score.text="SCORE %d"%game.state.score;objective.text=game.objective();location_text.text=game.location()
 prompt.visible=game.mode=="game" and not game.interaction.is_empty()
 if prompt.visible:prompt.text="E  "+str(game.interaction.name)
 notice_panel.visible=game.mode=="game" and game.notice_time>0;notice.text=game.notice
 combo.text="%d CHAIN"%game.combo if game.combo>=2 else ""
 weapon.text="GRENADE ARM / L / 18 EN" if game.state.grenade else "HOLD RIGHT CLICK / H TO CHARGE"
 if game.mode=="dialogue" and is_instance_valid(dialogue_text):type_clock+=get_process_delta_time()*55;dialogue_text.visible_characters=mini(int(type_clock),dialogue_text.get_total_character_count())
 var boss=null
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.boss and not enemy.defeated:boss=enemy;break
 boss_bar.visible=is_instance_valid(boss) and game.active();boss_label.visible=boss_bar.visible
 if boss_bar.visible:
  boss_bar.max_value=boss.max_health;boss_bar.value=boss.health;boss_label.text="FELDYNAUGHT" if boss.kind=="feldynaught" else "HANMURU DOLL"
 reticle.queue_redraw()
 if is_instance_valid(game.player) and game.player.charge>.1:weapon.text="CHARGE READY / RELEASE" if game.player.charge>=.65 else "CHARGING BUSTER..."
 fade_rect.color.a=game.fade
 var b=hud.get_node_or_null("HealButton")
 if b:b.text="Q  BOTTLE x%d"%game.state.bottles
