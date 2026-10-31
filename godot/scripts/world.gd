extends Node3D
## HD-2D world: pixel-art billboards inside lit 3D rooms (torches, shadows, glow, fog, depth of field).

const PX := 1.1 / 32.0          # world units per sprite pixel (heroes are 32 px -> 1.1 units tall)
const SPR := "res://assets/sprites/"

var cam: Camera3D
var we: WorldEnvironment
var sun: DirectionalLight3D
var content: Node3D
var flickers: Array = []
var anims: Array = []
var tex_cache := {}
var cursor: Label3D
var cursor_target = null
var defend_rings := {}
var t := 0.0
var cam_base := Transform3D()
var cam_orbit := false

func _ready() -> void:
	content = Node3D.new()
	add_child(content)
	cam = Camera3D.new()
	cam.current = true
	add_child(cam)
	we = WorldEnvironment.new()
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	add_child(sun)
	cursor = Label3D.new()
	cursor.text = "▼"
	cursor.font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	cursor.font_size = 48
	cursor.pixel_size = 0.006
	cursor.outline_size = 14
	cursor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	cursor.no_depth_test = true
	cursor.visible = false
	add_child(cursor)

func _process(delta: float) -> void:
	t += delta
	for f in flickers:
		if is_instance_valid(f.l):
			f.l.light_energy = f.base * (1.0 + 0.13 * sin(t * 11.0 + f.seed) + 0.07 * sin(t * 23.0 + f.seed * 3.0))
		if f.has("f") and is_instance_valid(f.f):
			f.f.texture = tex(SPR + "prop_flame%d.png" % (int(t * 9.0 + f.seed) % 4))
	for a in anims:
		if not is_instance_valid(a.n):
			continue
		match a.k:
			"bob":
				a.n.position.y = a.y + sin(t * a.get("spd", 2.0) + a.get("ph", 0.0)) * a.get("amp", 0.08)
			"spin":
				a.n.rotation.y += delta * a.get("spd", 1.0)
	if cursor.visible and cursor_target != null and cursor_target.has("node") and is_instance_valid(cursor_target.node):
		var n = cursor_target.node
		cursor.global_position = n.global_position + Vector3(0, unit_height(cursor_target) + 0.35 + sin(t * 8.0) * 0.06, 0)
	if cam_orbit:
		var a = sin(t * 0.15) * 0.35
		cam.position = Vector3(sin(a) * 8.0, 3.2, cos(a) * 8.0)
		cam.look_at(Vector3(0, 1.6, 0))

# ---------------- helpers ----------------
func tex(path: String) -> Texture2D:
	if not tex_cache.has(path):
		tex_cache[path] = load(path)
	return tex_cache[path]

func clear() -> void:
	for ch in content.get_children():
		ch.queue_free()
	flickers.clear()
	anims.clear()
	defend_rings.clear()
	cursor.visible = false
	cursor_target = null
	cam_orbit = false

