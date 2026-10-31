extends CanvasLayer
## UI layer: FF-style windows, async menus (choose/say/confirm), HUD panels, minimap, fades.

const Y = "#ffe680"
const GR = "#7dffa0"
const BL = "#8ec5ff"
const RD = "#ff8a8a"
const DIM = "#9aa3d8"
const PU = "#e0a8ff"

var root: Control
var vignette: ColorRect
var panel_box: Control
var info_box: Control
var menu_box: Control
var fade_rect: ColorRect
var card_box: Control
var minimap: Control
var menus: Array = []
var font_body: FontFile
var font_head: FontFile
var win_style: StyleBoxTexture
var ui_theme: Theme

static func c(col: String, s) -> String:
	return "[color=%s]%s[/color]" % [col, str(s)]

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	font_body = load("res://assets/fonts/VT323-Regular.ttf")
	font_head = load("res://assets/fonts/PressStart2P-Regular.ttf")
	for f in [font_body, font_head]:
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.hinting = TextServer.HINTING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	win_style = StyleBoxTexture.new()
	win_style.texture = load("res://assets/ui/window.png")
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		win_style.set_texture_margin(s, 11)
	win_style.content_margin_left = 18
	win_style.content_margin_right = 18
	win_style.content_margin_top = 10
	win_style.content_margin_bottom = 10
	ui_theme = Theme.new()
	ui_theme.default_font = font_body
	ui_theme.default_font_size = 30
	for t in ["Label", "RichTextLabel"]:
		ui_theme.set_color("font_shadow_color", t, Color(0, 0, 0, 0.75))
		ui_theme.set_constant("shadow_offset_x", t, 2)
		ui_theme.set_constant("shadow_offset_y", t, 2)
	ui_theme.set_color("font_color", "Label", Color.WHITE)
	ui_theme.set_color("default_color", "RichTextLabel", Color.WHITE)
	ui_theme.set_constant("line_separation", "RichTextLabel", -6)
	ui_theme.set_constant("line_spacing", "Label", -6)

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ui_theme
	add_child(root)
	vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new()
	sh.code = "shader_type canvas_item;\nvoid fragment(){ vec2 d = (UV - 0.5) * vec2(1.25, 1.0); float v = smoothstep(0.32, 0.86, length(d)); COLOR = vec4(0.0, 0.0, 0.02, v * 0.62); }"
	var sm = ShaderMaterial.new()
	sm.shader = sh
	vignette.material = sm
	root.add_child(vignette)
	minimap = MiniMap.new()
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(minimap)
	panel_box = _layer_ctl()
	info_box = _layer_ctl()
	menu_box = _layer_ctl()
	card_box = _layer_ctl()
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade_rect)

func _layer_ctl() -> Control:
	var ctl = Control.new()
	ctl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ctl)
	return ctl

func _setup_input() -> void:
	var add_key = func(action: String, keys: Array):
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys:
			var e = InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
	add_key.call("ui_accept", [KEY_Z])
	add_key.call("ui_cancel", [KEY_X, KEY_BACKSPACE])
	add_key.call("ui_up", [KEY_W])
	add_key.call("ui_down", [KEY_S])
	add_key.call("ui_left", [KEY_A])
	add_key.call("ui_right", [KEY_D])
	add_key.call("mute", [KEY_M])
	add_key.call("fullscreen", [KEY_F11])
	var jb = InputEventJoypadButton.new()
	jb.button_index = JOY_BUTTON_START
	InputMap.action_add_event("ui_cancel", jb)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		Snd.set_muted(not Meta.muted)
		refresh()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if menus.is_empty():
		return
	if menus.back().handle(event):
		get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	Meta.fullscreen = not Meta.fullscreen
	Meta.save_meta()
	apply_window_mode()

func apply_window_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if Meta.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

# ---------------- building blocks ----------------
func rt(bb: String, size: int = 30) -> RichTextLabel:
	var r = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if size != 30:
		r.add_theme_font_size_override("normal_font_size", size)
	r.text = bb
	return r

