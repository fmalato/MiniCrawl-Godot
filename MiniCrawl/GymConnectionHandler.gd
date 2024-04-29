extends Node


const HOSTNAME = "127.0.0.1"
const PORT = 5555

@onready var _server_init: bool = false

@onready var stream_peer: StreamPeerTCP = StreamPeerTCP.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	await _init_server()
	_server_init = true

func _three_way_handshake():
	var err = stream_peer.connect_to_host(HOSTNAME, PORT)
	while stream_peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		stream_peer.poll()
	var message = JSON.stringify({"type": "handshake", "message": "SYN"}).to_utf8_buffer()
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	var response = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	if response["message"] == "SYN/ACK":
		message = JSON.stringify({"type": "handshake", "message": "ACK"}).to_utf8_buffer()
		stream_peer.put_data(message)
	else:
		print("Received wrong message during handshake.")
	
func _init_server():
	get_tree().set_pause(true)
	await _three_way_handshake()
	get_tree().set_pause(false)
	
func set_window_coordinates(window_position, window_size):
	get_tree().set_pause(true)
	var payload = JSON.stringify({"type": "config", "message": "SET_WINDOW_COORDS", "pos_x": window_position.x, "pos_y": window_position.y, "width": window_size.x, "height": window_size.y}).to_utf8_buffer()
	stream_peer.put_data(payload)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	# Decode message
	var floor_data = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return floor_data
	
func get_floor_data():
	get_tree().set_pause(true)
	var message = JSON.stringify({"type": "data_request", "message": "FLOOR_DATA_REQUEST"}).to_utf8_buffer()
	# TODO: how to remove redundant code without incurring in async problems?
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	# Decode message
	var floor_data = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return floor_data

func get_agent_action():
	get_tree().set_pause(true)
	get_viewport().get_texture().get_image().save_jpg("res://tmp.jpg", 0.35)
	#var frame = get_viewport().get_texture().get_image().get_data()
	var message = JSON.stringify({"type": "data_request", "message": "ACTION_REQUEST"}).to_utf8_buffer()
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	var action = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return action
	
func get_level_name():
	get_tree().set_pause(true)
	var message = JSON.stringify({"type": "data_request", "message": "LEVEL_NAME_REQUEST"}).to_utf8_buffer()
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	var response = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return response

func alert_new_level():
	get_tree().set_pause(true)
	var message = JSON.stringify({"type": "completion", "message": "NEW_LEVEL", "success": "True"}).to_utf8_buffer()
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	# Decode message
	var response = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return response
	
func start_recording():
	get_tree().set_pause(true)
	var message = JSON.stringify({"type": "config", "message": "START_RECORDING"}).to_utf8_buffer()
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	# Decode message
	var response = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return response

func request_shutdown():
	get_tree().set_pause(true)
	var message = JSON.stringify({"type": "completion", "message": "SHUTDOWN", "success": "False"}).to_utf8_buffer()
	stream_peer.put_data(message)
	while stream_peer.get_available_bytes() == 0:
		stream_peer.poll()
	# Decode message
	var response = JSON.parse_string(stream_peer.get_utf8_string(stream_peer.get_available_bytes()))
	get_tree().set_pause(false)
	
	return response
	
func confirm_shutdown():
	get_tree().set_pause(true)
	var message = JSON.stringify({"type": "completion", "message": "ACK_SHUTDOWN"}).to_utf8_buffer()
	stream_peer.put_data(message)
	get_tree().set_pause(false)
	
func is_server_init():
	return _server_init
