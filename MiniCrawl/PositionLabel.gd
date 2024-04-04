extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player_position = get_node("../Bob").global_position
	set_text("Position: (" + str(player_position.x) + ", " + str(player_position.y) + ", " + str(player_position.z) + ")")
