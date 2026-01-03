extends Node
const Messages = preload("res://core/messages.gd")

signal room_list_updated(rooms:Array)

#FUNÇÕES INTERNAS DO JOGADOR
func _ready():
	#conectar com sinais do godot pra saber se a conexão caiu
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)

#FUNÇÕES DE CONEXÃO - as ações do jogador
func connect_to_server(ip: String, port: int):
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_client("ws://" + ip + ":" + str(port))
	if error != OK:
		print("Erro ao tentar iniciar o cliente: ", error)
		return
	multiplayer.multiplayer_peer = peer
	print("Tentando conectar em: ", ip, ":", port)


func create_room(r_id, p_name, p_color: Color, n_players, b_size):
	#Preenchi para teste do servidor
	print("[CLIENTE]- EXECUTEI  CREATE_ROOM")
	var payload = Messages.create_room_config_payload(r_id, p_name, p_color, n_players, b_size)
	rpc_id(1, Messages.REQUEST_CREATE_ROOM, payload)

func get_rooms():
	rpc_id(1, "request_room_list")  #Isso aqui não funciona ainda

func join_room(r_id, p_name, p_color:Color):
	#TODO: Criar a mansagem e manda pro servidor -> create_join_game_payload
	pass
func make_move(tipo: String, x:int, y: int, scored:bool):
	#TODO: Da mesma forma do anterior, também vai ter que criar a mensagem usando a função create_move_payload e depois fazer o rpc
	pass
		
func apply_remote_move(_move_data: Dictionary): 
	# TODO: Essa função é local, recebe a jogada remota e aplica atualizando a UI
	pass





#FUNÇÕES RECEBIDAS DO SERVIDOR

@rpc("any_peer")
func start_game(): pass

@rpc("any_peer")
func request_create_room(_payload: Dictionary): pass

@rpc("any_peer")
func request_join_room(_payload: Dictionary): pass

@rpc("any_peer")
func receive_room_update(_room_data: Dictionary): 
	#TODO: Aqui tem que chamar uma outra função pra atualizar a UI
	pass

@rpc("any_peer")
func on_game_over(_payload: Dictionary): pass

@rpc("any_peer")
func request_make_move(_payload: Dictionary): pass

@rpc("any_peer")
func receive_move(move_data: Dictionary):
	apply_remote_move(move_data)

@rpc("any_peer")
func notify_game_over(_payload: Dictionary): pass

@rpc("any_peer")
func receive_room_list(list_of_rooms: Array):
	print("A lista chegou: ", list_of_rooms)
	room_list_updated.emit(list_of_rooms)
	# TODO: colocar aqui o código para atualizar os botões da interface com as opções de sala

@rpc("any_peer") func request_room_list(): pass

#SINAIS INTERNOS
func _on_connected():
	print("Conectado com sucesso ao servidor!")
	get_rooms()  #pede a lista de salas assim que se conecta

func _on_failed():
	print("Falha ao conectar.")
