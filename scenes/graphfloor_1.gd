# Nomeie este script como desejar (ex: graph.gd, floor1_graph.gd)
# Anexe-o ao nó principal do seu andar (ex: Floor1 ou Floor2)
extends Node2D

# --- REFERÊNCIAS AOS NÓS DA CENA ---
# VERIFIQUE SE OS NOMES APÓS O '$' CORRESPONDEM EXATAMENTE AOS SEUS NÓS NA ÁRVORE DE CENA!
# Estes nós devem ser filhos diretos do nó que tem este script.

@onready var tilemap: TileMap = $Floor1TileMap # MUDE AQUI para o nome do TileMap deste andar
@onready var player = $Player                  # MUDE AQUI para o nome do seu nó Player
@onready var path_display_line: Line2D = $PathDisplayLine # MUDE AQUI para o nome do seu nó Line2D

# --- VARIÁVEIS DO SCRIPT ---
var logic_map: Array = [] # Matriz com 0 (livre) e 1 (obstáculo)

# --- FUNÇÃO DE INICIALIZAÇÃO ---
func _ready():
	# Configura a aparência da linha para ser pontilhada
	if is_instance_valid(path_display_line):
		# Substitua "ponto_1px_alternado.png" pelo nome do seu arquivo de textura, se for diferente.
		# Certifique-se que este arquivo está na raiz do seu projeto (res://)
		# ou ajuste o caminho se estiver em uma subpasta (ex: "res://assets/ponto_1px_alternado.png")
		var linha_textura = load("res://assets/ponto_1px_alternado.png") 
		
		if linha_textura:
			path_display_line.texture = linha_textura
			path_display_line.texture_mode = Line2D.LINE_TEXTURE_TILE 
			path_display_line.width = 1.0 
			path_display_line.default_color = Color.YELLOW # Defina a cor desejada para os pontos
			path_display_line.antialiased = false 
		else:
			printerr(name + ": ERRO AO CARREGAR TEXTURA - res://ponto_1px_alternado.png não encontrada!")
	else:
		printerr(name + ": Nó PathDisplayLine não encontrado ou inválido!")

	# 1. Gera a representação lógica do mapa para pathfinding
	generate_logic_map()

	if logic_map.is_empty() or (logic_map.size() > 0 and logic_map[0].is_empty()):
		printerr(name + ": logic_map está vazio ou não foi gerado corretamente.")
		return

	var bounds = tilemap.get_used_rect()
	if not is_instance_valid(player):
		printerr(name + ": Nó Player não é válido ou não encontrado!")
		return
	var player_start_tile_coords = world_to_map(player.global_position)
	
	var dijkstra_start_node = player_start_tile_coords - bounds.position

	var logic_map_height = logic_map.size()
	var logic_map_width = logic_map[0].size()
	if not (dijkstra_start_node.x >= 0 and dijkstra_start_node.x < logic_map_width and \
			dijkstra_start_node.y >= 0 and dijkstra_start_node.y < logic_map_height):
		printerr(name + ": Posição inicial ajustada do jogador (", dijkstra_start_node, ") está fora dos limites da logic_map.")
		clear_path_line()
		return
	if logic_map[dijkstra_start_node.y][dijkstra_start_node.x] == 1:
		printerr(name + ": Posição inicial ajustada do jogador (", dijkstra_start_node, ") é um obstáculo.")
		clear_path_line()
		return

	# #########################################################################
	# ##  IMPORTANTE: ATUALIZE AS COORDENADAS DAS SAÍDAS ABAIXO              ##
	# ##  Use as coordenadas (X,Y) dos TILES das suas saídas REAIS          ##
	# ##  para o mapa DESTE ANDAR específico.                                ##
	# #########################################################################
	var exits_tile_coords = [
		Vector2i(127, 34),  # EXEMPLO: Coordenada da Saída de Emergência (branca)
		Vector2i(83, 59),   # EXEMPLO: Coordenada da Porta Marrom 1
		Vector2i(47, 59)    # EXEMPLO: Coordenada da Porta Marrom 2
		# Adicione ou remova conforme as saídas do seu mapa atual
	]
	# Estas são as coordenadas COMPLETAS do tilemap, como você as vê no editor.
	# O script subtrai 'bounds.position' depois para usar com a logic_map.

	var best_path_logic_coords: Array = []
	var shortest_length = INF

	for exit_tc in exits_tile_coords:
		var dijkstra_end_node = exit_tc - bounds.position

		if not (dijkstra_end_node.x >= 0 and dijkstra_end_node.x < logic_map_width and \
				dijkstra_end_node.y >= 0 and dijkstra_end_node.y < logic_map_height):
			continue
		if logic_map[dijkstra_end_node.y][dijkstra_end_node.x] == 1:
			continue
		
		var current_path_logic_coords = dijkstra(dijkstra_start_node, dijkstra_end_node)
		if not current_path_logic_coords.is_empty() and current_path_logic_coords.size() < shortest_length:
			best_path_logic_coords = current_path_logic_coords
			shortest_length = current_path_logic_coords.size()

	clear_path_line()

	if not best_path_logic_coords.is_empty():
		print(name + " - Melhor caminho (coordenadas lógicas): ", best_path_logic_coords)
		draw_path_line(best_path_logic_coords)
	else:
		print(name + " - Nenhum caminho possível.")
