extends Area2D

func _on_body_entered(body: PhysicsBody2D) -> void:
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/floor1.tscn")
