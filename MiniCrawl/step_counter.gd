extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_text("Step: " + str(get_parent().get_current_timestep()))