# Em graph.gd ou floor1_graph.gd
# Dentro da função _ready()

	# ... (cálculo do best_path_logic_coords e shortest_length) ...

	clear_path_line()

	if not best_path_logic_coords.is_empty():
		print(name + " - Melhor caminho (coordenadas lógicas): ", best_path_logic_coords)
		draw_path_line(best_path_logic_coords)

		# CONVERTE O CAMINHO PARA COORDENADAS COMPLETAS DO TILEMAP
		var shortest_path_tile_coords: Array = []
		# 'bounds' deve ter sido definido anteriormente em _ready() com tilemap.get_used_rect()
		# Se 'bounds' não estiver mais no escopo aqui, redefina: 
		var current_bounds_pos = tilemap.get_used_rect().position 
		for logic_coord_i in best_path_logic_coords:
			var logic_coord: Vector2i = logic_coord_i
			shortest_path_tile_coords.append(logic_coord + current_bounds_pos)
		# No script principal do PRIMEIRO ANDAR (ex: floor1_graph.gd)

# ... (suas variáveis @onready var tilemap, player, path_display_line, etc. devem estar aqui) ...

	# ---- INÍCIO DA LÓGICA DE POSICIONAMENTO DO JOGADOR AO CHEGAR DE OUTRO ANDAR ----
	if Engine.has_meta("player_target_spawn_name"):
		var spawn_name_from_meta = Engine.get_meta("player_target_spawn_name")
		Engine.remove_meta("player_target_spawn_name") # Lê e depois remove o metadado

		if not spawn_name_from_meta.is_empty():
			# Tenta encontrar o nó Player e o Marker2D de spawn
			# Certifique-se que o nó Player no Floor1 se chama "Player" ou ajuste o caminho
			var player_node = get_node_or_null("Player") 
			var spawn_marker = get_node_or_null(spawn_name_from_meta) # Busca o Marker2D pelo nome guardado

			if is_instance_valid(player_node) and is_instance_valid(spawn_marker):
				print(name + ": Posicionando jogador '", player_node.name, "' no marcador '", spawn_marker.name, "'")
				player_node.global_position = spawn_marker.global_position
			elif not is_instance_valid(player_node):
				printerr(name + ": Nó do jogador ('Player') não encontrado no Floor1 para o spawn.")
			elif not is_instance_valid(spawn_marker):
				printerr(name + ": Marcador de spawn '", spawn_name_from_meta, "' não encontrado no Floor1. Verifique os nomes dos Marker2Ds e a configuração da escada no Floor2.")
		else:
			print(name + ": Nome do spawn vindo dos metadados estava vazio.")
	# ---- FIM DA LÓGICA DE POSICIONAMENTO DO JOGADOR ----
	
	# ... (resto do seu código _ready, como a chamada para generate_logic_map() e o cálculo do caminho) ...
	# É importante que o jogador seja posicionado ANTES de calcular o caminho se o caminho
	# depender da posição inicial do jogador.

func generate_logic_map():
	if not is_instance_valid(tilemap):
		printerr(name + " - generate_logic_map: Nó TileMap não é válido!")
		logic_map = [] 
		return

	var bounds = tilemap.get_used_rect()
	if bounds.size.x <= 0 or bounds.size.y <= 0: 
		printerr(name + " - generate_logic_map: TileMap não tem área útil (get_used_rect). logic_map ficará vazio.")
		logic_map = []
		return
		
	var width = int(bounds.size.x)
	var height = int(bounds.size.y)

	logic_map.clear()
	logic_map.resize(height)

	for y in range(height):
		logic_map[y] = []
		logic_map[y].resize(width) 
		for x in range(width):
			var tile_pos_on_map = Vector2i(int(bounds.position.x + x), int(bounds.position.y + y))
			var is_obstacle = false
			
			var source_id = tilemap.get_cell_source_id(0, tile_pos_on_map) # Camada 0
			if source_id != -1: 
				var atlas_coords = tilemap.get_cell_atlas_coords(0, tile_pos_on_map)
				var alternative_tile = tilemap.get_cell_alternative_tile(0, tile_pos_on_map)
				var tile_set: TileSet = tilemap.tile_set
				if is_instance_valid(tile_set): 
					var tile_set_source : TileSetSource = tile_set.get_source(source_id)
					if tile_set_source is TileSetAtlasSource: 
						var atlas_source : TileSetAtlasSource = tile_set_source
						var tile_data: TileData = atlas_source.get_tile_data(atlas_coords, alternative_tile)
						if tile_data: 
							if tile_data.get_collision_polygons_count(0) > 0:
								is_obstacle = true
			
			for danger_node in get_tree().get_nodes_in_group("Danger"):
				if danger_node is Node2D: 
					var danger_tile_coord = world_to_map(danger_node.global_position)
					if danger_tile_coord == tile_pos_on_map:
						is_obstacle = true
						break
			
			logic_map[y][x] = 1 if is_obstacle else 0

