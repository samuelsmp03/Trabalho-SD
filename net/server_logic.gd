extends Node
const GameConfig = preload("res://core/game_config.gd")
const RoomState = preload("res://core/room_state.gd")
const Messages = preload("res://core/messages.gd")

# Variáveis Globais

var players : Dictionary = {} # {peer_id(int) : PlayerState}
var rooms: Dictionary = {}    # {room_id(String): RoomState}
var peer_to_room: Dictionary = {}  # Atalho mais rápido entre salas e jogadores, peer_id(int): room_id (String) }

# Cores disponíveis
const AVAILABLE_COLORS: Array[String] = [
	"#FB5677",
	"#00B29A",
	"#000082",
	"#C000D8",
	"#BFC3FF",
	"#C67500"
]

# ---- Função de inicialização do servidor ----
# OBS:  quem inicia o servidor de rede é o Network.gd (autoload).
# Então este script só precisa "escutar" eventos de conexão/desconexão.

func setup() -> void:
	randomize() # Para poder sortear uma cor caso usuario selecione uma já usada
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[SERVIDOR] ServerLogic pronto. Meu node path: ", get_path())


# ---- Sinais de Conexão e Desconexão ----
func _on_peer_connected(id: int):
	# Cliente ainda não tem nome, nem sala.
	# Aqui estamos registrando apenas o seu id que o Godot disponibiliza
	print("[SERVIDOR] Peer conectado ao servidor: ", id)

	#Cleinte novo fica armazenado num PlayerState inicialmente vazio até ele se identificar no PlayerProfile
	# Ele é atualizado na função create_room / join_room
	players[id] = RoomState.PlayerState.new(id, "Aguardando...", "", "#FFFFFF")


func _on_peer_disconnected(id: int):
	print("[SERVIDOR] Peer desconectado: ", id)

	var r_id: String = peer_to_room.get(id, "")
	if r_id != "" and rooms.has(r_id):
		var room = rooms[r_id]

		# Guarda ordem antiga para passar token corretamente (PLAYING)
		var old_players: Array = room.players.duplicate()
		var old_idx := old_players.find(id)

		# Remove o jogador da sala
		room.players.erase(id)

		# -------------------------
		# SALA DE ESPERA (WAITING)
		# -------------------------
		if room.status == GameConfig.RoomStatus.WAITING:
			# Se não sobrou ninguém, apaga a sala
			if room.players.size() == 0:
				rooms.erase(r_id)
			else:
				# Se o host caiu e sobrou alguém, promove
				if int(room.host) == int(id):
					room.host = int(room.players[0])

				# Mantém token_owner consistente (na espera, costuma ser o host)
				if int(room.token_owner) == int(id):
					room.token_owner = int(room.host)

				_send_room_info_update(r_id)

		# -------------------------
		# JOGO EM ANDAMENTO (PLAYING)
		# -------------------------
		elif room.status == GameConfig.RoomStatus.PLAYING:
			# Sala vazia? apaga
			if room.players.size() == 0:
				rooms.erase(r_id)
			else:
				# Se quem caiu estava na vez e ainda restou mais de 1, passa o token
				if int(room.token_owner) == int(id) and room.players.size() > 1:
					if old_idx == -1:
						old_idx = 0
					var next_idx: int = old_idx % room.players.size()
					room.token_owner = int(room.players[next_idx])

				# Se sobrou só 1, encerra e manda pro ranking (payload via Messages)
				if room.players.size() == 1:
					var winner_id := int(room.players[0])

					var ranking: Array = []
					if players.has(winner_id):
						var p = players[winner_id].to_dict()
						if not p.has("score"):
							p["score"] = 0
						ranking.append(p)
					else:
						ranking.append({"id": winner_id, "name": "Jogador", "color": "#FFFFFF", "score": 0})

					var payload := Messages.create_game_over_payload(ranking, winner_id)

					room.status = GameConfig.RoomStatus.FINISHED
					NetworkManager.send_game_over_to(winner_id, payload)
					_send_room_info_update(r_id)
				else:
					_send_room_info_update(r_id)

		# Outros estados
		else:
			# Se quiser, pode apagar sala se ficar vazia; caso contrário, só manda update
			if room.players.size() == 0:
				rooms.erase(r_id)
			else:
				_send_room_info_update(r_id)

	# Limpa registros globais
	players.erase(id)
	peer_to_room.erase(id)

# ---- Lógica da Sala ----

