extends Node
## Turn-based battle engine (FF-style): pick commands for the party, then everyone acts by agility.

var active := false
var enemies: Array = []
var boss := false
var round_n := 0
var acting = null
var msg := ""
var defending: Array = []

func c(col: String, s) -> String:
	return UI.c(col, s)

func w() -> Node:
	return G.world

func set_msg(m: String) -> void:
	msg = m
	UI.refresh()

func make_enemy(k: String, n: int) -> Dictionary:
	var d = D.EN[k]
	var hp_m = (0.55 + 0.45 * n) if d.get("boss", false) else (0.85 + 0.15 * n)
	var e = d.duplicate(true)
	e["key"] = k
	e["scale"] = d.get("scale", 2)
	e["acts"] = d.get("acts", [["atk", 1]]).duplicate(true)
	e["maxhp"] = roundi(d.hp * hp_m)
	e["hp"] = e.maxhp
	e["atk"] = d.atk * ((1 + 0.04 * (n - 1)) if d.get("boss", false) else 1.0)
	e["dead"] = false
	e["poison"] = 0
	e["stolen"] = false
	e["weak"] = d.get("weak", [])
	e["resist"] = d.get("resist", [])
	return e

func battle(keys: Array, opt: Dictionary):
	G.busy = true
	Snd.sfx("enc")
	for i in 3:
		UI.set_fade(0.8)
		await G.wait(0.06)
		UI.set_fade(0.0)
		await G.wait(0.06)
	await UI.fade(1.0, 0.18)
	var n = G.run.party.size()
	enemies = []
	for k in keys:
		enemies.append(make_enemy(k, n))
	var cnt = {}
	for e in enemies:
		cnt[e.name] = int(cnt.get(e.name, 0)) + 1
	var seen = {}
	for e in enemies:
		if cnt[e.name] > 1:
			seen[e.name] = int(seen.get(e.name, 0)) + 1
			e["label"] = e.name + " " + "ABCD"[seen[e.name] - 1]
		else:
			e["label"] = e.name
	boss = opt.get("boss", false)
	round_n = 0
	acting = null
	msg = ""
	defending = []
	active = true
	G.mode = "battle"
	Snd.play_song("boss" if boss else "battle")
	w().build_battle(G.run.floor, enemies, G.run.party)
	UI.refresh()
	await UI.fade(0.0, 0.22)
	var result = ""
	while true:
		round_n += 1
		if round_n > 1:
			if G.has_relic("etherleaf"):
				for h in G.run.party:
					if h.hp > 0: h.mp = mini(G.stats(h).mp, h.mp + 2)
			if G.has_relic("halo"):
				for h in G.run.party:
					if h.hp > 0: h.hp = mini(G.stats(h).hp, h.hp + roundi(G.stats(h).hp * 0.05))
			UI.refresh()
		w().refresh_poses(G.run.party)
		var cmds = await input_phase()
		var order = []
		if typeof(cmds) == TYPE_STRING and cmds == "flee":
			var pip_alive = false
			for h in G.run.party:
				if h.id == "pip" and h.hp > 0: pip_alive = true
			var ok = G.has_relic("smokebomb") or G.rf() < 0.55 + (0.2 if pip_alive else 0.0)
			set_msg("Escaped!" if ok else "Couldn't escape!")
			await G.wait(0.7)
			set_msg("")
			if ok:
				result = "fled"
				break
			for e in enemies:
				if not e.dead: order.append({"u": e, "hero": false})
		else:
			for pair in cmds:
				var h = pair[0]
				var cmd = pair[1]
				if cmd.type == "def":
					defending.append(h)
					w().set_defend(h, true)
				order.append({"u": h, "hero": true, "c": cmd, "i": G.stats(h).agi * (0.75 + G.rf() * 0.5) + (999 if G.has_relic("smokebomb") and round_n == 1 else 0)})
			for e in enemies:
				if not e.dead: order.append({"u": e, "hero": false, "i": e.agi * (0.75 + G.rf() * 0.5)})
			order.sort_custom(func(a, b): return a.i > b.i)
		for o in order:
			if check_end() != "": break
			if o.hero:
				if o.u.hp <= 0: continue
				await hero_act(o.u, o.c)
			else:
				if o.u.dead: continue
				await enemy_act(o.u)
		for h in defending:
			w().set_defend(h, false)
		defending = []
		result = check_end()
		if result != "": break
		for e in enemies:
			if not e.dead and e.poison > 0:
				e.poison -= 1
				damage_enemy(e, maxi(1, roundi(e.maxhp * 0.08)), Color("#b060ff"))
				await G.wait(0.35)
		result = check_end()
		if result != "": break
	if result == "win":
		await G.wait(0.5)
		await victory()
	if result == "lose":
		Snd.jingle("lose")
		await G.wait(0.5)
		await UI.say("Your party has fallen...")
	active = false
	for h in G.run.party:
		h.erase("node")
		h.erase("home")
	if result != "lose":
		await UI.fade(1.0, 0.22)
		G.mode = "dungeon"
		w().build_room(G.run)
		Snd.play_song("dungeon%d" % G.run.floor)
		UI.refresh()
		await UI.fade(0.0, 0.22)
	return result