func dijkstra(start_logic: Vector2i, end_logic: Vector2i) -> Array:
	if logic_map.is_empty() or logic_map[0].is_empty(): return [] 
	
	var width = logic_map[0].size()
	var height = logic_map.size()

	if not (start_logic.x >= 0 and start_logic.x < width and start_logic.y >= 0 and start_logic.y < height and \
			end_logic.x >= 0 and end_logic.x < width and end_logic.y >= 0 and end_logic.y < height):
		return []
	if logic_map[start_logic.y][start_logic.x] == 1 or logic_map[end_logic.y][end_logic.x] == 1:
		return []

	var distances: Dictionary = {}
	var previous: Dictionary = {}
	var queue: Array = []

	for y_idx in range(height):
		for x_idx in range(width):
			distances[Vector2i(x_idx, y_idx)] = INF
	
	distances[start_logic] = 0
	queue.append(start_logic)
	var visited_nodes = {} 

	while not queue.is_empty():
		queue.sort_custom(func(a, b): return distances[a] < distances[b])
		var current: Vector2i = queue.pop_front()

		if current == end_logic: break
		if visited_nodes.has(current): continue
		visited_nodes[current] = true

		for neighbor in get_neighbors(current, width, height):
			if logic_map[neighbor.y][neighbor.x] == 1: continue

			var alt_dist = distances[current] + 1
			if alt_dist < distances[neighbor]:
				distances[neighbor] = alt_dist
				previous[neighbor] = current
				if not visited_nodes.has(neighbor) and not neighbor in queue:
					queue.append(neighbor)
	
	var path: Array = []
	var u: Vector2i = end_logic
	if distances.get(u, INF) == INF: return [] 

	while previous.has(u):
		path.insert(0, u)
		u = previous[u]
	
	if u == start_logic: path.insert(0, u) 
	elif start_logic == end_logic and distances.get(start_logic, INF) == 0: return [start_logic]
	elif path.is_empty() and start_logic != end_logic: return []

	return path


func get_neighbors(pos: Vector2i, width: int, height: int) -> Array:
	var neighbors: Array = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT] 
	for dir in directions:
		var n = pos + dir
		if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height:
			neighbors.append(n)
	return neighbors

# --- FUNÇÕES UTILITÁRIAS E DE DESENHO ---

func world_to_map(p_global_position: Vector2) -> Vector2i:
	if not is_instance_valid(tilemap):
		printerr(name + " - world_to_map: Nó TileMap não é válido!")
		return Vector2i.ZERO 
	return tilemap.local_to_map(tilemap.to_local(p_global_position))

func clear_path_line():
	if is_instance_valid(path_display_line):
		path_display_line.points = PackedVector2Array()
		path_display_line.visible = false

func draw_path_line(path_logic_coords: Array): 
	if not is_instance_valid(path_display_line) or not is_instance_valid(tilemap):
		printerr(name + " - draw_path_line: PathDisplayLine ou TileMap não são válidos.")
		return
	if path_logic_coords.is_empty():
		clear_path_line()
		return

	var bounds_pos = tilemap.get_used_rect().position
	var tile_size_vec2: Vector2 = Vector2(tilemap.tile_set.tile_size) 

	var points_for_line2d := PackedVector2Array()
	
	for logic_coord_i in path_logic_coords:
		var logic_coord: Vector2i = logic_coord_i
		var tilemap_cell_coord: Vector2i = logic_coord + Vector2i(bounds_pos) 
		var cell_center_local_to_tilemap: Vector2 = tilemap.map_to_local(tilemap_cell_coord) + tile_size_vec2 / 2.0
		var point_local_to_this_node: Vector2 = tilemap.position + cell_center_local_to_tilemap
		points_for_line2d.append(point_local_to_this_node)

	path_display_line.points = points_for_line2d
	path_display_line.visible = true

# --- SINAL (OPCIONAL - estava no seu script original) ---
# func _on_fire_body_entered(body: Node2D) -> void:
	# Se você conectar o sinal 'body_entered' de um nó 'Fire' a esta função,
	# este código será executado.
	# pass
