extends Node

enum RoomStatus {
	WAITING,  #esperando por mais jogadores
	PLAYING,   
	FINISHED
}
#
#enum PeerType {
	#CLIENT,
	#SERVER
#}

# Configuração de Jogadores

const MIN_PLAYERS  = 2
const MAX_PLAYERS = 5


# Configuração de Tabuleiro
const DEFAULT_BOARD_SIZE = 5
const MIN_BOARD_SIZE = 3
const MAX_BOARD_SIZE = 10

# Tempo Limite
const TURN_TIME_SEC = 10 #Tempo máximo para jogar (Segundos)
const MAX_WAIT_ROOM = 60 #tempo máximo de espera na sala de espera

# Máximo de Reconexão
const MAX_CONNECT_RETRIES := 3
const RETRY_DELAY_SEC := 1.0
