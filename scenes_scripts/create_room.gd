extends TextureRect


func _on_ok_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/LobbyStartPlayer.tscn")


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
