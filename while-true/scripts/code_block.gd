extends Area2D
@export var code_to_unlock: String = "rise_unlocked"
@export var popup_text: String = "You can now use rise() on the editor"
var popup_instance: Node = null
const PopupText = preload("res://scenes/pop_up_text.tscn")

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if code_to_unlock == "rise_unlocked":
			Global.rise_unlocked = true
			print("rise_unlocked")
			show_popup()
			get_parent().get_parent().get_node("CodeEditor").update_available_blocks()
		elif code_to_unlock == "spawn_unlocked":
			Global.spawn_unlocked = true
			print("spawn_unlocked")
			show_popup()
			get_parent().get_parent().get_node("CodeEditor").update_available_blocks()
		else:
			print("Unknown code to unlock: ", code_to_unlock)
		queue_free()  # Remove the pickup from the scene

func show_popup():
	if popup_instance:
		popup_instance.queue_free()
	var popup = PopupText.instantiate()
	get_tree().current_scene.add_child(popup)
	popup_instance = popup
	popup.show_popup(popup_text)