func check_end() -> String:
	var all_dead = true
	for e in enemies:
		if not e.dead: all_dead = false
	if all_dead: return "win"
	for h in G.run.party:
		if h.hp > 0: return ""
	return "lose"

# ---------------- input ----------------
func input_phase():
	var alive = []
	for h in G.run.party:
		if h.hp > 0: alive.append(h)
	var cmds = {}
	var i = 0
	while i < alive.size():
		var h = alive[i]
		acting = h
		w().step(h, true)
		UI.refresh()
		var cmd = await command_menu(h, i > 0)
		w().step(h, false)
		if typeof(cmd) == TYPE_STRING and cmd == "back":
			i = maxi(0, i - 1)
			continue
		if typeof(cmd) == TYPE_STRING and cmd == "flee":
			acting = null
			return "flee"
		cmds[i] = [h, cmd]
		i += 1
	acting = null
	UI.refresh()
	var out = []
	for k in range(alive.size()):
		out.append(cmds[k])
	return out

func usable_items() -> Array:
	var l = []
	for i in D.ITEM_ORDER:
		if int(G.run.items.get(i, 0)) > 0: l.append(i)
	return l

func any_dead() -> bool:
	for x in G.run.party:
		if x.hp <= 0: return true
	return false

func command_menu(h: Dictionary, can_back: bool):
	while true:
		var sk = []
		for s in D.CHARS[h.id].skills:
			if D.SK[s].lv <= h.lv: sk.append(s)
		var v = await UI.choose({"title": G.nm(h), "x": 16, "y": 400, "w": 416, "cancel": can_back, "rows": 5, "items": [
			{"label": "Attack", "value": "atk"}, {"label": "Skills", "value": "skill", "disabled": sk.is_empty()},
			{"label": "Items", "value": "item", "disabled": usable_items().is_empty()}, {"label": "Defend", "value": "def"},
			{"label": "Flee", "value": "flee", "disabled": boss}]})
		if v == null: return "back"
		if v == "def": return {"type": "def"}
		if v == "flee": return "flee"
		if v == "atk":
			var t = await pick_target("enemy", h)
			if t != null: return {"type": "atk", "t": t}
			continue
		if v == "skill":
			var items = []
			for s in sk:
				var cst = G.skill_cost(h, s)
				items.append({"label": D.SK[s].name, "right": "%d MP" % cst, "value": s, "disabled": h.mp < cst or (D.SK[s].tgt == "deadAlly" and not any_dead())})
			var id = await UI.choose({"title": "Skills · %d MP" % h.mp, "x": 16, "y": 220, "w": 533, "rows": 6, "items": items,
				"on_hover": func(it): UI.set_info("[center]%s[/center]" % D.SK[it.value].desc, Rect2(307, 12, 667, 0))})
			if id == null: continue
			var t = await pick_target(D.SK[id].tgt, h)
			if t == null: continue
			return {"type": "skill", "id": id, "t": t}
		if v == "item":
			var items = []
			for i in usable_items():
				items.append({"label": D.ITEMS[i].name, "right": "×%d" % G.run.items[i], "value": i, "disabled": D.ITEMS[i].tgt == "deadAlly" and not any_dead()})
			var id = await UI.choose({"title": "Items", "x": 16, "y": 220, "w": 533, "rows": 6, "items": items,
				"on_hover": func(it): UI.set_info("[center]%s[/center]" % D.ITEMS[it.value].desc, Rect2(307, 12, 667, 0))})
			if id == null: continue
			var t = await pick_target(D.ITEMS[id].tgt, h)
			if t == null: continue
			return {"type": "item", "id": id, "t": t}
	return "back"

