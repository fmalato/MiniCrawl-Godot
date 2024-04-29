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

@onready var player: CharacterBody3D = $Bob
@onready var prompt: Label3D = $Prompt
@onready var target: Node3D = null

@onready var current_timestep: int = 0

var current_level = 0
var last_player_rotarion = null
var request_in_progress = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var target_object = OBJECTS.pick_random()
	var target_color = COLORS.keys().pick_random()
	target = get_node(target_object + "s/" + target_color.capitalize())
	
	last_player_rotarion = player.rotation
	
	prompt.set_text("Collect\n" + target_color.to_upper() + " " + target_object.to_upper())

func _physics_process(delta):
	if check_player_movement():
			current_timestep += 1
	if player.in_hand != null:
		if player.in_hand == target:
			get_parent().has_agent_succeded = true
			get_parent().is_child_scene_done = true
		else:
			get_parent().has_agent_succeded = false
			get_parent().is_child_scene_done = true
	last_player_rotarion = player.rotation

func _on_level_ended_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	request_in_progress = false
	get_tree().change_scene_to_file("res://Scenes/dungeon_crawler.tscn")
	
func _on_level_failed_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	request_in_progress = false
	get_tree().quit()
	
func check_player_movement():
	var has_moved = false
	if (player.rotation - last_player_rotarion).length() > 0 or player.get_last_motion().length() > 0:
		has_moved = true
		
	return has_moved
	
func is_server_init():
	return get_parent().is_server_init()

func get_current_timestep():
	return current_timestep
