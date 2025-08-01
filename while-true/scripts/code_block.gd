extends Area2D
@export var code_to_unlock: String = "rise_unlocked"

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if code_to_unlock == "rise_unlocked":
			Global.rise_unlocked = true
			print("rise_unlocked")
			get_parent().get_parent().get_node("CodeEditor").update_available_blocks()
		else:
			print("Unknown code to unlock: ", code_to_unlock)
		queue_free()  # Remove the pickup from the scene
