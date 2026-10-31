extends Node
## Music (looping tracks rendered from the original compositions), jingles and SFX.

var music: AudioStreamPlayer
var jingle_p: AudioStreamPlayer
var sfx_players: Array = []
var cur := ""
var want := ""
var cache := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = AudioStreamPlayer.new()
	music.volume_db = -3.0
	add_child(music)
	jingle_p = AudioStreamPlayer.new()
	add_child(jingle_p)
	for i in 8:
		var p = AudioStreamPlayer.new()
		p.volume_db = -2.0
		add_child(p)
		sfx_players.append(p)

func _stream(path: String, loop: bool) -> AudioStream:
	if cache.has(path):
		return cache[path]
	var s = load(path)
	if s is AudioStreamWAV:
		if loop:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
		else:
			s.loop_mode = AudioStreamWAV.LOOP_DISABLED
	cache[path] = s
	return s

func play_song(name: String) -> void:
	want = name
	if Meta.muted or name == "":
		music.stop()
		cur = ""
		return
	if cur == name and music.playing:
		return
	cur = name
	jingle_p.stop()
	music.stream = _stream("res://assets/audio/music_%s.wav" % name, true)
	music.volume_db = -30.0
	music.play()
	var tw = create_tween()
	tw.tween_property(music, "volume_db", -3.0, 0.6)

func stop_song() -> void:
	music.stop()
	cur = ""

func jingle(name: String) -> void:
	stop_song()
	want = ""
	if Meta.muted:
		return
	jingle_p.stream = _stream("res://assets/audio/jingle_%s.wav" % name, false)
	jingle_p.play()

func sfx(name: String) -> void:
	if Meta.muted:
		return
	var path = "res://assets/audio/sfx_%s.wav" % name
	if not ResourceLoader.exists(path):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = _stream(path, false)
			p.play()
			return
	sfx_players[0].stream = _stream(path, false)
	sfx_players[0].play()

func set_muted(v: bool) -> void:
	Meta.muted = v
	Meta.save_meta()
	if v:
		music.stop()
		jingle_p.stop()
		cur = ""
	else:
		var w = want
		want = ""
		play_song(w)