func pick_target(kind: String, h, pos: Dictionary = {}):
	if kind == "self": return h
	if kind == "allEnemies" or kind == "allAllies": return "all"
	var list = []
	if kind == "enemy":
		for e in enemies:
			if not e.dead: list.append(e)
	elif kind == "ally":
		for x in G.run.party:
			if x.hp > 0: list.append(x)
	else:
		for x in G.run.party:
			if x.hp <= 0: list.append(x)
	if list.is_empty(): return null
	var idx = 0
	if kind == "ally":
		var lo = 2.0
		for i in list.size():
			var r = float(list[i].hp) / G.stats(list[i]).hp
			if r < lo:
				lo = r
				idx = i
	var items = []
	for u in list:
		var right = "" if kind == "enemy" else "%d/%d" % [u.hp, G.stats(u).hp]
		items.append({"label": u.get("label", G.nm(u) if u.has("id") else ""), "right": right, "value": u})
	var spec = {"title": "Target", "x": 16, "y": 440, "w": 416, "rows": 4, "idx": idx, "items": items,
		"on_hover": func(it): _hover_target(it)}
	spec.merge(pos, true)
	var v = await UI.choose(spec)
	w().set_cursor(null)
	return v

func _hover_target(it) -> void:
	if active:
		w().set_cursor(it.value)

# ---------------- actions ----------------
func live_enemy(t):
	if t is Dictionary and not t.get("dead", true): return t
	for e in enemies:
		if not e.dead: return e
	return null

func damage_enemy(e: Dictionary, d: int, col: Color = Color.WHITE) -> void:
	if e.dead: return
	e.hp -= d
	w().flash(e)
	w().popup(w().center_of(e), str(d), col)
	if e.hp <= 0:
		e.hp = 0
		e.dead = true
		G.run.kills += 1
		Meta.stat_add("kills")
		w().kill(e)
	UI.refresh()

func heal_hero(h: Dictionary, amt: float) -> int:
	var s = G.stats(h)
	var b = h.hp
	h.hp = mini(s.hp, h.hp + roundi(amt))
	if active and h.hp > 0:
		w().set_pose(h, w().idle_pose(h))
	return h.hp - b

func hurt_hero(h: Dictionary, d: int) -> void:
	h.hp = maxi(0, h.hp - d)
	if h.hp > 0:
		w().pose_for(h, "hurt", 0.35)
	w().shake(h)
	w().flash(h)
	w().popup(w().center_of(h), str(d))
	if h.hp <= 0:
		if G.has_relic("fairy") and not G.run.fairy_used:
			G.run.fairy_used = true
			h.hp = roundi(G.stats(h).hp * 0.3)
			w().popup(w().center_of(h) + Vector3(0, 0.4, 0), "FAIRY", Color("#ffa0e0"))
			w().sparkle(w().center_of(h), Color("#ffa0e0"))
			Snd.sfx("heal")
		else:
			Snd.sfx("die")
			w().set_dead_pose(h, true)
	UI.refresh()

