extends Node3D

@onready var grid_map : GridMap = $GridMap
@onready var player : CharacterBody3D = $Bob
@onready var key : Area3D = $Key

@onready var current_timestep = 0
@onready var key_collected = false

var connection_handler = null

var last_player_rotarion = null

const CELL_EDGE : float = 6.0
const MAX_TIMESTEPS : int = 2000

const window_size = Vector2i(800, 600)
var window_position = null

var connections = null
var orientations = null
var level_type = null

var goal_position = null
var player_position = null

var skip_button_pressed = false

func _ready():
	get_tree().set_pause(true)
	connection_handler = get_parent().get_node("GymConnectionHandler")
	while !connection_handler.is_server_init():
		continue
	await _get_floor_data()
	
	key.body_entered.connect(_on_body_entered)
	
	var meshes_dict = {}
	var meshes_items = grid_map.mesh_library.get_item_list()
	for item_id in meshes_items:
		var item_name = grid_map.mesh_library.get_item_name(item_id)
		meshes_dict[item_name] = item_id
	
	var iter = 0
	
	#await $BuildFloorRequest.request_completed
	var tile_name = ""
	var starting_positions = []
	for i in range(connections.size()):
		for j in range(connections[0].size()):
			tile_name = connections[j][i]
			if !tile_name == "empty":
				var item_id = meshes_dict[tile_name]
				var orientation = null
				if tile_name.find("room") != -1:
					orientation = get_room_rotation_from_code(tile_name, orientations[j][i])
				else:
					orientation = get_corridor_rotarion_from_code(tile_name, orientations[j][i])
				grid_map.set_cell_item(Vector3i(i, 0, j), item_id, grid_map.get_orthogonal_index_from_basis(orientation))
	
	# Set player position and rotation
	player.position = Vector3(player_position.x, 1.5, player_position.y)
	player.rotate_x(deg_to_rad(90))
	player.rotation.z = 0
	# Set key position
	key.position = Vector3(goal_position.x, 1.25, goal_position.y)
	
	# Set initial player rotation
	last_player_rotarion = player.rotation
	if get_parent().agent_controlled_by_human and !get_parent().recording_started:
		var response = connection_handler.start_recording()
		get_parent().recording_started = true
	get_tree().set_pause(false)
	
func _get_floor_data():
	var floor_data = connection_handler.get_floor_data()
	await connect_floor_data(floor_data)
	
func connect_floor_data(data):
	connections = []
	orientations = []
	var rows_connect = data["connections"].split("\n")
	var rows_orient = data["orientations"].split("\n")
	var goal_pos = data["goal_position"].split(",")
	var player_pos = data["player_position"].split(",")
	goal_position = Vector2(int(goal_pos[0]) * CELL_EDGE + CELL_EDGE / 2, int(goal_pos[1]) * CELL_EDGE + CELL_EDGE / 2)
	player_position = Vector2(int(player_pos[0]) * CELL_EDGE + CELL_EDGE / 2, int(player_pos[1]) * CELL_EDGE + CELL_EDGE / 2)
	
	for x in rows_connect:
		connections.append(x.split(","))
	for x in rows_orient:
		orientations.append(x.split(","))
	
	connections.pop_back()
	orientations.pop_back()
	
func _on_body_entered(body):
	if body == $Bob:
		key.queue_free()
		key_collected = true

func is_server_init():
	return get_parent().is_server_init()

# Starting from last door before a blank on the right. Reference: https://imgur.com/BblmzVh
func get_corridor_rotarion_from_code(item: String, code: String):
	# TODO: find proper solution
	if item == "corridor" or item == "dead_end":
		if code == "1":
			return Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
		elif code == "2":
			return Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
		elif code == "3":
			return Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0))
		elif code == "0":
			return Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	else:
		if code == "0":
			return Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
		elif code == "1":
			return Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
		elif code == "2":
			return Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0))
		elif code == "3":
			return Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))

func get_room_rotation_from_code(item: String, code: String):
	if item != "room_3":
		if code == "0":
			return Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0))
		elif code == "1":
			return Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
		elif code == "2":
			return Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
		elif code == "3":
			return Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
	else:
		if code == "0":
			return Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1))
		elif code == "1":
			return Basis(Vector3(0, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, 0))
		elif code == "2":
			return Basis(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
		elif code == "3":
			return Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, 0))
		
func check_player_movement():
	var has_moved = false
	if (player.rotation - last_player_rotarion).length() > 0:
		has_moved = true
	if player.get_last_motion().length() > 0:
		has_moved = true
		
	return has_moved

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if get_parent().is_server_init():
		if check_player_movement():
			current_timestep += 1
		if Input.is_key_pressed(KEY_F7):
			skip_button_pressed = true
		if current_timestep > MAX_TIMESTEPS:
			# TODO: these should be signals! (How to signal a grandparent?)
			get_parent().has_agent_succeded = false
			get_parent().is_child_scene_done = true
		# Update player rotation tracking
		last_player_rotarion = player.rotation
		if key_collected or skip_button_pressed:
			get_parent().has_agent_succeded = true
			get_parent().is_child_scene_done = true
			#get_tree().set_pause(true)

func get_current_timestep():
	return current_timestep
