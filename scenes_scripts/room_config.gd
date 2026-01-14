extends TextureRect 


func _on_ok_button_pressed() -> void:
	if Global.my_id == 0:
		$AcceptDialog.dialog_text = "Ainda conectando ao servidor... espere 1s e tente de novo."
		$AcceptDialog.popup_centered()
		return
		
	var num_players = $MarginContainer/VBoxContainer/MaxBox/NumPlayerInput.text.to_int() 
	var b_size = $MarginContainer/VBoxContainer/GridBox/BoardSizeInput.text.to_int()
	
	var erro_msg = ""
	
	if num_players < 2 or num_players > 5:
		erro_msg = "A sala deve ter entre 2 e 5 jogadores!"
	elif b_size < 3 or b_size > 10: #TODO VOLTAR PARA 5
		erro_msg = "O tabuleiro deve ter entre 5 e 10!"
		
	if erro_msg != "":
		$AcceptDialog.dialog_text = erro_msg
		$AcceptDialog.popup_centered()
		return 
	
	# Primeiro cria a intenção para criar sala
	Global.pending_action = "create"

	# Depois salva no Global as configs da sala
	Global.pending_room_id = str(Global.my_id) # TODO: TROCAR PARA OUTRO ID AQUI DPS
	Global.pending_num_players = num_players
	Global.pending_board_size = b_size

	# Por fim vai para a tela de perfil (nome/cor), é lá que vamos chamar a função do network para criar a sala
	get_tree().change_scene_to_file("res://scenes/PlayerProfile.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
