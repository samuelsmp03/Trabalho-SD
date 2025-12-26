extends RefCounted

const GameConfig = preload("res://core/game_config.gd")
# ===================================================
# CLASSE: PlayerState
# Representação do estado do jogador no SERVIDOR
# O servidor guarda as informações da sessão, não o estado do jogo (do tabuleiro)
# ===================================================
class PlayerState:
	var peer_id: int        
	var name: String       
	var room_id: String     
	var color: String      
	var connected: bool     

	func _init(p_id: int, p_name: String, p_room_id: String, p_color_hex: String):
		peer_id = p_id
		name = p_name
		room_id = p_room_id
		color = p_color_hex 
		connected = true

	# converte o objeto PlayerState para dicionário
	func to_dict() -> Dictionary:
		return {
			"peer_id": peer_id,
			"name": name,
			"room_id": room_id,
			"color": color, 
			"connected": connected
		}

# ===================================================
# CLASSE: RoomState
# Representa o estado de uma sala de jogo no SERVIDOR
# ===================================================
class RoomState:
	var id:String
	var players: Array[int]
	var host: int
	var token_owner: int
	var status: int
	
	var target_player_count: int
	var board_dimension: int
	
	func _init(room_id: String, host_id: int, p_target_player_count: int, p_board_dim: int):
		id = room_id
		players = [host_id]
		host = host_id
		token_owner = host_id
		status = GameConfig.RoomStatus.WAITING
		
		# Configurações da sala
		target_player_count = p_target_player_count
		board_dimension = p_board_dim 
		
	# converte o objeto RoomState para um dicionário 
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"peer_ids_in_room": players,
			"host": host,
			"token_owner": token_owner,
			"status": GameConfig.RoomStatus.keys()[status],
			"target_player_count": target_player_count,
			"board_dimension": board_dimension
		}
		
		
# IDEIA DA ESTRUTURA GLOBAL DE GERENCIAMENTO (Para implementar no net_server.gd)
# é o Formato de como o Servidor deverá organizar os dados.

# players: Dictionary<int, PlayerState>
#   players = {
#       2: PlayerState(peer_id=2, ...), 
#       3: PlayerState(peer_id=3, ...)
#   }
#
# rooms: Dictionary<String, RoomState>
#   rooms = {
#       "ABCDE": RoomState(id="ABCDE", host=2, ...)
#   }
#
# peer_to_room: Dictionary<int, String> ( Seria um mapa rápido para encontrar a sala de um peer)
#   peer_to_room = {
#       2: "ABCDE",
#       3: "ABCDE"
#   }
