extends Node

# Esse script funciona como uma camada de rede.
# O cliente e o servidor o utilizam para fazer as chamadas RPC.


const ServerLogic = preload("res://net/server_logic.gd")
const Messages = preload("res://core/messages.gd")


# Sinais

signal room_list_updated(rooms: Array) # Lista de Salas (Network -> Cliente)
signal room_updated(room_data: Dictionary) # Atualização de Sala (Network -> Cliente)
signal game_started # TODO servidor não emite isso ainda
#signal goto_wait_room #TODO servidor não emite isso ainda
signal move_received(move_data: Dictionary) # Cliente recebe jogada (Network -> Cliente)
signal game_over(payload: Dictionary) # Servidor anunciou fim de jogo (Servidor -> Network -> Cliente)

var last_room_data: Dictionary = {} #Pra ajudar na hora de trocar de cena em wait_room.gd 
var server_node: Node = null



func _ensure_connected() -> bool:
	return multiplayer.multiplayer_peer != null and \
		multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func start_dedicated_server(port: int):
	var peer = WebSocketMultiplayerPeer.new()
	var err := peer.create_server(port)
	if err != OK:
		push_error("[SERVIDOR] create_server falhou: %s" % err)
		return

	multiplayer.multiplayer_peer = peer

	server_node = ServerLogic.new()
	server_node.name = "ServerLogic"
	add_child(server_node)
	server_node.setup()
	

	print("[SERVIDOR] Online na porta ", port)


func start_client(ip: String, port: int):
	var peer = WebSocketMultiplayerPeer.new()
	var err = peer.create_client("ws://" + ip + ":" + str(port))
	if err != OK:
		push_error("[CLIENTE] create_client falhou: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	print("[CLIENTE] Conectando...")


func _on_connected():
	Global.my_id = multiplayer.get_unique_id()

	var peers := multiplayer.get_peers()
	Global.server_id = peers[0] if peers.size() > 0 else 1

	print("[CLIENTE] conectado. my_id=", Global.my_id, " server_id=", Global.server_id)


func _on_failed():
	push_error("[CLIENTE] Falha ao conectar")



# --- API para o Client Logic ---
func create_room(r_id: String, n_players: int, b_size: int):
	if not _ensure_connected():
		print("[CLIENTE] ainda não conectado (create_room)")
		return

	var payload = Messages.create_room_config_payload(
		r_id,
		Global.my_name,
		Global.my_color,
		n_players,
		b_size
	)
	rpc_id(Global.server_id, "rpc_request_create_room", payload)


func join_room(r_id: String):
	if not _ensure_connected():
		print("[CLIENTE] ainda não conectado (join_room)")
		return

	var payload = Messages.create_join_game_payload(r_id, Global.my_name, Global.my_color)
	rpc_id(Global.server_id, "rpc_request_join_room", payload)


func make_move(tipo: String, x: int, y: int, scored: bool):
	if not _ensure_connected():
		print("[CLIENTE] ainda não conectado (make_move)")
		return

	var payload = Messages.create_move_payload(tipo, x, y, scored)
	rpc_id(Global.server_id, "rpc_request_make_move", payload)


func get_rooms_list():
	if not _ensure_connected():
		print("[CLIENTE] ainda não conectado (get_rooms_list)")
		return
	rpc_id(Global.server_id, "rpc_request_room_list")


# --- SEND helpers (usados pelo ServerLogic) ---
func send_room_update_to(peer_id: int, room_data: Dictionary) -> void:
	rpc_id(peer_id, "rpc_receive_room_update", room_data)

func send_room_list_to(peer_id: int, list_of_rooms: Array) -> void:
	rpc_id(peer_id, "rpc_receive_room_list", list_of_rooms)

func send_start_game_to(peer_id: int) -> void:
	rpc_id(peer_id, "rpc_start_game")

func send_broadcast_move_to(peer_id: int, move_data: Dictionary) -> void:
	rpc_id(peer_id, "rpc_broadcast_move", move_data)
	
func send_game_over_to(peer_id:int, payload:Dictionary): 
	rpc_id(peer_id, "rpc_broadcast_game_over", payload)

# --- RPC: CLIENTE -> SERVIDOR ---
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_create_room(payload: Dictionary):
	if multiplayer.is_server() and server_node:
		server_node.handle_create_room(payload, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func rpc_request_join_room(payload: Dictionary):
	if multiplayer.is_server() and server_node:
		server_node.handle_join_room(payload, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func rpc_request_make_move(payload: Dictionary):
	if multiplayer.is_server() and server_node:
		server_node.handle_make_move(payload, multiplayer.get_remote_sender_id())

@rpc("any_peer", "call_remote", "reliable")
func rpc_request_room_list():
	if multiplayer.is_server() and server_node:
		server_node.handle_room_list(multiplayer.get_remote_sender_id())


# --- RPC: SERVIDOR -> CLIENTE ---
@rpc("any_peer", "call_remote", "reliable")
func rpc_receive_room_update(room_data: Dictionary):
	last_room_data = room_data
	Global.room_id = str(room_data.get("room_id", ""))
	
	# Emite-se o sinal de room_update, esse sinal será escutado no client_logic
	
	room_updated.emit(room_data) 
	
	#var scene = get_tree().current_scene
	#if scene and scene.name in ["JoinRoomByCode", "PlayerProfile"]:
		#goto_wait_room.emit() # Emite-se o sinal de ida para a sala de espera

@rpc("any_peer", "call_remote", "reliable")
func rpc_receive_room_list(list: Array):
	room_list_updated.emit(list)

@rpc("any_peer", "call_remote", "reliable")
func rpc_start_game():
	game_started.emit()

@rpc("any_peer", "call_remote", "reliable")
func rpc_broadcast_move(move_data: Dictionary):
	move_received.emit(move_data)


@rpc("any_peer", "call_remote", "reliable")
func rpc_broadcast_game_over(payload: Dictionary):
	game_over.emit(payload)
