# graph.gd - Anexado ao nó Floor2 (ou similar)
extends Node2D

# --- REFERÊNCIAS AOS NÓS DA CENA ---
@onready var tilemap: TileMap = $Floor2TileMap
@onready var player = $Player 
@onready var path_display_line: Line2D = $PathDisplayLine

# --- VARIÁVEIS DO SCRIPT ---
var logic_map: Array = []

# --- FUNÇÃO DE INICIALIZAÇÃO ---
func _ready():
	# Configura a aparência da linha para ser pontilhada
	if is_instance_valid(path_display_line):
		var linha_textura = load("res://assets/ponto_1px_alternado.png") 
		
		if linha_textura:
			path_display_line.texture = linha_textura
			path_display_line.texture_mode = Line2D.LINE_TEXTURE_TILE # <-- CORRIGIDO AQUI
			path_display_line.width = 1.0 
			path_display_line.default_color = Color.YELLOW 
			path_display_line.antialiased = false 
		else:
			printerr("graph.gd: ERRO AO CARREGAR TEXTURA - res://ponto_1px_alternado.png não encontrada!")
	else:
		printerr("graph.gd: Nó PathDisplayLine não encontrado ou inválido!")

	# 1. Gera a representação lógica do mapa para pathfinding
	generate_logic_map()

	if logic_map.is_empty() or (logic_map.size() > 0 and logic_map[0].is_empty()):
		printerr("graph.gd: logic_map está vazio ou não foi gerado corretamente.")
		return

	var bounds = tilemap.get_used_rect()
	var player_start_tile_coords = world_to_map(player.global_position)
	var dijkstra_start_node = player_start_tile_coords - bounds.position

	var logic_map_height = logic_map.size()
	var logic_map_width = logic_map[0].size()
	if not (dijkstra_start_node.x >= 0 and dijkstra_start_node.x < logic_map_width and \
			dijkstra_start_node.y >= 0 and dijkstra_start_node.y < logic_map_height):
		printerr("graph.gd: Posição inicial ajustada do jogador (", dijkstra_start_node, ") está fora dos limites da logic_map.")
		clear_path_line()
		return
	if logic_map[dijkstra_start_node.y][dijkstra_start_node.x] == 1:
		printerr("graph.gd: Posição inicial ajustada do jogador (", dijkstra_start_node, ") é um obstáculo.")
		clear_path_line()
		return

	var exits_tile_coords = [
		Vector2i(10, 60), 
		Vector2i(10, 22),   
		Vector2i(126, 33)  
	]

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
		print("Melhor caminho (coordenadas lógicas): ", best_path_logic_coords)
		draw_path_line(best_path_logic_coords)
	else:
		print("Nenhum caminho possível.")

# --- FUNÇÕES DE GERAÇÃO DO MAPA LÓGICO E PATHFINDING ---
# (generate_logic_map, dijkstra, get_neighbors - permanecem as mesmas da versão anterior completa)

func generate_logic_map():
	if not is_instance_valid(tilemap):
		printerr("generate_logic_map: Nó TileMap não é válido!")
		logic_map = [] 
		return

	var bounds = tilemap.get_used_rect()
	if bounds.size.x <= 0 or bounds.size.y <= 0: 
		printerr("generate_logic_map: TileMap não tem área útil (get_used_rect). logic_map ficará vazio.")
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
			
			var source_id = tilemap.get_cell_source_id(0, tile_pos_on_map)
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
			
			var cell_local_pos = tilemap.map_to_local(tile_pos_on_map)
			var cell_global_center_pos = tilemap.to_global(cell_local_pos + tilemap.tile_set.tile_size / 2.0)

			for danger_node in get_tree().get_nodes_in_group("Danger"):
				if danger_node is Node2D: 
					var danger_tile_pos = world_to_map(danger_node.global_position)
					if danger_tile_pos == tile_pos_on_map:
						is_obstacle = true
						break
			
			logic_map[y][x] = 1 if is_obstacle else 0

func dijkstra(start_logic: Vector2i, end_logic: Vector2i) -> Array:
	if logic_map.is_empty() or logic_map[0].is_empty(): return [] 
	
	var width = logic_map[0].size()
	var height = logic_map.size()

	if not (start_logic.x >= 0 and start_logic.x < width and start_logic.y >= 0 and start_logic.y < height and \
			end_logic.x >= 0 and end_logic.x < width and end_logic.y >= 0 and end_logic.y < height):
		printerr("Dijkstra: Coordenadas de início ou fim fora dos limites da logic_map.")
		return []
	if logic_map[start_logic.y][start_logic.x] == 1 or logic_map[end_logic.y][end_logic.x] == 1:
		printerr("Dijkstra: Início ou fim é um obstáculo na logic_map.")
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
		printerr("world_to_map: Nó TileMap não é válido!")
		return Vector2i.ZERO 
	return tilemap.local_to_map(tilemap.to_local(p_global_position))

func clear_path_line():
	if is_instance_valid(path_display_line):
		path_display_line.points = PackedVector2Array()
		path_display_line.visible = false

func draw_path_line(path_logic_coords: Array): 
	if not is_instance_valid(path_display_line) or not is_instance_valid(tilemap):
		printerr("draw_path_line: PathDisplayLine ou TileMap não são válidos.")
		return
	if path_logic_coords.is_empty():
		clear_path_line()
		return

	var bounds_pos = tilemap.get_used_rect().position
	var tile_size_vec2: Vector2 = Vector2(tilemap.tile_set.tile_size) 

	var world_points := PackedVector2Array()
	
	for logic_coord_i in path_logic_coords:
		var logic_coord: Vector2i = logic_coord_i
		var tilemap_cell_coord: Vector2i = logic_coord + Vector2i(bounds_pos) 
		var cell_center_local_to_tilemap: Vector2 = tilemap.map_to_local(tilemap_cell_coord) + tile_size_vec2 / 2.0
		var point_local_to_floor2: Vector2 = tilemap.position + cell_center_local_to_tilemap
		world_points.append(point_local_to_floor2)

	path_display_line.points = world_points
	path_display_line.visible = true
	# A configuração da textura, cor, etc., já foi feita em _ready()

# --- SINAL ---
func _on_fire_body_entered(body: Node2D) -> void:
	pass
