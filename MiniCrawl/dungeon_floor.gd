extends Node3D

@onready var grid_map : GridMap = $GridMap
@onready var player : CharacterBody3D = $Bob
@onready var key : Area3D = $Key
@onready var fps_counter : Label = $FPSCounter
@onready var step_counter: Label = $StepCounter
@onready var level_counter: Label = $LevelCounter

@onready var current_timestep = 0
@onready var current_level = 0
@onready var key_collected = false

var last_player_rotarion = null

const CELL_EDGE : float = 6.0
const MAX_TIMESTEPS : int = 2000

const window_size = Vector2i(800, 600)
var window_position = null
var server_init = false

var connections = null
var orientations = null
var level_type = null

var skip_button_pressed = false

func _ready():
	_init_server()
	
	key.body_entered.connect(_on_body_entered)
	
	var meshes_dict = {}
	var meshes_items = grid_map.mesh_library.get_item_list()
	for item_id in meshes_items:
		var item_name = grid_map.mesh_library.get_item_name(item_id)
		meshes_dict[item_name] = item_id
	
	var iter = 0
	
	await $BuildFloorRequest.request_completed
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
			if tile_name.find("room") != -1 and (i != 0 or j != 0):
				starting_positions.append(Vector2(i * CELL_EDGE + CELL_EDGE / 2, j* CELL_EDGE + CELL_EDGE / 2))
	
	# Set initial player rotation
	last_player_rotarion = player.rotation
	
	# Set player position and rotation
	var player_position = starting_positions.pick_random()
	player.position = Vector3(player_position.x, 1.5, player_position.y)
	player.rotate_x(deg_to_rad(90))
	player.rotate_y(deg_to_rad(180))
	player.rotation.z = 0
	starting_positions.erase(player_position)
	# Set key position
	var key_position = starting_positions.pick_random()
	key.position = Vector3(key_position.x, 1.25, key_position.y)
	
func _init_server():
	$BuildFloorRequest.request_completed.connect(_on_build_floor_completed)
	$LevelCompletedRequest.request_completed.connect(_on_level_ended_completed)
	$ShutdownRequest.request_completed.connect(_on_shutdown_completed)
	
	$BuildFloorRequest.request("http://127.0.0.1:5555/get_maze_map", ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	
func _on_build_floor_completed(result, response_code, headers, body):
	connections = []
	orientations = []
	var data = JSON.parse_string(body.get_string_from_utf8())
	var rows_connect = data["connections"].split("\n")
	var rows_orient = data["orientations"].split("\n")
	
	for x in rows_connect:
		connections.append(x.split(","))
	for x in rows_orient:
		orientations.append(x.split(","))
	
	connections.pop_back()
	orientations.pop_back()
	
	# Set current level
	level_counter.set_current_level(data["level"])
	current_level = int(data["level"])
	
	server_init = true
	
func _on_level_ended_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	get_tree().change_scene_to_file("res://dungeon_crawler.tscn")
	
func _on_shutdown_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	get_tree().quit()
	
func _on_body_entered(body):
	if body == $Bob:
		key.queue_free()
		key_collected = true

func is_server_init():
	return server_init

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
	if server_init:
		if check_player_movement():
			current_timestep += 1
		if Input.is_key_pressed(KEY_F7):
			skip_button_pressed = true
		if current_timestep > MAX_TIMESTEPS:
			var payload = JSON.stringify({"message": "SHUTDOWN_REQUEST", "success": "False"})
			$ShutdownRequest.request("http://127.0.0.1:5555/shutdown", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
		# Update player rotation tracking
		last_player_rotarion = player.rotation
		if key_collected or skip_button_pressed:
			var payload = JSON.stringify({"success": "True"})
			$LevelCompletedRequest.request("http://127.0.0.1:5555/level_completed", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)

func get_current_timestep():
	return current_timestep

func get_current_level():
	return level_counter
