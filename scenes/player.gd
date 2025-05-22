extends CharacterBody2D

@export var Speed : float = 20.0

var path : Array = []
var current_target_index = 0
var auto_move = false

func _physics_process(delta: float) -> void:
	if auto_move and path.size() > 0 and current_target_index < path.size():
		var tile_pos = path[current_target_index]
		var target = get_parent().get_node("Floor2TileMap").map_to_local(tile_pos) + Vector2(8, 8) 
		var direction = (target - global_position).normalized()
		velocity = direction * Speed

		if global_position.distance_to(target) < 2.0:
			current_target_index += 1
			if current_target_index >= path.size():
				auto_move = false
				velocity = Vector2.ZERO
	else:
		# Movimento manual por teclado
		var direction = Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			direction.x += 1
		if Input.is_action_pressed("ui_left"):
			direction.x -= 1
		if Input.is_action_pressed("ui_down"):
			direction.y += 1
		if Input.is_action_pressed("ui_up"):
			direction.y -= 1
		direction = direction.normalized()
		velocity = direction * Speed

	move_and_slide()

func follow_path(new_path: Array):
	path = new_path
	current_target_index = 0
	auto_move = true
