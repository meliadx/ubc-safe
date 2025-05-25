extends Node2D

@onready var stairs_area = $StairTrigger
var can_use_stairs = false

func _on_stair_trigger_body_entered(body):
	if body.name == "Player":
		can_use_stairs = true

func _on_stair_trigger_body_exited(body):
	if body.name == "Player":
		can_use_stairs = false

func _process(delta):
	if can_use_stairs and Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene_to_file("res://floor1.tscn")
