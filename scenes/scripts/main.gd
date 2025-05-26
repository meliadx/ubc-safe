extends Node2D

@onready var tilemap = $Floor2TileMap
var logic_map = []

func _ready():
	generate_logic_map()
	var start = world_to_map($Player.global_position)
	var end = Vector2i(10, 5) 

	var path = dijkstra(start, end)
	if path:
		print("Caminho encontrado: ", path)
		$Player.follow_path(path)
	else:
		print("Nenhum caminho possível.")

func world_to_map(world_pos):
	return tilemap.local_to_map(to_local(world_pos))

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

			if tile_data and tile_data.get_collision_polygons_count(0) > 0:
				logic_map[y].append(1) # Obstáculo
			else:
				logic_map[y].append(0) # Livre

func dijkstra(start: Vector2i, end: Vector2i) -> Array:
	var width = logic_map[0].size()
	var height = logic_map.size()

	var visited = {}
	var distances = {}
	var previous = {}
	var queue = []

	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			distances[pos] = INF
			visited[pos] = false
	distances[start] = 0
	queue.append(start)

	while queue.size() > 0:
		queue.sort_custom(func(a, b): return distances[a] < distances[b])
		var current = queue.pop_front()

		if current == end:
			break

		if visited[current]:
			continue
		visited[current] = true

		for neighbor in get_neighbors(current, width, height):
			if visited[neighbor]:
				continue
			if logic_map[neighbor.y][neighbor.x] == 1:
				continue # Obstáculo

			var alt = distances[current] + 1
			if alt < distances[neighbor]:
				distances[neighbor] = alt
				previous[neighbor] = current
				queue.append(neighbor)

	# Reconstruir caminho
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
		
func get_neighbors(pos: Vector2i, width: int, height: int) -> Array:
	var neighbors = []
	var directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

	for dir in directions:
		var n = pos + dir
		if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height:
			neighbors.append(n)
	return neighbors


func _on_commons_stairs_2_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_common_stairs_1_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
