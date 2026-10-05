extends CanvasLayer
const HUD = preload("res://scripts/hud.gd")
const BLUE := Color("163e68")
const GOLD := Color("f8d47b")
const WHITE := Color("fff4da")
var game
var root: Control
var overlay: Control
var hud
var tool_buttons: Array[Button] = []
var dialogue_lines: Array = []
var dialogue_index: int = 0
var dialogue_after: String = ""
var dialogue_text: RichTextLabel
var dialogue_button: Button
var type_clock: float = 0.0
var fish_time: float = 0.0
var fish_wait: float = 0.0
var fish_cursor: float = 0.0
var fish_target: float = 0.48
var fish_hits: int = 0
var fish_meter: Control
var fish_label: Label
var pause_tab: String = "Status"
var notice_label: Label
var return_to_title: bool = false

func _ready() -> void:
	layer=10
	root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.theme=make_theme()
	hud=HUD.new();hud.game=game;hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud)
	var hotbar:=HBoxContainer.new();hotbar.position=Vector2(218,307)
	hotbar.add_theme_constant_override("separation",6);root.add_child(hotbar)
	for i in range(4):
		var names := ["buster","hoe","water","seed"]
		var button:=Button.new()
		button.custom_minimum_size=Vector2(44,44)
		button.focus_mode=Control.FOCUS_NONE
		button.icon=load("res://assets/items/%s.png"%names[i])
		button.expand_icon=true
		button.add_theme_constant_override("icon_max_width",28)
		button.tooltip_text=["1: Mega Buster","2: Hoe","3: Watering Can","4: Selected Seeds / C chooses crop"][i]
		button.name="Tool%d"%(i+1)
		button.pressed.connect(func(): game.open_seeds() if i==3 and game.tool==3 else select_tool(i))
		hotbar.add_child(button);tool_buttons.append(button)
	var menu_button:=button_for("MENU",func(): game.ui.pause_screen("Status"))
	menu_button.position=Vector2(548,305);menu_button.size=Vector2(80,44);menu_button.name="PauseButton"
	menu_button.focus_mode=Control.FOCUS_NONE
	root.add_child(menu_button)
	var heal:=button_for("Q  %d"%game.state.items.heal,func(): game.use_heal())
	heal.position=Vector2(18,305);heal.size=Vector2(72,44);heal.name="HealButton"
	heal.focus_mode=Control.FOCUS_NONE
	heal.icon=load("res://assets/items/heal.png");heal.expand_icon=true;heal.add_theme_constant_override("icon_max_width",22)
	root.add_child(heal)
	var map_button:=button_for("MAP",func(): game.ui.pause_screen("Map"))
	map_button.position=Vector2(550,40);map_button.size=Vector2(78,44);map_button.name="MapButton"
	map_button.focus_mode=Control.FOCUS_NONE
	root.add_child(map_button)
	notice_label=Label.new();notice_label.position=Vector2(88,84);notice_label.size=Vector2(445,54)
	notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;notice_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_color_override("font_color",WHITE)
	notice_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(notice_label)
	overlay=Control.new();overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(overlay)

func select_tool(index: int) -> void:
	game.tool=index

func make_style(colour: Color, border: Color = Color("597c94")) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=colour
	style.border_color=border;style.set_border_width_all(1)
	style.content_margin_left=12;style.content_margin_right=12
	style.content_margin_top=8;style.content_margin_bottom=8
	return style

func make_theme() -> Theme:
	var theme:=Theme.new();theme.default_font_size=14
	for type in ["Label","Button","RichTextLabel"]: theme.set_color("font_color",type,WHITE)
	theme.set_stylebox("normal","Button",make_style(Color("224c74")))
	theme.set_stylebox("hover","Button",make_style(Color("416b89"),GOLD))
	theme.set_stylebox("pressed","Button",make_style(GOLD,GOLD))
	theme.set_stylebox("focus","Button",make_style(Color(0,0,0,0),GOLD))
	theme.set_stylebox("disabled","Button",make_style(Color("24405a"),Color("3e5667")))
	theme.set_color("font_disabled_color","Button",Color("7991a5"))
	theme.set_color("font_pressed_color","Button",BLUE)
	var panel_style:=make_style(BLUE,Color("7ba4ac"))
	panel_style.content_margin_left=0;panel_style.content_margin_right=0
	panel_style.content_margin_top=0;panel_style.content_margin_bottom=0
	theme.set_stylebox("panel","PanelContainer",panel_style)
	return theme

