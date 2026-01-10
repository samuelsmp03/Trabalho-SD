extends Node
const GameConfig = preload("res://core/game_config.gd")
const RoomState = preload("res://core/room_state.gd")
const Messages = preload("res://core/messages.gd")

# Variáveis Globais

var players : Dictionary = {} # {peer_id(int) : PlayerState}
var rooms: Dictionary = {}    # {room_id(String): RoomState}
var peer_to_room: Dictionary = {}  # Atalho mais rápido entre salas e jogadores, peer_id(int): room_id (String) } 


# ---- Função de inicialização do servidor ----
func _setup_server (port: int):
	var peer = WebSocketMultiplayerPeer.new() #objeto de rede -> vai ser o servidor
	
	var error = peer.create_server(port) 
	if error != OK:
		print("ERRO: Não foi possível iniciar o servidor na porta ", port)
		return error
	#essa instancia de peer vira o servidor	
	get_tree().get_multiplayer().multiplayer_peer = peer
	
	get_tree().get_multiplayer().peer_connected.connect(_on_peer_connected)
	get_tree().get_multiplayer().peer_disconnected.connect(_on_peer_disconnected)
	
	print("SERVIDOR ONLINE: Escutando na porta ", port)
	return OK
	
	
# ---- Sinais de Conexão e Desconexão ---- 
func _on_peer_connected(id: int):
	
	# Cliente ainda não tem nome, nem sala.
	# Aqui estamos registrando apenas o seu id que o Godot disponibiliza
	print("Peer conectado ao servidor: ", id)
	
	#Cleinte novo fica armazenado num PlayerState inicialmente vazio at[e ele se identificar no Lobby
	# Ele é atualizado na função create_room
	players[id] = RoomState.PlayerState.new(id, "Aguardando...", "", "#FFFFFF")
	
func _on_peer_disconnected(id:int):
	print ("Peer desconectado: ", id)
	
	# Depois temos que add aqui a função para tirar ele da sala e avisar os outros
	# Ou fazer o tratamento necessário para reconexão
	# Por enquanto, estamos apenas limpando o registro
	players.erase(id)
	
	
# ---- Lógica da Sala ----

#Função REQUEST_CREATE_ROOM chamada pelo CLIENTE para criar sala
# Exemplo do Payload que será feito no CLIENTE:
#var meu_payload = {
#    "room_id": "SALA_DA_AMANDA",
#    "player_name": "Amanda",
#    "player_color": "#00FF00", # Verde
#    "target_player_count": 2,    # Jogo para 2 pessoas
#    "board_dimension": 6         # Tabuleiro 6x6
# Isso é enviado assim pelo cliente para o servidor: rpc_id(1, "create_room", meu_payload)
# Esse 1 é o id do servidor

@rpc("any_peer")
func request_create_room(payload: Dictionary):
	print("[SERVIDOR] - 2 - ENTREI EM REQUEST_CREATE_ROOM")
	var sender_id = get_tree().get_multiplayer().get_remote_sender_id()
	print("[DEGUB SERVIDOR] - Payload recebido: ", payload)
	
	var r_id = payload.get("room_id","ERRO_SEM_NOME")
	
	if rooms.has(r_id):
		print("Erro: Sala já existe.")
		return
	
	#Criando sala
	var new_room = RoomState.RoomState.new(
		r_id,
		sender_id,
		payload.num_players,
		payload.board_size)
	rooms[r_id] = new_room
	peer_to_room[sender_id] = r_id
	
	#Atualizando o PlayerState que já existia desde a conexão
	
	_update_player_session(sender_id, payload.player_name, payload.player_color, r_id)

	print("Sala ", r_id, " criada por ", payload.player_name)
	_send_room_info_update(r_id)
#----------------------------------------------------------------	
	
# Funcção JOIN_ROOM chamada pelo Cliente que desejar entrar na sala
# PAyload dessa função contem apenas o id da sala, nome do jogador e cor do jogador
# Isso pq ele está apenas entrando num jogo e não criando
# Exemplo: 
#var payload_entrada = {
#    "room_id": "SALA123",
#    "player_name": "Marcos",
#    "player_color": "#0000FF" # Azul}
# Enviaria assim: rpc_id(1, "join_room" payload_entrada

@rpc("any_peer")
func request_join_room(payload:Dictionary):
	print("[SERVIDOR] ENTREI EM JOIN ROOM - NAO ERA PRA ACONTECER")
	var sender_id = get_tree().get_multiplayer().get_remote_sender_id()
	var r_id = payload.room_id
	
	if not rooms.has(r_id):
		print("Erro: Sala ", r_id, " não encontrada.")
		#Depois temos que adicionar aqui um RPC de erro para o cliente
		return
	var room = rooms[r_id]
	
	#Sala está cheia?
	if room.players.size()>= room.target_player_count: 
		print("Erro: Sala ", r_id, " já está cheia.")
		return
	#O jogo já começou?
	if room.status != GameConfig.RoomStatus.WAITING:
		print("Erro: O jogo na sala ", r_id, " já está em andamento.")
		return

	# Se passou nas validações, adicionamos o jogador à sala
	room.players.append(sender_id)
	peer_to_room[sender_id] = r_id
	
	#Atualizando playerState desse jogador
	_update_player_session(sender_id, payload.player_name, payload.player_color, r_id)
	print("Jogador ", payload.player_name, " entrou na sala ", r_id)
	
	_send_room_info_update(r_id) #atualiza o lobby quando um novo jogador entrar
	#Verificação de Início de Jogo
	if room.players.size() == room.target_player_count:
		_begin_game(r_id)
		
		
		
		
		
		
		
		
