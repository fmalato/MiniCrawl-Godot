extends Node3D

const MAX_TIMESTEPS = 1000

var colors = ["red", "green", "blue", "yellow"]
@onready var level_counter: Label = $LevelCounter
@onready var prompt: Label3D = $Prompt
@onready var player: CharacterBody3D = $Bob
var target1_name = null
var target2_name = null
var target1 = null
var target2 = null

var targets_intersect = false

@onready var current_timestep: int = 0
@onready var current_level: int = 0

var last_player_rotarion = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$LevelCompletedRequest.request_completed.connect(_on_level_ended_completed)
	$LevelFailedRequest.request_completed.connect(_on_level_failed_completed)
	
	target1_name = colors.pick_random()
	colors.erase(target1_name)
	target2_name = colors.pick_random()
	
	target1 = get_node("Cubes/" + target1_name.capitalize())
	target2 = get_node("Cubes/" + target2_name.capitalize())
	get_node("Cubes/" + target2_name.capitalize() + "/NearbyArea").body_entered.connect(_on_body_entered)
	
	last_player_rotarion = player.rotation
	
	prompt.set_text(target1_name.to_upper() + "\nnear\n" + target2_name.to_upper())
	level_counter.set_text("Level: " + str(current_level))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if check_player_movement():
			current_timestep += 1
	if Input.is_key_pressed(KEY_F7) or targets_intersect:
		var payload = JSON.stringify({"success": "True"})
		$LevelCompletedRequest.request("http://127.0.0.1:5555/level_completed", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
	if current_timestep > MAX_TIMESTEPS:
		var payload = JSON.stringify({"message": "SHUTDOWN_REQUEST", "success": "False"})
		$LevelFailedRequest.request("http://127.0.0.1:5555/shutdown", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)

func _on_level_ended_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	get_tree().change_scene_to_file("res://dungeon_crawler.tscn")
	
func _on_level_failed_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	get_tree().quit()

func _on_body_entered(body):
	if body == target1:
		targets_intersect = true
		
func check_player_movement():
	var has_moved = false
	if (player.rotation - last_player_rotarion).length() > 0 or player.get_last_motion().length() > 0:
		has_moved = true
		
	return has_moved
	
func get_current_timestep():
	return current_timestep

func get_current_level():
	return current_level