func button_for(text: String, callback: Callable, disabled: bool = false) -> Button:
	var button:=Button.new();button.text=text;button.custom_minimum_size.y=44
	button.disabled=disabled;button.pressed.connect(callback)
	button.mouse_entered.connect(func(): game.audio.effect("select",1.15))
	return button

func text_label(text: String, font_size: int = 14, colour: Color = WHITE) -> Label:
	var label:=Label.new();label.text=text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",colour)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func clear_overlay() -> void:
	for node in overlay.get_children():
		overlay.remove_child(node);node.queue_free()
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	dialogue_text=null;dialogue_button=null;fish_meter=null;fish_label=null
	return_to_title=false

func cancel_overlay() -> void:
	if return_to_title: title_screen()
	else: game.resume_game()

func dim(colour: Color = Color(0.02,0.07,0.12,0.65)) -> void:
	var rect:=ColorRect.new();rect.color=colour;rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter=Control.MOUSE_FILTER_STOP;overlay.add_child(rect)
	overlay.mouse_filter=Control.MOUSE_FILTER_STOP

func panel_box(at: Vector2, dimensions: Vector2) -> VBoxContainer:
	var panel:=PanelContainer.new();panel.position=at;panel.size=dimensions
	overlay.add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	panel.add_child(margin)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",8)
	margin.add_child(box)
	return box

func title_screen() -> void:
	clear_overlay();game.mode="title"
	dim(Color(0.025,0.09,0.17,0.62))
	var box:=VBoxContainer.new();box.position=Vector2(38,24);box.size=Vector2(346,300)
	box.add_theme_constant_override("separation",6);overlay.add_child(box)
	box.add_child(text_label("A MEGA MAN LEGENDS FAN ADVENTURE",14,GOLD))
	box.add_child(text_label("KATTELOX",42,WHITE))
	box.add_child(text_label("DAYS",48,GOLD))
	box.add_child(text_label("A little island. An ancient mystery.\nA place to call home.",14))
	var start:=button_for("New Adventure",func():
		if game.state.save_exists(): menu("NEW ADVENTURE","Starting again replaces your current save.",[{"text":"Start a new adventure","action":"new"}],true)
		else: game.start_new())
	start.name="NewAdventure";box.add_child(start)
	var cont:=button_for("Continue",func(): game.continue_game(),not game.state.save_exists())
	cont.name="ContinueAdventure";box.add_child(cont)
	var footer:=text_label("WASD move   E interact   J fire   Shift dash   Esc menu",14)
	footer.position=Vector2(38,332);footer.size=Vector2(590,24);overlay.add_child(footer)
	var hero:=TextureRect.new()
	var atlas:=AtlasTexture.new();atlas.atlas=load("res://assets/characters/megaman.png");atlas.region=Rect2(0,90,38,45)
	hero.texture=atlas;hero.position=Vector2(459,154);hero.size=Vector2(106,126)
	hero.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;hero.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	hero.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(hero)
	var version:=text_label("KATTELOX DAYS  0.2.0",14,GOLD)
	version.position=Vector2(424,292);version.size=Vector2(210,28);overlay.add_child(version)
	if not cont.disabled: cont.grab_focus()
	else: start.grab_focus()

func menu(title: String, description: String, choices: Array, return_title: bool = false) -> void:
	clear_overlay();game.mode="menu";dim()
	return_to_title=return_title
	var box:=panel_box(Vector2(74,22),Vector2(492,316))
	box.add_child(text_label(title,22,GOLD))
	var detail:=text_label(description);detail.custom_minimum_size.y=40;box.add_child(detail)
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",6)
	scroll.add_child(list)
	var first: Button=null
	for choice in choices:
		var action: String=choice.action
		var button:=button_for(choice.text,func(): game.execute_choice(action),bool(choice.get("disabled",false)))
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT;button.name=action;list.add_child(button)
		if first==null and not button.disabled: first=button
	var back:=button_for("Back",func():
		if return_title: title_screen()
		else: game.resume_game())
	box.add_child(back)
	if first!=null: first.grab_focus()
	else: back.grab_focus()

