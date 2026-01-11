extends Control

@onready var name_input = $MarginContainer/VBoxContainer/NameBox/LineEdit
@onready var color_grid = $MarginContainer/VBoxContainer/GridContainer
@onready var ok_button = $MarginContainer/VBoxContainer/MarginContainer/okButton
@onready var network_manager = get_node("/root/NetworkManager")

var selected_color: Color = Color.WHITE
var color_selected: bool = false 
var room_data: Dictionary =  {}

func set_room_data(data: Dictionary):
	room_data = data
	print("Dados recebidos da sala:", room_data)
	
func _ready():
	
	if room_data.size() > 0:
		print("Perfil para Sala: " + str(room_data.get("room_id", "")))

	
	elif Global.pending_room_data.has("room_id") :
		print("Perfil para Sala: " + str(Global.pending_room_data.get("room_id", "")))

	else:
		print("Configure Seu Perfil")
	
	
	for button in color_grid.get_children():
		if button is Button:
			button.pressed.connect(_on_color_selected.bind(button.modulate))
	
	ok_button.pressed.connect(_on_ok_pressed)

func _on_color_selected(color: Color):
	selected_color = color
	color_selected = true 
	ok_button.modulate = color
	print("Cor selecionada confirmada: ", color)

func _on_ok_pressed():
	var p_name = name_input.text.strip_edges()
	
	if p_name.length() < 3:
		_shake_node(name_input)
		print("Erro: Nome muito curto!")
		return
		
	if not color_selected:
		print("Erro: Escolha uma cor antes de continuar!")
		return
	
	Global.my_name = p_name
	Global.my_color = selected_color
	print("Perfil salvo: ", p_name, " - Cor: ", selected_color)
	

	if room_data.size() > 0:  # Veio de create_room (tem dados)
		# CRIAR SALA NOVA
		network_manager.create_room(
		str(room_data.get("room_id", "")),
		int(room_data.get("num_players", 0)),
		int(room_data.get("b_size", 0)))

		get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")

		
	elif Global.selected_room_id != "":
	# ENTRAR EM SALA EXISTENTE
		network_manager.join_room(Global.selected_room_id)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")

	else:
		print("Indo para seleção/criação de sala...")
		get_tree().call_deferred("change_scene_to_file", "res://scenes/LobbyRoom.tscn")


func _create_new_room():
	print("=== CRIANDO SALA NOVA ===")
	
	# Pegar dados da sala do Global
	var room_id = Global.pending_room_data.room_id
	var num_players = Global.pending_room_data.num_players
	var b_size = Global.pending_room_data.b_size
	
	print("Configuração da sala:")
	print("  Nome:", room_id)
	print("  Jogadores:", num_players)
	print("  Tabuleiro:", b_size, "x", b_size)
	print("  Criador:", Global.my_name, "Cor:", Global.my_color)
	
	# Chamar NetworkManager para criar sala
	network_manager.create_room(room_id, num_players, b_size)
	
	# Limpar dados temporários
	Global.pending_room_data = {}
	
	# Ir para sala de espera
	get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")


func _join_existing_room():
	print("=== ENTRANDO EM SALA EXISTENTE ===")
	
	# Aqui você precisa ter o room_id salvo em algum lugar
	# Por exemplo: Global.selected_room_id
	if  Global.selected_room_id != "":
		print("Entrando na sala:", Global.selected_room_id)
		network_manager.join_room(Global.selected_room_id)
		get_tree().change_scene_to_file("res://scenes/WaitRoom.tscn")
	else:
		print("Erro: Nenhuma sala selecionada!")
		# Volta para lista de salas
		get_tree().change_scene_to_file("res://scenes/LobbyRoom.tscn")

func _shake_node(node):
	var tween = create_tween()
	tween.tween_property(node, "position:x", node.position.x + 10, 0.05)
	tween.tween_property(node, "position:x", node.position.x - 10, 0.05)
	tween.set_loops(2)
