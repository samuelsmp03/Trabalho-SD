extends TextureRect 


func _on_ok_button_pressed() -> void:
	var num_players = $MarginContainer/VBoxContainer/MaxBox/NumPlayerInput.text.to_int() 
	var b_size = $MarginContainer/VBoxContainer/GridBox/BoardSizeInput.text.to_int()
	
	var erro_msg = ""
	
	if num_players < 2 or num_players > 5:
		erro_msg = "A sala deve ter entre 2 e 5 jogadores!"
	elif b_size < 5 or b_size > 10:
		erro_msg = "O tabuleiro deve ter entre 5 e 10!"
		
	if erro_msg != "":
		$AcceptDialog.dialog_text = erro_msg
		$AcceptDialog.popup_centered()
		return 
	
	var room_id = str(randi() % 10)
	
	if NetClient:
		NetClient._create_room(room_id, num_players, b_size)
		get_tree().change_scene_to_file("res://scenes/LobbyStartPlayer.tscn")
	else:
		$AcceptDialog.dialog_text = "Erro crítico: Gerenciador de rede não encontrado."
		$AcceptDialog.popup_centered()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
