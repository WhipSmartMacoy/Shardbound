extends Node
## Game flow & run logic (title, camp, runs, floors, rooms, shop, unlocks). Battles live in battle.gd.

var world = null
var mode := "title"
var run = null
var busy := false
var card_on := false
var rng := RandomNumberGenerator.new()

const Y = "#ffe680"
const GR = "#7dffa0"
const BL = "#8ec5ff"
const RD = "#ff8a8a"
const DIM = "#9aa3d8"
const PU = "#e0a8ff"
const INFO_R = Rect2(667, 173, 597, 0)
const TIERS = ["I", "II", "III", "IV"]

func _ready() -> void:
	rng.randomize()
	randomize()

func c(col: String, s) -> String:
	return UI.c(col, s)

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func pick(a: Array):
	return a[rng.randi() % a.size()]

func ri(a: int, b: int) -> int:
	return rng.randi_range(a, b)

func rf() -> float:
	return rng.randf()

func shuffled(a: Array) -> Array:
	var b = a.duplicate()
	for i in range(b.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = b[i]
		b[i] = b[j]
		b[j] = tmp
	return b

func nm(h) -> String:
	return D.CHARS[h.id].name

func start() -> void:
	UI.apply_window_mode()
	title()

# ================= stats =================
func has_relic(id: String) -> bool:
	return run != null and id in run.relics

func stats(h: Dictionary) -> Dictionary:
	var g = D.CHARS[h.id].g
	var L = float(h.lv)
	var hp = g.hp * (30 + 11 * L)
	var mp = g.mp * (8 + 2.5 * L)
	var st = g.str * (6 + 1.7 * L)
	var mag = g.mag * (6 + 1.7 * L)
	var df = g.def * (3 + 1.3 * L)
	var agi = g.agi * (6 + 0.8 * L)
	hp *= 1 + 0.08 * Meta.upr("vit")
	mp *= 1 + 0.1 * Meta.upr("wis")
	if has_relic("vitalseed"): hp *= 1.2
	if has_relic("glassblade"): hp *= 0.75
	if has_relic("manaprism"): mp *= 1.3
	if has_relic("swiftfeather"): agi += 6
	if has_relic("crown"):
		hp *= 1.15; mp *= 1.15; st *= 1.15; mag *= 1.15; df *= 1.15; agi *= 1.15
	if run != null:
		hp *= run.hp_mult
	var s = {"hp": maxi(1, roundi(hp)), "mp": roundi(mp), "str": roundi(st), "mag": roundi(mag), "def": roundi(df), "agi": roundi(agi)}
	s["mdef"] = roundi(s.def * 0.5 + s.mag * 0.5)
	return s

func xp_need(lv: int) -> int:
	return roundi(6 * pow(lv, 1.6))

func make_hero(id: String, lv: int) -> Dictionary:
	var h = {"id": id, "lv": lv, "xp": 0, "hp": 1, "mp": 0}
	var s = stats(h)
	h.hp = s.hp
	h.mp = s.mp
	return h

func with_max(fn: Callable) -> void:
	var before = []
	for h in run.party:
		before.append(stats(h))
	fn.call()
	for i in run.party.size():
		var h = run.party[i]
		var a = stats(h)
		var b = before[i]
		if h.hp > 0:
			h.hp = clampi(h.hp + maxi(0, a.hp - b.hp), 1, a.hp)
		h.mp = clampi(h.mp + maxi(0, a.mp - b.mp), 0, a.mp)

func out_mult(h: Dictionary, kind: String) -> float:
	var m = 1.0 + 0.06 * Meta.upr("might")
	if kind == "phys" and has_relic("whetstone"): m *= 1.2
	if has_relic("glassblade"): m *= 1.45
	if kind == "magic" and has_relic("embercore"): m *= 1.3
	if has_relic("berserker") and h.hp < stats(h).hp * 0.5: m *= 1.4
	if h.id == "kael" and kind == "phys": m *= 1 + 0.1 * Meta.upr("sig_kael")
	if h.id == "doran" and kind == "magic": m *= 1 + 0.15 * Meta.upr("sig_doran")
	return m

func crit_chance(h: Dictionary) -> float:
	var cc = 0.05
	if h.id == "pip": cc += 0.1
	if has_relic("clover"): cc += 0.1
	if has_relic("loadeddice"): cc += 0.05
	return cc

func skill_cost(h: Dictionary, id: String) -> int:
	var cst = int(D.SK[id].mp)
	if has_relic("battery"): cst = int(floor(cst * 0.7))
	if h.id == "mira" and Meta.upr("sig_mira") > 0: cst = maxi(0, cst - 1)
	return cst

func gold_mult() -> float:
	var m = (1 + 0.25 * Meta.upr("coin")) * (1.5 if has_relic("goldtooth") else 1.0)
	for h in run.party:
		if h.id == "pip":
			m *= 1 + 0.3 * Meta.upr("sig_pip")
			break
	return m

func price(p: int) -> int:
	return roundi(p * (0.8 if Meta.upr("favor") > 0 else 1.0))

func pool_open(p: String) -> bool:
	if p == "base": return true
	if p.begins_with("ach:"): return Meta.ach.get(p.substr(4), false)
	return Meta.unlocked.get(p, false)

func relic_pool() -> Array:
	var l = []
	for id in D.RELICS:
		if pool_open(D.RELICS[id].pool) and not has_relic(id):
			l.append(id)
	return l

func gain_relic(id: String) -> void:
	with_max(func(): run.relics.append(id))
	Meta.seen[id] = true
	Meta.save_meta()

# ================= title / camp =================
func sound_item() -> Dictionary:
	return {"label": "Sound: " + ("Off" if Meta.muted else "On"), "value": "snd"}

func screen_item() -> Dictionary:
	return {"label": "Display: " + ("Fullscreen" if Meta.fullscreen else "Window"), "value": "fs"}

func title() -> void:
	mode = "title"
	run = null
	Bt.active = false
	UI.menus.clear()
	world.build_camp(true)
	UI.refresh()
	Snd.play_song("camp")
	await UI.fade(0.0, 0.6)
	var idx = 0
	while true:
		var v = await UI.choose({"x": 467, "y": 340, "w": 346, "cancel": false, "idx": idx, "items": [
			{"label": "Enter Camp", "value": "camp"}, {"label": "How to Play", "value": "how"}, sound_item(), screen_item(),
			{"label": "Erase Progress", "value": "reset"}, {"label": "Quit", "value": "quit"}]})
		match v:
			"camp":
				await UI.fade(1.0, 0.3)
				camp()
				return
			"how":
				idx = 1
				await UI.say(D.HOWTO, {"x": 80, "y": 60, "w": 1120})
			"snd":
				idx = 2
				Snd.set_muted(not Meta.muted)
			"fs":
				idx = 3
				UI.toggle_fullscreen()
			"reset":
				idx = 4
				if await UI.confirm("Erase ALL permanent progress?"):
					Meta.wipe()
					world.build_camp(true)
					await UI.say("Progress erased.")
			"quit":
				get_tree().quit()
				return

func camp() -> void:
	mode = "camp"
	run = null
	busy = false
	Bt.active = false
	UI.menus.clear()
	world.build_camp(false)
	UI.refresh()
	Snd.play_song("camp")
	await UI.fade(0.0, 0.4)
	var idx = 0
	while true:
		var v = await UI.choose({"title": "Camp", "x": 32, "y": 330, "w": 380, "cancel": false, "idx": idx, "rows": 9, "items": [
			{"label": "Embark", "value": 0}, {"label": "Upgrades", "value": 1}, {"label": "Heroes", "value": 2}, {"label": "Relic Codex", "value": 3},
			{"label": "Feats", "value": 4}, {"label": "How to Play", "value": 5}, sound_item(), {"label": "Title", "value": 6}]})
		if v is String and v == "snd":
			Snd.set_muted(not Meta.muted)
			idx = 6
			continue
		idx = v
		match v:
			0:
				await UI.fade(1.0, 0.35)
				start_run()
				return
			1: await upgrades_menu()
			2: await heroes_menu()
			3: await codex_menu()
			4: await feats_menu()
			5: await UI.say(D.HOWTO, {"x": 80, "y": 60, "w": 1120})
			6:
				await UI.fade(1.0, 0.3)
				title()
				return
		UI.refresh()

func upgrades_menu() -> void:
	var idx = 0
	var rs = Meta.roster().size()
	while true:
		var list = D.all_upgrades()
		var items = []
		for i in list.size():
			var u = list[i]
			var r = Meta.upr(u.id)
			var mx = u.cost.size()
			var lock = (not Meta.unlocked.get(u.hero, false)) if u.has("hero") else rs < u.req
			var right = ("locked" if u.has("hero") else "needs %d heroes" % u.req) if lock else ("MAX" if r >= mx else "✦%d" % u.cost[r])
			var label = "??? (hero locked)" if (lock and u.has("hero")) else "%s %s%s" % [u.name, "◆".repeat(r), "◇".repeat(mx - r)]
			items.append({"label": label, "right": right, "u": u, "disabled": lock or r >= mx, "value": i})
		var v = await UI.choose({"title": "Upgrades · ✦ %d" % Meta.shards, "x": 32, "y": 24, "w": 620, "rows": 13, "idx": idx, "items": items,
			"on_hover": func(it):
				var u = it.u
				var hl = u.has("hero") and not Meta.unlocked.get(u.hero, false)
				var foot = ("Camp tier %s (heroes unlocked: %d/4)" % [TIERS[u.req - 1], rs]) if u.has("req") else "Hero upgrade"
				UI.set_info("%s\n%s\n%s" % [c(Y, "Locked" if hl else u.name), ("Unlock %s to train them." % D.CHARS[u.hero].name) if hl else u.desc, c(DIM, foot)], INFO_R)})
		if v == null:
			return
		idx = v
		var u = list[v]
		var r = Meta.upr(u.id)
		if Meta.shards < u.cost[r]:
			Snd.sfx("err")
			await UI.say("Not enough Soul Shards.")
			continue
		Meta.shards -= u.cost[r]
		Meta.up[u.id] = r + 1
		Meta.save_meta()
		Snd.sfx("coin")
		UI.refresh()

func stars(v: float) -> String:
	return "★".repeat(roundi(v * 3))

func heroes_menu() -> void:
	var items = []
	for id in D.HERO_IDS:
		var un = Meta.unlocked.get(id, false)
		items.append({"label": ("%s the %s" % [D.CHARS[id].name, D.CHARS[id].title]) if un else "???", "value": id, "id": id})
	await UI.choose({"title": "Heroes", "x": 32, "y": 80, "w": 400, "rows": 4, "items": items, "on_hover": func(it):
		var C = D.CHARS[it.id]
		var g = C.g
		if Meta.unlocked.get(it.id, false):
			var sk = []
			for s in C.skills:
				sk.append("Lv%d %s" % [D.SK[s].lv, D.SK[s].name])
			UI.set_info("[img=87]res://assets/sprites/hero_%s.png[/img]\n%s\n%s\nHP %s  STR %s\nMAG %s  DEF %s\nAGI %s  MP %s\n%s" % [it.id, c(Y, "%s · %s" % [C.name, C.title]), C.blurb,
				stars(g.hp), stars(g.str), stars(g.mag), stars(g.def), stars(g.agi), stars(g.mp), c(DIM, ", ".join(sk))], INFO_R)
		else:
			UI.set_info("%s\nHow to unlock:\n%s" % [c(Y, "Locked hero"), c(Y, C.hint)], INFO_R)})

func codex_menu() -> void:
	var ids = D.RELICS.keys()
	var found = 0
	for i in ids:
		if Meta.seen.get(i, false): found += 1
	var items = []
	for id in ids:
		var R = D.RELICS[id]
		var op = pool_open(R.pool)
		items.append({"label": (R.name if Meta.seen.get(id, false) else c(DIM, R.name)) if op else "??? (locked)", "id": id, "value": id})
	await UI.choose({"title": "Relic Codex · %d/%d found" % [found, ids.size()], "x": 32, "y": 24, "w": 587, "rows": 14, "items": items, "on_hover": func(it):
		var R = D.RELICS[it.id]
		var op = pool_open(R.pool)
		var src = "Always in the pool."
		if R.pool.begins_with("ach:"):
			var an = ""
			for a in D.ACH:
				if a.id == R.pool.substr(4): an = a.name
			src = "Unlocked by feat: " + an
		elif R.pool != "base":
			src = "Unlocked with hero: " + D.CHARS[R.pool].name
		if op:
			UI.set_info("%s\n%s\n%s" % [c(Y, R.name), R.desc, c(DIM, src + ("" if Meta.seen.get(it.id, false) else " · not yet found"))], INFO_R)
		else:
			UI.set_info("%s\n%s" % [c(Y, "Locked relic"), c(DIM, src.replace("Unlocked", "Unlock"))], INFO_R)})

func featsMenu_progress(a: Dictionary) -> String:
	if a.has("stat") and not Meta.ach.get(a.id, false):
		return "\n" + c(DIM, "Progress %d/%d" % [mini(int(Meta.st.get(a.stat, 0)), a.n), a.n])
	return ""

func feats_menu() -> void:
	var items = []
	for a in D.ACH:
		items.append({"label": (c(GR, "✔ ") if Meta.ach.get(a.id, false) else "· ") + a.name, "a": a, "value": a.id})
	await UI.choose({"title": "Feats", "x": 32, "y": 50, "w": 587, "rows": 10, "items": items, "on_hover": func(it):
		var a = it.a
		UI.set_info("%s\n%s\nReward: %s%s%s" % [c(Y, a.name), a.desc, c(Y, a.reward), featsMenu_progress(a), ("\n" + c(GR, "Completed")) if Meta.ach.get(a.id, false) else ""], INFO_R)})

# ================= runs =================
func start_run() -> void:
	run = {"party": [], "floor": 0, "gold": 0, "keys": Meta.upr("key"), "items": {"potion": 2 + Meta.upr("pack"), "ember": Meta.upr("ember")},
		"relics": [], "kills": 0, "bosses": 0, "hp_mult": 1.0, "fairy_used": false, "unlocks": [], "pos": Vector2i(4, 4), "prev": null, "map": null, "dir": null}
	if Meta.upr("heir") > 0:
		var p = relic_pool()
		if not p.is_empty():
			var id = pick(p)
			run.relics.append(id)
			Meta.seen[id] = true
	for id in Meta.roster():
		run.party.append(make_hero(id, 1 + Meta.upr("vet_" + id)))
	Meta.stat_add("runs")
	Meta.save_meta()
	if int(Meta.st.runs) == 1:
		mode = "end"
		world.build_void()
		UI.refresh()
		UI.set_fade(0.0)
		await UI.say("The Shard that lit the world has shattered, and its last piece sinks into the Under-Spire.\n\n%s descends alone. He won't stay alone for long..." % c(Y, "Kael"))
	await enter_floor(0)

func enter_floor(fi: int) -> void:
	busy = true
	run.floor = fi
	run.map = gen_floor(fi)
	run.pos = Vector2i(4, 4)
	run.prev = null
	run.fairy_used = false
	run.dir = null
	if has_relic("goldkey"):
		run.keys += 1
	Meta.st.best = maxi(int(Meta.st.best), fi + 1)
	Meta.save_meta()
	mode = "dungeon"
	UI.set_fade(1.0)
	card_on = true
	UI.refresh()
	UI.show_card("FLOOR %d" % (fi + 1), D.FLOORS[fi].name)
	Snd.play_song("dungeon%d" % fi)
	await wait(1.4)
	UI.show_card("", "")
	card_on = false
	if has_relic("compass"):
		for k in run.map:
			run.map[k].seen = true
	reveal(run.pos)
	world.build_room(run)
	UI.refresh()
	await UI.fade(0.0, 0.35)
	if fi == 2:
		await grant("delver")
	if fi == 0 and int(Meta.st.runs) == 1:
		await UI.say("%s Walk through doors with the arrow keys, WASD or D-pad. The minimap (top right) marks special rooms: %s, %s, %s." % [c(Y, "Tip:"), c("#ff4040", "boss"), c(Y, "reliquary"), c(GR, "shop")])
	busy = false
	UI.refresh()

func gen_floor(fi: int) -> Dictionary:
	var N = 9
	var target = 9 + fi * 2
	var specials = ["boss", "treasure", "shop"]
	if fi == 1:
		specials.append("cell")
	var D4 = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var start = Vector2i(4, 4)
	for tries in 3000:
		var R = {start: true}
		var list = [start]
		var q = [start]
		var guard = 0
		while list.size() < target and guard < 400:
			guard += 1
			if q.is_empty():
				q.append(pick(list))
			var cur = q.pop_front()
			for d in shuffled(D4):
				if list.size() >= target:
					break
				var np = cur + d
				if np.x < 0 or np.y < 0 or np.x >= N or np.y >= N or R.has(np) or rf() < 0.5:
					continue
				var cnt = 0
				for d2 in D4:
					if R.has(np + d2): cnt += 1
				if cnt > 1:
					continue
				R[np] = true
				list.append(np)
				q.append(np)
		if list.size() < target:
			continue
		var dist = {start: 0}
		var bq = [start]
		while not bq.is_empty():
			var p = bq.pop_front()
			for d in D4:
				if R.has(p + d) and not dist.has(p + d):
					dist[p + d] = dist[p] + 1
					bq.append(p + d)
		var dead = []
		for p in list:
			if p == start: continue
			var cnt = 0
			for d in D4:
				if R.has(p + d): cnt += 1
			if cnt == 1: dead.append(p)
		dead.sort_custom(func(a, b): return dist[a] > dist[b])
		if dead.size() < specials.size() or dist[dead[0]] < 3:
			continue
		var map = {}
		for p in list:
			map[p] = {"x": p.x, "y": p.y, "type": "combat", "cleared": false, "visited": false, "seen": false, "used": false, "open": false}
		map[start].type = "start"
		map[dead[0]].type = "boss"
		var rest = shuffled(dead.slice(1))
		for i in range(1, specials.size()):
			map[rest[i - 1]].type = specials[i]
		var others = []
		for p in list:
			if map[p].type == "combat": others.append(p)
		others = shuffled(others)
		var extra = ["chest", pick(["fountain", "altar"])] if fi == 0 else ["camp", "chest", pick(["fountain", "altar"])]
		for i in extra.size():
			if i < others.size():
				map[others[i]].type = extra[i]
		for p in map:
			var r = map[p]
			r.cleared = not (r.type == "combat" or r.type == "boss")
		return map
	push_error("floor gen failed")
	return {}

func reveal(p: Vector2i) -> void:
	var r = run.map[p]
	r.visited = true
	r.seen = true
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if run.map.has(p + d):
			run.map[p + d].seen = true

func cur_room():
	if run == null or run.map == null or not run.map.has(run.pos):
		return null
	return run.map[run.pos]

func room_text(r: Dictionary) -> String:
	var txt = D.ROOMS[r.type].text
	if r.type == "cell" and not r.used and not Meta.unlocked.get("doran", false):
		txt = "A young mage slumps in an iron cage. He looks up hopefully."
	if r.type == "shop" and not Meta.unlocked.get("pip", false):
		txt = "A merchant's stall. A scruffy kid in a green hood is being held here over a debt."
	if r.used and r.type in ["chest", "camp", "altar", "fountain", "treasure"]:
		txt = "There is nothing more here."
	if r.type == "boss" and run.floor == 2:
		txt = "Silence. The Shard is free."
	return txt

func _unhandled_input(ev: InputEvent) -> void:
	if mode != "dungeon" or busy or run == null or not UI.menus.is_empty() or card_on:
		return
	if ev.is_action_pressed("ui_up"): try_move(Vector2i(0, -1))
	elif ev.is_action_pressed("ui_down"): try_move(Vector2i(0, 1))
	elif ev.is_action_pressed("ui_left"): try_move(Vector2i(-1, 0))
	elif ev.is_action_pressed("ui_right"): try_move(Vector2i(1, 0))
	elif ev.is_action_pressed("ui_accept"): do_room_action()
	elif ev.is_action_pressed("ui_cancel"): pause_menu()
	else: return
	get_viewport().set_input_as_handled()

func ui_action(m: String) -> void:
	if busy or not UI.menus.is_empty():
		return
	if m == "room": do_room_action()
	elif m == "menu": pause_menu()

func try_move(d: Vector2i) -> void:
	if busy or run == null or not UI.menus.is_empty() or mode != "dungeon":
		return
	var np = run.pos + d
	if not run.map.has(np):
		return
	var r = run.map[np]
	busy = true
	if r.type == "cell" and not r.open:
		if run.keys > 0:
			if not await UI.confirm("A sealed iron door. Use a %s?" % c(Y, "Key")):
				busy = false
				return
			run.keys -= 1
			r.open = true
			Snd.sfx("coin")
		else:
			await UI.say("A sealed iron door. It needs a %s. Keys drop from battles, chests and shops." % c(Y, "Key"))
			busy = false
			return
	Snd.sfx("door")
	run.dir = d
	await UI.fade(1.0, 0.14)
	run.prev = run.pos
	run.pos = np
	reveal(np)
	world.build_room(run)
	UI.refresh()
	await UI.fade(0.0, 0.14)
	await on_enter(r)
	if run != null and mode == "dungeon":
		busy = false
		UI.refresh()

func on_enter(r: Dictionary) -> void:
	if r.type == "combat" and not r.cleared:
		var res = await Bt.battle(formation(), {})
		if res == "win":
			r.cleared = true
		elif res == "fled":
			run.pos = run.prev
			run.prev = null
			world.build_room(run)
		elif res == "lose":
			await end_run(false)
			return
	elif r.type == "boss" and not r.cleared:
		var F = D.FLOORS[run.floor]
		await UI.say(F.intro)
		var res = await Bt.battle([F.boss], {"boss": true})
		if res == "lose":
			await end_run(false)
			return
		r.cleared = true
		run.bosses += 1
		if run.floor == 0:
			if not Meta.unlocked.get("mira", false):
				await UI.say("The Warden crumbles. The chained prisoner is a young healer. \"I'm %s. You freed me, so I'll follow you down.\"" % c(Y, "Mira"))
			await grant("warden")
		if run.floor == 2:
			await grant("victor")
			await end_run(true)
			return
		world.build_room(run)
		await UI.say("The guardian falls. A stairway opens downward.")
	UI.refresh()

func formation() -> Array:
	var F = D.FLOORS[run.floor]
	var n = run.party.size()
	var mx = mini(4, 1 + n)
	var mn = mini(mx, 2 if run.floor >= 1 else 1)
	var cnt = 1 if (n == 1 and run.floor == 0 and rf() < 0.6) else ri(mn, mx)
	var l = []
	for i in cnt:
		l.append(pick(F.pool))
	return l

func grant(id: String) -> void:
	if Meta.ach.get(id, false):
		return
	Meta.ach[id] = true
	Meta.save_meta()
	var a = null
	for x in D.ACH:
		if x.id == id: a = x
	if run != null:
		run.unlocks.append(a.name + " → " + a.reward)
	Snd.sfx("heal")
	if a.has("hero"):
		var cid = a.hero
		var C = D.CHARS[cid]
		Meta.unlocked[cid] = true
		Meta.save_meta()
		if run != null:
			var present = false
			for h in run.party:
				if h.id == cid: present = true
			if not present:
				var tot = 0
				for h in run.party: tot += h.lv
				var lv = maxi(1, roundi(float(tot) / run.party.size())) + Meta.upr("vet_" + cid)
				run.party.append(make_hero(cid, lv))
				if mode == "dungeon":
					world.build_room(run)
				UI.refresh()
		await UI.say("[img=87]res://assets/sprites/hero_%s.png[/img]\n%s\n%s joins your party!\n%s" % [cid, c(Y, "★ NEW HERO UNLOCKED ★"), c(Y, "%s the %s" % [C.name, C.title]),
			c("#c8cff8", "%s %s's relics join the pool and Camp Tier %s opens." % [C.blurb, C.name, TIERS[Meta.roster().size() - 1]])])
		if Meta.roster().size() == 4:
			await grant("party")
	else:
		await UI.say("%s\n%s\nUnlocked: %s" % [c(Y, "★ FEAT: %s ★" % a.name), a.desc, c(Y, a.reward)])

func check_feats() -> void:
	if int(Meta.st.kills) >= 50: await grant("slayer")
	if int(Meta.st.chests) >= 8: await grant("looter")
	if int(Meta.st.deaths) >= 3: await grant("mourner")

func end_run(victory: bool) -> void:
	busy = true
	if victory: Meta.stat_add("wins")
	else: Meta.stat_add("deaths")
	var rs = Meta.roster().size()
	var base = run.kills + run.bosses * 15 + (run.floor + 1) * 5 + (60 if victory else 0)
	var mult = (1 + 0.1 * (rs - 1)) * (1.3 if Meta.upr("siphon") > 0 else 1.0)
	var earned = roundi(base * mult)
	Meta.shards += earned
	Meta.stat_add("shardsTotal", earned)
	Meta.save_meta()
	await check_feats()
	await UI.fade(1.0, 0.35)
	mode = "end"
	Bt.active = false
	world.build_void()
	UI.refresh()
	if victory: Snd.play_song("camp")
	await UI.fade(0.0, 0.25)
	var rel = []
	for r in run.relics: rel.append(D.RELICS[r].name)
	var txt = c(Y, "★ THE SHARD IS RESTORED ★" if victory else "EXPEDITION FAILED") + "\n"
	if victory: txt += "Dawn breaks over the Under-Spire. Keep running for more unlocks!\n"
	txt += "Reached floor %d · Monsters slain %d · Bosses %d\nRelics held: %s\n\n" % [run.floor + 1, run.kills, run.bosses, c(PU, ", ".join(rel) if rel.size() else "none")]
	txt += "Soul Shards: %d kills + %d bosses + %d depth%s × %.2f = %s\n" % [run.kills, run.bosses * 15, (run.floor + 1) * 5, " + 60 victory" if victory else "", mult, c(Y, "✦ %d" % earned)]
	txt += (c(GR, "New this run: ") + " · ".join(run.unlocks)) if run.unlocks.size() else c(DIM, "No new unlocks this run.")
	await UI.say(txt, {"x": 120, "y": 110, "w": 1040})
	await UI.fade(1.0, 0.35)
	run = null
	busy = false
	camp()

# ================= room actions =================
func room_action_def(r: Dictionary):
	match r.type:
		"treasure": return null if r.used else {"label": "Open the reliquary", "fn": act_treasure}
		"shop": return {"label": "Browse wares", "fn": act_shop}
		"chest": return null if r.used else {"label": "Open the chest", "fn": act_chest}
		"camp": return null if r.used else {"label": "Rest by the fire", "fn": act_camp}
		"altar": return null if r.used else {"label": "Make an offering", "fn": act_altar}
		"fountain": return null if r.used else {"label": "Drink", "fn": act_fountain}
		"cell": return null if r.used else {"label": "Search the cell" if Meta.unlocked.get("doran", false) else "Free the prisoner", "fn": act_cell}
		"boss": return {"label": "Descend", "fn": act_descend} if (r.cleared and run.floor < 2) else null
	return null

func do_room_action() -> void:
	if busy or not UI.menus.is_empty() or run == null:
		return
	var r = cur_room()
	var a = room_action_def(r)
	if a == null:
		return
	busy = true
	await a.fn.call(r)
	if run != null and mode == "dungeon":
		busy = false
		world.build_room(run)
		UI.refresh()

func act_descend(_r) -> void:
	await UI.fade(1.0, 0.35)
	await enter_floor(run.floor + 1)
	busy = true

func choose_relic(n: int, head: String) -> void:
	var p = shuffled(relic_pool()).slice(0, n)
	if p.is_empty():
		run.gold += 50
		await UI.say("The relics have all been claimed. You find 50 G instead.")
		return
	var items = []
	for id in p:
		items.append({"label": D.RELICS[id].name, "value": id, "id": id})
	var v = await UI.choose({"title": head, "x": 32, "y": 80, "w": 560, "cancel": false, "items": items,
		"on_hover": func(it): UI.set_info("%s\n%s" % [c(Y, D.RELICS[it.id].name), D.RELICS[it.id].desc], INFO_R)})
	gain_relic(v)
	Snd.sfx("heal")
	await UI.say("Obtained %s!\n%s" % [c(PU, D.RELICS[v].name), c("#c8cff8", D.RELICS[v].desc)])

func act_treasure(r) -> void:
	r.used = true
	world.build_room(run)
	await choose_relic(4 if Meta.upr("sense") > 0 else 3, "Choose one relic")

func act_chest(r) -> void:
	r.used = true
	world.build_room(run)
	Meta.stat_add("chests")
	Meta.save_meta()
	Snd.sfx("coin")
	var roll = rf()
	var msg = ""
	if roll < 0.4:
		var g = ri(15, 30) * (run.floor + 1)
		run.gold += g
		msg = "Found %s!" % c(Y, "%d G" % g)
	elif roll < 0.65:
		run.keys += 1
		msg = "Found a %s!" % c(Y, "Key")
	else:
		var it = pick(["potion", "potion", "ether", "hipotion", "firebomb"])
		run.items[it] = int(run.items.get(it, 0)) + 1
		var g = ri(5, 10) * (run.floor + 1)
		run.gold += g
		msg = "Found a %s and %d G!" % [c(BL, D.ITEMS[it].name), g]
	UI.refresh()
	await UI.say(msg)
	await check_feats()

func act_camp(r) -> void:
	r.used = true
	Snd.sfx("heal")
	for h in run.party:
		var s = stats(h)
		if h.hp <= 0: h.hp = roundi(s.hp * 0.25)
		else: h.hp = mini(s.hp, h.hp + roundi(s.hp * 0.5))
		h.mp = mini(s.mp, h.mp + roundi(s.mp * 0.5))
	world.build_room(run)
	UI.refresh()
	await UI.say("The party rests. HP and MP restored by half; the fallen get back up.")

func act_fountain(r) -> void:
	r.used = true
	world.build_room(run)
	if rf() < 0.7:
		Snd.sfx("heal")
		for h in run.party:
			var s = stats(h)
			if h.hp > 0: h.hp = s.hp
			h.mp = s.mp
		UI.refresh()
		await UI.say("The water is pure. The party is fully restored!")
	else:
		run.keys += 1
		Snd.sfx("coin")
		UI.refresh()
		await UI.say("Something glints at the bottom: a %s!" % c(Y, "Key"))

func act_altar(r) -> void:
	if not await UI.confirm("Offer %s (for this run) in exchange for a relic?" % c(RD, "15% of max HP")):
		return
	r.used = true
	world.build_room(run)
	Snd.sfx("die")
	run.hp_mult *= 0.85
	for h in run.party:
		h.hp = mini(h.hp, stats(h).hp)
	UI.refresh()
	await choose_relic(2, "The altar offers...")

func act_cell(r) -> void:
	r.used = true
	if not Meta.unlocked.get("doran", false):
		await UI.say("You pry the cage open. \"Finally! The name's %s. Point me at something and I'll set it on fire.\"" % c(Y, "Doran"))
		world.build_room(run)
		await grant("cell")
	else:
		world.build_room(run)
		await UI.say("The cage is empty, but a relic lies in the straw.")
		await choose_relic(1, "Found in the cell")

func act_shop(r) -> void:
	if not r.has("stock"):
		var st = [{"k": "item", "id": "potion"}, {"k": "item", "id": "ether"}, {"k": "item", "id": "hipotion" if run.floor > 0 else "firebomb"}, {"k": "item", "id": "ember"}, {"k": "key", "p": 25}]
		for id in shuffled(relic_pool()).slice(0, 2):
			st.append({"k": "relic", "id": id, "p": 75 + run.floor * 20})
		r["stock"] = st
	var idx = 0
	while true:
		var items = []
		for i in r.stock.size():
			var s = r.stock[i]
			var label = ""
			var p = 0
			var desc = ""
			if s.k == "item":
				label = D.ITEMS[s.id].name
				p = price(D.ITEMS[s.id].price)
				desc = D.ITEMS[s.id].desc + " (have %d)" % int(run.items.get(s.id, 0))
			elif s.k == "key":
				label = "Key"
				p = price(s.p)
				desc = "Opens sealed doors."
			else:
				label = c(PU, D.RELICS[s.id].name)
				p = price(s.p)
				desc = D.RELICS[s.id].desc
			var sold = s.get("sold", false)
			items.append({"label": c(DIM, "— sold —") if sold else label, "right": "" if sold else "%d G" % p, "disabled": sold, "value": i, "desc": desc, "p": p})
		if not Meta.unlocked.get("pip", false):
			items.append({"label": c(Y, "Pay the kid's debt"), "right": "99 G", "value": "pip", "desc": "\"Please, mister. He says I owe him. I'll come with you if you pay!\"", "p": 99})
		var v = await UI.choose({"title": "Shop · %d G" % run.gold, "x": 32, "y": 50, "w": 587, "rows": 9, "idx": idx, "items": items,
			"on_hover": func(it): UI.set_info("%s\n%s" % [c(Y, "Merchant"), it.desc], INFO_R)})
		if v == null:
			return
		for i in items.size():
			if typeof(items[i].value) == typeof(v) and items[i].value == v: idx = i
		var it = items[idx]
		if run.gold < it.p:
			Snd.sfx("err")
			await UI.say("Not enough gold.")
			continue
		run.gold -= it.p
		Snd.sfx("coin")
		UI.refresh()
		if v is String and v == "pip":
			await UI.say("The merchant pockets the gold. The kid grins: \"Name's %s. Your pockets are safe... probably.\"" % c(Y, "Pip"))
			await grant("debt")
			world.build_room(run)
			continue
		var s = r.stock[v]
		if s.k == "item":
			run.items[s.id] = int(run.items.get(s.id, 0)) + 1
		elif s.k == "key":
			run.keys += 1
			s["sold"] = true
		else:
			gain_relic(s.id)
			s["sold"] = true
			await UI.say("Obtained %s!" % c(PU, D.RELICS[s.id].name))
		UI.refresh()

func pause_menu() -> void:
	if busy or not UI.menus.is_empty() or run == null:
		return
	busy = true
	var idx = 0
	while true:
		var v = await UI.choose({"title": "Menu", "x": 427, "y": 120, "w": 426, "idx": idx, "items": [
			{"label": "Party", "value": 0}, {"label": "Relics", "value": 1}, {"label": "Items", "value": 2}, {"label": "Abandon run", "value": 3},
			sound_item(), screen_item(), {"label": "Close", "value": 4}]})
		if v == null or (v is int and v == 4):
			break
		if v is String:
			if v == "snd":
				Snd.set_muted(not Meta.muted)
				idx = 4
			else:
				UI.toggle_fullscreen()
				idx = 5
			continue
		idx = v
		if v == 0:
			var txt = ""
			for h in run.party:
				var s = stats(h)
				txt += "[img=44]res://assets/sprites/hero_%s.png[/img] %s Lv%d %s\n   HP %d/%d  MP %d/%d · STR %d MAG %d DEF %d AGI %d\n" % [h.id, c(Y, nm(h)), h.lv, c(DIM, "EXP %d/%d" % [h.xp, xp_need(h.lv)]), h.hp, s.hp, h.mp, s.mp, s.str, s.mag, s.def, s.agi]
			await UI.say(txt.strip_edges(), {"x": 160, "y": 40, "w": 960})
		elif v == 1:
			if run.relics.is_empty():
				await UI.say("No relics yet. Find them in reliquaries, shops and altars.")
			else:
				var items = []
				for id in run.relics:
					items.append({"label": D.RELICS[id].name, "id": id, "value": id})
				await UI.choose({"title": "Relics", "x": 32, "y": 50, "w": 560, "rows": 10, "items": items, "on_hover": func(it): UI.set_info("%s\n%s" % [c(Y, D.RELICS[it.id].name), D.RELICS[it.id].desc], INFO_R)})
		elif v == 2:
			await item_menu_field()
		elif v == 3:
			if await UI.confirm("Abandon this run? You keep earned Soul Shards."):
				busy = false
				await end_run(false)
				return
	busy = false
	UI.refresh()

func item_menu_field() -> void:
	while true:
		var ids = []
		for i in D.ITEM_ORDER:
			if int(run.items.get(i, 0)) > 0 and not D.ITEMS[i].get("battle", false):
				ids.append(i)
		if ids.is_empty():
			await UI.say("No usable items.")
			return
		var items = []
		for i in ids:
			items.append({"label": D.ITEMS[i].name, "right": "×%d" % run.items[i], "value": i, "id": i})
		var id = await UI.choose({"title": "Items", "x": 32, "y": 80, "w": 506, "items": items, "on_hover": func(it): UI.set_info(D.ITEMS[it.id].desc, INFO_R)})
		if id == null:
			return
		var t = await Bt.pick_target(D.ITEMS[id].tgt, null, {"x": 560, "y": 160, "w": 440})
		if t == null:
			continue
		var m = Bt.apply_item(id, t)
		UI.refresh()
		await UI.say(m)
