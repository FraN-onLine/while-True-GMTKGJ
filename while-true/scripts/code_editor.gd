extends CanvasLayer

@onready var block_list = $VBoxContainer/HSplitContainer/AvailableBlocks/BlockList
@onready var code_blocks = $VBoxContainer/HSplitContainer/CodeArea/CodeContainer/CodeBlocks
@onready var test_button = $VBoxContainer/Buttons/TestButton
@onready var break_button = $VBoxContainer/Buttons/BreakButton
@onready var close_button = $VBoxContainer/Buttons/CloseButton
@onready var help_button = $VBoxContainer/TitleContainer/HelpButton
@onready var status_label = $VBoxContainer/StatusLabel

var current_code: Array = []
var available_blocks = {
	"drop()": {"type": "function", "params": ["anvil", "snake", "ball", "rock", "card"]},
	"hole_open()": {"type": "function", "params": []},
	"hole_close()": {"type": "function", "params": []},
	"wait()": {"type": "function", "params": ["1", "2", "3"]},
	"if:": {"type": "conditional", "params": ["level / 2 == 0", "level > 2"]}
}

# Dragging variables
var dragging = false
var dragged_block = null
var drag_offset = Vector2.ZERO

# =============================================================================
# GAME EXTENSION GUIDE FOR DEVELOPERS
# =============================================================================
# 
# HOW TO ADD NEW LEVELS:
# 
# 1. UPDATE global.gd:
#    - Add new case in load_level() function
#    - Set loop_duration and current_sequence for the new level
#    - Example:
#      3:
#          loop_duration = 7.0
#          current_sequence = ["light_on", "door_open", "ball_roll"]
# 
# 2. UPDATE loop_manager.gd:
#    - Add new event handling in play_next_event() function
#    - Create corresponding play_*() functions
#    - Example:
#      "light_on":
#          play_light_on()
#      "door_open":
#          play_door_open()
# 
# 3. UPDATE code_editor.gd:
#    - Add new function blocks in available_blocks dictionary
#    - Add conversion logic in convert_code_to_sequence()
#    - Example:
#      "light_on()": {"type": "function", "params": []}
#      "door_open()": {"type": "function", "params": []}
# 
# 4. CREATE NEW ROOM SCENE:
#    - Copy room.tscn to room_level3.tscn
#    - Add level-specific visual elements
#    - Update main_game.gd to load the new scene
# 
# HOW TO ADD NEW DROPPABLE TYPES:
# 
# 1. UPDATE droppable.gd:
#    - Add new type in droppable_types dictionary
#    - Set color, size, and label properties
#    - Example:
#      "gem": {
#          "color": Color(0.8, 0.2, 0.8, 1),
#          "size": Vector2(25, 25),
#          "label": "Gem"
#      }
# 
# 2. UPDATE code_editor.gd:
#    - Add "gem" to drop() parameters in available_blocks
#    - Add conversion in convert_code_to_sequence()
#    - Example:
#      elif param == "gem":
#          converted.append("gem_drop")
# 
# HOW TO ADD NEW CODE BLOCKS:
# 
# 1. UPDATE code_editor.gd:
#    - Add new block in available_blocks dictionary
#    - Create corresponding add_*_block() function
#    - Add conversion logic in convert_code_to_sequence()
# 
# 2. UPDATE code_editor.tscn:
#    - Add new button in BlockList
#    - Button text should match the key in available_blocks
# 
# EXAMPLE: Adding a "loop()" block
# 
# 1. In available_blocks:
#    "loop()": {"type": "function", "params": ["3", "5", "10"]}
# 
# 2. In convert_code_to_sequence():
#    elif code.begins_with("loop("):
#        var count = code.split("(")[1].split(")")[0]
#        for i in range(int(count)):
#            converted.append("loop_iteration")
# 
# 3. In loop_manager.gd:
#    "loop_iteration":
#        play_loop_iteration()
# 
# =============================================================================