func handle_create_room(payload: Dictionary, sender_id: int) -> void:
	print("[SERVIDOR] PEDIDO DE CRIAÇÃO DE SALA RECEBIDO. PAYLOAD: ", payload)

	var r_id := str(payload.get("room_id", "ERRO_SEM_NOME"))
	var target_player_count := int(payload.get("num_players", 0))
	var board_size := int(payload.get("board_size", 0))
	var player_name := str(payload.get("player_name", ""))
	var player_color = payload.get("player_color", payload.get("color", "#FFFFFF"))

	# Normaliza tudo para HEX "#RRGGBB"
	if typeof(player_color) == TYPE_COLOR:
		player_color = (player_color as Color).to_html()
	elif typeof(player_color) == TYPE_ARRAY and player_color.size() >= 3:
		var a = float(player_color[3]) if player_color.size() >= 4 else 1.0
		player_color = Color(float(player_color[0]), float(player_color[1]), float(player_color[2]), a).to_html()
	elif typeof(player_color) != TYPE_STRING:
		player_color = "#FFFFFF"

	if r_id == "ERRO_SEM_NOME" or target_player_count <= 0 or board_size <= 0:
		print("[SERVIDOR] Payload inválido, abortando criação.")
		return

	if rooms.has(r_id):
		print("[SERVIDOR] Erro: Sala já existe.")
		return

	#Criando sala
	var new_room = RoomState.RoomState.new(
		r_id,
		sender_id,
		target_player_count,
		board_size
	)

	rooms[r_id] = new_room
	peer_to_room[sender_id] = r_id

	_update_player_session(sender_id, player_name, player_color, r_id)

	print("Sala ", r_id, " criada por ", player_name)

	if not rooms.has(r_id):
		print("[SERVIDOR] Erro: rooms perdeu a sala logo após criar. r_id:", r_id)
		return
	#print("[SERVIDOR DEBUG] create_room inst:", get_instance_id(), "rooms keys:", rooms.keys())

	_send_room_info_update(r_id)


#----------------------------------------------------------------

func handle_join_room(payload:Dictionary, sender_id: int) -> void:
	var r_id := str(payload.get("room_id", ""))
	var player_name := str(payload.get("player_name", ""))
	var player_color := str(payload.get("player_color", "#FFFFFF"))
	# Garantindo que a cor do jogador é única
	player_color = _ensure_unique_color(r_id, str(player_color))

	print("[SERVIDOR]: Alguém quer entrar na sala: ", player_name)

	if not rooms.has(r_id):
		print("[SERVIDOR] Erro: Sala ", r_id, " não encontrada.")
		#TODO: Depois temos que devolver o erro para o cliente
		return

	var room = rooms[r_id]

	var current_room : String = peer_to_room.get(sender_id, "")
	#Jogador está em outra sala?
	if current_room != "" and current_room != r_id:
		print("[SERVIDOR] Erro: peer ", sender_id, " já está na sala ", current_room, " e tentou entrar em ", r_id)
		return

	# Jogador já esta na sala?
	if room.players.has(sender_id):
		print("[SERVIDOR] Aviso: peer ", sender_id, "já está na sala ", r_id)
		return

	#Sala está cheia?
	if room.players.size() >= room.target_player_count:
		print("[SERVIDOR] Erro: Sala ", r_id, " já está cheia.")
		return

	#O jogo já começou?
	if room.status != GameConfig.RoomStatus.WAITING:
		print("[SERVIDOR] Erro: O jogo na sala ", r_id, " já está em andamento.")
		return

	# Se passou nas validações, adicionamos o jogador à sala
	room.players.append(sender_id)
	peer_to_room[sender_id] = r_id

	#Atualizando playerState desse jogador
	_update_player_session(sender_id, player_name, player_color, r_id)
	print("[SERVIDOR] Jogador ", player_name, " entrou na sala ", r_id)

	_send_room_info_update(r_id) #atualiza o wait_room quando um novo jogador entrar

	#Verificação de Início de Jogo
	if room.players.size() == room.target_player_count:
		_begin_game(r_id)


#------ LOGICA DO JOGO------------------------

#Função MAKE_MOVE chamado pelo cliente quando ele clica para fazer uma linha
func handle_make_move(payload: Dictionary, sender_id: int) -> void:
	# Esse payload contém inicialmente (tipo: String, x:int, y: int, scored:bool)

	#Buscando sala
	var r_id = peer_to_room.get(sender_id, "")
	if r_id == "" or not rooms.has(r_id):
		return
	var room = rooms[r_id]

	if room.token_owner != sender_id:
		print("[SERVIDOR] Tentativa de jogada fora de turno por: ", sender_id)
		return

	#Transmitindo jogada + id do autor para os outros
	var sync_data = payload.duplicate()
	
	
	sync_data["author_id"] = sender_id
	sync_data["timestamp"] = Time.get_unix_time_from_system()

	# Primeiro envia a jogada para todos
	for p_id in room.players:
		
		#  O Network.gd (autoload) é a ponte RPC, por isso é get_parent
		NetworkManager.send_broadcast_move_to(p_id, sync_data)

	# Depois de enviar a jogada para todos, decide se passa o turno ou se apenas atualiza
	if not bool(payload.get("scored", false)):
		_next_turn(r_id)  #passa turno
	else:
		_send_room_info_update(r_id)  #envia atualização da sala para todos. Inclusive a informação de quem está com o token


