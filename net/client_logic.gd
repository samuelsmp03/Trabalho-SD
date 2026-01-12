extends Node

# Esse script é a lógica local do CLIENTE.
# É responsável por manter o estado local do cliente a partir dos eventos de rede.
# Não executa RPC diretamente. Escuta sinais do NetworkManager e repassa para a UI e vice versa.

signal room_state_changed(room_data: Dictionary)
signal move_received(move_data: Dictionary)
signal game_started
signal game_over(payload: Dictionary)

var room_data: Dictionary = {}          # último RECEIVE_ROOM_UPDATE completo
var players_details: Array = []         # room_data["players_details"] (lista)
var token_owner: int = -1               # 

@onready var network := get_node_or_null("/root/NetworkManager")
@onready var global := get_node_or_null("/root/Global")


func _ready():
	if network == null:
		push_error("[ClientLogic] Network autoload não encontrado (/root/NetworkManager).")
		return
	if global == null:
		push_error("[ClientLogic] Global autoload não encontrado (/root/Global).")
		return

# Conecta os sinais emitidos pelo NetworkManager (nossa camada RPC)
	if network.has_signal("room_updated"):
		network.room_updated.connect(_on_room_updated)

	if network.has_signal("game_started"):
		network.game_started.connect(_on_game_started)

	if network.has_signal("move_received"):
		network.move_received.connect(_on_move_received)

	if network.has_signal("game_over"):
		network.game_over.connect(_on_game_over)


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

	room_state_changed.emit(room_data)


func _on_game_started() -> void:
	game_started.emit()


func _on_move_received(move_data: Dictionary) -> void:
	move_received.emit(move_data)


func _on_game_over(payload: Dictionary) -> void:
	global.room_status = global.GameConfig.RoomStatus.FINISHED
	game_over.emit(payload)
	
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
	# Converte [{id: X, ...}, ...] em { X: {...}, ... } para lookup rapido na UI
	var d: Dictionary = {}
	for p in list_data:
		if typeof(p) == TYPE_DICTIONARY and p.has("id"):
			d[int(p["id"])] = p
	return d
