#Inicializa servidor e clientes
extends Node


func _ready():
	# Cria uma instância de Servidor
	if "--server" in OS.get_cmdline_args():
		NetworkManager.start_dedicated_server(8080)
	
	# Cria instâncias de cliente
	else:
		NetworkManager.start_client("127.0.0.1", 8080)
		get_tree().call_deferred("change_scene_to_file", "res://scenes/MainMenu.tscn")
