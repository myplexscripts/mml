extends Control
var game
const WHITE := Color("fff3d3")
const GOLD := Color("f4d07b")
var font: Font = ThemeDB.fallback_font

func text_at(text: String, at: Vector2, colour: Color = WHITE, width: float = -1) -> void:
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,width,14,colour)

func _draw() -> void:
	if not is_instance_valid(game.player): return
	# Atmosphere sits beneath the UI, while the world remains readable.
	if game.area=="surface":
		var hour: float=game.state.minutes/60.0
		var night: float=clampf((hour-17.0)/4.0,0,1)
		if hour<7: night=0.25
		if night>0: draw_rect(Rect2(0,0,640,360),Color(0.04,0.10,0.22,night*0.43))
		if game.state.day%4==0:
			for i in range(70):
				var x: float=fmod(i*83.0+game.clock*22,640)
				var y: float=fmod(i*49.0+game.clock*160,360)
				draw_line(Vector2(x,y),Vector2(x-3,y+8),Color(0.7,0.87,0.92,0.33),1)
	draw_rect(Rect2(0,0,640,33),Color(0.06,0.19,0.30,0.96))
	draw_rect(Rect2(0,33,640,2),Color("b8c9b1"))
	text_at("MEGAMAN",Vector2(18,23),GOLD)
	text_at("DAY %d"%game.state.day,Vector2(304,23))
	var mins: int=int(game.state.minutes)
	text_at("%02d:%02d"%[mins/60,mins%60],Vector2(394,23))
	text_at("%d Z"%game.state.zenny,Vector2(509,23),GOLD)
	draw_rect(Rect2(16,40,526,26),Color(0.06,0.18,0.29,0.83))
	var boss_target=null
	for enemy in game.enemies:
		if is_instance_valid(enemy) and enemy.boss and enemy.position.distance_to(game.player.position)<330:
			boss_target=enemy;break
	if is_instance_valid(boss_target):
		text_at("BONNE MACHINE" if boss_target.kind=="bonne" else "REFRACTOR GUARDIAN",Vector2(25,59))
		draw_rect(Rect2(274,48,254,8),Color("264b5a"))
		draw_rect(Rect2(274,48,254*float(boss_target.health)/boss_target.max_health,8),Color("e58b70"))
	else: text_at(game.objective(),Vector2(25,59),WHITE,510)
	# Legends' vertical segmented life gauge, chrome frame and danger light.
	draw_rect(Rect2(17,77,27,115),Color("233947"))
	draw_rect(Rect2(17,77,27,115),Color("b8cbd1"),false,2)
	draw_rect(Rect2(21,81,19,107),Color("142f42"))
	var segments: int=int(ceil(float(game.state.health)/game.state.max_health()*12))
	for i in range(12):
		var fill:=GOLD if game.state.health>25 else Color("ec8e76")
		if i>=segments: fill=Color("3b535b")
		draw_rect(Rect2(23,178-i*8,15,6),fill)
	draw_circle(Vector2(31,70),4,Color("c7e8a2") if game.state.health>25 else Color("eb7660"))
	text_at(str(game.state.health),Vector2(18,210))
	text_at("EN",Vector2(18,231),Color("bad7cf"))
	draw_rect(Rect2(18,240,58,5),Color("203f52"))
	draw_rect(Rect2(18,240,58*game.state.energy/100,5),Color("90c8ad"))
	draw_rect(Rect2(0,302,640,58),Color(0.05,0.17,0.27,0.93))
	for i in range(4): text_at(str(i+1),Vector2(235+i*50,299),GOLD)
	text_at("SCORE",Vector2(103,324),Color("a3c7ce"))
	text_at(str(game.state.score),Vector2(103,346),GOLD)
	text_at("SEEDS %d"%game.state.items.seeds,Vector2(429,331))
	if game.combo>=2:
		text_at("%d CHAIN"%game.combo,Vector2(503,113),GOLD)
		draw_rect(Rect2(502,119,98*game.combo_time/5.0,3),GOLD)
	if not game.interaction.is_empty() and game.mode=="game":
		var prompt: String="E  "+str(game.interaction.name)
		var w: float=minf(420,font.get_string_size(prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+30)
		draw_rect(Rect2(320-w/2,262,w,31),Color(0.05,0.17,0.27,0.94))
		text_at(prompt,Vector2(334-w/2,283),GOLD,w-20)
	if game.notice_time>0 and game.mode=="game":
		draw_rect(Rect2(82,79,457,64),Color(0.05,0.17,0.27,0.89))
	if game.fade>0: draw_rect(Rect2(0,0,640,360),Color(0.03,0.08,0.13,game.fade))
