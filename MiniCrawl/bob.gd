extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_action = null
var agent_controlled = false
var request_in_progress = false

func _ready():
	$GetActionRequest.request_completed.connect(_on_get_action_completed)

func _physics_process(delta):
	var input_dir = Vector2(0, 0)
	if not agent_controlled:
		# Rotation
		if Input.is_key_pressed(KEY_A):
			rotate_y(deg_to_rad(ROTATION_SPEED))
		if Input.is_key_pressed(KEY_D):
			rotate_y(deg_to_rad(-ROTATION_SPEED))
		# Translation
		input_dir = Input.get_vector("ui_left", "ui_right", "forward", "backward")
	else:
		if not request_in_progress and get_parent().is_server_init():
			get_tree().paused = true
			request_in_progress = true
			$GetActionRequest.request("http://127.0.0.1:5555/get_action")
			get_tree().paused = false
		if current_action == "1":
			rotate_y(deg_to_rad(ROTATION_SPEED))
		elif current_action == "2":
			rotate_y(deg_to_rad(-ROTATION_SPEED))
		elif current_action == "3":
			input_dir.y = 1
		elif current_action == "4":
			input_dir.y = -1
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	# This one slows down execution
	#current_action = null
	
func _on_get_action_completed(result, response_code, headers, body):
	# Get and execute action
	current_action = JSON.parse_string(body.get_string_from_utf8())["action"]
	request_in_progress = false
