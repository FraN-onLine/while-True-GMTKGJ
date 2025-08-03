extends Node2D
var anvil
var hole

var current_event_index: int = 0
var event_timer: float = 0.0
var event_duration: float = 1.1  # Duration of each event
var loop_counter: int = 1  # Hidden counter for loop iterations
var leave_label_scene = preload("res://scenes/leave_label.tscn")
# Animation states
var anvil_falling: bool = false
var card_falling: bool = false

# Spawn points for cards
var spawn_points: Array[Marker2D] = []
var current_spawn_index: int = 0
var level_8 = 0
var level_8_started = false

# Droppable resources
var droppable_scene = preload("res://scenes/droppable.tscn")
var riseable_scene = preload("res://scenes/riseable.tscn")
var mob_scene = preload("res://scenes/Mob.tscn")
var loop_font: Font = preload("res://Assets/UI/Font/Press_Start_2P/PressStart2P-Regular.ttf")
var spawned_nodes: Array[Node] = []


func _ready():
	# Connect to global signals
	Global.loop_broken.connect(_on_loop_broken)
	Global.level_completed.connect(_on_level_completed)
	
	# Setup level-specific elements
	setup_level_elements()
	

func _process(delta):
	if Global.current_level == 8:
		level_8 += delta
		if level_8 > 5 and !level_8_started:
			level_8_started = true
			start_cinematic_sequence()
		
	if not Global.is_loop_active:
		return
	
	event_timer += delta
	
	# Check if it's time for the next event
	if event_timer >= event_duration:
		event_timer = 0.0
		play_next_event()

func play_next_event():
	var event = Global.current_sequence[current_event_index]
	print("Playing event: ", event, " at index: ", current_event_index, " loop: ", loop_counter)
	
	if Global.current_level == 2:
		if event == "card_drop":
			spawn_card()
		elif event.begins_with("if__"):
			# Evaluate the condition
			if loop_counter % 2 == 0:
				spawn_card()
			current_event_index = (current_event_index + 1) % Global.current_sequence.size()
			current_spawn_index = 0
	else:
		match event:
			"anvil_drop":
				play_anvil_fall()
			"hole_appear":
				play_hole_appear()
			"hole_close":
				play_hole_close()
			"virus_rise":
				play_virus_rise()
			"mob_spawn":
				play_mob_spawn()
			"Leave!_print":
				play_leave_label()
			_:
				if Global.current_level == 3:
					if event.begins_with("if__"):
						if loop_counter % 3 == 0:
							play_virus_rise()
						else:
							current_spawn_index = 1
					current_event_index = (current_event_index + 1) % Global.current_sequence.size()
			
	
	# Move to next event
	current_event_index = (current_event_index + 1) % Global.current_sequence.size()
	
	# Increment loop counter when we complete a full sequence
	if current_event_index == 0:
		loop_counter += 1
		print("Loop completed, counter: ", loop_counter)

