# Player.gd - Anexado ao nó Player
extends CharacterBody2D

@export var Speed : float = 20.0 # Ajuste a velocidade conforme necessário

# As variáveis relacionadas ao auto_move e ao caminho não são mais necessárias aqui
# var current_path_nodes : Array = []
# var current_target_index = 0
# var auto_move = false

# A referência ao tilemap_node também não é mais necessária para este script simplificado
# @onready var tilemap_node: TileMap = get_parent().get_node_or_null("Floor2TileMap") if get_parent() else null

func _physics_process(delta: float) -> void:
	# Movimento manual por teclado
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1
	
	if input_direction != Vector2.ZERO:
		input_direction = input_direction.normalized()
		velocity = input_direction * Speed
	else:
		# Para o jogador se não houver input.
		# Se quiser um movimento mais suave ao parar, use move_toward:
		# velocity = velocity.move_toward(Vector2.ZERO, ALGUMA_FRICCAO * delta)
		velocity = Vector2.ZERO 

	move_and_slide()

# A função follow_path não é mais necessária, então pode ser removida.
# func follow_path(new_path_tile_coords: Array):
#	 print("Player: Recebeu novo caminho com ", new_path_tile_coords.size(), " nós.")
#	 current_path_nodes = new_path_tile_coords
#	 current_target_index = 0
#	 if not current_path_nodes.is_empty():
#		 auto_move = true
#	 else:
#		 auto_move = false
