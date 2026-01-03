extends RefCounted

# Este arquivo define o protocolo de comunicação
# Estamos usando mensagens para cada tipo de comando/evento

# ----- LOBBY/GERENCIAMENTO -----

const REQUEST_CREATE_ROOM = "create_room"
const REQUEST_JOIN_ROOM = "join_room"
const UPDATE_PLAYER_CONFIG = "update_player_config"
const START_GAME = "start_game"



# ---- SINCRONIZAÇÃO DE ESTADO DA PARTIDA DO SERVIDOR -> CLIENTE -----

#Mensagem que o servidor envia para atualizar o estado da sala (lista de players)
const ROOM_INFO_UPDATE = "room_info_update"
const RECEIVE_ROOM_UPDATE = "receive_room_update"

# Mensagem que o servidor envia para notificar a mudança de turno.
const UPDATE_TURN_INFO = "update_turn_info"  #alterar isso no documento, pq lá t pass_token

# ---- LOGICA DO JOGO -----
const MAKE_MOVE = "make_move" #cliente envia jogada para servidor
const BROADCAST_MOVE = "broadcast_move" #servidor envia jogada para os clientes aplicarem o movimento

# ---- FIM DE JOGO -----
const NOTIFY_GAME_OVER = "notify_game_over"
const ON_GAME_OVER = "on_game_over"
const RECONECCT_STATE_REQUEST = "reconnect_state_request"
const RECONNECT_STATE_RESPONSE = "reconnect_state_response"

# ---- ESTRUTURA DOS PAYLOADS -----

static func create_room_config_payload(room_id:String, player_name:String, player_color: Color, num_players: int, board_size: int) -> Dictionary:
	#criador do jogo (host) define numero de jogadores e tamanho da malha
	return {
		"room_id": room_id,
		"player_name": player_name,
		"player_color": player_color.to_html(false),
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
