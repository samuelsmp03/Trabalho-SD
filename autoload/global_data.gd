# global_data.gd
extends Node

const GameConfig = preload("res://core/game_config.gd")

var flag = ""
var selected_room_id = ""
var server_id: int = 1

# ----- DADOS DO JOGADOR -----
var my_id: int = 0             
var my_name: String = "Jogador" + str(randi() % 1000)      
var my_color: Color = Color.from_hsv(randf(), 0.8, 0.9)
var my_color_hex: String = my_color.to_html()

# ----- DADOS DA SALA -----
var room_id: String = ""      
var is_host: bool = false      
var room_players: Dictionary = {}
var last_game_result: Dictionary = {}

# ----- CONFIGURAÇÕES DO JOGO -----
var board_size: int = GameConfig.DEFAULT_BOARD_SIZE  
var max_players: int = GameConfig.MAX_PLAYERS        
var min_players: int = GameConfig.MIN_PLAYERS        
var current_turn_player_id: int = -1
var room_status: int = GameConfig.RoomStatus.WAITING  

# ---- CONFIGURAÇÕES PARA AÇÃO DE ENTRAR OU CRIAR EM SALA ----
var pending_action: String = ""  # "create" ou "join"
var pending_room_id: String = ""
var pending_num_players: int = 0
var pending_board_size: int = 0


var pending_room_data: Dictionary = {} #ainda não tá sendo usado

# ----- FUNÇÕES ÚTEIS -----
func clear_pending():
	pending_action = ""
	pending_room_id = ""
	pending_num_players = 0
	pending_board_size = 0
	
	
func is_valid_board_size(size: int) -> bool:
	return size >= GameConfig.MIN_BOARD_SIZE and size <= GameConfig.MAX_BOARD_SIZE

func is_valid_player_count(count: int) -> bool:
	return count >= GameConfig.MIN_PLAYERS and count <= GameConfig.MAX_PLAYERS

func get_room_status_text() -> String:
	match room_status:
		GameConfig.RoomStatus.WAITING:
			return "Aguardando jogadores"
		GameConfig.RoomStatus.PLAYING:
			return "Em andamento"
		GameConfig.RoomStatus.FINISHED:
			return "Finalizado"
		_:
			return "Desconhecido"

func reset_pending_data():
	pending_room_data = {}
