extends StaticBody2D
class_name RisingObstacle

@onready var sprite := $Sprite2D
@onready var label := $Label

var start_position := Vector2.ZERO
var target_position := Vector2.ZERO
var rising := false
var rise_speed := 100
var direction = Vector2.UP


func setup_riseable(type: String):

	var data = load("res://resources/%s.tres" % type)
	if not data:
		push_error("Missing riseable data: %s" % type)
		queue_free()
		return

	sprite.color = data.color
	label.text = data.label

func _process(delta):
	position += direction * rise_speed * delta
	if global_position.y < -1000:
		queue_free()
			
