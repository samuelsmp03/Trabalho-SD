extends Control

@onready var code_input = $MarginContainer/VBoxContainer/HBoxContainer/codeRoom
@onready var room_list_container = $MarginContainer/VBoxContainer/ScrollContainer/RoomListContainer
@onready var empty_label = $MarginContainer/VBoxContainer/EmptyLabel

@onready var ClientLogic = get_node("/root/ClientLogic")

@onready var room_item_scene = preload("res://scenes/auxiliary_nodes/RoomItem.tscn")


func _ready():
	# escuta a lista vinda do ClientLogic
	if ClientLogic.has_signal("send_room_list_updated_to_UI"): 
		ClientLogic.send_room_list_updated_to_UI.connect(_on_room_list_updated)
	else:
		push_error("[JoinRoomByCode] ClientLogic não tem o sinal send_room_list_updated_to_UI")

	# pede lista assim que abrir a tela
	ClientLogic.get_rooms_list()
	
func _on_ok_button_pressed():
	
	if Global.my_id == 0:
		$AcceptDialog.dialog_text = "Ainda conectando ao servidor... espere 1s e tente de novo."
		$AcceptDialog.popup_centered()
		return

	var room_code = code_input.text.strip_edges().to_upper() 
	
	if room_code == "":
		print("Erro: Digite um código de sala!")
		return

	ClientLogic.join_room(room_code)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")
	
	
	#Função para atualizar a UI quando uma nova lista de salas chega. Cria dinamicamente a lista. 
func _on_room_list_updated(list_of_rooms: Array) -> void:
	
	for child in room_list_container.get_children():
		child.queue_free()  #limpa a lista anterior
		
	#Se não há salas, mostra a mensagem
	if list_of_rooms.is_empty():
		empty_label.text = "Nenhuma sala disponível no momento"
		empty_label.visible = true
		return
	
	empty_label.visible = false
	#criando um item por sala
	for room_info in list_of_rooms:
		if typeof(room_info) != TYPE_DICTIONARY:
			continue
		
		_add_room_item(room_info)
		
	
# Função para adicionar a linha com a sala para a pessoa entrar
func _add_room_item(room_info: Dictionary) -> void:
	var room_id: String = str(room_info.get("room_id", ""))
	var player_count: int = int(room_info.get("player_count", 0))
	var max_players: int = int(room_info.get("max_players", 0))
	var status = room_info.get("status", 0)
	var host_name = room_info.get("host_name", "")
	
	# Instancia a cena RoomItem
	var room_item = room_item_scene.instantiate()
	
	# Configura os labels
	var room_id_label = room_item.get_node("RoomIdLabel")
	var room_info_label = room_item.get_node("RoomInfoLabel")
	var spacer = room_item.get_node("Spacer")
	var join_button = room_item.get_node("JoinButton")
	
	room_id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	
	# Define os textos
	room_id_label.text = "Sala: " + room_id
	
	var status_text = _get_status_text(int(status))
	var info_text = "• %d/%d • %s" % [player_count, max_players, status_text]
	if host_name != "" and host_name != "Desconhecido":
		info_text = "Criado por " + host_name + " " + info_text
	
	room_info_label.text = info_text
	
	# Configura o botão
	join_button.text = "Entrar"
	join_button.disabled = (player_count >= max_players) or (int(status) == 1)
	join_button.pressed.connect(func():
		_on_join_button_pressed(room_id)
	)
	
	# Adiciona a linha ao container
	room_list_container.add_child(room_item)
	
	
# Função pra quanto qualquer botão Entrar for pressionado
func _on_join_button_pressed(room_id: String) -> void:
	if Global.my_id == 0:
		$AcceptDialog.dialog_text = "Ainda conectando ao servidor... espere 1s e tente de novo"
		$AcceptDialog.popup_centered()
		return

	if room_id == "":
		return

	ClientLogic.join_room(room_id)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")

# Função auxiliar pra converter status numérico para texto
func _get_status_text(status: int) -> String:
	match status:
		0: return "Aguardando..."
		1: return "Em jogo"
		2: return "Encerrada"
		_: return "Desconhecido"
