extends Node2D

@onready var sprite = $Sprite2D
@onready var label = $Label

var resource_name: String = "droppable"
var resource_type: String = "generic"

# Predefined droppable types
var droppable_types = {
	"anvil": {
		"color": Color(0.3, 0.3, 0.3, 1),
		"size": Vector2(40, 60),
		"label": "Anvil"
	},
	"snake": {
		"color": Color(0.2, 0.8, 0.2, 1),
		"size": Vector2(30, 20),
		"label": "Snake"
	},
	"ball": {
		"color": Color(0.8, 0.2, 0.2, 1),
		"size": Vector2(25, 25),
		"label": "Ball"
	},
	"rock": {
		"color": Color(0.6, 0.4, 0.2, 1),
		"size": Vector2(35, 35),
		"label": "Rock"
	},
	"card": {
		"color": Color(0.9, 0.9, 0.1, 1),
		"size": Vector2(30, 45),
		"label": "Card"
	}
}

func _ready():
	setup_droppable()

func setup_droppable(type: String = "anvil"):
	resource_type = type
	resource_name = type
	
	if droppable_types.has(type):
		var config = droppable_types[type]
		sprite.color = config.color
		sprite.size = config.size
		sprite.offset_left = -config.size.x / 2
		sprite.offset_top = -config.size.y / 2
		sprite.offset_right = config.size.x / 2
		sprite.offset_bottom = config.size.y / 2
		label.text = config.label
	else:
		# Default configuration
		sprite.color = Color(0.5, 0.5, 0.5, 1)
		label.text = type.capitalize()

func get_resource_name() -> String:
	return resource_name

func get_resource_type() -> String:
	return resource_type 