func evaluate_condition(condition: String) -> bool:
	# Parse conditions like "LOOP_/2_==0" or "LOOP_>3"
	print("condition...")
	if condition.contains("=="):
		var parts = condition.split("==")
		var left = parts[0].replace("_", "")
		var right = parts[1].replace("_", "")
		
		if left.contains("/"):
			var div_parts = left.split("/")
			var loop_val = loop_counter
			var divisor = int(div_parts[1])
			var result = loop_val / divisor
			return result == int(right)
	elif condition.contains(">"):
		var parts = condition.split(">")
		var left = parts[0].replace("_", "")
		var right = parts[1].replace("_", "")
		
		if left == "LOOP":
			return loop_counter > int(right)
	
	return false

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
			anvil = $Anvil
			hole = $"../Hole"
			if anvil and anvil.has_method("setup_droppable"):
				anvil.setup_droppable("anvil")
				
			await start_level1_intro()
		2:
			# Level 2: Setup card spawn points only (cards are spawned dynamically)
			spawn_points = [
				get_node_or_null("CardDropRight"),
				get_node_or_null("CardDropLeft"), 
				get_node_or_null("CardDropCenter")
			]
			# Filter out null entries
			spawn_points = spawn_points.filter(func(point): return point != null)
			print("Found ", spawn_points.size(), " card spawn points")
			# Reset spawn index
			current_spawn_index = 0
		3:
			hole = $"../Hole"
			# Level 3: Setup hole and virus rise
			spawn_points = [
				get_node_or_null("Rise1"),
				get_node_or_null("Rise2")
			]
			current_spawn_index = 0
		4:
			hole = $"../Hole"
			spawn_points = [
				get_node_or_null("Rise1"),
				get_node_or_null("Rise2")
			]
			current_spawn_index = 0
		5:
			spawn_points = [
				get_node_or_null("Spawn1"),
				get_node_or_null("Spawn2"),
				get_node_or_null("Spawn3"),
				get_node_or_null("Spawn4")
			]
			current_spawn_index = 0
		7:
			spawn_points = [
				get_node_or_null("Rise1"),
				get_node_or_null("Spawn1"),
				get_node_or_null("Rise2"),
				get_node_or_null("Spawn2")
			]
			current_spawn_index = 0
		
func spawn_card():
	if spawn_points.size() == 0:
		print("No spawn points found for cards!")
		return

	# Get current spawn point
	var spawn_point = spawn_points[current_spawn_index]
	print("Spawning card at spawn point ", current_spawn_index, " at position ", spawn_point.global_position)

	# Create card droppable
	var card = droppable_scene.instantiate()
	card.global_position = spawn_point.global_position
	card.direction = Vector2.DOWN
	get_tree().current_scene.add_child(card)
	card.setup_droppable("Card")
	spawned_nodes.append(card)  # in spawn_card

	# Move to next spawn point for next card
	current_spawn_index = (current_spawn_index + 1) % spawn_points.size()

func play_virus_rise():
	print("Virus rising!")
	# This would be implemented with actual virus sprites
	if spawn_points.size() == 0:
		print("No spawn points for virus rise!")
		return
	var spawn_point = spawn_points[current_spawn_index]
	print("Spawning virus at spawn point ", current_spawn_index, " at position ", spawn_point.global_position)

	var riseable = riseable_scene.instantiate()
	riseable.global_position = spawn_point.global_position
	riseable.direction = Vector2.UP
	get_tree().current_scene.add_child(riseable)
	riseable.setup_riseable("virus")
	spawned_nodes.append(riseable) 
	current_spawn_index = (current_spawn_index + 1) % spawn_points.size()
	
func play_mob_spawn():
	print("Mob spawning!")
	# This would be implemented with actual virus sprites
	if spawn_points.size() == 0:
		print("No spawnpoints!")
		return
	var spawn_point = spawn_points[current_spawn_index]
	print("Spawning mob at spawn point ", current_spawn_index, " at position ", spawn_point.global_position)

	var mob = mob_scene.instantiate()
	mob.global_position = spawn_point.global_position
	get_tree().current_scene.add_child(mob)
	spawned_nodes.append(mob)  
	current_spawn_index = (current_spawn_index + 1) % spawn_points.size()

func play_hole_appear():
	print("Hole appearing!")
	hole.visible = false
	$"../Hole/HoleShape".disabled = true
	

func play_hole_close():
	print("Hole closing!")
	hole.visible = true
	$"../Hole/HoleShape".disabled = false
	
func play_leave_label():
	print("Leave!? label shown!")
	var label_instance = leave_label_scene.instantiate()
	
	# Position the label at the player's global position
	var player = get_tree().get_nodes_in_group("Player")[0] # adjust path if needed
	if player:
		label_instance.global_position = player.global_position
	else:
		print("Player not found!")
		return
	
	# Optional: Add label to current scene and track it
	get_tree().current_scene.add_child(label_instance)
	spawned_nodes.append(label_instance)


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
	pass

