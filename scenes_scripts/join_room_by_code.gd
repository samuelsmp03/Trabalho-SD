extends Control

@onready var code_input = $MarginContainer/HBoxContainer/codeRoom

func _on_ok_button_pressed():
	
	if Global.my_id == 0:
		$AcceptDialog.dialog_text = "Ainda conectando ao servidor... espere 1s e tente de novo."
		$AcceptDialog.popup_centered()
		return

	var room_code = code_input.text.strip_edges().to_upper() 
	
	if room_code == "":
		print("Erro: Digite um código de sala!")
		return
		

	NetworkManager.join_room(room_code)
	get_tree().call_deferred("change_scene_to_file", "res://scenes/WaitRoom.tscn")

	
