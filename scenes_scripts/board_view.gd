extends Control

@export var dot_scene: PackedScene
@export var line_scene: PackedScene
@export var box_scene: PackedScene

var board_logic: BoardState

var spacing: int = 100
var offset: Vector2 = Vector2(50, 50)

signal line_clicked(type: String, x: int, y: int)

func setup_view(w: int, h: int, logic_ref: BoardState) -> void:
	board_logic = logic_ref
	# Limpa o tabuleiro antes de gerar um novo
	for n in get_children(): 
		n.queue_free()
	
	# Gera as Linhas
	for i in range(w):
		for j in range(h):
			if i < w - 1: _spawn_line("h", i, j)
			if j < h - 1: _spawn_line("v", i, j)
			
	# Gera os Pontos
	for i in range(w):
		for j in range(h):
			var dot = dot_scene.instantiate()
			add_child(dot)
			dot.pivot_offset = dot.size / 2.0
			var dot_pos = Vector2(i * spacing, j * spacing) + offset
			dot.position = dot_pos - (dot.size / 2.0)

func _spawn_line(type: String, x: int, y: int) -> void:
	var line = line_scene.instantiate() as Button
	add_child(line) 

	var fill = line.get_node_or_null("Fill")
	if fill:
		fill.color = Color.WHITE


	
	line.pivot_offset = line.size / 2.0
	
	var line_pos = Vector2.ZERO
	if type == "h":
		line_pos = Vector2((x + 0.5) * spacing, y * spacing) + offset
		line.rotation_degrees = 0
	else:
		line_pos = Vector2(x * spacing, (y + 0.5) * spacing) + offset
		line.rotation_degrees = 90
	
	line.position = line_pos - (line.size / 2.0)
	
	# Metadados essenciais para identificação
	line.set_meta("type", type)
	line.set_meta("x", x)
	line.set_meta("y", y)
	
	# Nome único para podermos encontrar esta linha depois via código
	line.name = "Line_%s_%d_%d" % [type, x, y]
	
	line.pressed.connect(_on_line_pressed.bind(line))

func _on_line_pressed(line_node: Button) -> void:
	var type = line_node.get_meta("type")
	var x = line_node.get_meta("x")
	var y = line_node.get_meta("y")
	
	# Verificação local rápida apenas para evitar cliques em linhas já ocupadas
	if board_logic.is_move_legal(type, x, y):
		
		#print("[CLICK] type=", type, " x=", x, " y=", y)
		line_clicked.emit(type, x, y)

# Esta função é chamada pela GameRoom quando o servidor confirma a jogada
func update_line_visual(type: String, x: int, y: int, color: Color) -> void:
	var line_name = "Line_%s_%d_%d" % [type, x, y]
	var line_node = get_node_or_null(line_name)
	if not line_node:
		print("NAO ACHOU LINHA:", line_name)
		return

	print("ACHOU LINHA:", line_name, " filhos=", line_node.get_children())

	var fill := line_node.get_node("Fill") as ColorRect
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# garante o Fill por cima
	line_node.move_child(fill, line_node.get_child_count() - 1)

	fill.color = Color(color.r, color.g, color.b, 1.0)



	line_node.disabled = true



func spawn_box(bx: int, by: int, color: Color) -> void:
	var box = box_scene.instantiate() as Control
	# Centraliza a caixa no meio do quadrado formado pelos 4 pontos
	var box_center = Vector2((bx + 0.5) * spacing, (by + 0.5) * spacing) + offset
	
	add_child(box)
	box.position = box_center - (box.size / 2.0)
	box.modulate = color

	# Garante que a caixa fique atrás das linhas e pontos para não tapar o visual
	move_child(box, 0)
