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
	
	await  $BuildFloorRequest.request_completed
	var tile_name = ""
	var key_positions = []
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
				key_positions.append(Vector3((i + 1) * CELL_EDGE / 2, 2.75, (j + 1) * CELL_EDGE / 2))
	
	# Set player position to (0, 0)
	player.position = Vector3(CELL_EDGE / 2, 3.25, CELL_EDGE / 2)
	player.rotate_x(deg_to_rad(90))
	player.rotate_y(deg_to_rad(180))
	player.rotation.z = 0
	# Set initial player rotation
	last_player_rotarion = player.rotation
	
	# Set key position
	if level_type == "dungeon_floor":
		#key.position = key_positions.pick_random()
		key.position = Vector3(9, 2.75, 9)
	
func _init_server():
	$InitServerRequest.request_completed.connect(_on_init_server_completed)
	$BuildFloorRequest.request_completed.connect(_on_build_floor_completed)
	$ShutdownRequest.request_completed.connect(_on_shutdown_completed)
	# Set window size and position
	var screen_size = DisplayServer.screen_get_size()
	DisplayServer.window_set_size(window_size)
	window_position = Vector2i(screen_size[0] / 2 - window_size[0] / 2, screen_size[1] / 2 - window_size[1] / 2)
	get_window().position = window_position
	var payload = JSON.stringify({"pos_x": window_position.x, "pos_y": window_position.y, "width": window_size.x, "height": window_size.y})
	$InitServerRequest.request("http://127.0.0.1:5555/init", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
	$BuildFloorRequest.request("http://127.0.0.1:5555/get_maze_map", ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func _on_init_server_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	print("Server initialized!")
	
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
	level_type = data["level_type"]
	
	server_init = true
	
func _on_shutdown_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	get_tree().quit()
	
func _on_body_entered(body):
	print("Key collected!")
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
			var payload = JSON.stringify({"message": "SHUTDOWN_REQUEST"})
			$ShutdownRequest.request("http://127.0.0.1:5555/shutdown", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
		# Update player rotation tracking
		last_player_rotarion = player.rotation
		if key_collected or skip_button_pressed:
			if current_level % 5 == 0 and current_level != 0:
				get_tree().change_scene_to_file("res://put_next_boss_stage.tscn")
			else:
				get_tree().change_scene_to_file("res://generated_demo_level.tscn")
	
func get_current_timestep():
	return current_timestep
	
func get_current_level():
	return level_counter
