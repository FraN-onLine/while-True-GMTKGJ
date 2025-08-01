extends Node2D

@onready var player = $Player
@onready var room = $Room
@onready var ui = $UI
@onready var code_editor = $CodeEditor

func _ready():
	# Connect signals
	Global.sequence_detected.connect(_on_sequence_detected)
	Global.loop_broken.connect(_on_loop_broken)
	Global.level_completed.connect(_on_level_completed)
	
	# Always load the current level to reset is_loop_active
	Global.load_level(Global.current_level)
	# Update UI
	update_level_display()

func _on_sequence_detected(sequence: Array):
	pass  # Handled by UI

func _on_loop_broken():
	pass  # Handled by UI

func _on_level_completed():
	# Load next level
	Global.is_loop_active = true
	Global.current_level += 1
	Global.load_level(Global.current_level)
	update_level_display()
	
	# Load appropriate room scene based on level
	load_level_room()
	# Respawn player
	if player:
		player.position = Vector2(415, 650)
		player.velocity = Vector2.ZERO

func update_level_display():
	pass  # Handled by UI

func open_code_editor():
	code_editor.open_editor()

func load_level_room():
	# Remove current room
	if room:
		room.queue_free()
	
	# Load appropriate room based on level
	var room_scene_path = ""
	match Global.current_level:
		1:
			room_scene_path = "res://levels/room.tscn"
		2:
			room_scene_path = "res://scenes/room_level2.tscn"
		_:
			room_scene_path = "res://scenes/room.tscn"
	
	# Load and add new room
	var room_scene = load(room_scene_path)
	room = room_scene.instantiate()
	add_child(room)
	move_child(room, 0)  # Move to back 