func dialogue_screen(person: String, lines: Array, after: String) -> void:
	clear_overlay();game.mode="dialogue"
	dialogue_lines=lines;dialogue_index=0;dialogue_after=after;type_clock=0
	var box:=panel_box(Vector2(24,199),Vector2(592,145))
	var head:=HBoxContainer.new();box.add_child(head)
	var name_label:=text_label(person.to_upper(),18,GOLD)
	name_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(name_label)
	var hint:=text_label("E / Enter",14,Color("a5cad3"))
	hint.autowrap_mode=TextServer.AUTOWRAP_OFF
	head.add_child(hint)
	dialogue_text=RichTextLabel.new();dialogue_text.bbcode_enabled=false
	dialogue_text.text=str(dialogue_lines[0]);dialogue_text.visible_characters=0
	dialogue_text.size_flags_vertical=Control.SIZE_EXPAND_FILL;dialogue_text.custom_minimum_size.y=58
	dialogue_text.scroll_active=false;dialogue_text.mouse_filter=Control.MOUSE_FILTER_IGNORE
	box.add_child(dialogue_text)
	dialogue_button=button_for("Continue",func(): advance_dialogue())
	dialogue_button.custom_minimum_size.y=32;box.add_child(dialogue_button)
	dialogue_button.grab_focus()
	var names: Dictionary={"Roll":"roll","Data":"data","Tron":"tron","Barrell":"barrell","Amelia":"amelia"}
	if names.has(person):
		var portrait:=TextureRect.new();var atlas:=AtlasTexture.new()
		atlas.atlas=load("res://assets/characters/%s.png"%names[person]);atlas.region=Rect2(0,0,24,36)
		portrait.texture=atlas;portrait.position=Vector2(535,125);portrait.size=Vector2(48,72)
		portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(portrait)

func advance_dialogue() -> void:
	if not is_instance_valid(dialogue_text): return
	if dialogue_text.visible_characters<dialogue_text.get_total_character_count():
		dialogue_text.visible_characters=dialogue_text.get_total_character_count();return
	dialogue_index+=1;game.audio.effect("select")
	if dialogue_index>=dialogue_lines.size():
		var after:=dialogue_after;game.dialogue_done(after)
		return
	dialogue_text.text=str(dialogue_lines[dialogue_index]);dialogue_text.visible_characters=0;type_clock=0