func head_label(t: String, size: int = 13) -> Label:
	var l = Label.new()
	l.text = t
	l.add_theme_font_override("font", font_head)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(Y))
	return l

func make_win(rect: Rect2, bb: String = "", title: String = "") -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", win_style)
	p.position = rect.position
	p.custom_minimum_size = rect.size
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	if title != "":
		v.add_child(head_label(title))
	if bb != "":
		v.add_child(rt(bb))
	return p

func box(p: PanelContainer) -> VBoxContainer:
	return p.get_child(0)

# ---------------- menus ----------------
func choose(spec: Dictionary):
	var m = Menu.new()
	m.setup(spec)
	menu_box.add_child(m)
	menus.append(m)
	_rerender_menus()
	m.hovered()
	var v = await m.done
	menus.erase(m)
	m.queue_free()
	clear_info()
	if G.world:
		G.world.set_cursor(null)
	_rerender_menus()
	return v

func say(bb: String, opts: Dictionary = {}):
	var spec = {"kind": "msg", "text": bb, "x": opts.get("x", 160), "y": opts.get("y", 200), "w": opts.get("w", 960), "items": []}
	return await choose(spec)

func confirm(q: String, opts: Dictionary = {}) -> bool:
	var spec = {"head": q, "x": opts.get("x", 373), "y": opts.get("y", 227), "w": opts.get("w", 533), "idx": 0,
		"items": [{"label": "Yes", "value": "y"}, {"label": "No", "value": "n"}]}
	var v = await choose(spec)
	return v == "y"

func _rerender_menus() -> void:
	for m in menus:
		m.active = (m == menus.back())
		m.render()

func set_info(bb: String, rect: Rect2 = Rect2(667, 173, 597, 0)) -> void:
	clear_info()
	info_box.add_child(make_win(rect, bb))

func clear_info() -> void:
	for ch in info_box.get_children():
		ch.queue_free()

# ---------------- fades & cards ----------------
func fade(to: float, dur: float = 0.25) -> void:
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", to, dur)
	await tw.finished

func set_fade(a: float) -> void:
	fade_rect.color.a = a

func show_card(a: String, b: String) -> void:
	for ch in card_box.get_children():
		ch.queue_free()
	if a == "":
		return
	var v = VBoxContainer.new()
	v.position = Vector2(0, 280)
	v.custom_minimum_size = Vector2(1280, 0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var l1 = head_label(a, 44)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_constant_override("outline_size", 10)
	l1.add_theme_color_override("font_outline_color", Color.BLACK)
	var l2 = Label.new()
	l2.text = b
	l2.add_theme_font_size_override("font_size", 46)
	l2.add_theme_color_override("font_color", Color("#cfd6ff"))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l1)
	v.add_child(l2)
	card_box.add_child(v)

