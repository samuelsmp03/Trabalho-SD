extends Control

@onready var code_input = $MarginContainer/HBoxContainer/codeRoom

func _on_ok_button_pressed():
	var room_code = code_input.text.strip_edges().to_upper() 
	
	if room_code == "":
		print("Erro: Digite um código de sala!")
		return
		
	if Global.my_id == 0:
		print("Erro crítico: Dados do jogador não encontrados no Global.")
		return
		
	NetClient._join_room(room_code)
