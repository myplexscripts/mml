extends CanvasLayer
const BLUE:=Color("102d50")
const GOLD:=Color("ffdc83")
const WHITE:=Color("fff2d4")

class Meter extends Control:
 var value: float=0:
  set(next):value=next;queue_redraw()
 var max_value: float=100:
  set(next):max_value=maxf(1,next);queue_redraw()
 var tint:=Color("f4d484")
 var segmented: bool=false
 func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw():
  draw_rect(Rect2(Vector2.ZERO,size),Color("29434b"))
  draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*clampf(value/max_value,0,1),size.y)),tint)
  if segmented:
   for i in range(1,10):draw_line(Vector2(i*size.x/10,0),Vector2(i*size.x/10,size.y),Color("173e62"),2)

var game
var root: Control
var overlay: Control
var hud: Control
var fade_rect: ColorRect
var health: Meter
var energy: Meter
var health_text: Label
var currency: Label
var objective: Label
var location_text: Label
var prompt: Label
var notice: Label
var notice_panel: PanelContainer
var weapon: Label
var score: Label
var boss_bar: Meter
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
var font: Font=preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var radar: Control


func plate(at: Vector2,dimensions: Vector2,accent: Color=GOLD) -> Panel:
 var node:=Panel.new();node.position=at;node.size=dimensions;node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 node.add_theme_stylebox_override("panel",style(Color(.025,.09,.16,.9),Color("477792")));hud.add_child(node)
 var strip:=ColorRect.new();strip.position=Vector2(0,0);strip.size=Vector2(3,dimensions.y);strip.color=accent;strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;node.add_child(strip)
 return node

func _ready() -> void:
 layer=10;root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.theme=theme();add_child(root)
 hud=Control.new();hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud)
 plate(Vector2(22,20),Vector2(278,82))
 health_text=label("MEGAMAN",20,GOLD);health_text.position=Vector2(38,27);hud.add_child(health_text)
 health=Meter.new();health.position=Vector2(38,58);health.size=Vector2(246,15);health.segmented=true;hud.add_child(health)
 energy=Meter.new();energy.position=Vector2(38,86);energy.size=Vector2(246,6);energy.tint=Color("62dcd3");hud.add_child(energy)
 var energy_tag:=label("EN",11,Color("7bb6c6"));energy_tag.position=Vector2(38,73);hud.add_child(energy_tag)
 plate(Vector2(336,20),Vector2(590,68),Color("62dcd3"))
 location_text=label("",14,Color("79b8cd"));location_text.position=Vector2(354,26);location_text.size=Vector2(554,19);hud.add_child(location_text)
 objective=label("",22);objective.position=Vector2(354,45);objective.size=Vector2(554,32);hud.add_child(objective)
 plate(Vector2(1080,20),Vector2(178,70))
 currency=label("250 Z",27,GOLD);currency.position=Vector2(1098,23);currency.size=Vector2(142,35);currency.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(currency)
 score=label("SCORE 0",14,Color("9bbbc8"));score.position=Vector2(1098,59);score.size=Vector2(142,22);score.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(score)
 prompt=label("",22,GOLD);prompt.position=Vector2(430,599);prompt.size=Vector2(420,50);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;prompt.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;prompt.add_theme_stylebox_override("normal",style(Color(.025,.09,.16,.94),Color("bdad72")));hud.add_child(prompt)
 notice_panel=PanelContainer.new();notice_panel.position=Vector2(360,110);notice_panel.size=Vector2(560,56);notice_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(notice_panel)
 notice=label("",20);notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;notice_panel.add_child(notice)
 plate(Vector2(22,620),Vector2(294,74),Color("62dcd3"))
 var title:=label("BUSTER / SPECIAL",13,Color("79b8cd"));title.position=Vector2(40,628);hud.add_child(title)
 weapon=label("",18,GOLD);weapon.position=Vector2(40,650);weapon.size=Vector2(265,30);hud.add_child(weapon)
 combo=label("",24,GOLD);combo.position=Vector2(940,116);combo.size=Vector2(312,30);combo.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;hud.add_child(combo)
 var controls:=label("WASD  MOVE    J  FIRE    SHIFT  DASH    K  LOCK    ESC  FIELD LOG",15,Color("c9ddd9"));controls.position=Vector2(354,672);controls.size=Vector2(580,24);controls.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(controls)
 var heal:=button("Q  BOTTLE",func():game.use_bottle());heal.name="HealButton";heal.position=Vector2(1034,646);heal.size=Vector2(132,48);heal.focus_mode=Control.FOCUS_NONE;hud.add_child(heal)
 var menu_button:=button("MENU",func():game.ui.pause_screen("Status"));menu_button.position=Vector2(1174,646);menu_button.size=Vector2(84,48);menu_button.focus_mode=Control.FOCUS_NONE;hud.add_child(menu_button)
 plate(Vector2(1080,455),Vector2(178,178),Color("62dcd3"))
 var map_label:=label("RADAR / M  MAP",13,Color("79b8cd"));map_label.position=Vector2(1094,461);hud.add_child(map_label)
 radar=Control.new();radar.position=Vector2(1090,487);radar.size=Vector2(158,135);radar.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(radar);radar.draw.connect(draw_radar)
 boss_label=label("",20,GOLD);boss_label.position=Vector2(430,534);boss_label.size=Vector2(420,28);boss_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hud.add_child(boss_label)
 boss_bar=Meter.new();boss_bar.position=Vector2(430,565);boss_bar.size=Vector2(420,12);boss_bar.tint=Color("e27a60");hud.add_child(boss_bar)
 reticle=Control.new();reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);reticle.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(reticle);reticle.draw.connect(draw_reticle)
 overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(overlay)
 fade_rect=ColorRect.new();fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade_rect.color=Color(0,0,0,0);fade_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(fade_rect)

