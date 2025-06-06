# Static variables to hold data across scene loads
static var current_level_shortest_path: Array = []
static var player_actual_path_tiles: Array = []

# Chamado no início de cada nível pelo script do andar (graph.gd/floorX_graph.gd)
static func start_level(shortest_path_for_level: Array):
	current_level_shortest_path = shortest_path_for_level
	player_actual_path_tiles.clear() # Limpa o caminho do jogador do nível anterior
	print("GlobalGameData: Nível iniciado. Caminho mais curto com ", shortest_path_for_level.size(), " tiles.")
	# print("Caminho mais curto: ", shortest_path_for_level) # Para debug

# Chamado pelo script do Player cada vez que ele entra em um novo tile
static func record_player_tile(tile_coord: Vector2i):
	# Só adiciona se for um tile diferente do último registrado
	if player_actual_path_tiles.is_empty() or player_actual_path_tiles.back() != tile_coord:
		player_actual_path_tiles.append(tile_coord)
		# print("GlobalGameData: Jogador visitou tile ", tile_coord) # Para debug

# Chamado pela tela de vitória/fim para obter as estatísticas
static func get_accuracy_stats() -> Dictionary:
	if current_level_shortest_path.is_empty():
		return {
			"accuracy": 0.0, 
			"lcs_length": 0, 
			"shortest_length": 0, 
			"player_path_length": player_actual_path_tiles.size()
		}

	var lcs_len = _calculate_lcs_length(player_actual_path_tiles, current_level_shortest_path)
	var accuracy_percent = 0.0
	if current_level_shortest_path.size() > 0: # Evita divisão por zero
		accuracy_percent = (float(lcs_len) / current_level_shortest_path.size()) * 100.0
	
	var stats = {
		"accuracy": accuracy_percent,
		"lcs_length": lcs_len,
		"shortest_length": current_level_shortest_path.size(),
		"player_path_length": player_actual_path_tiles.size()
	}
	print("GlobalGameData: Calculando precisão - ", stats)
	return stats

# Função estática interna para calcular o comprimento da Maior Subsequência Comum (LCS)
static func _calculate_lcs_length(seq1: Array, seq2: Array) -> int:
	var m = seq1.size()
	var n = seq2.size()
	
	if m == 0 or n == 0:
		return 0

	var dp_table = []
	dp_table.resize(m + 1)
	for i in range(m + 1):
		dp_table[i] = []
		dp_table[i].resize(n + 1)
		for j in range(n + 1): # Inicializa com zeros
			dp_table[i][j] = 0
			
	for i in range(1, m + 1):
		for j in range(1, n + 1):
			if seq1[i - 1] == seq2[j - 1]: # Compara os elementos (Vector2i)
				dp_table[i][j] = dp_table[i - 1][j - 1] + 1
			else:
				dp_table[i][j] = max(dp_table[i - 1][j], dp_table[i][j - 1])
				
	return dp_table[m][n]
