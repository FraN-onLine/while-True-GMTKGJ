extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var instructions_button = $VBoxContainer/InstructionsButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	instructions_button.pressed.connect(_on_instructions_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Load the main game scene
	get_tree().change_scene_to_file("res://scenes/main_game.tscn")

func _on_instructions_pressed():
	# Show instructions dialog
	show_instructions()

func _on_settings_pressed():
	# Show settings dialog
	show_settings()

func _on_quit_pressed():
	# Quit the game
	get_tree().quit()

func show_instructions():
	# Create a simple instructions dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Instructions"
	dialog.dialog_text = """
	While True:
	
	HOW TO PLAY:
	1. Watch the repeating sequence of events in the room
	2. Press ESC to open the code editor
	3. Drag and drop code blocks to create your solution
	4. Test your code and break the loop!
	
	CONTROLS:
	- WASD or Arrow Keys: Move character
	- Space: Jump
	- ESC: Open code editor
	
	GOAL:
	Write code that matches the observed sequence to break the loop!
	"""
	add_child(dialog)
	dialog.popup_centered()

func show_settings():
	# Create a simple settings dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Settings"
	dialog.dialog_text = """
	Settings
	
	"""
	add_child(dialog)
	dialog.popup_centered() 