func mat_tex(kind: String, fi: int, scale: float, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = tex("res://assets/tex/%s%d.png" % [kind, fi])
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = tex("res://assets/tex/%s%d_n.png" % [kind, fi])
	m.normal_scale = 1.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.roughness = 0.9
	return m

func matc(col: Color, emit: float = 0.0, unshaded: bool = false) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.85
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(pos: Vector3, size: Vector3, mat: Material, parent: Node = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	(parent if parent else content).add_child(mi)
	return mi

func spr(path: String, scale: float = 1.0, shaded: bool = true, parent: Node = null) -> Sprite3D:
	var s = Sprite3D.new()
	s.texture = tex(path)
	s.pixel_size = PX * scale
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.shaded = shaded
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.double_sided = true
	s.offset = Vector2(0, s.texture.get_height() / 2.0)
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shaded else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else content).add_child(s)
	return s

func prop(name: String, pos: Vector3) -> Sprite3D:
	var s = spr(SPR + "prop_%s.png" % name, 0.5)
	s.position = pos
	return s

func blob(pos: Vector3, r: float, parent: Node = null) -> void:
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(r * 2, r * 1.2)
	mi.mesh = q
	var m = StandardMaterial3D.new()
	m.albedo_texture = tex("res://assets/ui/shadow.png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.rotation_degrees.x = -90
	mi.position = pos + Vector3(0, 0.015, 0)
	(parent if parent else content).add_child(mi)

func light(pos: Vector3, col: Color, energy: float, rng: float, shadows: bool = false, flicker: bool = true, flame: Sprite3D = null) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.shadow_enabled = shadows
	l.position = pos
	content.add_child(l)
	if flicker:
		var f = {"l": l, "base": energy, "seed": randf() * 10.0}
		if flame:
			f["f"] = flame
		flickers.append(f)
	return l

func torch(pos: Vector3, col: Color) -> void:
	var h = prop("torch", pos)
	h.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	var fl = spr(SPR + "prop_flame0.png", 0.45, false)
	fl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	fl.modulate = Color(1.6, 1.3, 1.1)
	fl.position = pos + Vector3(0, 0.38, 0.02)
	light(pos + Vector3(0, 0.75, 0.55), col, 2.6, 8.5, true, true, fl)

func fire(pos: Vector3, scale: float = 1.0, col: Color = Color("#ffa040")) -> void:
	prop("logs", pos)
	var fl = spr(SPR + "prop_flame0.png", 1.1 * scale, false)
	fl.modulate = Color(1.8, 1.4, 1.1)
	fl.position = pos + Vector3(0, 0.12, 0.05)
	light(pos + Vector3(0, 0.8, 0.3), col, 3.2 * scale, 9.0, true, true, fl)
	var p = CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 1.6
	p.direction = Vector3(0, 1, 0)
	p.spread = 20.0
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.1
	p.gravity = Vector3(0, 0.2, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q = QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var pm = matc(Color("#ffb040"), 4.0, true)
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = pm
	p.mesh = q
	p.color = Color("#ffb040")
	p.position = pos + Vector3(0, 0.3, 0)
	content.add_child(p)

func shard(pos: Vector3, s: float = 1.0) -> Node3D:
	var n = Node3D.new()
	n.position = pos
	content.add_child(n)
	var m = matc(Color("#8ee0ff"), 3.0)
	m.metallic = 0.2
	m.roughness = 0.15
	for dir in [1, -1]:
		var mi = MeshInstance3D.new()
		var c = CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.28 * s
		c.height = 0.55 * s
		c.radial_segments = 4
		c.rings = 1
		mi.mesh = c
		mi.material_override = m
		mi.position.y = dir * 0.275 * s
		if dir < 0:
			mi.rotation_degrees.x = 180
		n.add_child(mi)
	var l = OmniLight3D.new()
	l.light_color = Color("#8ee0ff")
	l.light_energy = 2.0
	l.omni_range = 6.0
	n.add_child(l)
	anims.append({"n": n, "k": "spin", "spd": 0.8})
	anims.append({"n": n, "k": "bob", "y": pos.y, "amp": 0.12, "spd": 1.6})
	return n

func setup_env(fog: Color, ambient: Color, amb_e: float, near: float, far: float, sun_e: float = 0.45) -> void:
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = fog.darkened(0.55)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = ambient
	e.ambient_light_energy = amb_e
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.1
	e.glow_enabled = true
	e.glow_intensity = 0.85
	e.glow_bloom = 0.06
	e.glow_hdr_threshold = 0.95
	e.ssao_enabled = true
	e.ssao_intensity = 1.4
	e.fog_enabled = true
	e.fog_light_color = fog
	e.fog_density = 0.02
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.08
	e.adjustment_saturation = 1.12
	we.environment = e
	var ca = CameraAttributesPractical.new()
	ca.dof_blur_far_enabled = true
	ca.dof_blur_far_distance = far
	ca.dof_blur_far_transition = 6.0
	ca.dof_blur_near_enabled = true
	ca.dof_blur_near_distance = near
	ca.dof_blur_near_transition = 2.5
	ca.dof_blur_amount = 0.07
	cam.attributes = ca
	sun.light_color = Color(0.75, 0.8, 1.0)
	sun.light_energy = sun_e
	sun.rotation_degrees = Vector3(-58, 22, 0)

func set_cam(pos: Vector3, look: Vector3, fov: float) -> void:
	cam.position = pos
	cam.fov = fov
	cam.look_at(look)

# ---------------- dungeon room ----------------
func build_room(run: Dictionary) -> void:
	clear()
	var fi = run.floor
	var F = D.FLOORS[fi]
	setup_env(F.fog, F.ambient, 0.5, 7.0, 15.0, 0.6)
	var fm = mat_tex("floor", fi, 0.25)
	var wm = mat_tex("wall", fi, 0.5)
	var dark = matc(Color(0.01, 0.01, 0.015), 0.0, true)
	box(Vector3(0, -0.3, 0), Vector3(14, 0.6, 9), fm)
	var pos = run.pos
	var nb = {}
	var dirs = {"n": Vector2i(0, -1), "s": Vector2i(0, 1), "w": Vector2i(-1, 0), "e": Vector2i(1, 0)}
	for d in dirs:
		nb[d] = run.map.get(pos + dirs[d])
	var H = 3.2
	# back wall (north)
	_wall_x(-4.85, -7.6, 7.6, H, wm, nb.n != null)
	# side walls
	_wall_z(-7.3, -5.15, 4.5, H, wm, nb.w != null)
	_wall_z(7.3, -5.15, 4.5, H, wm, nb.e != null)
	# low front lip
	box(Vector3(-4.3, 0.12, 4.65), Vector3(6.0, 0.3, 0.3), wm)
	box(Vector3(4.3, 0.12, 4.65), Vector3(6.0, 0.3, 0.3), wm)
	if nb.s == null:
		box(Vector3(0, 0.12, 4.65), Vector3(2.6, 0.3, 0.3), wm)
	# doors
	for d in nb:
		if nb[d] != null:
			_door(d, nb[d], dark)
	torch(Vector3(-4.0, 1.7, -4.5), F.torch)
	torch(Vector3(4.0, 1.7, -4.5), F.torch)
	var r = run.map[pos]
	_feature(r, run, Vector3(0, 0, -1.7))
	# party
	var n = run.party.size()
	for i in n:
		var h = run.party[i]
		var s = spr(SPR + "hero_%s.png" % h.id)
		s.position = Vector3(-(n - 1) * 0.65 + i * 1.3, 0, 2.3)
		s.flip_h = not (run.dir != null and run.dir.x < 0)
		if h.hp <= 0:
			s.modulate = Color(0.35, 0.35, 0.45)
			s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			s.rotation_degrees.z = 90
			s.position.y = 0.3
		blob(s.position * Vector3(1, 0, 1), 0.45)
	set_cam(Vector3(0, 8.0, 10.6), Vector3(0, 0.2, 0.5), 36)

func _wall_x(z: float, x0: float, x1: float, h: float, m: Material, gap: bool) -> void:
	if gap:
		box(Vector3((x0 - 1.15) / 2.0, h / 2, z), Vector3(-1.15 - x0, h, 0.6), m)
		box(Vector3((x1 + 1.15) / 2.0, h / 2, z), Vector3(x1 - 1.15, h, 0.6), m)
		box(Vector3(0, h - 0.5, z), Vector3(2.3, 1.0, 0.6), m)
	else:
		box(Vector3((x0 + x1) / 2.0, h / 2, z), Vector3(x1 - x0, h, 0.6), m)

func _wall_z(x: float, z0: float, z1: float, h: float, m: Material, gap: bool) -> void:
	if gap:
		box(Vector3(x, h / 2, (z0 - 1.15) / 2.0), Vector3(0.6, h, -1.15 - z0), m)
		box(Vector3(x, h / 2, (z1 + 1.15) / 2.0), Vector3(0.6, h, z1 - 1.15), m)
		box(Vector3(x, h - 0.5, 0), Vector3(0.6, 1.0, 2.3), m)
	else:
		box(Vector3(x, h / 2, (z0 + z1) / 2.0), Vector3(0.6, h, z1 - z0), m)

func _door(d: String, nr: Dictionary, dark: Material) -> void:
	var col = {"boss": Color("#b02828"), "treasure": Color("#e0b43a"), "shop": Color("#5ac85a")}.get(nr.type, Color("#8a7a5a"))
	var emit = 1.2 if nr.type in ["boss", "treasure", "shop"] else 0.0
	var fm = matc(col, emit)
	var locked = nr.type == "cell" and not nr.get("open", false)
	match d:
		"n":
			box(Vector3(0, 1.1, -5.05), Vector3(2.3, 2.2, 0.2), dark)
			box(Vector3(-1.2, 1.1, -4.5), Vector3(0.18, 2.2, 0.2), fm)
			box(Vector3(1.2, 1.1, -4.5), Vector3(0.18, 2.2, 0.2), fm)
			box(Vector3(0, 2.25, -4.5), Vector3(2.58, 0.18, 0.2), fm)
			if locked:
				_bars(Vector3(0, 1.1, -4.55), true)
		"w", "e":
			var sx = -1.0 if d == "w" else 1.0
			box(Vector3(sx * 7.5, 1.1, 0), Vector3(0.2, 2.2, 2.3), dark)
			box(Vector3(sx * 6.95, 1.1, -1.2), Vector3(0.2, 2.2, 0.18), fm)
			box(Vector3(sx * 6.95, 1.1, 1.2), Vector3(0.2, 2.2, 0.18), fm)
			box(Vector3(sx * 6.95, 2.25, 0), Vector3(0.2, 0.18, 2.58), fm)
			if locked:
				_bars(Vector3(sx * 6.95, 1.1, 0), false)
		"s":
			box(Vector3(0, -0.02, 4.4), Vector3(2.2, 0.08, 0.9), dark)
			box(Vector3(-1.2, 0.35, 4.6), Vector3(0.22, 0.7, 0.22), fm)
			box(Vector3(1.2, 0.35, 4.6), Vector3(0.22, 0.7, 0.22), fm)
			if locked:
				_bars(Vector3(0, 0.3, 4.4), true, 0.6)

func _bars(c: Vector3, along_x: bool, h: float = 2.2) -> void:
	var m = matc(Color("#888890"))
	m.metallic = 0.7
	for i in 7:
		var o = -0.9 + i * 0.3
		box(c + (Vector3(o, 0, 0) if along_x else Vector3(0, 0, o)), Vector3(0.06, h, 0.06), m)
	box(c + Vector3(0, -0.05, 0), Vector3(0.25, 0.25, 0.12) if along_x else Vector3(0.12, 0.25, 0.25), matc(Color("#e0b43a"), 1.0))

func _feature(r: Dictionary, run: Dictionary, p: Vector3) -> void:
	var used = r.get("used", false)
	match r.type:
		"chest":
			prop("chest_open" if used else "chest", p)
		"treasure":
			prop("pedestal", p)
			if not used:
				var orb = MeshInstance3D.new()
				var sm = SphereMesh.new()
				sm.radius = 0.14
				sm.height = 0.28
				orb.mesh = sm
				orb.material_override = matc(Color("#ffe680"), 4.0)
				orb.position = p + Vector3(0, 1.3, 0)
				content.add_child(orb)
				anims.append({"n": orb, "k": "bob", "y": 1.3, "amp": 0.08, "spd": 2.2})
				light(p + Vector3(0, 1.4, 0.3), Color("#ffd870"), 1.8, 5.0, false, false)
		"shop":
			prop("stall", p)
			if not Meta.unlocked.get("pip", false):
				var s = spr(SPR + "hero_pip.png")
				s.position = p + Vector3(2.6, 0, 0.3)
				blob(s.position, 0.4)
				var ex = Label3D.new()
				ex.text = "!"
				ex.font = load("res://assets/fonts/PressStart2P-Regular.ttf")
				ex.font_size = 48
				ex.pixel_size = 0.008
				ex.modulate = Color(UI.Y)
				ex.outline_size = 12
				ex.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				ex.position = s.position + Vector3(0, 1.5, 0)
				content.add_child(ex)
				anims.append({"n": ex, "k": "bob", "y": 1.5, "amp": 0.06, "spd": 5.0})
		"camp":
			fire(p, 0.5 if used else 1.0)
		"altar":
			prop("altar_used" if used else "altar", p)
			if not used:
				light(p + Vector3(0, 0.9, 0.4), Color("#ff3030"), 2.0, 5.0, false, true)
		"fountain":
			prop("fountain_used" if used else "fountain", p)
			if not used:
				light(p + Vector3(0, 0.8, 0.5), Color("#60b0ff"), 1.2, 4.5, false, false)
		"cell":
			if not used and not Meta.unlocked.get("doran", false):
				prop("cage", p)
			else:
				prop("cage_open", p)
		"boss":
			if r.cleared and run.floor < 2:
				box(p + Vector3(0, 0.005, 0), Vector3(2.2, 0.02, 1.6), matc(Color(0.01, 0.01, 0.01), 0.0, true))
				for i in 4:
					box(p + Vector3(0, 0.02, -0.6 + i * 0.36), Vector3(2.0 - i * 0.25, 0.02, 0.06), matc(Color(0.18, 0.18, 0.2)))
			elif r.cleared:
				shard(p + Vector3(0, 1.2, 0))
		"start":
			var ring = MeshInstance3D.new()
			var tm = TorusMesh.new()
			tm.inner_radius = 0.9
			tm.outer_radius = 1.0
			ring.mesh = tm
			ring.scale = Vector3(1, 0.05, 0.6)
			ring.material_override = matc(Color("#8ee0ff"), 1.2)
			ring.position = p + Vector3(0, 0.02, 0.6)
			content.add_child(ring)

# ---------------- battle arena ----------------
const SLOTS = {1: [[150, 160]], 2: [[105, 130], [195, 165]], 3: [[85, 115], [195, 120], [140, 178]], 4: [[80, 110], [185, 110], [105, 180], [210, 180]]}

func build_battle(fi: int, enemies: Array, party: Array) -> void:
	clear()
	var F = D.FLOORS[fi]
	setup_env(F.fog, F.ambient, 0.38, 3.5, 12.0, 0.6)
	var fm = mat_tex("floor", fi, 0.25)
	var wm = mat_tex("wall", fi, 0.5)
	box(Vector3(0, -0.3, -1), Vector3(26, 0.6, 16), fm)
	box(Vector3(0, 2.6, -6.2), Vector3(28, 5.2, 0.6), wm)
	for x in [-6.4, 6.4]:
		var pil = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.55
		cy.bottom_radius = 0.6
		cy.height = 5.2
		pil.mesh = cy
		pil.material_override = wm
		pil.position = Vector3(x, 2.6, -4.6)
		content.add_child(pil)
		box(Vector3(x, 0.12, -4.6), Vector3(1.6, 0.25, 1.6), wm)
		torch(Vector3(x, 2.3, -3.95), F.torch)
	if enemies.size() == 1 and enemies[0].get("boss", false):
		enemies[0]["home"] = Vector3(-2.2, 0, -0.6)
	else:
		var sl = SLOTS[enemies.size()]
		for i in enemies.size():
			enemies[i]["home"] = Vector3((sl[i][0] - 240) / 40.0, 0, (sl[i][1] - 150) / 32.0)
	for e in enemies:
		var sc = float(e.get("scale", 2)) / 2.0
		var s = spr(SPR + "enemy_%s.png" % e.key, sc)
		var hp = e.home + (Vector3(0, 0.7, 0) if e.get("fly", false) else Vector3.ZERO)
		s.position = hp
		e["node"] = s
		blob(e.home, 0.45 * sc)
		if e.get("fly", false):
			anims.append({"n": s, "k": "bob", "y": hp.y, "amp": 0.15, "spd": 4.0, "ph": randf() * 6.0})
	var n = party.size()
	for i in n:
		var h = party[i]
		var s = spr(SPR + "hero_%s.png" % h.id)
		var z = -1.7 + i * 1.15 + (4 - n) * 0.55
		h["home"] = Vector3(3.0 + i * 0.35, 0, z)
		s.position = h.home
		h["node"] = s
		blob(h.home, 0.45)
		set_dead_pose(h, h.hp <= 0)
	set_cam(Vector3(0.6, 3.1, 8.6), Vector3(0.5, 0.9, -0.2), 40)

func unit_height(u: Dictionary) -> float:
	if u.has("key"):
		return 1.1 * float(u.get("scale", 2)) / 2.0 * (32.0 / 32.0) + (0.7 if u.get("fly", false) else 0.0)
	return 1.1

func center_of(u: Dictionary) -> Vector3:
	if not u.has("node") or not is_instance_valid(u.node):
		return Vector3.ZERO
	var base = u.node.global_position
	return base + Vector3(0, unit_height(u) * 0.55 - (0.7 if u.get("fly", false) else 0.0) * 0.0, 0.1)

func set_dead_pose(h: Dictionary, dead: bool) -> void:
	if not h.has("node") or not is_instance_valid(h.node):
		return
	var s = h.node
	if dead:
		s.modulate = Color(0.4, 0.4, 0.5)
		s.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		s.rotation_degrees = Vector3(0, 0, 90)
		s.position = h.home + Vector3(0.55, 0.0, 0)
	else:
		s.modulate = Color.WHITE
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.rotation_degrees = Vector3.ZERO
		s.position = h.home

func set_cursor(u) -> void:
	cursor_target = u
	cursor.visible = u != null

func step(u: Dictionary, fwd: bool) -> void:
	if not u.has("node") or not is_instance_valid(u.node):
		return
	var tw = create_tween()
	var target = u.home + (Vector3(-0.6, 0, 0) if fwd else Vector3.ZERO)
	tw.tween_property(u.node, "position:x", target.x, 0.12)

func flash(u: Dictionary, times: int = 1) -> void:
	if not u.has("node") or not is_instance_valid(u.node):
		return
	var s = u.node
	var base = s.modulate
	var tw = create_tween()
	for i in times:
		tw.tween_property(s, "modulate", Color(4, 4, 4, 1), 0.05)
		tw.tween_property(s, "modulate", base, 0.07)

func shake(u: Dictionary) -> void:
	if not u.has("node") or not is_instance_valid(u.node):
		return
	var s = u.node
	var x0 = s.position.x
	var tw = create_tween()
	for i in 4:
		tw.tween_property(s, "position:x", x0 + (0.1 if i % 2 == 0 else -0.1), 0.04)
	tw.tween_property(s, "position:x", x0, 0.04)

func kill(u: Dictionary) -> void:
	if not u.has("node") or not is_instance_valid(u.node):
		return
	var s = u.node
	var tw = create_tween()
	tw.tween_property(s, "modulate", Color(3, 1.2, 1.2, 1), 0.08)
	tw.tween_property(s, "modulate", Color(1, 0.2, 0.3, 0), 0.4)
	tw.tween_callback(s.hide)
	burst(center_of(u), Color("#ff9a7a"), 14)

func popup(pos: Vector3, text: String, col: Color = Color.WHITE, size: int = 40) -> void:
	var l = Label3D.new()
	l.text = text
	l.font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	l.font_size = size
	l.pixel_size = 0.0075
	l.modulate = col
	l.outline_size = 12
	l.outline_modulate = Color.BLACK
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 10
	l.position = pos + Vector3(randf_range(-0.12, 0.12), 0.3, 0.3)
	content.add_child(l)
	var tw = create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.45, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_interval(0.45)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)

func burst(pos: Vector3, col: Color, amount: int = 26) -> void:
	var p = CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.55
	p.spread = 180.0
	p.direction = Vector3(0, 1, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.2
	p.gravity = Vector3(0, -1.5, 0)
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q = QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	var pm = matc(col, 5.0, true)
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = pm
	p.mesh = q
	p.position = pos
	content.add_child(p)
	p.emitting = true
	var l = OmniLight3D.new()
	l.light_color = col
	l.light_energy = 4.0
	l.omni_range = 4.5
	l.position = pos + Vector3(0, 0, 0.4)
	content.add_child(l)
	var tw = create_tween()
	tw.tween_property(l, "light_energy", 0.0, 0.45)
	tw.tween_callback(l.queue_free)
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)

func sparkle(pos: Vector3, col: Color) -> void:
	var p = CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.6
	p.amount = 16
	p.lifetime = 0.8
	p.direction = Vector3(0, 1, 0)
	p.spread = 25.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.4
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.6
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q = QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var pm = matc(col, 4.0, true)
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = pm
	p.mesh = q
	p.position = pos - Vector3(0, 0.4, 0)
	content.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)

func slash(pos: Vector3, col: Color = Color.WHITE) -> void:
	for i in 3:
		var mi = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2(0.05, 0.9)
		mi.mesh = q
		var m = matc(col, 4.0, true)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		mi.material_override = m
		mi.position = pos + Vector3(-0.2 + i * 0.2, 0, 0.5)
		mi.rotation_degrees = Vector3(0, 0, 40)
		mi.scale = Vector3(1, 0.1, 1)
		content.add_child(mi)
		var tw = create_tween()
		tw.tween_property(mi, "scale:y", 1.0, 0.08)
		tw.tween_property(m, "albedo_color:a", 0.0, 0.18)
		tw.tween_callback(mi.queue_free)

func set_defend(h: Dictionary, on: bool) -> void:
	if defend_rings.has(h.id):
		if is_instance_valid(defend_rings[h.id]):
			defend_rings[h.id].queue_free()
		defend_rings.erase(h.id)
	if on and h.has("node"):
		var ring = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 0.42
		tm.outer_radius = 0.48
		ring.mesh = tm
		ring.scale = Vector3(1, 0.08, 0.7)
		ring.material_override = matc(Color("#8ec5ff"), 2.5)
		ring.position = h.home + Vector3(0, 0.05, 0)
		content.add_child(ring)
		defend_rings[h.id] = ring

# ---------------- camp / title ----------------
func build_camp(title_mode: bool) -> void:
	clear()
	setup_env(Color("#141238"), Color("#5a6ab0"), 0.35, 2.0, 14.0, 0.25)
	var we_env = we.environment
	we_env.background_color = Color("#06051a")
	var gm = mat_tex("floor", 0, 0.3, Color(0.45, 0.6, 0.45))
	box(Vector3(0, -0.3, 0), Vector3(40, 0.6, 40), gm)
	var tree_m = matc(Color("#0c1410"))
	for i in 22:
		var a = TAU * i / 22.0 + randf() * 0.2
		var r = 9.0 + randf() * 6.0
		var cone = MeshInstance3D.new()
		var c = CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.9 + randf() * 0.6
		c.height = 3.0 + randf() * 2.5
		c.radial_segments = 6
		cone.mesh = c
		cone.material_override = tree_m
		cone.position = Vector3(cos(a) * r, c.height / 2.0, sin(a) * r - 2.0)
		if cone.position.z > 5.0:
			continue
		content.add_child(cone)
	var star_m = matc(Color(1, 1, 1), 3.0, true)
	for i in 120:
		var st = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.04 + randf() * 0.05
		sm.height = sm.radius * 2
		sm.radial_segments = 4
		sm.rings = 2
		st.mesh = sm
		st.material_override = star_m
		st.position = Vector3(randf_range(-30, 30), randf_range(6, 20), randf_range(-30, -18))
		content.add_child(st)
	fire(Vector3(0, 0, 0), 1.3)
	var spots = [[Vector3(-1.9, 0, -0.4), true], [Vector3(1.9, 0, -0.4), false], [Vector3(-1.35, 0, 1.35), true], [Vector3(1.35, 0, 1.35), false]]
	for i in 4:
		var id = D.HERO_IDS[i]
		var s = spr(SPR + "hero_%s.png" % id)
		s.position = spots[i][0]
		s.flip_h = spots[i][1]
		blob(s.position, 0.42)
		if not Meta.unlocked.get(id, false):
			s.modulate = Color(0.03, 0.03, 0.06)
			var q = Label3D.new()
			q.text = "?"
			q.font = load("res://assets/fonts/PressStart2P-Regular.ttf")
			q.font_size = 40
			q.pixel_size = 0.008
			q.outline_size = 10
			q.modulate = Color(UI.DIM)
			q.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			q.position = s.position + Vector3(0, 1.5, 0)
			content.add_child(q)
	if title_mode:
		shard(Vector3(0, 3.0, -1.5), 2.2)
		cam_orbit = true
		set_cam(Vector3(0, 3.2, 8.0), Vector3(0, 1.6, 0), 42)
	else:
		set_cam(Vector3(0, 2.7, 6.6), Vector3(0, 0.6, 0), 40)

func build_void() -> void:
	clear()
	setup_env(Color("#05040c"), Color("#303050"), 0.2, 1.0, 30.0, 0.0)
	set_cam(Vector3(0, 2, 6), Vector3.ZERO, 40)
