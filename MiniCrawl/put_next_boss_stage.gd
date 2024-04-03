extends Node3D

var colors = ["RED", "GREEN", "BLUE", "YELLOW"]
@onready var prompt: Label3D = $Prompt

# Called when the node enters the scene tree for the first time.
func _ready():
	var target1 = colors.pick_random()
	colors.erase(target1)
	var target2 = colors.pick_random()
	prompt.set_text(target1.to_upper() + "\nnear\n" + target2.to_upper())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
