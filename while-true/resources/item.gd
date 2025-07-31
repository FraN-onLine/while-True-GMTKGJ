extends Resource
class_name Item

@export var name: String = ""
@export var texture: Texture2D
@export var color: Color = Color.WHITE
@export var size: Vector2 = Vector2(50, 50)
@export var label: String = "Lols"

func _init(p_name: String = "", p_texture: Texture2D = null, p_color: Color = Color.WHITE, p_size: Vector2 = Vector2(50, 50), p_label: String = ""):
	name = p_name
	texture = p_texture
	color = p_color
	size = p_size
	label = p_label 
