extends Node2D

@onready var tilemap = $Floor2TileMap
var logic_map = [] # Aqui vai ser nossa matriz com 0 (livre) e 1 (obstáculo), baseada no tilemap

func _ready():
	# Gera a matriz lógica do mapa, identificando onde pode e onde não pode andar
	generate_logic_map()

	# Pega a posição atual do player no formato do tilemap (coordenadas X e Y)
	var start = world_to_map($Player.global_position)

	# Lista com os possíveis destinos
	var exits = [
		Vector2i(10, 60),
		Vector2i(10, 22),
		Vector2i(126, 33)
	]

	# Aqui vamos guardar o melhor caminho encontrado e o tamanho dele
	var best_path = []
	var shortest_length = INF

	# Para cada destino, roda o Dijkstra e compara o tamanho do caminho
	for exit in exits:
		var path = dijkstra(start, exit)
		if path.size() > 0 and path.size() < shortest_length:
			best_path = path
			shortest_length = path.size()

	# Se achou algum caminho viável, manda o player seguir ele
	if best_path.size() > 0:
		print("Melhor caminho: ", best_path)
		$Player.follow_path(best_path)
	else:
		print("Nenhum caminho possível.")

# Converte uma posição global do jogo para coordenada do tilemap
func world_to_map(world_pos):
	return tilemap.local_to_map(to_local(world_pos))

# Gera a matriz lógica do mapa, marcando onde é livre (0) e onde é parede (1)
func generate_logic_map():
	var bounds = tilemap.get_used_rect()
	var width = bounds.size.x
	var height = bounds.size.y

	logic_map.resize(height)
	for y in range(height):
		logic_map[y] = []
		for x in range(width):
			var tile_pos = Vector2i(x + bounds.position.x, y + bounds.position.y)
			var tile_data = tilemap.get_cell_tile_data(0, tile_pos)

			var is_obstacle = false

			# Verifica se o tile tem colisão
			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				is_obstacle = true

			# Verifica se há fogo nesta posição (grupo "Danger")
			var world_pos = tilemap.map_to_local(tile_pos)
			for danger in get_tree().get_nodes_in_group("Danger"):
				if danger.global_position.floor() == tilemap.to_global(world_pos).floor():
					is_obstacle = true
					break

			# Marca 1 para obstáculo, 0 para livre
			logic_map[y].append(1 if is_obstacle else 0)

# Algoritmo de Dijkstra: calcula o menor caminho entre dois pontos
func dijkstra(start: Vector2i, end: Vector2i) -> Array:
	var width = logic_map[0].size()
	var height = logic_map.size()

	var visited = {}
	var distances = {}
	var previous = {}
	var queue = []

	# Inicializa as distâncias como infinito e marca todos como não visitados
	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			distances[pos] = INF
			visited[pos] = false
	distances[start] = 0
	queue.append(start)

	while queue.size() > 0:
		# Ordena a fila para pegar o nó com menor distância
		queue.sort_custom(func(a, b): return distances[a] < distances[b])
		var current = queue.pop_front()

		if current == end:
			break

		if visited[current]:
			continue
		visited[current] = true

		# Verifica vizinhos válidos (não visitados, não obstáculos)
		for neighbor in get_neighbors(current, width, height):
			if visited[neighbor]:
				continue
			if logic_map[neighbor.y][neighbor.x] == 1:
				continue # Se for obstáculo, ignora

			var alt = distances[current] + 1
			if alt < distances[neighbor]:
				distances[neighbor] = alt
				previous[neighbor] = current
				queue.append(neighbor)

	# Reconstrói o caminho a partir do destino
	var path = []
	var u = end
	while previous.has(u):
		path.insert(0, u)
		u = previous[u]

	if path.size() > 0:
		path.insert(0, start)
		return path
	else:
		return []

# Retorna os vizinhos diretos (cima, baixo, esquerda, direita) dentro dos limites do mapa
func get_neighbors(pos: Vector2i, width: int, height: int) -> Array:
	var neighbors = []
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for dir in directions:
		var n = pos + dir
		if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height:
			neighbors.append(n)
	return neighbors
	
func _on_fire_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
