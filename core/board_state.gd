extends Node

#Script que armazena a lógica por trás do tabuleiro, pontuação e validação de jogadas. 
#Cada jogador possuirá uma instância de board_state

class BoardState:
	var h_lines : Array # Matriz das linhas horizontais
	var v_lines : Array # Matriz das linhas verticais
	var boxes: Array # Matriz das caixas já formadas
	
	var width: int
	var height: int
	
	func _init(w:int, h:int):
		width = w
		height = h
		
		h_lines = []
		v_lines = []
		boxes = []
	
	# Função que inicializa um tabuleiro
	func _create_game():
		
		# Inicializando as linhas horizontais do tabuleiro
		h_lines.clear()
		
		# Os laços de preenchimento das matrizes vão até width - 1 pois se há N pontos no máximo
		# podem se traçar N-1 retas na mesma linha ou na mesma coluna
		
		for i in range(width - 1):
			var column: Array[int] = []
			column.resize(height)
			column.fill(0)
			h_lines.append(column)
			
		# Inicializando as linhas verticais do tabuleiro
		v_lines.clear()
		for i in range(width):
			var column : Array[int] = []
			column.resize(height - 1)
			column.fill(0)
			v_lines.append(column)

		# Inicializando os quadrados
		boxes.clear()
		for i in range(width - 1):
			var column : Array[int] = []
			column.resize(height - 1)
			column.fill(0)
			boxes.append(column)
			
	# Função para validar se o movimento é possível
	func is_move_legal(tipo: String, x: int, y: int) -> bool:
		if tipo == "h":
			return h_lines[x][y] == 0
		return v_lines[x][y] == 0
