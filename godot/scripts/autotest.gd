extends Node
## Automated play-tester (only active with:  -- --autotest [--shots] [--cheat]).
## Presses real input actions like a player would, logs progress and takes screenshots.

var t := 0.0
var next_act := 0.0
var shots := false
var cheat := false
var shot_done := {}
var log_lines: Array = []
var max_time := 240.0
var dirs = ["ui_up", "ui_down", "ui_left", "ui_right"]
var last_mode := ""
var runs_target := 2

func _ready() -> void:
	var args = OS.get_cmdline_user_args()
	shots = "--shots" in args
	cheat = "--cheat" in args
	for a in args:
		if a.begins_with("--time="): max_time = float(a.substr(7))
		if a.begins_with("--runs="): runs_target = int(a.substr(7))
	Engine.time_scale = 1.0 if shots else 4.0
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("[autotest] start shots=%s cheat=%s" % [shots, cheat])

func press(action: String) -> void:
	var e = InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
	var r = InputEventAction.new()
	r.action = action
	r.pressed = false
	Input.parse_input_event(r)

func shot(name: String) -> void:
	if not shots or shot_done.has(name): return
	shot_done[name] = true
	await get_tree().create_timer(1.3, true, false, true).timeout
	var img = get_viewport().get_texture().get_image()
	img.save_png("/home/claude/shots/%s.png" % name)
	print("[autotest] shot ", name)

func shot_now(name: String) -> void:
	if not shots or shot_done.has(name): return
	shot_done[name] = true
	await get_tree().create_timer(0.2, true, false, true).timeout
	get_viewport().get_texture().get_image().save_png("/home/claude/shots/%s.png" % name)
	print("[autotest] shot ", name)

func _process(delta: float) -> void:
	t += delta / max(Engine.time_scale, 0.001)
	if t > max_time:
		finish()
		return
	if G.mode != last_mode:
		print("[autotest] t=%.1f mode=%s floor=%s party=%s" % [t, G.mode, (G.run.floor if G.run else "-"), (G.run.party.size() if G.run else "-")])
		last_mode = G.mode
	if t < next_act: return
	next_act = t + (0.35 if shots else 0.12)
	if cheat and G.run != null:
		for h in G.run.party:
			h.lv = maxi(h.lv, 14)
			h.hp = maxi(h.hp, 400)
			h.mp = 99
		G.run.keys = maxi(G.run.keys, 2)
		G.run.gold = maxi(G.run.gold, 300)
	var m = UI.menus
	if G.mode == "title" and m.size() > 0:
		shot("01_title"); press("ui_accept"); return
	if G.mode == "camp" and m.size() > 0:
		shot("02_camp")
		if int(Meta.st.runs) >= runs_target:
			finish(); return
		var top = m.back()
		if top.spec.get("title", "") == "Camp":
			top.idx = 0
		press("ui_accept"); return
	if G.mode == "battle" and m.size() == 0 and Bt.acting != null and G.run.party.size() >= 2:
		shot_now("10_action")
	if G.mode == "battle" and m.size() > 0 and m.back().kind == "msg" and G.run.party.size() >= 2:
		shot("11_victory")
	if G.mode == "battle" and m.size() > 0:
		var top = m.back()
		if top.spec.get("title", "") == "Target" and G.run.party.size() >= 2: shot("05_battle_target")
		elif Bt.boss: shot("06_boss")
		else: shot("04_battle")
		press("ui_accept"); return
	if m.size() > 0:
		var top = m.back()
		var ttl = str(top.spec.get("title", ""))
		if ttl.begins_with("Shop"):
			shot("07_shop")
			press("ui_cancel" if randf() < 0.6 else "ui_accept"); return
		if ttl == "Menu":
			press("ui_cancel"); return
		press("ui_accept"); return
	if G.mode == "dungeon" and not G.busy and not G.card_on:
		var r = G.cur_room()
		if r and r.type == "shop": shot("08_room_shop")
		elif r and r.type == "start" and not G.busy: shot("03_room")
		elif r and r.type in ["camp", "treasure", "altar", "fountain", "cell"]: shot("09_room_" + r.type)
		if randf() < 0.3: press("ui_accept")
		else: press(dirs[randi() % 4])

func finish() -> void:
	print("[autotest] DONE t=%.1f runs=%d wins=%d deaths=%d kills=%d best=%d unlocked=%s ach=%s shards=%d" % [t, Meta.st.runs, Meta.st.wins, Meta.st.deaths, Meta.st.kills, Meta.st.best, str(Meta.unlocked.keys()), str(Meta.ach.keys()), Meta.shards])
	set_process(false)
	get_tree().quit()
