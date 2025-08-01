extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var respawn_position := Vector2(415, 650)

func _ready():
	# Setup anvil as droppable if it exists
	respawn_position = position
	

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Check for falling off the world
	if position.y > 900:
		respawn()
	
	# Handle menu input
	handle_menu_input()

func handle_menu_input():
	if Input.is_action_just_pressed("ui_cancel"):  # Escape key
		open_code_editor()

func open_code_editor():
	# Signal to main game to open code editor
	get_parent().open_code_editor() 

func _on_body_entered(body):
	if body.name == "Hole" or body.name == "DeathZone":
		respawn()

func respawn():
	position = respawn_position
	velocity = Vector2.ZERO 