func phys_hit(h: Dictionary, t: Dictionary, pw: float) -> void:
	var s = G.stats(h)
	var d = (s.str * 2.2 * pw - t.def) * (0.9 + G.rf() * 0.2) * G.out_mult(h, "phys")
	var crit = G.rf() < G.crit_chance(h)
	if crit: d *= 2.5 if G.has_relic("loadeddice") else 1.6
	var di = maxi(1, roundi(d))
	w().set_pose(h, "atk1")
	await G.wait(0.12)
	w().pose_for(h, "atk2", 0.3)
	w().slash(w().center_of(t), Color("#ffe94a") if crit else Color.WHITE)
	Snd.sfx("crit" if crit else "hit")
	await G.wait(0.13)
	damage_enemy(t, di, Color("#ffe94a") if crit else Color.WHITE)
	if crit: w().popup(w().center_of(t) + Vector3(0, 0.45, 0), "CRIT", Color("#ffe94a"), 28)
	if G.has_relic("vampfang"):
		var a = heal_hero(h, di * 0.15)
		if a > 0: w().popup(w().center_of(h), str(a), Color("#7dffa0"))
	if G.has_relic("glove") and G.rf() < 0.2:
		var g = G.ri(2, 6) * (G.run.floor + 1)
		G.run.gold += g
		w().popup(w().center_of(t) + Vector3(0, 0.6, 0), "+%dG" % g, Color(UI.Y), 28)
	UI.refresh()
	await G.wait(0.33)

func steal(_h: Dictionary, t: Dictionary) -> void:
	var p = w().center_of(t)
	w().pose_for(_h, "atk2", 0.4)
	if t.stolen:
		w().popup(p, "EMPTY", Color("#aaaaaa"), 28)
		await G.wait(0.5)
		return
	if not (G.has_relic("glove") or G.rf() < 0.6):
		w().popup(p, "MISS", Color("#aaaaaa"), 28)
		await G.wait(0.5)
		return
	t.stolen = true
	Snd.sfx("coin")
	if G.rf() < 0.6:
		var g = roundi(G.ri(8, 18) * (G.run.floor + 1) * G.gold_mult())
		G.run.gold += g
		w().popup(p, "+%dG" % g, Color(UI.Y), 32)
		set_msg("Stole %d G!" % g)
	else:
		var it = G.pick(["potion", "potion", "ether", "hipotion"])
		G.run.items[it] = int(G.run.items.get(it, 0)) + 1
		w().popup(p, D.ITEMS[it].name, Color(UI.BL), 26)
		set_msg("Stole a %s!" % D.ITEMS[it].name)
	await G.wait(0.7)

func hero_act(h: Dictionary, cmd: Dictionary) -> void:
	acting = h
	w().step(h, true)
	UI.refresh()
	await G.wait(0.15)
	if cmd.type == "atk":
		var t = live_enemy(cmd.t)
		if t != null:
			await phys_hit(h, t, 1.0)
			if G.has_relic("echobell") and G.rf() < 0.2 and not t.dead:
				set_msg("Echo!")
				await phys_hit(h, t, 1.0)
	elif cmd.type == "skill":
		await use_skill(h, cmd.id, cmd.t)
	elif cmd.type == "item":
		if int(G.run.items.get(cmd.id, 0)) <= 0:
			set_msg("None left!")
			await G.wait(0.5)
		else:
			set_msg(D.ITEMS[cmd.id].name)
			if cmd.id == "firebomb":
				G.run.items.firebomb -= 1
				Snd.sfx("magic")
				var live = []
				for e in enemies:
					if not e.dead: live.append(e)
				for e in live: w().burst(w().center_of(e), D.ELC.fire)
				await G.wait(0.3)
				for e in live:
					damage_enemy(e, roundi((40 + 35 * G.run.floor) * (2 if "fire" in e.weak else 1)), D.ELC.fire)
			else:
				w().pose_for(h, "cast", 0.6)
				var t = cmd.t
				if D.ITEMS[cmd.id].tgt == "ally" and t.hp <= 0:
					for x in G.run.party:
						if x.hp > 0:
							t = x
							break
				apply_item(cmd.id, t)
				w().sparkle(w().center_of(t), Color("#7dffa0"))
				Snd.sfx("heal")
			await G.wait(0.5)
	w().step(h, false)
	acting = null
	set_msg("")
	await G.wait(0.12)