#------ LGICA DO JOGO------------------------

#Função MAKE_MOVE chamado pelo cliente quando ele clica para fazer uma linha
@rpc("any_peer")
func request_make_move(payload: Dictionary):
	# Esse payload contém inicialmente (tipo: String, x:int, y: int, scored:bool)
	var sender_id = get_tree().get_multiplayer().get_remote_sender_id()
	
	#Buscando sala
	var r_id = peer_to_room.get(sender_id, "")
	if r_id == "" or not rooms.has(r_id): return 
	var room = rooms[r_id]
	
	if room.token_owner != sender_id: 
		print("Tentativa de jogada fora de turno por: ", sender_id)
		return 
	
	#Transmitindo jogada + id do autor para os outros
	var sync_data = payload.duplicate()
	sync_data["author_id"] = sender_id
	sync_data["timestamp"] = Time.get_unix_time_from_system()
	
	# Primeiro envia a jogada para todos
	for p_id in room.players:
		rpc_id(p_id, Messages.BROADCAST_MOVE, sync_data)
	
	# Depois de enviar a jogada para todos, decide se passa o turno ou se apenas atualiza
	if not payload.scored:
		_next_turn(r_id)  #passa turno 
	else:
		_send_room_info_update(r_id)  #envia atualização da sala para todos. Inclusive a informação mas de quem está com o token

@rpc("any_peer")
func request_room_list():
	var sender_id = get_tree().get_multiplayer().get_remote_sender_id()
	var list_of_rooms = []
	
	for r_id in rooms.keys():
		var room = rooms[r_id]
		var info = {
			"room_id": r_id,
			"player_count": room.players.size(),
			"max_players": room.target_player_count,
			"status": room.status
		}
		list_of_rooms.append(info)
	
	rpc_id(sender_id, Messages.RECEIVE_ROOM_LIST, list_of_rooms)

	
	
# ---- Funções INTERNAS (começam com _) ----
func _handle_game_over(payload: Dictionary):
	var sender_id = get_tree().get_multiplayer().get_remote_sender_id()

	var r_id = peer_to_room.get(sender_id, "")
	if r_id == "":
		return

	var room = rooms[r_id]

	if room.token_owner != sender_id:
		print("Aviso de fim de jogo ignorado pois o player não era dono da vez")
		return

	room.status = GameConfig.RoomStatus.FINISHED
	print("FIM DE JOGO NA SALA: ", r_id)

	for p_id in room.players:
		rpc_id(p_id, Messages.BROADCAST_GAME_OVER, payload)


#Função para atualizar estado do jogador, pq ele é criado sem alguns atributos. 
func _update_player_session(p_id: int, p_name:String, p_color:String, r_id: String):
	var p_state = players[p_id]
	p_state.name = p_name
	p_state.color = p_color
	p_state.room_id = r_id
	
	#Criando atalho para dicionario de busca rapida
	peer_to_room[p_id] = r_id

func _send_room_info_update(r_id: String):
	if not rooms.has(r_id):
		print("[ERRO]: Tentativa de atualizar sala inexistente: ", r_id) 
		return
	var room = rooms[r_id]  #Guarda a sala
	
	var room_data = room.to_dict() # Mantem os dados em um dict
	
	#criando lista com detalhes de cada jogador para enviar também no pacote de payload
	var players_list = []
	for p_id in room.players:
		if players.has(p_id):
			players_list.append(players[p_id].to_dict())
		
	room_data["players_details"] = players_list
	for p_id in room.players:
		rpc_id(p_id, Messages.RECEIVE_ROOM_UPDATE, room_data)
	print("Atualização da sala ", r_id, " enviada para ", room.players.size(), " jogadores.")
		


func _next_turn (r_id:String):
	var room = rooms [r_id]

	var current_idx = room.players.find(room.token_owner)

	var next_idx = (current_idx+1) % room.players.size()
	
	#Atualizando o jogador da vez
	room.token_owner = room.players[next_idx]
	print("Turno passou de ", room.players[current_idx], " para ", room.token_owner)
	
	#Sincronizando com todos
	_send_room_info_update(r_id)
	
func _begin_game(room_id: String):
	var room = rooms[room_id]
	room.status = GameConfig.RoomStatus.PLAYING
	room.token_owner = room.players[0]
	
	print("Iniciando jogo na sala: ", room_id)
	
	for player_id in room.players:
		rpc_id(player_id, Messages.START_GAME)
	
	_send_room_info_update(room_id)
	



#RPC do cliente

@rpc("any_peer") func request_game_over(_data: Dictionary):	 
	_handle_game_over(_data)
	pass

@rpc("any_peer") func receive_room_list(_l: Array): pass

@rpc("any_peer") func receive_room_update(_d: Dictionary): pass

@rpc("any_peer") func start_game(): pass

@rpc("any_peer") func broadcast_move(_d: Dictionary): pass

@rpc("any_peer") func broadcast_game_over(_p: Dictionary): pass

#Todo: Reconexão: receive e request