# ---------------- panels per mode ----------------
func refresh() -> void:
	for ch in panel_box.get_children():
		ch.queue_free()
	var mode = G.mode
	vignette.visible = mode in ["dungeon", "battle", "camp", "title"]
	minimap.visible = mode == "dungeon" and G.card_on == false and G.run != null
	if mode == "title":
		var t = head_label("SHARDBOUND", 66)
		t.position = Vector2(0, 92)
		t.custom_minimum_size = Vector2(1280, 0)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_color_override("font_outline_color", Color("#5a1e00"))
		t.add_theme_constant_override("outline_size", 14)
		t.add_theme_color_override("font_shadow_color", Color.BLACK)
		t.add_theme_constant_override("shadow_offset_x", 8)
		t.add_theme_constant_override("shadow_offset_y", 8)
		panel_box.add_child(t)
		var s = Label.new()
		s.text = "a turn-based roguelite"
		s.add_theme_font_size_override("font_size", 38)
		s.add_theme_color_override("font_color", Color("#cfd6ff"))
		s.position = Vector2(0, 186)
		s.custom_minimum_size = Vector2(1280, 0)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel_box.add_child(s)
		var h = Label.new()
		h.text = "Arrows/WASD/D-pad  ·  Z/Enter/(A) confirm  ·  X/Esc/(B) back  ·  M mute  ·  F11 fullscreen"
		h.add_theme_font_size_override("font_size", 24)
		h.add_theme_color_override("font_color", Color("#6a6f9a"))
		h.position = Vector2(0, 684)
		h.custom_minimum_size = Vector2(1270, 0)
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel_box.add_child(h)
	elif mode == "camp":
		var rs = Meta.roster().size()
		panel_box.add_child(make_win(Rect2(16, 16, 420, 0), "Soul Shards %s\nHeroes %d/4 · Camp Tier %s" % [c(Y, "✦ %d" % Meta.shards), rs, ["I", "II", "III", "IV"][rs - 1]], "Camp"))
		panel_box.add_child(make_win(Rect2(800, 16, 464, 0), "Runs %d · Wins %d\nBest floor %d · Kills %d" % [Meta.st.runs, Meta.st.wins, Meta.st.best, Meta.st.kills], "Record"))
	elif mode == "dungeon" and G.run != null and not G.card_on:
		var run = G.run
		panel_box.add_child(make_win(Rect2(16, 16, 540, 0), "%s %s\nGold %s · Keys %s · Relics %s" % [c(Y, "F%d" % (run.floor + 1)), D.FLOORS[run.floor].name, c(Y, run.gold), c(Y, run.keys), c(PU, run.relics.size())]))
		var r = G.cur_room()
		if r != null:
			var R = D.ROOMS[r.type]
			var a = G.room_action_def(r)
			var w = make_win(Rect2(16, 539, 747, 165), G.room_text(r), R.name)
			var acts = rt("")
			var s2 = ""
			if a != null:
				s2 += "[url=room][bgcolor=#0d1350][ Z · %s ][/bgcolor][/url]   " % a.label
			s2 += "[url=menu][bgcolor=#0d1350][ X · Menu ][/bgcolor][/url]"
			if a == null:
				s2 += c(DIM, "   arrows/D-pad: move")
			acts.text = s2
			acts.meta_clicked.connect(func(m): G.ui_action(str(m)))
			box(w).add_child(acts)
			panel_box.add_child(w)
		panel_box.add_child(party_win(Rect2(779, 539, 485, 165)))
	elif mode == "battle" and Bt.active:
		if Bt.msg != "":
			var mw = make_win(Rect2(307, 12, 667, 0), "[center]%s[/center]" % Bt.msg)
			panel_box.add_child(mw)
		var groups = {}
		var order = []
		for e in Bt.enemies:
			if not e.dead:
				if not groups.has(e.name):
					groups[e.name] = 0
					order.append(e.name)
				groups[e.name] += 1
		var txt = ""
		for n in order:
			txt += n + (c(DIM, " ×%d" % groups[n]) if groups[n] > 1 else "") + "\n"
		panel_box.add_child(make_win(Rect2(16, 539, 416, 165), txt.strip_edges()))
		panel_box.add_child(party_win(Rect2(448, 539, 816, 165)))
	elif mode == "end":
		pass

func party_win(rect: Rect2) -> PanelContainer:
	var p = make_win(rect)
	var v = box(p)
	v.add_theme_constant_override("separation", 0)
	for h in G.run.party:
		var s = G.stats(h)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var dead = h.hp <= 0
		var act = Bt.active and Bt.acting == h
		var n = Label.new()
		n.text = D.CHARS[h.id].name
		n.custom_minimum_size.x = 92
		n.add_theme_color_override("font_color", Color(RD) if dead else (Color(Y) if act else Color.WHITE))
		var lv = Label.new()
		lv.text = "Lv%d" % h.lv
		lv.custom_minimum_size.x = 64
		lv.add_theme_color_override("font_color", Color(DIM))
		var hpbox = VBoxContainer.new()
		hpbox.add_theme_constant_override("separation", -4)
		hpbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var hp = Label.new()
		hp.text = "%d/%d" % [h.hp, s.hp]
		var low = dead or h.hp < s.hp * 0.25
		if low:
			hp.add_theme_color_override("font_color", Color(RD))
		hpbox.add_child(hp)
		var bar = Bar.new()
		bar.ratio = clampf(float(h.hp) / max(1, s.hp), 0.0, 1.0)
		bar.col = Color("#ff6a6a") if low else Color("#5fe07a")
		bar.custom_minimum_size = Vector2(150, 6)
		hpbox.add_child(bar)
		var mp = Label.new()
		mp.text = "%d mp" % h.mp
		mp.add_theme_color_override("font_color", Color(BL))
		for x in [n, lv, hpbox, mp]:
			row.add_child(x)
		v.add_child(row)
	return p