func pause_screen(tab: String = "Status") -> void:
	clear_overlay();game.mode="pause";pause_tab=tab
	var bg:=ColorRect.new();bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader:=Shader.new()
	shader.code="shader_type canvas_item; uniform bool still = false; void fragment(){ vec2 p=UV*vec2(640.,360.); float t=still?0.:TIME*8.; float band=step(28.,mod(p.x+p.y+t,64.)); float line=step(62.,mod(p.x+p.y+t,64.)); float grid=step(31.,mod(p.y-t*.4,32.)); vec3 col=mix(vec3(.07,.22,.39),vec3(.08,.28,.47),band); col+=vec3(.018,.045,.06)*(line+grid*.4); COLOR=vec4(col,1.); }"
	var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("still",game.state.reduced_motion)
	bg.material=material;overlay.add_child(bg)
	var heading:=text_label("MEGAMAN",24,GOLD);heading.position=Vector2(24,14);heading.size=Vector2(220,30);overlay.add_child(heading)
	var funds:=text_label("%d Z    SCORE %d"%[game.state.zenny,game.state.score],16,WHITE)
	funds.position=Vector2(324,21);funds.size=Vector2(292,28);funds.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;overlay.add_child(funds)
	var tabs:=HBoxContainer.new();tabs.position=Vector2(24,54);tabs.size=Vector2(592,44);tabs.add_theme_constant_override("separation",5);overlay.add_child(tabs)
	for name in ["Status","Equipment","Map","Journal","Options"]:
		var button:=button_for(name,func(): pause_screen(name))
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if name==tab: button.add_theme_stylebox_override("normal",make_style(GOLD,GOLD));button.add_theme_color_override("font_color",BLUE)
		tabs.add_child(button)
	var panel:=PanelContainer.new();panel.position=Vector2(24,110);panel.size=Vector2(592,176);overlay.add_child(panel)
	var margin:=MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,12)
	panel.add_child(margin)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",6);margin.add_child(box)
	match tab:
		"Status":
			box.add_child(text_label(game.rank_name(),20,GOLD))
			box.add_child(text_label("Health %d/%d     Energy %d/100     Day %d"%[game.state.health,game.state.max_health(),int(game.state.energy),game.state.day]))
			box.add_child(text_label("FLUTTER SYSTEMS",14,Color("a6d3d4")))
			box.add_child(text_label("Stabilizer %s    Nav %s    Engine %s"%["OK" if game.state.repair>=1 else "OFF","OK" if game.state.repair>=2 else "OFF","OK" if game.state.repair>=3 else "OFF"]))
			box.add_child(text_label("Best dig %d   Relics donated %d   Roll %d/10"%[game.state.best_dig,game.state.museum_donated,game.state.friendship.Roll]))
			box.add_child(text_label(game.objective(),14,GOLD))
		"Equipment":
			box.add_child(text_label("Buster Power %d   Rapid Fire %d   Armour %d"%[game.state.power,game.state.rapid,game.state.armour],16,GOLD))
			var scroll:=ScrollContainer.new();scroll.custom_minimum_size.y=70;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;box.add_child(scroll)
			var grid:=GridContainer.new();grid.columns=4;grid.custom_minimum_size.x=540;grid.add_theme_constant_override("h_separation",16);grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(grid)
			for entry in [["scrap","Scrap"],["shard","Shards"],["heal","Bottles"],["fish","Fish"],["seeds","Turnip seeds"],["tomato_seeds","Tomato seeds"],["sunflower_seeds","Flower seeds"],["turnips","Turnips"],["tomatoes","Tomatoes"],["sunflowers","Flowers"],["relic","Relics"],["servo","Servo"],["circuit","Circuit"],["refractor","Refractor"]]:
				var item_label:=text_label("%s  %d"%[entry[1],game.state.items[entry[0]]],13)
				item_label.autowrap_mode=TextServer.AUTOWRAP_OFF;grid.add_child(item_label)
			box.add_child(text_label("Damage %d   Shot interval %.2fs   Max health %d"%[10+game.state.power*6,maxf(0.13,0.3-game.state.rapid*.055),game.state.max_health()]))
			box.add_child(text_label("Grenade Arm: L / B (18 energy)" if game.state.grenade_unlocked else "Weapon plans: eastern ruin chamber."))
		"Map":
			var map:=Control.new();map.custom_minimum_size=Vector2(560,142);box.add_child(map)
			map.draw.connect(func(): draw_map(map));map.queue_redraw()
		"Journal":
			box.add_child(text_label(game.objective(),18,GOLD))
			box.add_child(text_label("Garden: E farms, C selects crops. Tomatoes regrow. Ship or gift your harvest."))
			box.add_child(text_label("Town: ship produce, finish requests, donate relics and meet neighbours."))
			box.add_child(text_label("Combat: J fires, K locks, L grenades, Shift dashes, Q heals. E opens caches."))
		"Options":
			for entry in [["Music: "+("On" if game.state.music else "Off"),"music"],["Sound effects: "+("On" if game.state.sound else "Off"),"sound"],["Reduced motion: "+("On" if game.state.reduced_motion else "Off"),"motion"]]:
				var action: String=entry[1];var button:=button_for(entry[0],func(): game.execute_choice(action))
				button.custom_minimum_size.y=36;box.add_child(button)
	var footer:=HBoxContainer.new();footer.position=Vector2(24,302);footer.size=Vector2(592,44);footer.add_theme_constant_override("separation",8);overlay.add_child(footer)
	var resume:=button_for("Return to Game",func(): game.resume_game());resume.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(resume)
	var save:=button_for("Save",func(): game.execute_choice("save"));footer.add_child(save)
	var title:=button_for("Title Screen",func(): game.execute_choice("title"));footer.add_child(title)
	resume.grab_focus()

func draw_map(control: Control) -> void:
	var scale_factor: float=minf(300.0/game.world.size.x,134.0/game.world.size.y)
	var offset:=Vector2(6,4)
	control.draw_rect(Rect2(offset,game.world.size*scale_factor),Color("1c3548"))
	if game.area=="surface":
		control.draw_rect(Rect2(offset+Vector2(52,106)*scale_factor,Vector2(1164,820)*scale_factor),Color("6d8d64"))
		for rect in game.world.blockers: control.draw_rect(Rect2(offset+rect.position*scale_factor,rect.size*scale_factor),Color("afae8c"))
	else:
		for cell in game.world.floor_cells: control.draw_rect(Rect2(offset+Vector2(cell)*32*scale_factor,Vector2(32,32)*scale_factor),Color("75928d"))
	for item in game.world.interactables: control.draw_circle(offset+item.pos*scale_factor,3,Color("83d6d7"))
	for enemy in game.enemies:
		if is_instance_valid(enemy) and enemy.boss: control.draw_circle(offset+enemy.position*scale_factor,4,Color("ed8665"))
	control.draw_circle(offset+game.player.position*scale_factor,4,GOLD)
	control.draw_string(ThemeDB.fallback_font,Vector2(316,24),game.location_name(),HORIZONTAL_ALIGNMENT_LEFT,-1,14,WHITE)
	control.draw_string(ThemeDB.fallback_font,Vector2(316,54),"Yellow: MegaMan",HORIZONTAL_ALIGNMENT_LEFT,-1,14,GOLD)
	control.draw_string(ThemeDB.fallback_font,Vector2(316,80),"Cyan: destination",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("a7d7d2"))
	control.draw_string(ThemeDB.fallback_font,Vector2(316,106),"E interacts nearby",HORIZONTAL_ALIGNMENT_LEFT,-1,14,WHITE)

