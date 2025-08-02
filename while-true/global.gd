extends Node

# Global game state management
var current_level: int = 1
var current_sequence: Array = []
var detected_sequence: Array = []
var is_loop_active: bool = true
var loop_timer: float = 0.0
var loop_duration: float = 5.0  # Default loop duration in seconds
var allowed_items : Array = []
var rise_unlocked: bool = false

# Signal for when a sequence is detected
signal sequence_detected(sequence: Array)
signal loop_broken
signal level_completed

func _ready():
	# Initialize the first level
	load_level(current_level)

func load_level(level_number: int):
	current_level = level_number
	current_sequence = []
	detected_sequence = []
	is_loop_active = true
	loop_timer = 0.0
	
	# Set level-specific parameters
	match level_number:
		1:
			loop_duration = 5.0
			current_sequence = ["anvil_drop", "hole_appear", "hole_close"]
			allowed_items = ["rock", "anvil"]
		2:
			loop_duration = 6.0
			current_sequence = ["card_drop", "card_drop", "if__loop_%_2_==_0", "card_drop"]
			allowed_items = ["card"]
		3:
			loop_duration = 5.0
			current_sequence = ["hole_appear", "if__loop_%_3_==_0", "virus_rise", "virus_rise", "hole_close"]
			allowed_items = ["card", "virus"]
		4:
			loop_duration = 5.0
			current_sequence = ["hole_appear", "virus_rise", "virus_rise", "hole_close"]
			allowed_items = ["virus"]
		5:
			loop_duration = 5.0
			current_sequence = ["mob_spawn", "mob_spawn", "mob_spawn"]
			allowed_items = ["virus"]
		_:
			loop_duration = 5.0
			current_sequence = []
			allowed_items = ["anvil"]

func add_to_detected_sequence(event: String):
	if not detected_sequence.has(event):
		detected_sequence.append(event)
		print("Detected event: ", event)
		sequence_detected.emit(detected_sequence)

func set_detected_sequence(sequence: Array):
	detected_sequence = sequence.duplicate()
	print("Sequence set: ", detected_sequence)

func submit_sequence():
	if detected_sequence == current_sequence:
		print("Correct sequence submitted!")
		level_completed.emit()
		return true
	else:
		print("Incorrect sequence. Expected: ", current_sequence, " Got: ", detected_sequence)
		detected_sequence.clear()
		return false

func break_loop():
	if submit_sequence():
		loop_broken.emit()
		return true
	return false

func reset_level():
	detected_sequence.clear()
	is_loop_active = true
	loop_timer = 0.0
