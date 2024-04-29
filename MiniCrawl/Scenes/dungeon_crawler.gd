# https://gist.github.com/WeaponsTheyFear/6d6a43cd39eee7010fc5c5a8393e5117
class_name Core
extends Node

@onready var connection_handler = $GymConnectionHandler
@onready var current_scene_instance = null
@onready var step_counter: Label = $StepCounter
@onready var level_counter: Label = $LevelCounter

var agent_controlled_by_human = true
var recording_started = false
var window_position = null
var server_init = false
var level_name = null
var is_active_scene = true
var is_child_scene_done = false
var has_agent_succeded = null
var record_dir = null

func _ready():
	Engine.physics_ticks_per_second = 60
	var window_size = null
	if agent_controlled_by_human:
		window_size = Vector2i(800, 600)
	else:
		window_size = Vector2i(160, 120)
		step_counter.set_visible(false)
		level_counter.set_visible(false)
	# Set window size and position
	var screen_size = DisplayServer.screen_get_size()
	DisplayServer.window_set_size(window_size)
	window_position = Vector2i(screen_size[0] / 2.0 - window_size[0] / 2.0, screen_size[1] / 2.0 - window_size[1] / 2.0)
	get_window().position = window_position
	while !connection_handler.is_server_init():
		continue
	server_init = true
	var response = connection_handler.set_window_coordinates(window_position, window_size)
	if response["message"] == "ALL_SET":
		record_dir = response["record_dir"]
		_call_next_scene(1)
	
func _physics_process(delta):
	if is_child_scene_done:
		get_tree().set_pause(true)
		await current_scene_instance.get_node("Bob").save_actions(record_dir)
		get_tree().set_pause(false)
		if has_agent_succeded:
			var response = connection_handler.alert_new_level()
			if response["message"] == "MAX_LEVEL_REACHED":
				connection_handler.confirm_shutdown()
				get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
				get_tree().quit()
			# TODO: why doesn't this stop when "MAX_LEVEL_REACHED" is received?
			else:
				await _call_next_scene(int(response["level"]))
		else:
			get_tree().set_pause(true)
			var response = connection_handler.request_shutdown()
			if response["message"] == "SHUTDOWN_COMPLETE":
				connection_handler.confirm_shutdown()
				get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
				get_tree().quit()
	
func _call_next_scene(current_level):
	var response = connection_handler.get_level_name()
	level_name = response["message"]
	var prefix = ""
	if level_name.find("boss_stage") != -1:
		prefix = "Boss/"
	var scene_name = "res://Scenes/" + prefix + level_name + ".tscn"
	if current_scene_instance != null:
		current_scene_instance.visible = false
		remove_child(current_scene_instance)
		current_scene_instance.queue_free()
	var current_scene = load(scene_name)
	current_scene_instance = current_scene.instantiate()
	add_child(current_scene_instance)
	current_scene_instance.visible = true
	current_scene_instance.global_position = Vector3(0, 0, 0)
	step_counter.current_scene = current_scene_instance
	level_counter.set_current_level(current_level) 
	is_child_scene_done = false
	has_agent_succeded = null

func is_server_init():
	return server_init
	
func get_current_timestep():
	return current_scene_instance.get_current_timestep()