func _process(_d: float) -> void:
	if minimap.visible:
		minimap.queue_redraw()

# ================= inner classes =================
class Bar extends Control:
	var ratio := 1.0
	var col := Color.GREEN
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * ratio, size.y - 2)), col)

class Cursor extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(24, 24)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var pts = PackedVector2Array([Vector2(4, 5), Vector2(19, 13), Vector2(4, 21)])
		draw_colored_polygon(pts, Color.BLACK)
		var pts2 = PackedVector2Array([Vector2(6, 8), Vector2(15, 13), Vector2(6, 18)])
		draw_colored_polygon(pts2, Color.WHITE)

class Menu extends PanelContainer:
	signal done(value)
	var spec := {}
	var items: Array = []
	var idx := 0
	var rows := 8
	var active := true
	var kind := "menu"
	var vb: VBoxContainer
	var closed := false

	func setup(s: Dictionary) -> void:
		spec = s
		kind = s.get("kind", "menu")
		items = s.get("items", [])
		rows = int(s.get("rows", 8))
		add_theme_stylebox_override("panel", UI.win_style)
		position = Vector2(s.get("x", 16), s.get("y", 475))
		custom_minimum_size = Vector2(s.get("w", 416), 0)
		mouse_filter = Control.MOUSE_FILTER_STOP
		vb = VBoxContainer.new()
		vb.add_theme_constant_override("separation", 0)
		add_child(vb)
		if s.has("idx") and s.idx != null:
			idx = int(s.idx)
		else:
			idx = 0
			for i in items.size():
				if not items[i].get("disabled", false):
					idx = i
					break
		idx = clampi(idx, 0, max(0, items.size() - 1))
		if kind == "msg":
			gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_finish(null))

	func hovered() -> void:
		if spec.has("on_hover") and items.size() > 0:
			spec.on_hover.call(items[idx])

	func render() -> void:
		for ch in vb.get_children():
			ch.queue_free()
		if kind == "msg":
			var r = UI.rt(spec.text)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(r)
			if active:
				var more = Label.new()
				more.text = "▼"
				more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				more.add_theme_font_size_override("font_size", 20)
				vb.add_child(more)
			return
		if spec.get("title", "") != "":
			vb.add_child(UI.head_label(spec.title))
		if spec.get("head", "") != "":
			var h = UI.rt(spec.head)
			vb.add_child(h)
		var n = items.size()
		var rcount = mini(rows, n)
		var start = 0
		if n > rcount:
			start = clampi(idx - rcount / 2, 0, n - rcount)
			var up = Label.new()
			up.text = "▲" if start > 0 else " "
			up.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			up.add_theme_font_size_override("font_size", 16)
			vb.add_child(up)
		for i in range(start, start + rcount):
			vb.add_child(_row(i))
		if n > rcount:
			var dn = Label.new()
			dn.text = "▼" if start + rcount < n else " "
			dn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			dn.add_theme_font_size_override("font_size", 16)
			vb.add_child(dn)

	func _row(i: int) -> Control:
		var it = items[i]
		var row = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.custom_minimum_size.y = 32
		var cur = Cursor.new()
		cur.visible = active and i == idx
		var holder = Control.new()
		holder.custom_minimum_size = Vector2(26, 26)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(cur)
		cur.position = Vector2(0, 3)
		row.add_child(holder)
		var lbl = UI.rt(str(it.get("label", "")))
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dis = it.get("disabled", false)
		if dis:
			lbl.modulate = Color(0.55, 0.6, 0.85)
		elif i == idx and active:
			lbl.modulate = Color(1, 0.98, 0.75)
		row.add_child(lbl)
		if it.get("right", "") != "":
			var r = Label.new()
			r.text = str(it.right)
			r.add_theme_color_override("font_color", Color("#7c84b8") if dis else Color("#cfd6ff"))
			row.add_child(r)
		row.gui_input.connect(func(ev): _row_input(ev, i))
		return row

	func _row_input(ev: InputEvent, i: int) -> void:
		if not active or closed:
			return
		if ev is InputEventMouseMotion and idx != i:
			idx = i
			hovered()
			call_deferred("render")
		elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			idx = i
			_pick()
		elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			_back()

	func move(d: int) -> void:
		if items.is_empty():
			return
		idx = (idx + d + items.size()) % items.size()
		Snd.sfx("move")
		hovered()
		render()

	func _pick() -> void:
		if items.is_empty():
			return
		var it = items[idx]
		if it.get("disabled", false):
			Snd.sfx("err")
			return
		Snd.sfx("ok")
		_finish(it.get("value", idx))

	func _back() -> void:
		if spec.get("cancel", true):
			Snd.sfx("back")
			_finish(null)

	func _finish(v) -> void:
		if closed:
			return
		closed = true
		done.emit(v)

	func pick_index(i: int) -> void:
		idx = i
		_pick()

	func handle(ev: InputEvent) -> bool:
		if closed:
			return false
		if kind == "msg":
			if ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel"):
				Snd.sfx("ok")
				_finish(null)
				return true
			return false
		if ev.is_action_pressed("ui_up", true):
			move(-1)
			return true
		if ev.is_action_pressed("ui_down", true):
			move(1)
			return true
		if ev.is_action_pressed("ui_accept"):
			_pick()
			return true
		if ev.is_action_pressed("ui_cancel"):
			_back()
			return true
		return ev is InputEventKey or ev is InputEventJoypadButton