func _ready():
	# Connect button signals
	test_button.pressed.connect(_on_test_pressed)
	break_button.pressed.connect(_on_break_pressed)
	close_button.pressed.connect(_on_close_pressed)
	help_button.pressed.connect(_on_help_pressed)
	
	# Connect block button signals
	for child in block_list.get_children():
		if child is Button:
			child.pressed.connect(_on_block_pressed.bind(child.text))
	
	# Initially hide the editor
	visible = false
	
	# Update available blocks based on level
	update_available_blocks()

func _input(event):
	if not visible:
		return
	
	# Handle ESC key to close editor
	if event.is_action_pressed("ui_cancel"):
		close_editor()
		return
	
	# Handle dragging
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.global_position)
			else:
				end_drag()
	elif event is InputEventMouseMotion and dragging:
		update_drag(event.global_position)

func _on_block_pressed(block_name: String):
	add_code_block(block_name)

func add_code_block(block_name: String):
	var block_data = available_blocks[block_name]
	
	if block_data.type == "conditional":
		add_conditional_block(block_name, block_data)
	else:
		add_function_block(block_name, block_data)

func add_function_block(block_name: String, block_data: Dictionary):
	# Create a new code block container with visual styling
	var block_container = PanelContainer.new()
	block_container.add_theme_stylebox_override("panel", create_block_style())
	
	var inner_container = HBoxContainer.new()
	inner_container.add_theme_constant_override("separation", 5)
	block_container.add_child(inner_container)
	
	# Create the function name label
	var func_label = Label.new()
	func_label.text = block_name.split("(")[0] + "("
	func_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
	inner_container.add_child(func_label)
	
	# Create parameter input if needed
	if block_data.params.size() > 0:
		var param_input = LineEdit.new()
		param_input.placeholder_text = "parameter"
		param_input.text = block_data.params[0]
		param_input.custom_minimum_size.x = 100
		param_input.add_theme_stylebox_override("normal", create_input_style())
		inner_container.add_child(param_input)
	
	# Close parenthesis
	var close_label = Label.new()
	close_label.text = ")"
	close_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
	inner_container.add_child(close_label)
	
	# Remove button
	var remove_button = Button.new()
	remove_button.text = "×"
	remove_button.custom_minimum_size.x = 30
	remove_button.add_theme_stylebox_override("normal", create_button_style())
	remove_button.pressed.connect(_on_remove_block.bind(block_container))
	inner_container.add_child(remove_button)
	
	# Make block draggable
	make_draggable(block_container)
	
	code_blocks.add_child(block_container)
	current_code.append({"type": block_name, "container": block_container})

func add_conditional_block(block_name: String, block_data: Dictionary):
	# Create conditional block container with visual styling
	var conditional_container = PanelContainer.new()
	conditional_container.add_theme_stylebox_override("panel", create_conditional_style())
	
	var inner_container = VBoxContainer.new()
	conditional_container.add_child(inner_container)
	
	# Create the if line
	var if_container = HBoxContainer.new()
	if_container.add_theme_constant_override("separation", 5)
	
	var if_label = Label.new()
	if_label.text = "if "
	if_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8, 1))
	if_container.add_child(if_label)
	
	# Create condition input
	var condition_input = LineEdit.new()
	condition_input.placeholder_text = "condition"
	condition_input.text = block_data.params[0]
	condition_input.custom_minimum_size.x = 150
	condition_input.add_theme_stylebox_override("normal", create_input_style())
	if_container.add_child(condition_input)
	
	var colon_label = Label.new()
	colon_label.text = ":"
	colon_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8, 1))
	if_container.add_child(colon_label)
	
	# Remove button
	var remove_button = Button.new()
	remove_button.text = "×"
	remove_button.custom_minimum_size.x = 30
	remove_button.add_theme_stylebox_override("normal", create_button_style())
	remove_button.pressed.connect(_on_remove_block.bind(conditional_container))
	if_container.add_child(remove_button)
	
	inner_container.add_child(if_container)
	
	# Create indented content area
	var content_container = VBoxContainer.new()
	content_container.offset_left = 20.0
	
	# Add a button to add content inside the if block
	var add_content_button = Button.new()
	add_content_button.text = "+ Add content"
	add_content_button.add_theme_stylebox_override("normal", create_button_style())
	add_content_button.pressed.connect(_on_add_content_pressed.bind(content_container))
	content_container.add_child(add_content_button)
	
	inner_container.add_child(content_container)
	
	# Make block draggable
	make_draggable(conditional_container)
	
	code_blocks.add_child(conditional_container)
	current_code.append({"type": block_name, "container": conditional_container, "content": content_container})

