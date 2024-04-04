extends Node3D

const COLORS = {
	"red": Color("ff0000"),
	"yellow": Color("fffb00"),
	"green": Color("00800b"),
	"blue": Color("0006bf"),
	"purple": Color("6200ff"),
	"grey": Color("4d4d4d"),
}

const OBJECTS = ["Ball", "Cube", "Prism"]

@onready var level_counter: Label = $LevelCounter
@onready var player: CharacterBody3D = $Bob
@onready var prompt: Label3D = $Prompt
@onready var target: Node3D = null

@onready var current_timestep: int = 0

var current_level = 0
var last_player_rotarion = null
var request_in_progress = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$LevelCompletedRequest.request_completed.connect(_on_level_ended_completed)
	$LevelFailedRequest.request_completed.connect(_on_level_failed_completed)
	
	var target_object = OBJECTS.pick_random()
	var target_color = COLORS.keys().pick_random()
	target = get_node(target_object + "s/" + target_color.capitalize())
	
	last_player_rotarion = player.rotation
	
	prompt.set_text("Collect\n" + target_color.to_upper() + " " + target_object.to_upper())
	level_counter.set_text("Level: " + str(current_level))

func _physics_process(delta):
	if check_player_movement():
			current_timestep += 1
	if player.in_hand != null:
		if player.in_hand == target:
			var payload = JSON.stringify({"success": "True"})
			if !request_in_progress:
				$LevelCompletedRequest.request("http://127.0.0.1:5555/level_completed", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
		else:
			var payload = JSON.stringify({"message": "SHUTDOWN_REQUEST", "success": "False"})
			if !request_in_progress:
				$LevelFailedRequest.request("http://127.0.0.1:5555/shutdown", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)

func _on_level_ended_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	request_in_progress = false
	get_tree().change_scene_to_file("res://dungeon_crawler.tscn")
	
func _on_level_failed_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	request_in_progress = false
	get_tree().quit()
	
func check_player_movement():
	var has_moved = false
	if (player.rotation - last_player_rotarion).length() > 0 or player.get_last_motion().length() > 0:
		has_moved = true
		
	return has_moved

func get_current_timestep():
	return current_timestep

func get_current_level():
	return current_level