func draw_radar() -> void:
 if not is_instance_valid(game.world) or not is_instance_valid(game.player):return
 var bounds: Rect2=game.world.bounds
 var scale: float=minf(radar.size.x/bounds.size.x,radar.size.y/bounds.size.y)*.94
 var offset: Vector2=radar.size/2-bounds.get_center()*scale
 radar.draw_rect(Rect2(Vector2.ZERO,radar.size),Color("071d2c"))
 if game.area=="ruins":
  for cell in game.world.cells:
   var at: Vector2=game.world.origin+Vector2(cell)*game.world.cell_size
   radar.draw_rect(Rect2(offset+at*scale,Vector2.ONE*game.world.cell_size*scale),Color("395b65"))
 else:
  radar.draw_rect(Rect2(offset+bounds.position*scale,bounds.size*scale),Color("304d55"))
  for wall in game.world.walls:radar.draw_rect(Rect2(offset+wall.position*scale,wall.size*scale),Color("132d3f"))
 for item in game.world.interactables:radar.draw_circle(offset+Vector2(item.pos.x,item.pos.z)*scale,2,Color("62dcd3"))
 for enemy in game.enemies:
  if is_instance_valid(enemy) and not enemy.defeated:radar.draw_circle(offset+Vector2(enemy.position.x,enemy.position.z)*scale,2,Color("e27a60"))
 var pos: Vector2=offset+Vector2(game.player.position.x,game.player.position.z)*scale
 radar.draw_circle(pos,3,GOLD);radar.draw_line(pos,pos+Vector2(game.player.facing.x,game.player.facing.z)*7,GOLD,1.5,true)

func style(colour: Color,border: Color=Color("567689")) -> StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=colour;s.border_color=border;s.set_border_width_all(1);s.corner_radius_top_left=5;s.corner_radius_bottom_right=5;s.shadow_color=Color(0,0,0,.3);s.shadow_size=5;s.content_margin_left=18;s.content_margin_right=18;s.content_margin_top=12;s.content_margin_bottom=12;return s
func theme() -> Theme:
 var t:=Theme.new();t.default_font=font;t.default_font_size=20
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
 box.add_child(label("FLUTTERBOUND",52,GOLD))
 var subtitle:=label("A top-down Digger adventure",20);box.add_child(subtitle)
 var gap:=Control.new();gap.custom_minimum_size.y=24;box.add_child(gap)
 var new_button:=button("New adventure",func():
  if game.state.save_exists():menu("NEW ADVENTURE","Replace this Flutterbound save? The previous Kattelox Days save remains separate.",[{"text":"Start a new adventure","action":"new"}],true)
  else:game.start_new())
 new_button.name="NewAdventure";box.add_child(new_button)
 var load_button:=button("Continue",func():game.continue_game());load_button.name="ContinueAdventure";load_button.disabled=not game.state.save_exists();box.add_child(load_button)
 var credits:=button("Controls and credits",func():credits_screen());box.add_child(credits)
 box.add_child(label("v0.5.0 / Unofficial fan adventure",14,Color("aac8c7")))
 new_button.grab_focus()

