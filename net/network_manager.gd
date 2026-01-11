extends Node
const Messages = preload("res://core/messages.gd")

signal room_list_updated(rooms:Array)


const NetServerScript = preload("res://net/net_server.gd")

var _server: Node = null
var _is_server := false


#FUNÇÕES INTERNAS DO JOGADOR
func _ready():
	#conectar com sinais do godot pra saber se a conexão caiu
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)

func start_server(port: int):
	_is_server = true
	print("[SERVER] NetworkManager iniciado:", get_path())

	_server = NetServerScript.new()
	_server.name = "ServerImpl"
	add_child(_server)

	_server._setup_server(port)


func start_client(ip: String, port: int):
	_is_server = false
	print("[CLIENT] NetworkManager iniciado:", get_path())
	connect_to_server(ip, port)


func connect_to_server(ip: String, port: int):
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_client("ws://" + ip + ":" + str(port))
	if error != OK:
		print("[CLIENT] Erro ao iniciar conexão:", error)
		return

	multiplayer.multiplayer_peer = peer
	print("[CLIENT] Conectando ao servidor:", ip, port)

	

func create_room(r_id: String, n_players: int, b_size: int):
	if not _ensure_connected():
		print("[CLIENTE] Ainda não conectado. Função: create_room.")
		return
	print("Vou criar sala. Meu ID: ", Global.my_id)
	
	var payload = Messages.create_room_config_payload(r_id, Global.my_name, Global.my_color, n_players, b_size)
	if (payload):
		print("[CLIENTE]: Enviando payload de CRIAR SALA para servidor: ", payload)
		print("[CLIENTE] Meu node path: ", get_path())
		
		print("[CLIENTE] rpc node:", self, " path:", get_path(), " instance_id:", get_instance_id())

		rpc_id(Global.server_id, "request_create_room", payload)
	else:
		print("[CLIENTE]: payload de CRIAR sala é null")
			

func get_rooms_list():
	if not _ensure_connected():
		print("[CLIENTE] Ainda não conectado. Função: get_rooms_list.")
		return
	rpc_id(Global.server_id, Messages.REQUEST_ROOM_LIST)  #Isso aqui não funciona ainda

func join_room(r_id: String):
	if not _ensure_connected():
		print("[CLIENTE] Ainda não conectado. Função: join_room.")
		return
	print("[CLIENTE] Pedindo para entrar na sala: ", r_id)
	
	var payload = Messages.create_join_game_payload(r_id, Global.my_name, Global.my_color)
	
	rpc_id(Global.server_id,Messages.REQUEST_JOIN_ROOM,payload)
	print("[CLIENTE] Tentando entrar na sala ", r_id, " como ", Global.my_name)
	
	
func make_move(tipo: String, x:int, y: int, scored:bool):
	if not _ensure_connected():
		print("[CLIENTE] Ainda não conectado. Função: make_move")
		return
	var payload = Messages.create_move_payload(tipo,x,y,scored)
	rpc_id(Global.server_id,Messages.REQUEST_MAKE_MOVE,payload)
	
	
func _apply_move(_move_data: Dictionary): 
	# TODO: Essa função é local, recebe a jogada remota e aplica atualizando a UI
	pass

func _send_game_over(_payload: Dictionary): 
	#Todo -> envia mensagem pro servidor falando que o jogo acabou. O nome tá request é só pra informar que sai do cliente par ao s
	pass



#FUNÇÕES RPC 
@rpc("any_peer","call_remote","reliable")
func ping():
	if _is_server:
		print("[SERVER] ping de ", multiplayer.get_remote_sender_id())



@rpc("any_peer", "call_remote", "reliable")
func start_game(): pass


@rpc("any_peer", "call_remote", "reliable")
func request_join_room(payload: Dictionary):
	if _server == null: return
	_server.request_join_room(payload)

@rpc("any_peer", "call_remote", "reliable")
func request_create_room(payload: Dictionary):
	print("[SERVER][Autoload] request_create_room chegou:", payload)
	if _server == null:
		print("[NetworkManager] _server == null; ignorando request_create_room.")
		return
	_server.request_create_room(payload)

@rpc("any_peer", "call_remote", "reliable")
func request_make_move(payload: Dictionary):
	if _server == null: return
	_server.request_make_move(payload)
	
	
@rpc("any_peer", "call_remote", "reliable")
func receive_room_update(_room_data: Dictionary): 
	Global.room_id = str(_room_data.get("id",""))
	
	if get_tree().current_scene.name == "LobbyRooms":
		get_tree().change_scene_to_file("res://scenes/WaitRoom.tscn")

@rpc("any_peer", "call_remote", "reliable")
func broadcast_move(move_data: Dictionary):
	_apply_move(move_data)

@rpc("any_peer", "call_remote", "reliable")
func broadcast_game_over(_payload: Dictionary): pass

@rpc("any_peer", "call_remote", "reliable")
func receive_room_list(list_of_rooms: Array):
	print("A lista chegou: ", list_of_rooms)
	room_list_updated.emit(list_of_rooms)
	# TODO: colocar aqui o código para atualizar os botões da interface com as opções de sala

@rpc("any_peer", "call_remote", "reliable")
func request_room_list():
	if _server == null: return
	_server.request_room_list()


@rpc("any_peer", "call_remote", "reliable")
func request_game_over(payload: Dictionary):
	if _server == null: return
	_server.request_game_over(payload) 



#Todo: reconexão -> receive e request

#SINAIS INTERNOS
func _on_connected():
	print("Conectado com sucesso ao servidor!")
	Global.my_id = multiplayer.get_unique_id()
	print("O meu ID de rede é: ", Global.my_id)
	
	var peers := multiplayer.get_peers()
	print("[CLIENTE] peers list:", peers)

	if peers.size() > 0:
		Global.server_id = peers[0]
		print("[CLIENTE] server_id escolhido:", Global.server_id)
	else:
		print("[CLIENTE] ERRO: peers vazio; ainda não vi o servidor.")

	
	#TESTE DE VIDA RPC
	rpc_id(1,"ping")
	#get_rooms_list()  #pede a lista de salas assim que se conecta

func _on_failed():
	print("Falha ao conectar.")
	
func _ensure_connected() -> bool:
	return multiplayer.multiplayer_peer != null and \
		multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
