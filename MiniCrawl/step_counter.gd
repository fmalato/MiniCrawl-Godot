extends Label

@onready var current_scene = null
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_scene != null:
		set_text("Step: " + str(get_parent().get_current_timestep()))