func credits_screen() -> void:
 var from_pause: bool=game.mode=="pause"
 clear_overlay();shade(.75);var box:=panel(Rect2(165,82,950,556))
 box.add_child(label("CONTROLS & CREDITS",28,GOLD))
 for text in ["WASD / arrows: move. Left click or J: fire. K: lock on. Shift: dash.","Hold right click / H / RT, then release: charged shot. L: Grenade Arm. Q: bottle.","E / F / Space: interact. Esc: pause. M: map. Tab: equipment. F11: fullscreen.","Controller: left stick moves, right stick aims, X fires, RB dashes, LB locks.","A interacts, B fires grenades, Y uses a bottle, Start pauses. Mouse wheel: zoom.","Mega Man Legends characters and original assets belong to Capcom.","Textured model rips and MegaMan fan model: Xinus22, using tools by Kion.","Models sourced from Sky Pirate Arcade / Legends Station. Full credits: docs/ASSETS.md.","Original music and environment construction: this fan project."]:
  box.add_child(label(text,17))
 var back:=button("Back",func():pause_screen("Options") if from_pause else title_screen());box.add_child(back);back.grab_focus()

func menu(title: String,description: String,choices: Array,return_title: bool=false) -> void:
 game.mode="menu";game.menu_return_title=return_title;clear_overlay();shade()
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
 var title:=label("DIGGERS FIELD LOG",36,GOLD);title.position=Vector2(64,32);overlay.add_child(title)
 var stats:=label("%d Z    SCORE %d"%[game.state.zenny,game.state.score],22);stats.position=Vector2(780,43);stats.size=Vector2(436,34);stats.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;overlay.add_child(stats)
 var tabs:=HBoxContainer.new();tabs.position=Vector2(64,96);tabs.size=Vector2(1152,54);tabs.add_theme_constant_override("separation",8);overlay.add_child(tabs)
 for name in ["Status","Equipment","Map","Journal","Options"]:
  var selected: String=name;var b:=button(name,func():pause_screen(selected));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(b)
  if name==tab:b.add_theme_stylebox_override("normal",style(GOLD));b.add_theme_color_override("font_color",BLUE)
 var box:=panel(Rect2(64,170,1152,414))
 match tab:
  "Status":
   var row:=HBoxContainer.new();row.add_theme_constant_override("separation",34);box.add_child(row)
   character_preview(row,"megaman",Vector2(270,318))
   var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",10);row.add_child(info)
   info.add_child(label(game.location().to_upper(),30,GOLD))
   info.add_child(label("MEGAMAN VOLNUTT / REGISTERED DIGGER",16,Color("79b8cd")))
   info.add_child(label("LIFE %d / %d     ENERGY %d%%"%[game.state.health,game.state.max_health(),int(game.state.energy)],22))
   info.add_child(label("FLUTTER / REPAIR STATUS",16,Color("79b8cd")))
   for i in range(3):
    var card:=HBoxContainer.new();info.add_child(card)
    var name_label:=label(["PORT STABILIZER","NAVIGATION CIRCUIT","MAIN ENGINE"][i],20);name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_child(name_label)
    card.add_child(label("ONLINE" if game.state.repair>i else "AWAITING PART",20,Color("62dcd3") if game.state.repair>i else Color("dca773")))
   info.add_child(label("BEST DIG  %d     RECOVERED RELICS  %d"%[game.state.best_run,game.state.relics],18))
   info.add_child(label(game.objective(),22,GOLD))
  "Equipment":
   var row:=HBoxContainer.new();row.add_theme_constant_override("separation",34);box.add_child(row)
   character_preview(row,"megaman",Vector2(270,318))
   var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",12);row.add_child(info)
   info.add_child(label("BUSTER / LOADOUT",30,GOLD))
   info.add_child(label("POWER  %d      RAPID FIRE  %d      ARMOUR  %d"%[game.state.power,game.state.rapid,game.state.armour],22))
   info.add_child(label("SHOT  %d DMG     CHARGED  %d DMG"%[12+game.state.power*6,40+game.state.power*6],21,Color("62dcd3")))
   info.add_child(label("GRENADE ARM / FITTED" if game.state.grenade else "SPECIAL WEAPON / NOT FITTED",22,GOLD))
   var detail:=label("L / B to launch • 18 energy" if game.state.grenade else "Find the eastern weapon plans, then see Roll.",20);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_child(detail)
   info.add_child(label("SCRAP  %d     SHARDS  %d     BOTTLES  %d"%[game.state.scrap,game.state.shards,game.state.bottles],22))
   info.add_child(label("REPAIR PARTS / "+(", ".join(game.state.parts).to_upper() if not game.state.parts.is_empty() else "NONE CARRIED"),20))
   info.add_child(label("K / LB locks onto a visible enemy. H / RT charges the Buster.",18,Color("9bbbc8")))
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

