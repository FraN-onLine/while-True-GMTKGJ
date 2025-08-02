extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -545.0
var input_timer = 0
var input_min = 0.1

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
	
	# Invert controls if on level 4
	if Global.current_level == 4:
		direction *= -1
	
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	# Check for falling off the world
	if position.y > 900:
		respawn()
		
	if Global.cooldown_editor > 0:
		Global.cooldown_editor -= delta
	
	input_timer += delta
	if input_min < input_timer and Global.cooldown_editor <= 0:
		Global.cooldown_editor = 0
		input_timer = 0
		handle_menu_input()

func handle_menu_input():
	if $"../CodeEditor".visible == false:
		if Input.is_action_pressed("ui_cancel"):  # Escape key
			open_code_editor()
	else:
		print("currently open")
		if Input.is_action_pressed("ui_cancel"):  # Escape key
			get_parent().close_code_editor()

func open_code_editor():
	get_parent().open_code_editor() 

func _on_body_entered(body):
	if body.name == "Hole" or body.name == "DeathZone":
		respawn()

func respawn():
	position = respawn_position
	velocity = Vector2.ZERO 
