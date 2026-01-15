extends Control

@onready var name_input = $MarginContainer/VBoxContainer/NameBox/LineEdit
@onready var color_grid = $MarginContainer/VBoxContainer/GridContainer
@onready var ok_button = $MarginContainer/VBoxContainer/MarginContainer/okButton
#@onready var network_manager = get_node("/root/NetworkManager")
@onready var ClientLogic = get_node("/root/ClientLogic")
var selected_color: Color = Color.WHITE
var color_selected: bool = false


func _ready():
	# Mostra  fluxo que está acontecendo no console
	if Global.pending_action == "create":
		print("[PLAYER_PROFILE] Perfil para CRIAR sala: ", Global.pending_room_id)
	elif Global.pending_action == "join":
		print("[PLAYER_PROFILE] Perfil para ENTRAR em sala existente")
	else:
		print("[PLAYER_PROFILE] Configure Seu Perfil")

	for button in color_grid.get_children():
		if button is Button:
			# define a cor real do jogador (você escolhe aqui)
			# se você já setou a cor no Inspector via modulate, copie uma vez e guarda em meta:
			button.set_meta("pick_color", button.modulate)
			button.pressed.connect(_on_color_selected.bind(button.get_meta("pick_color")))


	ok_button.pressed.connect(_on_ok_pressed)


func _on_color_selected(color: Color):
	selected_color = color
	color_selected = true
	ok_button.modulate = color
	print("[PLAYER_PROFILE] Cor selecionada confirmada: ", color)


func _on_ok_pressed():
	var p_name = name_input.text.strip_edges()

	if p_name.length() < 3:
		_shake_node(name_input)
		print("[PLAYER_PROFILE] Erro: Nome muito curto!")
		return

	if not color_selected:
		print("[PLAYER_PROFILE] Erro: Escolha uma cor antes de continuar!")
		return

	# Salva perfil local
	Global.my_name = p_name
	Global.my_color = selected_color
	Global.my_color_hex = selected_color.to_html(false) # "#RRGGBB"
	print("[PLAYER_PROFILE] Perfil salvo:", p_name, " HEX:", Global.my_color_hex)
	


	# -------------------------
	# DECISÃO DO FLUXO (ou cria sala vindo do Create Room, ou está entrando em sala existente - selecionada )
	# -------------------------

	# Criando sala (veio do CreateRoom)
	if Global.pending_action == "create":
		# opcional: protege caso ainda esteja conectando
		if Global.my_id == 0:
			print("[PLAYER_PROFILE] Ainda conectando ao servidor... tente novamente.")
			return

		print("=== [PLAYER_PROFILE] CRIANDO SALA NOVA ===")
		print("Configuração da sala:")
		print("  Nome:", Global.pending_room_id)
		print("  Jogadores:", Global.pending_num_players)
		print("  Tabuleiro:", Global.pending_board_size, "x", Global.pending_board_size)
		print("  Criador:", Global.my_name, "Cor:", Global.my_color)
		
		ClientLogic.create_room(
			str(Global.pending_room_id),
			int(Global.pending_num_players),
			int(Global.pending_board_size)
		)

		# Limpar pendências
		Global.clear_pending()

		get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")
		return

	# TERCEIRO Entrando em sala existente (veio do botão Entrar Sala)
	elif Global.pending_action == "join":
		print("[PLAYER_PROFILE] Indo para escolha de sala sala...")
		Global.clear_pending()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/JoinRoom.tscn")
		return

	else:
		print("[PLAYER_PROFILE] Fluxo desconhecido. Indo para JoinRoom...")
		get_tree().call_deferred("change_scene_to_file", "res://scenes/JoinRoom.tscn")


func _shake_node(node):
	var tween = create_tween()
	tween.tween_property(node, "position:x", node.position.x + 10, 0.05)
	tween.tween_property(node, "position:x", node.position.x - 10, 0.05)
	tween.set_loops(2)
