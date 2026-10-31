extends Node
## Permanent progression, saved to user://meta.json
## (on Windows: %APPDATA%\Godot\app_userdata\Shardbound\meta.json)

const PATH = "user://meta.json"

var shards := 0
var up := {}
var unlocked := {"kael": true}
var seen := {}
var ach := {}
var st := {}
var muted := false
var fullscreen := false

func _ready() -> void:
	reset_values()
	load_meta()

func reset_values() -> void:
	shards = 0
	up = {}
	unlocked = {"kael": true}
	seen = {}
	ach = {}
	st = {"kills": 0, "chests": 0, "deaths": 0, "runs": 0, "wins": 0, "best": 0, "shardsTotal": 0}

func load_meta() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	shards = int(d.get("shards", 0))
	for k in d.get("up", {}):
		up[k] = int(d["up"][k])
	unlocked = d.get("unlocked", {"kael": true})
	unlocked["kael"] = true
	seen = d.get("seen", {})
	ach = d.get("ach", {})
	for k in d.get("st", {}):
		st[k] = int(d["st"][k])
	muted = bool(d.get("muted", false))
	fullscreen = bool(d.get("fullscreen", false))

func save_meta() -> void:
	var f = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"shards": shards, "up": up, "unlocked": unlocked, "seen": seen, "ach": ach, "st": st, "muted": muted, "fullscreen": fullscreen}))

func wipe() -> void:
	var m = muted
	var fs = fullscreen
	reset_values()
	muted = m
	fullscreen = fs
	save_meta()

func upr(id: String) -> int:
	return int(up.get(id, 0))

func roster() -> Array:
	var r = []
	for c in D.HERO_IDS:
		if unlocked.get(c, false):
			r.append(c)
	return r

func stat_add(k: String, n: int = 1) -> void:
	st[k] = int(st.get(k, 0)) + n