func character_preview(parent: Control,key: String,dimensions: Vector2) -> void:
 var shell:=PanelContainer.new();shell.custom_minimum_size=dimensions;shell.add_theme_stylebox_override("panel",style(Color("091e34"),Color("3c6b89")));parent.add_child(shell)
 var view:=SubViewport.new();view.size=Vector2i(dimensions);view.transparent_bg=true;view.own_world_3d=true;view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 var n:=Node3D.new();view.add_child(n)
 var character=preload("res://scripts/legends/models.gd").make(key,2);character.rotation.y=-.35;n.add_child(character)
 var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-25,0);light.light_energy=.8;n.add_child(light)
 var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("c6e3ef");env.environment.ambient_light_energy=.5;n.add_child(env)
 var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=2.65;n.add_child(camera);camera.position=Vector3(0,1.3,4);camera.look_at_from_position(camera.position,Vector3(0,1,0))
 var image:=TextureRect.new();image.texture=view.get_texture();image.custom_minimum_size=dimensions;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;shell.add_child(image);image.add_child(view);preload("res://scripts/legends/models.gd").pose(character,0,false)

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
 if not game.active():return
 for enemy in game.enemies:
  if not is_instance_valid(enemy) or enemy.defeated or enemy.boss or enemy.hit_time<=0:continue
  var at: Vector2=game.camera.unproject_position(enemy.position+Vector3.UP*2)
  var bar:=Rect2(at-Vector2(20,3),Vector2(40,5))
  reticle.draw_rect(bar,BLUE);reticle.draw_rect(Rect2(bar.position,Vector2(40*maxf(0,float(enemy.health)/enemy.max_health),5)),GOLD)

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
 health_text.text="MEGAMAN    %d / %d"%[game.state.health,game.state.max_health()]
 currency.text="%d Z"%game.state.zenny;score.text="SCORE %d"%game.state.score;objective.text=game.objective();location_text.text=game.location()
 prompt.visible=game.mode=="game" and not game.interaction.is_empty()
 if prompt.visible:prompt.text="E  "+str(game.interaction.name)
 notice_panel.visible=game.mode=="game" and game.notice_time>0;notice.text=game.notice
 combo.text="%d CHAIN"%game.combo if game.combo>=2 else ""
 weapon.text="L   GRENADE ARM   /   18 EN" if game.state.grenade else "H / RIGHT CLICK   CHARGE SHOT"
 if game.mode=="dialogue" and is_instance_valid(dialogue_text):type_clock+=get_process_delta_time()*55;dialogue_text.visible_characters=mini(int(type_clock),dialogue_text.get_total_character_count())
 var boss=null
 for enemy in game.enemies:
  if is_instance_valid(enemy) and enemy.boss and not enemy.defeated:boss=enemy;break
 boss_bar.visible=is_instance_valid(boss) and game.active();boss_label.visible=boss_bar.visible
 if boss_bar.visible:
  boss_bar.max_value=boss.max_health;boss_bar.value=boss.health;boss_label.text="FELDYNAUGHT" if boss.kind=="feldynaught" else "HANMURU DOLL"
 reticle.queue_redraw();radar.queue_redraw()
 if is_instance_valid(game.player) and game.player.charge>.1:weapon.text="CHARGE READY / RELEASE" if game.player.charge>=.65 else "CHARGING BUSTER..."
 fade_rect.color.a=game.fade
 var b=hud.get_node_or_null("HealButton")
 if b:b.text="Q  BOTTLE x%d"%game.state.bottles
