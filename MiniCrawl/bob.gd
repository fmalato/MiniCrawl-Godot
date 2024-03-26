extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	"if not is_on_floor():
		velocity.y -= gravity * delta"

	# Rotation
	if Input.is_key_pressed(KEY_A):
		rotate_y(deg_to_rad(ROTATION_SPEED))
	if Input.is_key_pressed(KEY_D):
		rotate_y(deg_to_rad(-ROTATION_SPEED))
	# Translation
	var input_dir = Input.get_vector("ui_left", "ui_right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
