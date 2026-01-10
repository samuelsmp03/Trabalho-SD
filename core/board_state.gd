class_name BoardState
extends RefCounted

#Script que armazena a lógica por trás do tabuleiro, pontuação e validação de jogadas. 
#Cada jogador possuirá uma instância de board_state

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
	_create_game()

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
	
func apply_move(tipo: String, x: int, y: int, player_id: int) -> Array:
	var closed_boxes_coords = []
	
	if tipo == "h":
		h_lines[x][y] = player_id
		if _check_and_mark_box(x, y - 1, player_id): closed_boxes_coords.append(Vector2i(x, y - 1))
		if _check_and_mark_box(x, y, player_id): closed_boxes_coords.append(Vector2i(x, y))
	else:
		v_lines[x][y] = player_id
		if _check_and_mark_box(x - 1, y, player_id): closed_boxes_coords.append(Vector2i(x - 1, y))
		if _check_and_mark_box(x, y, player_id): closed_boxes_coords.append(Vector2i(x, y))
		
	return closed_boxes_coords

func _check_and_mark_box(bx: int, by: int, player_id: int) -> bool:
	# Verifica se as coordenadas do quadrado existem no grid
	if bx < 0 or bx >= width - 1 or by < 0 or by >= height - 1: return false
	# Se o quadrado já tem dono, ignora
	if boxes[bx][by] != 0: return false
	
	var top = h_lines[bx][by] != 0
	var bottom = h_lines[bx][by+1] != 0
	var left = v_lines[bx][by] != 0
	var right = v_lines[bx+1][by] != 0
	
	if top and bottom and left and right:
		boxes[bx][by] = player_id
		return true
	return false
