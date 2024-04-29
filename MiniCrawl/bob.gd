extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 1

@onready var agent_controlled = !get_parent().get_parent().agent_controlled_by_human

var connection_handler = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_action = null
var record = true
var actions = []
var timestamps = []

var in_hand: Node3D = null

signal update_location(loc)

func _ready():
	connection_handler = get_parent().get_parent().get_node("GymConnectionHandler")
	pass

func _physics_process(delta):
	var input_dir = Vector2(0, 0)
	var block_rotation = 0
	var current_key = ""
	if not agent_controlled:
		# Rotation
		if Input.is_key_pressed(KEY_A):
			# TODO: rotate_y() does not scale with physics (?)
			rotate_y(deg_to_rad(ROTATION_SPEED))
			if in_hand != null:
				block_rotation = deg_to_rad(ROTATION_SPEED)
			current_key = "a"
		if Input.is_key_pressed(KEY_D):
			rotate_y(deg_to_rad(-ROTATION_SPEED))
			if in_hand != null:
				block_rotation = deg_to_rad(-ROTATION_SPEED)
			current_key = "d"
		if Input.is_key_pressed(KEY_E):
			pick_up()
			current_key = "e"
		if Input.is_key_pressed(KEY_Q):
			drop()
			current_key = "q"
		# Translation
		input_dir = Input.get_vector("ui_left", "ui_right", "forward", "backward")
		if input_dir.y == 1:
			current_key = "s"
		if input_dir.y == -1:
			current_key = "w"
	else:
		if get_parent().is_server_init():
			get_tree().set_pause(true)
			current_action = get_action()
			get_tree().set_pause(false)
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
	if in_hand != null:
		var block_position = self.global_position - Vector3(0, 1.0, 0)
		in_hand.position = block_position - $Camera3D.get_global_transform().basis.z
		in_hand.rotate_y(block_rotation)

	move_and_slide()
	#emit_signal("update_location", self.global_position)
	if record:
		actions.append(current_key)
		timestamps.append(Time.get_unix_time_from_system())

func get_overlapping_bodies():
	if $PickUpArea.has_overlapping_bodies():
		return $PickUpArea.get_overlapping_bodies()
	else:
		return []
	
func pick_up():
	if in_hand == null and len($PickUpArea.get_overlapping_bodies()) > 1 and $PickUpArea.get_overlapping_bodies()[1] is RigidBody3D:
		in_hand = $PickUpArea.get_overlapping_bodies()[1]
		in_hand.gravity_scale = 0

func drop():
	if in_hand != null:
		in_hand.gravity_scale = 1
		in_hand = null
		
func get_action():
	var response = connection_handler.get_agent_action()
	# TODO: Godot crashes when agent fails level
	return response["action"]
	
func save_actions(record_dir):
	var file = null
	if FileAccess.file_exists("C:\\Users\\feder\\PycharmProjects\\MiniCrawl\\videos\\" + record_dir + "\\actions.csv"):
		file = FileAccess.open("C:\\Users\\feder\\PycharmProjects\\MiniCrawl\\videos\\" + record_dir + "\\actions.csv", FileAccess.READ_WRITE)
		file.seek_end()
	else:
		file = FileAccess.open("C:\\Users\\feder\\PycharmProjects\\MiniCrawl\\videos\\" + record_dir + "\\actions.csv", FileAccess.WRITE)
	for i in range(len(actions)):
		file.store_string(str(timestamps[i]) + "," + str(actions[i]) + "\n")
	file.close()
	
