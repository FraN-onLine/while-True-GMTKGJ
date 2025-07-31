extends Area2D
class_name droppable

@export var speed := 600
var direction := Vector2.ZERO
var player_camera: Camera2D = null

@onready var sprite = $Sprite2D
@onready var label = $Label

var item: Item

func _ready():
	# Find the player camera
	var cameras = get_tree().get_nodes_in_group("PlayerCamera")
	if cameras.size() > 0:
		player_camera = cameras[0]
	setup_droppable()

func _process(delta):
	position += direction * speed * delta
	if player_camera:
		var screen_size = get_viewport().get_visible_rect().size
		var cam_pos = player_camera.global_position
		var half_size = screen_size * 0.5 * player_camera.zoom
		var camera_rect = Rect2(cam_pos - half_size, screen_size * player_camera.zoom)
		if not camera_rect.has_point(global_position):
			queue_free()

func setup_droppable(type: String = "anvil"):
	# Load the appropriate resource based on type
	var resource_path = "res://resources/" + type + ".tres"
	if ResourceLoader.exists(resource_path):
		item = load(resource_path)
		apply_item()
	else:
		# Fallback to default configuration
		setup_default_droppable(type)

func setup_droppable_with_item(resource: Item):
	item = resource
	apply_item()

func apply_item():
	if item:
		sprite.color = item.color
		sprite.size = item.size
		sprite.offset_left = -item.size.x / 2
		sprite.offset_top = -item.size.y / 2
		sprite.offset_right = item.size.x / 2
		sprite.offset_bottom = item.size.y / 2
		label.text = item.label

func setup_default_droppable(type: String):
	# Default configuration for unknown types
	sprite.color = Color(0.5, 0.5, 0.5, 1)
	sprite.size = Vector2(50, 50)
	sprite.offset_left = -25
	sprite.offset_top = -25
	sprite.offset_right = 25
	sprite.offset_bottom = 25
	label.text = type.capitalize()

func get_resource_name() -> String:
	if item:
		return item.name
	return "unknown"

func get_resource_type() -> String:
	if item:
		return item.name
	return "generic" 