func _on_add_content_pressed(content_container: VBoxContainer):
	# Create a simple drop block inside the conditional
	var drop_container = PanelContainer.new()
	drop_container.add_theme_stylebox_override("panel", create_block_style())
	
	var inner_container = HBoxContainer.new()
	inner_container.add_theme_constant_override("separation", 5)
	drop_container.add_child(inner_container)
	
	var drop_label = Label.new()
	drop_label.text = "drop("
	drop_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
	inner_container.add_child(drop_label)
	
	var param_input = LineEdit.new()
	param_input.placeholder_text = "card"
	param_input.text = "card"
	param_input.custom_minimum_size.x = 80
	param_input.add_theme_stylebox_override("normal", create_input_style())
	inner_container.add_child(param_input)
	
	var close_label = Label.new()
	close_label.text = ")"
	close_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
	inner_container.add_child(close_label)
	
	var remove_button = Button.new()
	remove_button.text = "×"
	remove_button.custom_minimum_size.x = 30
	remove_button.add_theme_stylebox_override("normal", create_button_style())
	remove_button.pressed.connect(_on_remove_block.bind(drop_container))
	inner_container.add_child(remove_button)
	
	content_container.add_child(drop_container)

func _on_remove_block(block_container: Control):
	code_blocks.remove_child(block_container)
	block_container.queue_free()
	
	# Remove from current_code array
	for i in range(current_code.size()):
		if current_code[i].container == block_container:
			current_code.remove_at(i)
			break

func _on_test_pressed():
	var code_sequence = get_code_sequence()
	status_label.text = "Testing code: " + str(code_sequence)
	
	# Convert code to expected sequence format
	var converted_sequence = convert_code_to_sequence(code_sequence)
	
	# Test against current level sequence
	if converted_sequence == Global.current_sequence:
		status_label.text = "Code is correct! Press 'Break Loop' to complete the level."
		break_button.disabled = false
	else:
		status_label.text = "Code is incorrect. Expected: " + str(Global.current_sequence) + " Got: " + str(converted_sequence)
		break_button.disabled = true

func get_code_sequence() -> Array:
	var sequence = []
	for block_data in current_code:
		var block_text = block_data.type
		var container = block_data.container
		
		# Get parameter if it exists
		for child in container.get_children():
			if child is LineEdit:
				block_text = block_text.split("(")[0] + "(" + child.text + ")"
				break
		
		sequence.append(block_text)
	return sequence

func convert_code_to_sequence(code_sequence: Array) -> Array:
	var converted = []
	for code in code_sequence:
		if code.begins_with("drop("):
			var param = code.split("(")[1].split(")")[0]
			if param == "anvil":
				converted.append("anvil_fall")
			elif param == "snake":
				converted.append("snake_drop")
			elif param == "ball":
				converted.append("ball_drop")
			elif param == "rock":
				converted.append("rock_drop")
			elif param == "card":
				converted.append("card_drop")
		elif code == "hole_open()":
			converted.append("hole_appear")
		elif code == "hole_close()":
			converted.append("hole_close")
		elif code.begins_with("wait("):
			converted.append("wait")
		elif code.begins_with("if "):
			# Handle conditional logic
			var condition = code.split("if ")[1].split(":")[0]
			if condition == "level / 2 == 0":
				converted.append("card_drop")  # Conditional card drop
	
	return converted

