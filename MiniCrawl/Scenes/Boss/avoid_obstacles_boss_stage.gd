extends Node3D

const NUM_OBSTACLES = 10
const OBSTACLE_SPEED = 0.05
const MAX_TIMESTEPS = 2000
# Called when the node enters the scene tree for the first time.
@onready var obstacles_directions = []
@onready var key = $Key
@onready var player = $Bob
@onready var player_collided = false
@onready var key_collected = false
@onready var current_step = 0

var last_player_rotarion = null

func _ready():
	key.body_entered.connect(_on_key_collected)
	
	var positions_x = Array(range(-7, 7))
	var positions_z = Array(range(-7, 7))
	var directions = [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	for i in range(NUM_OBSTACLES):
		var position_x = positions_x.pick_random()
		var position_z = positions_z.pick_random()
		get_node("Obstacles/BlueBall" + str(i)).position = Vector3(position_x, 1.5, position_z)
		get_node("Obstacles/BlueBall" + str(i) + "/Area3D").body_entered.connect(_on_body_collided)
		positions_x.erase(position_x)
		positions_z.erase(position_z)
		obstacles_directions.append(directions.pick_random())
		
	last_player_rotarion = player.rotation


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	for i in range(NUM_OBSTACLES):
		var obstacle = get_node("Obstacles/BlueBall" + str(i))
		if obstacle.position.x >= 8.45 or obstacle.position.z >= 8.45 or obstacle.position.x <= -8.45 or obstacle.position.z <= -8.45:
			obstacles_directions[i] = -obstacles_directions[i]
		obstacle.position += obstacles_directions[i] * OBSTACLE_SPEED
		if player_collided or current_step > MAX_TIMESTEPS:
			get_parent().has_agent_succeded = false
			get_parent().is_child_scene_done = true
	if check_player_movement():
		current_step += 1
	if key_collected:
		get_parent().has_agent_succeded = true
		get_parent().is_child_scene_done = true
			
func check_player_movement():
	var has_moved = false
	if (player.rotation - last_player_rotarion).length() > 0:
		has_moved = true
	if player.get_last_motion().length() > 0:
		has_moved = true
		
	return has_moved
	
func is_server_init():
	return get_parent().is_server_init()
			
func _on_body_collided(body):
	if body == player:
		player_collided = true
		
func _on_key_collected(body):
	if body == player:
		key_collected = true
		
func _on_shutdown_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	get_tree().quit()
	
func get_current_timestep():
	return current_step