func apply_item(id: String, t: Dictionary) -> String:
	var s = G.stats(t)
	var m = ""
	if id == "ember":
		if t.hp > 0: return "No effect."
		t.hp = roundi(s.hp * 0.5)
		m = "%s is revived!" % G.nm(t)
		if active: w().set_dead_pose(t, false)
	else:
		if t.hp <= 0: return "No effect on the fallen."
		if id == "potion" or id == "hipotion":
			var a = heal_hero(t, 60 if id == "potion" else 180)
			if active: w().popup(w().center_of(t), str(a), Color("#7dffa0"))
			m = "%s recovers %d HP." % [G.nm(t), a]
		elif id == "ether":
			var b = t.mp
			t.mp = mini(s.mp, t.mp + 30)
			if active: w().popup(w().center_of(t), str(t.mp - b), Color(UI.BL))
			m = "%s recovers %d MP." % [G.nm(t), t.mp - b]
	G.run.items[id] = int(G.run.items[id]) - 1
	UI.refresh()
	return m

func use_skill(h: Dictionary, id: String, tg) -> void:
	var S = D.SK[id]
	var cst = G.skill_cost(h, id)
	if h.mp < cst:
		set_msg("Not enough MP!")
		await G.wait(0.5)
		return
	h.mp -= cst
	set_msg(S.name)
	var s = G.stats(h)
	match S.type:
		"phys":
			var ts = []
			if S.tgt == "allEnemies":
				for e in enemies:
					if not e.dead: ts.append(e)
			else:
				var t = live_enemy(tg)
				if t != null: ts.append(t)
			for t in ts:
				for k in int(S.get("hits", 1)):
					if t.dead: break
					await phys_hit(h, t, S.pow)
			if S.get("poison", false) and ts.size() > 0 and not ts[0].dead:
				ts[0].poison = 3
				w().popup(w().center_of(ts[0]) + Vector3(0, 0.45, 0), "POISON", Color("#b060ff"), 26)
			if S.get("steal", false) and ts.size() > 0 and not ts[0].dead:
				await steal(h, ts[0])
		"magic":
			var ts = []
			if S.tgt == "allEnemies":
				for e in enemies:
					if not e.dead: ts.append(e)
			else:
				var t = live_enemy(tg)
				if t != null: ts.append(t)
			w().pose_for(h, "cast", 0.9)
			Snd.sfx("magic")
			for t in ts: w().burst(w().center_of(t), D.ELC[S.el])
			await G.wait(0.38)
			for t in ts:
				var d = S.pow * s.mag / 5.0 * (0.92 + G.rf() * 0.16) * G.out_mult(h, "magic") - t.mdef
				var tag = ""
				if S.el in t.weak:
					d *= 2
					tag = "WEAK"
				elif S.el in t.resist:
					d *= 0.5
					tag = "RESIST"
				damage_enemy(t, maxi(1, roundi(d)), D.ELC[S.el])
				if tag != "":
					w().popup(w().center_of(t) + Vector3(0, 0.45, 0), tag, Color("#ffe94a") if tag == "WEAK" else Color("#aaaaaa"), 26)
			await G.wait(0.45)
		"heal", "healPct":
			var ts = []
			if S.tgt == "allAllies":
				for x in G.run.party:
					if x.hp > 0: ts.append(x)
			elif S.tgt == "self":
				ts = [h]
			else:
				var t = tg
				if t.hp <= 0:
					for x in G.run.party:
						if x.hp > 0:
							t = x
							break
				ts = [t]
			w().pose_for(h, "cast", 0.8)
			Snd.sfx("heal")
			for t in ts:
				var amt = G.stats(t).hp * S.pow if S.type == "healPct" else S.pow * s.mag / 5.0 * (0.92 + G.rf() * 0.16) * (1.4 if G.has_relic("rosary") else 1.0)
				var a = heal_hero(t, amt)
				w().sparkle(w().center_of(t), Color("#7dffa0"))
				w().popup(w().center_of(t), str(a), Color("#7dffa0"))
			UI.refresh()
			await G.wait(0.55)
		"revive":
			var t = tg
			if t.hp > 0:
				set_msg("No effect.")
			else:
				w().pose_for(h, "cast", 0.8)
				t.hp = roundi(G.stats(t).hp * S.pow)
				w().set_dead_pose(t, false)
				w().sparkle(w().center_of(t), Color("#fff6c0"))
				Snd.sfx("heal")
			UI.refresh()
			await G.wait(0.6)
		"steal":
			var t = live_enemy(tg)
			if t != null: await steal(h, t)

