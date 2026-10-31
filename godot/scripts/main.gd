extends Node
## Entry point: builds the 3D world node and starts the game flow.

func _ready() -> void:
	var w = preload("res://scripts/world.gd").new()
	w.name = "World"
	add_child(w)
	G.world = w
	if "--autotest" in OS.get_cmdline_user_args():
		var at = preload("res://scripts/autotest.gd").new()
		add_child(at)
	G.start()
