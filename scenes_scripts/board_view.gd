extends Control

@export var dot_scene: PackedScene
@export var line_scene: PackedScene
@export var box_scene: PackedScene

var board_logic: BoardState

var spacing: int = 100
var offset: Vector2 = Vector2(50, 50)

signal line_clicked(type: String, x: int, y: int)

func _spawn_line(type: String, x: int, y: int) -> void:
	var line = line_scene.instantiate() as Button
	add_child(line) 
	
	line.pivot_offset = line.size / 2.0
	
	var line_pos = Vector2.ZERO
	if type == "h":
		# Meio do caminho entre ponto (x,y) e (x+1, y)
		line_pos = Vector2((x + 0.5) * spacing, y * spacing) + offset
		line.rotation_degrees = 0
	else:
		# Meio do caminho entre ponto (x,y) e (x, y+1)
		line_pos = Vector2(x * spacing, (y + 0.5) * spacing) + offset
		line.rotation_degrees = 90
	
	line.position = line_pos - (line.size / 2.0)
	
	# Metadados e Sinais
	line.set_meta("type", type)
	line.set_meta("x", x)
	line.set_meta("y", y)
	line.pressed.connect(_on_line_pressed.bind(line))
	line.name = "Line_%s_%d_%d" % [type, x, y]

func setup_view(w: int, h: int, logic_ref: BoardState) -> void:
	board_logic = logic_ref
	for n in get_children(): n.queue_free()
	
	for i in range(w):
		for j in range(h):
			if i < w - 1: _spawn_line("h", i, j)
			if j < h - 1: _spawn_line("v", i, j)
			
	for i in range(w):
		for j in range(h):
			var dot = dot_scene.instantiate()
			add_child(dot)
			dot.pivot_offset = dot.size / 2.0
			var dot_pos = Vector2(i * spacing, j * spacing) + offset
			dot.position = dot_pos - (dot.size / 2.0)
			
func spawn_box(bx: int, by: int, color: Color) -> void:
	var box = box_scene.instantiate() as Control

	var box_center = Vector2((bx + 0.5) * spacing, (by + 0.5) * spacing) + offset
	
	add_child(box)
	
	box.position = box_center - (box.size / 2.0)
	box.modulate = color

	move_child(box, 0)

func _on_line_pressed(line_node: Button) -> void:
	var type = line_node.get_meta("type")
	var x = line_node.get_meta("x")
	var y = line_node.get_meta("y")
	
	if board_logic.is_move_legal(type, x, y):

		line_node.disabled = true 
		line_node.modulate = Color.RED 
		line_clicked.emit(type, x, y)

func update_line_visual(type: String, x: int, y: int, color: Color) -> void:
	var line_name = "Line_%s_%d_%d" % [type, x, y]
	var line_node = get_node_or_null(line_name)
	
	if line_node:
		line_node.modulate = color
		line_node.disabled = true # Garante que o botão fique travado