func _on_break_pressed():
	var code_sequence = get_code_sequence()
	var converted_sequence = convert_code_to_sequence(code_sequence)
	
	if converted_sequence == Global.current_sequence:
		Global.detected_sequence = converted_sequence
		if Global.break_loop():
			status_label.text = "Loop broken! Level complete!"
			await get_tree().create_timer(2.0).timeout
			close_editor()
		else:
			status_label.text = "Failed to break loop. Try again."
	else:
		status_label.text = "Incorrect sequence. Test your code first."

func _on_close_pressed():
	close_editor()

func _on_help_pressed():
	show_help_dialog()

func show_help_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "How to Use Code Editor"
	dialog.dialog_text = """
	CODE EDITOR HELP:
	
	1. ADDING BLOCKS:
	   - Click on any button in "Available Blocks" to add it to your code
	   - Only relevant blocks are shown for each level
	
	2. DRAGGING BLOCKS:
	   - Click and drag any code block to reorder them
	   - Blocks become semi-transparent while dragging
	
	3. EDITING PARAMETERS:
	   - Click in the input fields to edit function parameters
	   - For drop(): enter "anvil", "card", etc.
	   - For if: enter conditions like "level / 2 == 0"
	
	4. REMOVING BLOCKS:
	   - Click the "×" button on any block to remove it
	
	5. TESTING CODE:
	   - Click "Test Code" to check if your solution is correct
	   - The status will show if your code matches the expected sequence
	
	6. BREAKING THE LOOP:
	   - Once your code is correct, click "Break Loop" to complete the level
	
	7. CLOSING EDITOR:
	   - Press ESC or click "Close" to return to the game
	
	LEVEL 1 SOLUTION:
	while true:
		drop(anvil)
		hole_open()
		hole_close()
	
	LEVEL 2 SOLUTION:
	while true:
		drop(card)
		drop(card)
		if level / 2 == 0:
			drop(card)
	"""
	add_child(dialog)
	dialog.popup_centered()

func close_editor():
	visible = false
	get_tree().paused = false

func open_editor():
	visible = true
	get_tree().paused = true
	status_label.text = "Status: Ready to code"
	break_button.disabled = true
	
	# Update available blocks based on current level
	update_available_blocks()
	
	# Clear existing code blocks
	for child in code_blocks.get_children():
		child.queue_free()
	current_code.clear()

func update_available_blocks():
	# Show/hide buttons based on current level
	for child in block_list.get_children():
		if child is Button:
			match child.text:
				"drop()", "hole_open()", "hole_close()":
					child.visible = true  # Always show for Level 1
				"wait()", "if:":
					child.visible = (Global.current_level >= 2)  # Only show for Level 2+

# Styling functions
func create_block_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_color = Color(0.4, 0.4, 0.6, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func create_conditional_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.3, 0.3, 0.9)
	style.border_color = Color(0.2, 0.6, 0.6, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style

func create_input_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 1)
	style.border_color = Color(0.5, 0.5, 0.7, 1)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

func create_button_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.4, 1)
	style.border_color = Color(0.5, 0.5, 0.7, 1)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style

# Dragging functions
func make_draggable(block: Control):
	block.mouse_filter = Control.MOUSE_FILTER_STOP
	block.gui_input.connect(_on_block_gui_input.bind(block))

func _on_block_gui_input(event: InputEvent, block: Control):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_drag(event.global_position, block)
		else:
			end_drag()
	elif event is InputEventMouseMotion and dragging and dragged_block == block:
		update_drag(event.global_position)

func start_drag(position: Vector2, block: Control = null):
	if block:
		dragged_block = block
		drag_offset = position - block.global_position
		dragging = true
		block.modulate = Color(1, 1, 1, 0.8)  # Semi-transparent while dragging
		# Move block to front
		block.get_parent().move_child(block, -1)
		# Set input as handled
		get_viewport().set_input_as_handled()

func update_drag(position: Vector2):
	if dragged_block:
		dragged_block.global_position = position - drag_offset

func end_drag():
	if dragged_block:
		dragged_block.modulate = Color(1, 1, 1, 1)  # Restore opacity
		dragged_block = null
		dragging = false 
