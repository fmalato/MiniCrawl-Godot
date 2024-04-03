# https://gist.github.com/WeaponsTheyFear/6d6a43cd39eee7010fc5c5a8393e5117
class_name Core
extends Node

const window_size = Vector2i(800, 600)
var window_position = null
var server_init = false

func _ready():
	$HttpRequests/InitServerRequest.request_completed.connect(_on_init_server_completed)
	# Set window size and position
	var screen_size = DisplayServer.screen_get_size()
	DisplayServer.window_set_size(window_size)
	window_position = Vector2i(screen_size[0] / 2 - window_size[0] / 2, screen_size[1] / 2 - window_size[1] / 2)
	get_window().position = window_position
	var payload = JSON.stringify({"pos_x": window_position.x, "pos_y": window_position.y, "width": window_size.x, "height": window_size.y})
	#get_tree().paused = true
	$HttpRequests/InitServerRequest.request("http://127.0.0.1:5555/init", ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
	#get_tree().paused = false

func _physics_process(delta):
	pass

func _on_init_server_completed(result, response_code, headers, body):
	var data = JSON.parse_string(body.get_string_from_utf8())
	print("Server initialized!")
	
func is_server_init():
	return server_init
