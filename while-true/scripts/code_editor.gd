extends CanvasLayer

@onready var block_list = $VBoxContainer/HSplitContainer/AvailableBlocks/BlockList
@onready var code_blocks = $VBoxContainer/HSplitContainer/CodeArea/CodeContainer/CodeBlocks
@onready var test_button = $VBoxContainer/Buttons/TestButton
@onready var break_button = $VBoxContainer/Buttons/BreakButton
@onready var close_button = $VBoxContainer/Buttons/CloseButton
@onready var help_button = $VBoxContainer/Buttons/HelpButton
@onready var status_label = $VBoxContainer/StatusLabel
const MAX_BLOCK_COUNT := 8

var current_code: Array = []
var available_blocks = {
	"drop()": {"type": "function", "params": []},
	"rise()": {"type": "function", "params": []},
	"flash()": {"type": "function", "params": []},
	"hole_open()": {"type": "function", "params": []},
	"hole_close()": {"type": "function", "params": []},
	"wait()": {"type": "function", "params": ["1", "2", "3"]},
	"if:": {"type": "conditional", "params": ["loop / 2 == 0", "loop > 2"]},
	"spawn()": {"type": "function", "params": []},
	"print()": {"type": "function", "params": []}
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
# 1. CREATE NEW RESOURCE:
#    - Create new .tres file in resources/ folder
#    - Set name, color, size, and label properties
#    - Example: resources/gem.tres
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
		
	print(event)
	# Handle ESC key to close editor
	if event.is_action_pressed("close_editor"):
		close_editor()
		get_viewport().set_input_as_handled()
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

func _unhandled_input(event):
	if not visible:
		return
	
	if event.is_action_pressed("close_editor"):
		close_editor()
		get_viewport().set_input_as_handled()


func _on_block_pressed(block_name: String):
	print("Block pressed: ", block_name)  # Debug print
	add_code_block(block_name)

func add_code_block(block_name: String):
	if get_current_block_count() >= MAX_BLOCK_COUNT:
		status_label.text = "Maximum block count reached (" + str(MAX_BLOCK_COUNT) + "). Remove a block to add more."
		return
	print("Adding code block: ", block_name)  # Debug print
	var block_data = available_blocks[block_name]
	
	if block_data.type == "conditional":
		add_conditional_block(block_name, block_data)
	else:
		add_function_block(block_name, block_data)

func add_function_block(block_name: String, block_data: Dictionary):
	var block_container = PanelContainer.new()
	block_container.add_theme_stylebox_override("panel", create_block_style())

	var inner_container = HBoxContainer.new()
	inner_container.add_theme_constant_override("separation", 5)
	block_container.add_child(inner_container)

	var func_label = Label.new()
	func_label.text = block_name.split("(")[0] + "("
	func_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2, 1))
	inner_container.add_child(func_label)

	# For drop() and flash(), use OptionButton for item selection
	if block_name in ["drop()", "rise()", "spawn()", "print()"]:
		var option_button = OptionButton.new()
		var allowed = Global.allowed_items if Global.allowed_items.size() > 0 else null
		var dir = DirAccess.open("res://resources/")
		for item in Global.allowed_items:
			option_button.add_item(item)
		inner_container.add_child(option_button)
	else:
		if block_data.params.size() > 0:
			var param_input = LineEdit.new()
			param_input.placeholder_text = "parameter"
			param_input.text = block_data.params[0]
			param_input.custom_minimum_size.x = 100
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
	remove_button.pressed.connect(_on_remove_block.bind(block_container))
	inner_container.add_child(remove_button)

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
	
	# Create condition type dropdown
	var condition_type_dropdown = OptionButton.new()
	condition_type_dropdown.add_item("loop > n")
	condition_type_dropdown.add_item("loop % n == 0")
	condition_type_dropdown.selected = 0  # Default to loop > n
	condition_type_dropdown.custom_minimum_size.x = 120
	if_container.add_child(condition_type_dropdown)
	
	# Create number input for n
	var number_input = LineEdit.new()
	number_input.placeholder_text = "2"
	number_input.text = "2"
	number_input.custom_minimum_size.x = 50
	number_input.add_theme_stylebox_override("normal", create_input_style())
	if_container.add_child(number_input)
	
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
	
	inner_container.add_child(content_container)
	
	# Make block draggable
	make_draggable(conditional_container)
	
	code_blocks.add_child(conditional_container)
	current_code.append({"type": block_name, "container": conditional_container, "content": content_container, "condition_type": condition_type_dropdown, "number_input": number_input})