class MiniMap extends Control:
	const IC = {"boss": "#ff4040", "treasure": "#ffd23a", "shop": "#5ae05a", "cell": "#8ec5ff", "camp": "#ff9a3a", "altar": "#d040d0", "fountain": "#40b0ff", "chest": "#b07a3a"}
	func _draw() -> void:
		var run = G.run
		if run == null or run.map == null:
			return
		var cells = []
		for k in run.map:
			var r = run.map[k]
			if r.seen or r.visited:
				cells.append(r)
		if cells.is_empty():
			return
		var minx = 99
		var maxx = -99
		var miny = 99
		var maxy = -99
		for r in cells:
			minx = mini(minx, r.x)
			maxx = maxi(maxx, r.x)
			miny = mini(miny, r.y)
			maxy = maxi(maxy, r.y)
		var cw = 30.0
		var ch = 20.0
		var gw = (maxx - minx + 1) * (cw + 4) + 12
		var gh = (maxy - miny + 1) * (ch + 4) + 12
		var o = Vector2(1280 - gw - 16, 16)
		draw_rect(Rect2(o, Vector2(gw, gh)), Color(0, 0, 0, 0.55))
		var blink = int(Time.get_ticks_msec() / 300) % 2 == 0
		for r in cells:
			var p = o + Vector2(6 + (r.x - minx) * (cw + 4), 6 + (r.y - miny) * (ch + 4))
			var cur = Vector2i(r.x, r.y) == run.pos
			var col = Color("#ffffff") if (cur and blink) else (Color("#dde") if cur else (Color("#9a9aaa") if r.visited else Color("#44445a")))
			draw_rect(Rect2(p, Vector2(cw, ch)), col)
			if IC.has(r.type):
				draw_rect(Rect2(p + Vector2(cw / 2 - 5, ch / 2 - 5), Vector2(10, 10)), Color(IC[r.type]))
			elif r.type == "combat" and not r.cleared and r.visited:
				draw_rect(Rect2(p + Vector2(cw / 2 - 3, ch / 2 - 3), Vector2(6, 6)), Color("#a33"))
