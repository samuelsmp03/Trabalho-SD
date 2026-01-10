extends TextureRect


func _on_criar_sala_pressed() -> void:
	Global.flag = "criar"
	get_tree().change_scene_to_file("res://scenes/CreateRoom.tscn")


func _on_entrar_sala_pressed() -> void:
	Global.flag = "entrar"
	get_tree().change_scene_to_file("res://scenes/LobbyStartPlayer.tscn")
