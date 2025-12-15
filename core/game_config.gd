extends Node

enum RoomStatus {
	WAITING,  #esperando por mais jogadores
	PLAYING,   
	FINISHED
}

enum PeerType {
	CLIENT,
	SERVER
}


# Configuração de Jogadores

const MIN_PLAYERS  = 2
const MAX_PLAYERS = 5


# Configuração de Tabuleiro
const DEFAULT_BOARD_SIZE = 5 
const MIN_BOARD_SIZE = 4
const MAX_BOARD_SIZE = 10

# Tempo Limite
const MAX_TURB_TIME = 10 #Tempo máximo para jogar (Segundos)
const MAX_LOBBY_WAIT = 60 #tempo máximo de espera no lobby
