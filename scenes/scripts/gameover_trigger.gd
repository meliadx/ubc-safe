extends Area2D

func _on_body_entered(body: Node):
	if body.name == "Player":
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
