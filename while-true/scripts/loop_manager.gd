extends Node2D

@onready var anvil = $Anvil
@onready var hole = $Hole

var current_event_index: int = 0
var event_timer: float = 0.0
var event_duration: float = 1.0  # Duration of each event

# Animation states
var anvil_falling: bool = false
var hole_visible: bool = false

# Droppable resources
var droppable_scene = preload("res://scenes/droppable.tscn")

func _ready():
	# Connect to global signals
	Global.loop_broken.connect(_on_loop_broken)
	Global.level_completed.connect(_on_level_completed)
	
	# Setup level-specific elements
	setup_level_elements()

func _process(delta):
	if not Global.is_loop_active:
		return
	
	event_timer += delta
	
	# Check if it's time for the next event
	if event_timer >= event_duration:
		event_timer = 0.0
		play_next_event()

func play_next_event():
	var event = Global.current_sequence[current_event_index]
	
	match event:
		"anvil_fall":
			play_anvil_fall()
		"hole_appear":
			play_hole_appear()
		"hole_close":
			play_hole_close()
		"card_drop":
			play_card_drop()
		"light_on":
			play_light_on()
		"door_open":
			play_door_open()
		"ball_roll":
			play_ball_roll()
		"light_off":
			play_light_off()
	
	# Move to next event
	current_event_index = (current_event_index + 1) % Global.current_sequence.size()

func play_anvil_fall():
	print("Anvil falling!")
	anvil_falling = true
	
	# Setup anvil as droppable
	if anvil.has_method("setup_droppable"):
		anvil.setup_droppable("anvil")
	
	# Animate anvil falling
	var tween = create_tween()
	tween.tween_property(anvil, "position:y", 650, 1.0)
	tween.tween_callback(func(): 
		anvil_falling = false
		anvil.position.y = 100  # Reset position
	)

func create_droppable(type: String, position: Vector2):
	var droppable = droppable_scene.instantiate()
	droppable.setup_droppable(type)
	droppable.position = position
	add_child(droppable)
	return droppable

func setup_level_elements():
	# Setup level-specific elements based on current level
	match Global.current_level:
		1:
			# Level 1: Setup anvil and hole
			if anvil and anvil.has_method("setup_droppable"):
				anvil.setup_droppable("anvil")
		2:
			# Level 2: Setup cards
			var cards = get_children()
			for card in cards:
				if card.has_method("setup_droppable"):
					card.setup_droppable("card")

func play_card_drop():
	print("Card dropping!")
	
	# Find a card to animate
	var cards = get_children()
	for card in cards:
		if card.has_method("get_resource_type") and card.get_resource_type() == "card":
			# Animate card falling
			var tween = create_tween()
			tween.tween_property(card, "position:y", 650, 1.0)
			tween.tween_callback(func(): 
				card.position.y = 100  # Reset position
			)
			break

func play_hole_appear():
	print("Hole appearing!")
	hole_visible = true
	hole.modulate.a = 1.0

func play_hole_close():
	print("Hole closing!")
	hole_visible = false
	hole.modulate.a = 0.0

func play_light_on():
	print("Light turning on!")
	# Change background color to simulate light
	var tween = create_tween()
	tween.tween_property(get_parent().get_node("Room/Background"), "color", Color(0.8, 0.8, 0.6, 1), 0.5)

func play_door_open():
	print("Door opening!")
	# This would be implemented with actual door sprites

func play_ball_roll():
	print("Ball rolling!")
	# This would be implemented with actual ball sprites

func play_light_off():
	print("Light turning off!")
	# Change background color back
	var tween = create_tween()
	tween.tween_property(get_parent().get_node("Room/Background"), "color", Color(0.2, 0.2, 0.3, 1), 0.5)

func _on_loop_broken():
	# Stop all animations
	anvil_falling = false
	hole_visible = false
	
	# Reset positions
	anvil.position.y = 100
	hole.modulate.a = 0.0
	
	# Reset background
	get_parent().get_node("Room/Background").color = Color(0.2, 0.2, 0.3, 1)

func _on_level_completed():
	# Reset for next level
	current_event_index = 0
	event_timer = 0.0
	_on_loop_broken() 