func _on_level_completed():
	print("Cleaning up spawned nodes...")
	
	# Free all dynamically spawned nodes
	for node in spawned_nodes:
		if node and node.is_inside_tree():
			node.queue_free()
	spawned_nodes.clear()

	# Reset loop/event state
	loop_counter = 1
	current_event_index = 0
	event_timer = 0.0

	# Additional level-specific cleanup
	if Global.current_level == 2:
		if has_node("card"):
			get_node("card").queue_free()

	_on_loop_broken()

func start_cinematic_sequence():
	var messages = [
		"Error exception occurred..",
		"Rebooting the system, Please wait...",
		"As long as the PLAYER exists, the loop continues on.."
	]

	# UI layer on top
	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	# Fullscreen black background
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.anchor_left = 0
	fade_rect.anchor_top = 0
	fade_rect.anchor_right = 1
	fade_rect.anchor_bottom = 1
	ui_layer.add_child(fade_rect)

	# Label setup
	var label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.modulate.a = 0
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_override("font", loop_font)
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = 1
	label.anchor_bottom = 1
	ui_layer.add_child(label)

	# Initial fade-in of background
	var fade_bg = create_tween()
	fade_bg.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await fade_bg.finished

	# Iterate messages
	for message in messages:
		# Fade in label
		label.modulate = Color(1, 1, 1, 0)
		var fade_in = create_tween()
		fade_in.tween_property(label, "modulate:a", 1.0, 0.5)
		await fade_in.finished

		# Typing effect
		await type_text(label, message, 0.06)

		await get_tree().create_timer(2.0).timeout  # Hold after typing

		# Fade out text
		var fade_out = create_tween()
		fade_out.tween_property(label, "modulate:a", 0.0, 1.0)
		await fade_out.finished
		label.text = ""

		await get_tree().create_timer(0.5).timeout  # Brief pause between messages

	await get_tree().create_timer(1.5).timeout

	# Optional fade to black before scene change
	var fade_to_black = create_tween()
	fade_to_black.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await fade_to_black.finished

	get_tree().change_scene_to_file("res://scenes/title_screen_end.tscn")  # Update path

func type_text(label: Label, full_text: String, speed: float = 0.05) -> void:
	label.text = ""
	for i in range(full_text.length()):
		label.text += full_text[i]
		await get_tree().create_timer(speed).timeout

func start_level1_intro():
	var messages = [
		"You don't know what brought you here....",
		"But you know one thing... you must break the loop...."
	]

	var ui_layer = CanvasLayer.new()
	add_child(ui_layer)

	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.anchor_left = 0
	fade_rect.anchor_top = 0
	fade_rect.anchor_right = 1
	fade_rect.anchor_bottom = 1
	ui_layer.add_child(fade_rect)

	var label = Label.new()
	label.text = ""
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.modulate.a = 0
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_override("font", loop_font)
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = 1
	label.anchor_bottom = 1
	ui_layer.add_child(label)

	# Fade in background
	var fade_in_bg = create_tween()
	fade_in_bg.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await fade_in_bg.finished

	for message in messages:
		# Fade in label
		label.modulate = Color(1, 1, 1, 0)
		var fade_in_label = create_tween()
		fade_in_label.tween_property(label, "modulate:a", 1.0, 0.5)
		await fade_in_label.finished

		await type_text(label, message, 0.06)
		await get_tree().create_timer(1.5).timeout

		var fade_out_label = create_tween()
		fade_out_label.tween_property(label, "modulate:a", 0.0, 0.8)
		await fade_out_label.finished
		label.text = ""

	await get_tree().create_timer(0.5).timeout

	# Fade out black overlay
	var fade_out_bg = create_tween()
	fade_out_bg.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	await fade_out_bg.finished

	ui_layer.queue_free()  # Cleanup overlay
