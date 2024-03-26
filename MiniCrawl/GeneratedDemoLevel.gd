extends Node3D

@onready var grid_map : GridMap = $GridMap
@onready var player : CharacterBody3D = $Bob
@onready var key : Area3D = $Key
@onready var fps_counter : Label = $FPSCounter
@onready var current_timestep = 0

var last_player_rotarion = null

const CELL_EDGE : float = 6.0
const MAX_TIMESTEPS : int = 3000

func _ready():
	# Read files
	var grid_connections = FileAccess.open("res://Data/grid_connections.txt", FileAccess.READ)
	var grid_orientations = FileAccess.open("res://Data/grid_orientations.txt", FileAccess.READ)
	
	var conn_tiles = []
	var orient_tiles = []
	
	var meshes_dict = {}
	var meshes_items = grid_map.mesh_library.get_item_list()
	for item_id in meshes_items:
		var item_name = grid_map.mesh_library.get_item_name(item_id)
		meshes_dict[item_name] = item_id
	
	var iter = 0
	# Read files
	while !grid_connections.eof_reached():
		# Read connections
		var connections_row = grid_connections.get_csv_line(",")
		var orientations_row = grid_orientations.get_csv_line(",")
		conn_tiles.append([])
		orient_tiles.append([])
		for x in connections_row:
			conn_tiles[iter].append(x)
		for x in orientations_row:
			orient_tiles[iter].append(int(x))
		iter += 1
	# Remove last (empty) line
	conn_tiles.pop_back()
	orient_tiles.pop_back()
	
	var tile_name = ""
	var key_positions = []
	for i in range(conn_tiles.size()):
		for j in range(conn_tiles[0].size()):
			tile_name = conn_tiles[j][i]
			if !tile_name == "empty":
				var item_id = meshes_dict[tile_name]
				grid_map.set_cell_item(Vector3i(i, 0, j), item_id, get_rotarion_from_code(orient_tiles[j][i]))
			if tile_name.find("room") != -1 and (i != 0 or j != 0):
				key_positions.append(Vector3((i + 1) * CELL_EDGE / 2, 2.75, (j + 1) * CELL_EDGE / 2))
		
	grid_connections.close()
	grid_orientations.close()
	
	# Set player position to (0, 0)
	player.position = Vector3(CELL_EDGE / 2, 3.25, CELL_EDGE / 2)
	player.rotate_x(deg_to_rad(90))
	player.rotate_y(deg_to_rad(180))
	# Set initial player rotation
	last_player_rotarion = player.rotation
	
	# Set key position
	key.position = key_positions.pick_random()
	#key.position = Vector3(6, 2.75, 3)
	
	# Set FPS counter color
	var yellow = Color(0.8, 0.8, 0.1, 1)
	fps_counter.add_theme_color_override("font_color", yellow)

# Starting from last door before a blank on the right. Reference: https://imgur.com/BblmzVh
func get_rotarion_from_code(code: int):
	if code == 0:
		return 10
	elif code == 1:
		return 22
	elif code == 2:
		return 0
	elif code == 3:
		return 16
		
func check_player_movement():
	var has_moved = false
	if (player.rotation - last_player_rotarion).length() > 0:
		has_moved = true
	if player.get_last_motion().length() > 0:
		has_moved = true
		
	return has_moved

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if check_player_movement():
		current_timestep += 1
		print("%d" % current_timestep)
	if current_timestep > MAX_TIMESTEPS:
		get_tree().quit()
	# Update player rotation tracking
	last_player_rotarion = player.rotation
