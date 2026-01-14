extends RefCounted

# ---- ESTRUTURA DOS PAYLOADS -----

static func create_room_config_payload(room_id:String, player_name:String, player_color: Color, num_players: int, board_size: int) -> Dictionary:
	#criador do jogo (host) define numero de jogadores e tamanho da malha
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
static func create_game_over_payload(ranking: Array, winner_id: int) -> Dictionary:
	return {
		"ranking": ranking,      # [{id,name,score}, ...] já ordenado
		"winner_id": winner_id
	}


#----- EVENTOS LOCAIS (não é RPC) -------
const EVT_CONNECTION_ESTABLISH_FAILED = "evt_connection_establish_failed"
const EVT_CONNECTION_LOST             = "evt_connection_lost"
const EVT_DISCONNECTED_NORMALLY       = "evt_disconnected_normally"
const EVT_CONNECTION_ESTABLISHED      = "evt_connection_established"