func handle_room_list(sender_id: int) -> void:
	var list_of_rooms: Array = []

	for r_id in rooms.keys():
		var room = rooms[r_id]
		var info = {
			"room_id": r_id,
			"player_count": room.players.size(),
			"max_players": room.target_player_count,
			"status": room.status,
			"host_id": room.host,			  #host_id
			"host_name": ""
 		}
		
		#Busca o nome do host no dicionário de jogadores. "host" é o host_id 
		if players.has(room.host):    #se ele tem ID do host
			var host_state = players[room.host] 
			info["host_name"] = host_state.name 
		
		list_of_rooms.append(info)

	NetworkManager.send_room_list_to(sender_id, list_of_rooms)

# ---- Funções INTERNAS (começam com _) ----
func handle_game_over(payload: Dictionary, sender_id: int) -> void:
	var r_id: String = str(peer_to_room.get(sender_id, ""))
	if r_id == "" or not rooms.has(r_id):
		return

	var room = rooms[r_id]

	# evita repetição (2 clientes podem pedir ao mesmo tempo)
	if room.status == GameConfig.RoomStatus.FINISHED:
		return

	room.status = GameConfig.RoomStatus.FINISHED
	print("[SERVIDOR]FIM DE JOGO NA SALA:", r_id)

	for p_id in room.players:
		NetworkManager.send_game_over_to(p_id, payload)

	_send_room_info_update(r_id)


#Função para atualizar estado do jogador, pq ele é criado sem alguns atributos.
func _update_player_session(p_id: int, p_name:String, p_color:String, r_id: String):
	var p_state = players[p_id]
	p_state.name = p_name
	p_state.color = p_color
	p_state.room_id = r_id

	#Criando atalho para dicionario de busca rapida
	peer_to_room[p_id] = r_id

# Retorna quais cores estão sendo usadas
func _get_used_colors(room_id: String) -> Dictionary:
	var used := {}
	if not rooms.has(room_id):
		return used

	var room = rooms[room_id]
	for pid in room.players:
		if players.has(pid):
			used[str(players[pid].color)] = true
	return used

func _ensure_unique_color(room_id: String, requested_color: String) -> String:
	var used := _get_used_colors(room_id)

	# Se a cor pedida é válida e não está em uso, aceita
	if AVAILABLE_COLORS.has(requested_color) and not used.has(requested_color):
		return requested_color

	# Lista de cores livres
	var free_colors: Array[String] = []
	for c in AVAILABLE_COLORS:
		if not used.has(c):
			free_colors.append(c)

	# Se ainda tem cores livres, escolhe uma aleatória
	if free_colors.size() > 0:
		return free_colors[randi() % free_colors.size()]

	# Fallback (não deveria acontecer se max_players <= 6)
	return AVAILABLE_COLORS[randi() % AVAILABLE_COLORS.size()]


func _send_room_info_update(r_id: String):
	#print("[SERVIDOR] DEBUG send_update inst:", get_instance_id(), " r_id:", r_id, " keys:", rooms.keys())

	if not rooms.has(r_id):
		print("[SERVIDOR] Erro : Tentativa de atualizar sala inexistente: ", r_id)
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
		# Envia room_update para o Network que en
		NetworkManager.send_room_update_to(p_id, room_data)

	print("[SERVIDOR] Atualização da sala ", r_id, " enviada para ", room.players.size(), " jogadores.")


func _next_turn (r_id:String):
	var room = rooms[r_id]

	var current_idx = room.players.find(room.token_owner)
	var next_idx = (current_idx + 1) % room.players.size()

	#Atualizando o jogador da vez
	room.token_owner = room.players[next_idx]
	print("[SERVIDOR] Turno passou de ", room.players[current_idx], " para ", room.token_owner)

	#Sincronizando com todos
	_send_room_info_update(r_id)


func _begin_game(room_id: String):
	var room = rooms[room_id]
	room.status = GameConfig.RoomStatus.PLAYING
	room.token_owner = room.players[0]

	print("[SERVIDOR] Iniciando jogo na sala: ", room_id)

	for player_id in room.players:
		NetworkManager.send_start_game_to(player_id)

	_send_room_info_update(room_id)


#TODO: Reconexão: receive e request
