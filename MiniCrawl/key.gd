extends Area3D

const ROTATION_SPEED = 0.5

signal update_location(loc)

# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("update_location", self.global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	rotate_y(deg_to_rad(ROTATION_SPEED))

func step():
	rotate_y(deg_to_rad(ROTATION_SPEED))
