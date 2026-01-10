extends Node
const Messages = preload("res://core/messages.gd")

signal room_list_updated(rooms:Array)

#FUNÇÕES INTERNAS DO JOGADOR
func _ready():
	#conectar com sinais do godot pra saber se a conexão caiu
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)

#FUNÇÕES DE CONEXÃO - as ações do jogador
func _connect_to_server(ip: String, port: int):
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_client("ws://" + ip + ":" + str(port))
	if error != OK:
		print("Erro ao tentar iniciar o cliente: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Tentando conectar em: ", ip, ":", port)


func _create_room(r_id: String, n_players: int, b_size: int):
	var payload = Messages.create_room_config_payload(r_id, Global.my_name, Global.my_color, n_players, b_size)
	rpc_id(1, Messages.REQUEST_CREATE_ROOM, payload)

func _get_rooms():
	rpc_id(1, Messages.REQUEST_ROOM_LIST)  #Isso aqui não funciona ainda

func _join_room(r_id: String):
	print("[CLIENTE] Pedindo para entrar na sala: ", r_id)
	
	var payload = Messages.create_join_game_payload(r_id, Global.my_name, Global.my_color)
	
	rpc_id(1,Messages.REQUEST_JOIN_ROOM,payload)
	print("[CLIENTE] Tentando entrar na sala ", r_id, " como ", Global.my_name)
	
	
func _make_move(tipo: String, x:int, y: int, scored:bool):
	#TODO: OK! Da mesma forma do anterior, também vai ter que criar a mensagem usando a função create_move_payload e depois fazer o rpc
	var payload = Messages.create_move_payload(tipo,x,y,scored)
	rpc_id(1,Messages.REQUEST_MAKE_MOVE,payload)
	
	
func _apply_move(_move_data: Dictionary): 
	# TODO: Essa função é local, recebe a jogada remota e aplica atualizando a UI
	pass

func _send_game_over(_payload: Dictionary): 
	#Todo -> envia mensagem pro servidor falando que o jogo acabou. O nome tá request é só pra informar que sai do cliente par ao s
	pass



#FUNÇÕES RPC . Request -> cliente envia / Receive -> cliente recebe

@rpc("any_peer")
func start_game(): pass


@rpc("any_peer")
func request_join_room(_payload: Dictionary):
	# Fica vazia no cliente, pois quem executa é o servidor
	pass

@rpc("any_peer")
func request_create_room(_payload: Dictionary):
	pass

@rpc("any_peer")
func request_make_move(_payload: Dictionary):
	pass

@rpc("any_peer")
func receive_room_update(_room_data: Dictionary): 
	Global.room_id = _room_data.id
	
	if get_tree().current_scene.name == "LobbyRooms":
		get_tree().change_scene_to_file("res://scenes/WaitRoom.tscn")

@rpc("any_peer")
func broadcast_move(move_data: Dictionary):
	_apply_move(move_data)

@rpc("any_peer")
func broadcast_game_over(_payload: Dictionary): pass

@rpc("any_peer")
func receive_room_list(list_of_rooms: Array):
	print("A lista chegou: ", list_of_rooms)
	room_list_updated.emit(list_of_rooms)
	# TODO: colocar aqui o código para atualizar os botões da interface com as opções de sala

@rpc("any_peer") func request_room_list(): pass

@rpc("any_peer") func request_game_over(_p: Dictionary): pass


#Todo: reconexão -> receive e request

#SINAIS INTERNOS
func _on_connected():
	print("Conectado com sucesso ao servidor!")
	Global.my_id = multiplayer.get_unique_id()
	print("O meu ID de rede é: ", Global.my_id)
	_get_rooms()  #pede a lista de salas assim que se conecta

func _on_failed():
	print("Falha ao conectar.")
