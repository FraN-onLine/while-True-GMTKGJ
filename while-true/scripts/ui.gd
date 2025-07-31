extends CanvasLayer

@onready var level_label = $LevelLabel
@onready var instructions = $Instructions

func _ready():
	# Connect to global signals
	Global.loop_broken.connect(_on_loop_broken)
	Global.level_completed.connect(_on_level_completed)
	
	update_level_display()

func update_level_display():
	level_label.text = "Level " + str(Global.current_level)

func _on_loop_broken():
	instructions.text = "Loop broken! Level complete!"
	update_level_display()

func _on_level_completed():
	instructions.text = "Level " + str(Global.current_level) + " completed!"
	await get_tree().create_timer(2.0).timeout
	
	# Reset UI
	instructions.text = "Press ESC to open code editor!" 
