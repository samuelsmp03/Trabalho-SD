extends TextureRect
@onready var room_label = $MarginContainer/VBoxContainer/roomLabel
@onready var room_ocupancy_label = $MarginContainer/VBoxContainer/statusLabel
@onready var players_list = $MarginContainer/VBoxContainer/playersList
#@onready var network_manager = get_node("/root/NetworkManager")
@onready var ClientLogic = get_node("/root/ClientLogic")

var _changing:=false

func _ready():
	room_ocupancy_label.text = "Aguardando jogadores..."
	room_label.text = "Sala: " + str(Global.room_id if Global.room_id != "" else "--")


	ClientLogic.send_room_state_changed_to_UI.connect(_on_room_update)
	ClientLogic.game_started.connect(_on_start_game)
	
	if ClientLogic.room_data.size() > 0: #aplica o úmtimo estado se chegou antes, mais rápido dessa função waitroom._ready conectar o sinal
		_on_room_update(ClientLogic.room_data)
	else:
		room_ocupancy_label.text = "Aguardando jogadores..."
		room_label.text = "Sala: " + str(Global.room_id if Global.room_id != "" else "--")


func _on_room_update(room_data: Dictionary):
	room_label.text = "Sala: " + room_data.get("room_id", "--")

	room_ocupancy_label.text = "Jogadores: %d / %d" % [
		room_data.get("players", []).size(),
		room_data.get("target_player_count", 0)
	]

	# Limpa lista
	for child in players_list.get_children():
		child.queue_free()

	for player in room_data.get("players_details", []):
		var lbl = Label.new()
		lbl.text = player.get("name", "???")
		players_list.add_child(lbl)
	
	# Verifica se tem a quantidade de jogadores desejados e inicia o jogo.
	if room_data.get("players", []).size() == room_data.get("target_player_count", 0):
		print("[WAIT ROOM] Aguardando rpc_start_game do servidor")

	else:
		print("[WAIT ROOM] Ainda não tem a quantidade de jogadores necessários para iniciar o jogo")
	
func _on_start_game():
	if _changing:
		return   # já estou trocando, ignora
	_changing = true
	room_ocupancy_label.text = "Jogo iniciando..."
	get_tree().call_deferred("change_scene_to_file", "res://scenes/GameRoom.tscn")


	
