extends Control

var agreement_accepted = false
# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/VSplitContainer/HSplitContainer/Accept.pressed.connect(_on_agreement_accepted)
	$MarginContainer/VSplitContainer/HSplitContainer/Refuse.pressed.connect(_on_agreement_refused)
	var connection_handler = load("res://gym_connection_handler.tscn")
	# TODO: when adding this child, an error pops up.
	#get_parent().add_child(connection_handler)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_agreement_accepted():
	# TODO: not found
	agreement_accepted = true
	get_tree().change_scene_to_file("res://Scenes/dungeon_crawler.tscn")

func _on_agreement_refused():
	get_tree().quit()

func is_agreement_accepted():
	return agreement_accepted