func summary_screen(title: String, lines: Array) -> void:
	clear_overlay();game.mode="summary";dim()
	var box:=panel_box(Vector2(82,66),Vector2(476,234))
	box.add_child(text_label(title,24,GOLD))
	for line in lines: box.add_child(text_label(str(line),16))
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(spacer)
	var continue_button:=button_for("Back to Kattelox",func(): game.resume_game());box.add_child(continue_button);continue_button.grab_focus()

func fishing_screen() -> void:
	clear_overlay();game.mode="fishing";dim(Color(0.02,0.08,0.12,0.35))
	fish_time=0;fish_wait=randf_range(1.0,2.2);fish_target=randf_range(0.34,0.63);fish_hits=0
	var box:=panel_box(Vector2(108,76),Vector2(424,206))
	box.add_child(text_label("FISHING AT THE PIER",22,GOLD))
	fish_label=text_label("Waiting for a bite...",16);box.add_child(fish_label)
	fish_meter=Control.new();fish_meter.custom_minimum_size=Vector2(374,38);box.add_child(fish_meter)
	fish_meter.draw.connect(func():
		fish_meter.draw_rect(Rect2(0,8,374,22),Color("0e2b46"))
		fish_meter.draw_rect(Rect2(fish_target*374-33,8,66,22),Color("85b798"))
		fish_meter.draw_rect(Rect2(fish_cursor*374-3,4,6,30),GOLD))
	var catch_button:=button_for("E / click: Reel when the marker reaches green",func(): fish_press())
	box.add_child(catch_button);catch_button.grab_focus()
	box.add_child(text_label("Esc cancels. Three good reels land the fish.",14))

func fish_press() -> void:
	if game.mode!="fishing": return
	if fish_time<fish_wait: return
	if absf(fish_cursor-fish_target)<=0.095:
		fish_hits+=1;game.audio.effect("water")
		fish_target=randf_range(0.26,0.75)
		fish_label.text="Good reel! %d / 3"%fish_hits
		if fish_hits>=3:
			game.state.items.fish+=1;game.state.score+=75;game.audio.effect("item")
			game.state.save_game();game.resume_game();game.toast("Lake fish caught! Sell it, cook it or fill a town request.")
	else:
		game.resume_game();game.toast("The fish slipped away. Try again at the pier.")

func refresh(delta: float) -> void:
	if not is_instance_valid(root): return
	var display_hud: bool=game.mode!="title"
	hud.visible=display_hud
	for node in root.get_children():
		if node!=overlay and node!=hud: node.visible=display_hud and game.mode=="game"
	for i in range(tool_buttons.size()):
		tool_buttons[i].add_theme_stylebox_override("normal",make_style(GOLD,GOLD) if i==game.tool else make_style(Color("23496a")))
	var heal:=root.get_node("HealButton") as Button
	heal.text="Q %d"%game.state.items.heal
	if game.notice_time>0 and game.mode=="game": notice_label.text=game.notice
	else: notice_label.text=""
	if game.mode=="dialogue" and is_instance_valid(dialogue_text):
		type_clock+=delta*48
		dialogue_text.visible_characters=mini(dialogue_text.get_total_character_count(),int(type_clock)) if dialogue_text.visible_characters<dialogue_text.get_total_character_count() else dialogue_text.visible_characters
	if game.mode=="fishing" and is_instance_valid(fish_meter):
		fish_time+=delta
		fish_cursor=pingpong(maxf(0,fish_time-fish_wait)*0.72,1.0)
		if fish_time>=fish_wait and fish_hits==0: fish_label.text="A bite! Reel in the green zone."
		fish_meter.queue_redraw()
	hud.queue_redraw()
