extends RefCounted

# Este arquivo define o protocolo de comunicação
# Estamos usando mensagens para cada tipo de comando/evento

# ----- GERENCIAMENTO -----

const REQUEST_CREATE_ROOM = "request_create_room"
const REQUEST_JOIN_ROOM = "request_join_room"
const REQUEST_ROOM_LIST = "request_room_list"
const RECEIVE_ROOM_LIST = "receive_room_list"
const START_GAME = "start_game"
#adicionar player_config se precisarmos

#---- Sala ----
const RECEIVE_ROOM_UPDATE = "receive_room_update"


# ---- LOGICA DO JOGO -----
const REQUEST_MAKE_MOVE = "request_make_move" #cliente envia jogada para servidor
const BROADCAST_MOVE = "broadcast_move" #servidor envia jogada para os clientes aplicarem o movimento

# ---- FIM DE JOGO -----
const REQUEST_GAME_OVER = "request_game_over"   #Cliente notifica que o jogo acabou
const BROADCAST_GAME_OVER = "broadcast_game_over"   #Servidor avisa a todos que o jogo acabou

# ---- RECONEXÃO ----
const REQUEST_RECONNECT_STATE = "request_reconnect_state"
const RECEIVE_RECONNECT_STATE = "receive_reconnect_state"

# ---- ESTRUTURA DOS PAYLOADS -----

static func create_room_config_payload(room_id:String, player_name:String, player_color: Color, num_players: int, board_size: int) -> Dictionary:
	#criador do jogo (host) define numero de jogadores e tamanho da malha
	print("Passou por aqui: create_Room_config_payload em messages")
	return {
		"room_id": room_id,
		"player_name": player_name,
		"player_color": player_color.to_html(true),
		"num_players": num_players, 
		"board_size": board_size     
		
	}

# O Tabuleiro tem forma (tipo, x, y), onde tipo é vertical ou horizontal
#MEnsagem padrão para as jogadas
static func create_move_payload(tipo:String, x: int, y:int, has_scored:bool) -> Dictionary:
	
	#Não estamos enviando o jogador_id pq o servidor pode saber quem está enviando a mensagem usando get_tree().get_rpc_sender_id() 
	return {
		"move_type": tipo, # "H" ou "V"
		"pos_x": x,
		"pos_y": y,
		"scored": has_scored
	}
static func create_join_game_payload(r_id: String, p_name:String, p_color:Color):
	return {
		"room_id": r_id,
		"player_name": p_name,
		"player_color": p_color.to_html(false)
	}

#TODO: create_game_over_payload
