extends TextureRect



func _ready():
	print("[MainMenu] pedindo conexão via ClientLogic")
	ClientLogic.connect_with_retry("127.0.0.1", 8080)


func _on_criar_sala_pressed() -> void:
	Global.pending_action = "create"
	get_tree().change_scene_to_file("res://scenes/RoomConfig.tscn")


func _on_entrar_sala_pressed() -> void:
	Global.pending_action = "join_code"
	get_tree().change_scene_to_file("res://scenes/PlayerProfile.tscn")