func weighted(acts: Array) -> String:
	var tot = 0.0
	for a in acts: tot += a[1]
	var r = G.rf() * tot
	for a in acts:
		r -= a[1]
		if r <= 0: return a[0]
	return acts[0][0]

func enemy_act(e: Dictionary) -> void:
	if e.key == "wyrm" and not e.get("enraged", false) and e.hp < e.maxhp / 2:
		e["enraged"] = true
		e.acts.append(["nova", 2])
		set_msg("The Wyrm's shadow swells with rage!")
		w().burst(w().center_of(e), Color("#ff40a0"), 40)
		await G.wait(1.0)
	var S = D.ESK[weighted(e.acts)]
	w().flash(e, 2)
	set_msg(S.get("name", ""))
	await G.wait(0.38)
	var alive = []
	for h in G.run.party:
		if h.hp > 0: alive.append(h)
	if alive.is_empty(): return
	var ts = alive if S.get("all", false) else [G.pick(alive)]
	for t in ts:
		if S.has("color"): w().burst(w().center_of(t), Color(S.color), 18)
		else: w().slash(w().center_of(t), Color("#ff6060"))
	Snd.sfx("magic" if S.has("color") else "hit")
	await G.wait(0.17)
	for t in ts:
		var s = G.stats(t)
		var d = (e.atk * 2 * S.pow - s.def) if S.kind == "phys" else (S.pow - s.mdef * 0.5)
		d *= 0.9 + G.rf() * 0.2
		if t in defending: d *= 0.5
		if G.has_relic("ironcharm"): d *= 0.85
		var di = maxi(1, roundi(d))
		hurt_hero(t, di)
		if S.kind == "phys" and G.has_relic("thornmail"):
			damage_enemy(e, maxi(1, roundi(di * 0.25)), Color("#ffb0b0"))
		if S.get("drain", false):
			e.hp = mini(e.maxhp, e.hp + di)
			w().popup(w().center_of(e), str(di), Color("#7dffa0"))
	await G.wait(0.48)
	set_msg("")

func victory() -> void:
	Snd.jingle("win")
	w().victory_dance(G.run.party)
	var alive = []
	for h in G.run.party:
		if h.hp > 0: alive.append(h)
	var xp = 0
	var gold = 0
	for e in enemies:
		xp += int(e.xp)
		gold += int(e.gold)
	xp = roundi(xp * (1 + 0.2 * Meta.upr("xp")))
	gold = roundi(gold * (0.8 + G.rf() * 0.4) * G.gold_mult())
	G.run.gold += gold
	var lines = ["%s  +%d EXP  ·  +%d G" % [c(UI.Y, "Victory!"), xp, gold]]
	for h in alive:
		h.xp += xp
		while h.xp >= G.xp_need(h.lv):
			h.xp -= G.xp_need(h.lv)
			var b = G.stats(h)
			h.lv += 1
			var a = G.stats(h)
			h.hp += a.hp - b.hp
			h.mp += a.mp - b.mp
			lines.append("%s reached %s!" % [G.nm(h), c(UI.GR, "Lv %d" % h.lv)])
			for s in D.CHARS[h.id].skills:
				if D.SK[s].lv == h.lv:
					lines.append("%s learned %s!" % [G.nm(h), c(UI.BL, D.SK[s].name)])
	if G.rf() < 0.22:
		var it = G.pick(["potion", "potion", "ether", "firebomb"])
		G.run.items[it] = int(G.run.items.get(it, 0)) + 1
		lines.append("Found a %s." % c(UI.BL, D.ITEMS[it].name))
	if G.rf() < 0.08:
		G.run.keys += 1
		lines.append("Found a %s!" % c(UI.Y, "Key"))
	if G.has_relic("coal"):
		for h in G.run.party:
			if h.hp > 0: heal_hero(h, G.stats(h).hp * 0.15)
	if G.has_relic("gravemoss"):
		for h in G.run.party:
			if h.hp <= 0:
				h.hp = 1
				lines.append("%s stirs back to life." % G.nm(h))
	UI.refresh()
	await UI.say("\n".join(lines.slice(0, 8)), {"x": 200, "y": 150, "w": 880})
	await G.check_feats()
