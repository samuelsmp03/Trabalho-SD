extends Node

# Esse script é a lógica local do CLIENTE.
# É responsável por manter o estado local do cliente a partir dos eventos de rede.
# Não executa RPC diretamente. Escuta sinais do NetworkManager e repassa para a UI e vice versa.


const Messages = preload("res://core/messages.gd")
const GameConfig = preload("res://core/game_config.gd")

#signal room_state_changed(room_data: Dictionary)

signal send_room_list_updated_to_UI (list_of_rooms: Array) 
signal send_room_state_changed_to_UI(room_data: Dictionary)
signal move_received(move_data: Dictionary)
signal game_started
signal game_over(payload: Dictionary)

var room_data: Dictionary = {}          # último RECEIVE_ROOM_UPDATE completo
var players_details: Array = []         # room_data["players_details"] (lista)
var token_owner: int = -1               # 

var _did_emit_game_started := false

# Variáveis paraconexão/reconexão
var _connect_retry_count := 0
var _connecting := false
var _last_ip: String = ""
var _last_port: int = 0


@onready var network := get_node_or_null("/root/NetworkManager")
@onready var global := get_node_or_null("/root/Global")


func _ready():
	if network == null:
		push_error("[CLIENT] Network autoload não encontrado (/root/NetworkManager).")
		return
	if global == null:
		push_error("[CLIENT] Global autoload não encontrado (/root/Global).")
		return

# Conecta os sinais emitidos pelo NetworkManager (nossa camada RPC)
		
	if network.has_signal("room_updated"):
		network.room_updated.connect(_on_room_updated)

	if not network.game_started.is_connected(_on_game_started):
		network.game_started.connect(_on_game_started)

	if network.has_signal("move_received"):
		network.move_received.connect(_on_move_received)

	if network.has_signal("game_over"):
		network.game_over.connect(_on_game_over)
		
	if network.has_signal("room_list_updated"):
		network.room_list_updated.connect(_on_room_list_updated)
		
	if not network.multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		network.multiplayer.connected_to_server.connect(_on_connected_to_server)

	if not network.multiplayer.connection_failed.is_connected(_on_connection_failed):
		network.multiplayer.connection_failed.connect(_on_connection_failed)

	if not network.multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		network.multiplayer.server_disconnected.connect(_on_server_disconnected)

	

# -------------------------
# Eventos vindos do NetworkManager
# -------------------------

func _on_room_updated(new_room_data: Dictionary) -> void:
	room_data = new_room_data

	# Atualiza dados da sala no Global para facilitar acesso pelas cenas
	global.room_id = str(room_data.get("room_id", ""))

	# status da sala (WAITING / PLAYING / FINISHED)
	if room_data.has("status"):
		global.room_status = int(room_data["status"])

	# tamanho do tabuleiro / max players 
	if room_data.has("board_size"):
		global.board_size = int(room_data["board_size"])

	if room_data.has("target_player_count"):
		global.max_players = int(room_data["target_player_count"])
	elif room_data.has("max_players"):
		global.max_players = int(room_data["max_players"])

	# token_owner 
	token_owner = int(room_data.get("token_owner", -1))
	global.current_turn_player_id = token_owner

	# players_details (lista) e room_players (dict/cache pra UI)
	players_details = room_data.get("players_details", [])
	global.room_players = _players_list_to_dict(players_details)
	
	send_room_state_changed_to_UI.emit(room_data)
	

func _on_game_started() -> void:
	if _did_emit_game_started: return
	_did_emit_game_started = true
	game_started.emit()



func _on_move_received(move_data: Dictionary) -> void:
	move_received.emit(move_data)


func _on_game_over(payload: Dictionary) -> void:
	Global.last_game_result = payload
	game_over.emit(payload)
	
func _on_room_list_updated(list_of_rooms:Array) -> void:
	#Envia a lista atualizada de salas para a UI, precisa disso para a cena JoinRoom, para aparecer as salas lá
	send_room_list_updated_to_UI.emit(list_of_rooms)

# -------------------------
# Funções que encaminham para a camada de rede
# (pra não ter que chamar NetworkManager diretamente)
# -------------------------

func create_room(r_id:String, n_players:int, b_size:int) -> void:
	if network:
		network.create_room(r_id, n_players, b_size)

func join_room(r_id:String) -> void:
	if network:
		network.join_room(r_id)

func make_move(tipo:String, x:int, y:int, scored:bool) -> void:
	if network:
		network.make_move(tipo, x, y, scored)

func get_rooms_list() -> void:
	if network:
		network.get_rooms_list()
		
func request_game_over(ranking: Array, winner_id: int) -> void:
	if network:
		network.request_game_over(ranking, winner_id)




# -------------------------
# Consultas uteis para UI
# -------------------------

func is_my_turn() -> bool:
	return int(global.my_id) == int(global.current_turn_player_id)

func get_room_status_text() -> String:
	return global.get_room_status_text()

func get_players_details() -> Array:
	return players_details


# -------------------------
# Utils
# -------------------------

func _players_list_to_dict(list_data: Array) -> Dictionary:
	var d: Dictionary = {}
	for p in list_data:
		if typeof(p) == TYPE_DICTIONARY and p.has("id"):
			d[int(p["id"])] = p
	return d



#-------------------------
# Conexões
#------------------------
func connect_with_retry(ip:String, port: int) -> void:
	_last_ip = ip
	_last_port = port
	
	_connect_retry_count = 0
	_connecting = true
	
	print("[CLIENT] connect_with_retry ->", ip, ":", port)
	network.start_client(ip,port)

func _on_connected_to_server() -> void:
	if not _connecting:
		return
	_connecting = false
	_connect_retry_count = 0
	print("[CLIENT] Conectado com sucesso. ")
	
func _on_connection_failed() -> void:
	if not _connecting:
		return
	_connect_retry_count += 1
	print("[CLIENT] connection_failed: tentativa ", _connect_retry_count, "/", GameConfig.MAX_CONNECT_RETRIES)

	# Ainda tem tentativas?
	if _connect_retry_count < GameConfig.MAX_CONNECT_RETRIES:
		await get_tree().create_timer(GameConfig.RETRY_DELAY_SEC).timeout
		print("[CLIENT] Retentando conexão...")
		network.start_client(_last_ip, _last_port)
		return

	# Esgotou
	_connecting = false
	global.push_ui_event(
		"Não foi possível conectar ao servidor após %d tentativas.\nVerifique IP/porta, servidor ligado e sua conexão."
		% GameConfig.MAX_CONNECT_RETRIES,
		Messages.EVT_CONNECTION_ESTABLISH_FAILED
	)

func _on_server_disconnected() -> void:
	#TODO: tratar queda do servidor durante o jogo
	pass

#TODO: on_client_disconnected para tratar queda do cliente durante o jogo

	
