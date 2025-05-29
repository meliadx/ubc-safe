extends Button

func _ready():
	pass

func _pressed():
	get_tree().change_scene_to_file("res://scenes/floor2.tscn")