func _on_add_content_pressed(content_container: VBoxContainer):
	# Check if we can add more blocks
	if get_current_block_count() >= MAX_BLOCK_COUNT:
		status_label.text = "Maximum block count reached (" + str(MAX_BLOCK_COUNT) + ").
		 Remove a block to add more."
		return


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
	var converted_sequence = convert_code_to_sequence(code_sequence)
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
		
		if block_data.type == "if:":
			# Handle if block - get condition from dropdown and number input
			var condition_type = block_data.condition_type.get_item_text(block_data.condition_type.selected)
			var number = block_data.number_input.text
			block_text = "if " + condition_type.replace("n", number) + ":"
			sequence.append(block_text)
			
			# Add contents of the if block
			for content_block in block_data.content.get_children():
				if content_block is PanelContainer:
					# This is a drop block inside the if
					sequence.append("drop(card)")
		else:
			# Handle regular blocks
			for child in container.get_children():
				if child is HBoxContainer:
					for subchild in child.get_children():
						if subchild is OptionButton:
							block_text = block_text.split("(")[0] + "(" + subchild.get_item_text(subchild.selected) + ")"
							break
						elif subchild is LineEdit:
							block_text = block_text.split("(")[0] + "(" + subchild.text + ")"
							break
					break
			sequence.append(block_text)
	return sequence

func convert_code_to_sequence(code_sequence: Array) -> Array:
	var converted = []
	if Global.current_level >= 2:
		for code in code_sequence:
			if code.begins_with("drop("):
				var param = code.split("(")[1].split(")")[0]
				converted.append(param + "_drop")
			elif code.begins_with("rise("):
				var param = code.split("(")[1].split(")")[0]
				converted.append(param + "_rise")
			elif code.begins_with("if "):
				# Extract condition and normalize
				var condition = code.substr(3, code.find(":") - 3).strip_edges().replace(" ", "_").replace("/", "_/").replace("==", "==").replace(">", ">")
				converted.append("if__" + condition)
				# The if block contents (drop(card)) will be added in the next iteration
			elif code == "hole_open()":
				converted.append("hole_appear")
			elif code == "hole_close()":
				converted.append("hole_close")
			elif code.begins_with("wait("):
				converted.append("wait")
			elif code.begins_with("spawn("):
				var param = code.split("(")[1].split(")")[0]
				converted.append(param + "_spawn")
			elif code.begins_with("print("):
				if Global.current_level == 6:
					converted.append("hello_world_print")
				else:
					var param = code.split("(")[1].split(")")[0]
					converted.append(param + "_print")
	else:
		for code in code_sequence:
			if code.begins_with("drop("):
				var param = code.split("(")[1].split(")")[0]
				converted.append(param + "_drop")
			elif code == "hole_open()":
				converted.append("hole_appear")
			elif code == "hole_close()":
				converted.append("hole_close")
			elif code.begins_with("wait("):
				converted.append("wait")
	return converted

func _on_break_pressed():
	var code_sequence = get_code_sequence()
	var converted_sequence = convert_code_to_sequence(code_sequence)
	if converted_sequence == Global.current_sequence:
		Global.detected_sequence = converted_sequence
		if Global.break_loop():
			status_label.text = "Loop broken! Level complete!"
		else:
			status_label.text = "Failed to break loop. Try again."
	else:
		status_label.text = "Incorrect sequence. Test your code first."

func _on_close_pressed():
	print("Close button pressed")  # Debug print
	close_editor()

func _on_help_pressed():
	print("Help button pressed")  # Debug print
	show_help_dialog()

func show_help_dialog():
	var dialog = AcceptDialog.new()
	dialog.title = "How to Use Code Editor"
	dialog.dialog_text = """
	CODE EDITOR HELP:
	
	1. ADDING BLOCKS:
	   - Click on any button in "Available Blocks" to add it to your code
	
	3. EDITING PARAMETERS:
	   - Click in the input fields to edit function parameters
	   - For drop(): enter "anvil", "card", etc.
	   - For if: enter conditions like "level % 2 == 0"
	
	4. REMOVING BLOCKS:
	   - Click the "×" button on any block to remove it
	
	5. TESTING CODE:
	   - Click "Test Code" to check if your solution is correct
	   - The status will show if your code matches the expected sequence
	
	6. BREAKING THE LOOP:
	   - Once your code is correct, click "Break Loop" to complete the level
	
	7. CLOSING EDITOR:
	   - Press ESC or click "Close" to return to the game
	"""
	add_child(dialog)
	dialog.popup_centered()

func close_editor():
	Global.cooldown_editor = 0.5
	print("Closing editor")  # Debug print
	visible = false
	get_tree().paused = false

func open_editor():
	print("Opening editor")  # Debug print
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
				"rise()":
					child.visible = Global.rise_unlocked
				"spawn()":
					child.visible = Global.spawn_unlocked
				"print()":
					child.visible = Global.print_unlocked
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

func get_current_block_count() -> int:
	var count = 0
	for block_data in current_code:
		if block_data.type == "if:":
			count += 1
			# Count the inner blocks
			count += block_data.content.get_child_count()
		else:
			count += 1
	return count
